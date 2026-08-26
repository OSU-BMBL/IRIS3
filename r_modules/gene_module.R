#!/usr/bin/env Rscript
#' IRIS3 Gene Module Assignment
#'
#' Assigns QUBIC2 biclusters to cell types and generates promoter sequences
#' for motif discovery.
#'
#' Input:
#'   - {jobid}_blocks.conds.txt - QUBIC2 conditions file
#'   - {jobid}_blocks.gene.txt - QUBIC2 genes file
#'   - {jobid}_cell_label.txt - Cell type labels
#'   - {jobid}_gene_name.txt - Gene names
#'
#' Output:
#'   - {jobid}_CT_{n}_bic/ folders with FASTA sequences per cell type
#'   - {jobid}_gene_id_name.txt - Gene ID to name mapping

# Load utility modules
# Get script directory - works for both source() and Rscript
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg))))
  }
  tryCatch({
    script_file <- sys.frame(1)$ofile
    if (!is.null(script_file)) return(dirname(normalizePath(script_file)))
  }, error = function(e) NULL)
  return(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils/library_loader.R"))
source(file.path(script_dir, "utils/gene_annotation.R"))

# Load required libraries
load_iris3_libraries(c("core", "annotation"))

# Additional genome packages (Human + Mouse only)
suppressPackageStartupMessages({
  library(ensembldb)
  library(BSgenome.Hsapiens.UCSC.hg38)
  library(BSgenome.Mmusculus.UCSC.mm10)
  library(TxDb.Hsapiens.UCSC.hg38.knownGene)
  library(TxDb.Mmusculus.UCSC.mm10.knownGene)
})

#' Species-specific genome databases
.genome_db <- list(
  Human = list(
    bsgenome = BSgenome.Hsapiens.UCSC.hg38,
    txdb = TxDb.Hsapiens.UCSC.hg38.knownGene,
    orgdb = org.Hs.eg.db
  ),
  Mouse = list(
    bsgenome = BSgenome.Mmusculus.UCSC.mm10,
    txdb = TxDb.Mmusculus.UCSC.mm10.knownGene,
    orgdb = org.Mm.eg.db
  )
)

#' Parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  params <- list(
    working_dir = args[1],
    jobid = args[2],
    promoter_len = as.numeric(args[3]),
    gene_module_file = args[4],
    delim_gene_module = args[5]
  )

  # Handle delimiter
  if (!is.na(params$delim_gene_module)) {
    params$delim_gene_module <- switch(
      params$delim_gene_module,
      "tab" = "\t",
      "space" = " ",
      params$delim_gene_module
    )
  }

  return(params)
}

#' Read QUBIC2 block files
#' @param jobid Job identifier
#' @return List with conds and genes
read_qubic_blocks <- function(jobid) {

  conds_file <- paste0(jobid, "_blocks.conds.txt")
  genes_file <- paste0(jobid, "_blocks.gene.txt")

  if (!file.exists(conds_file) || !file.exists(genes_file)) {
    stop("QUBIC2 block files not found")
  }

  # Read conditions (cells)
  conds <- readLines(conds_file)
  conds <- strsplit(conds, " ")
  conds <- lapply(conds, function(x) x[-1])  # Remove first element

  # Read genes
  genes <- readLines(genes_file)
  genes <- strsplit(genes, " ")
  genes <- lapply(genes, function(x) x[-1])

  return(list(conds = conds, genes = genes))
}

#' Filter biclusters by size
#' @param blocks List with conds and genes
#' @param min_genes Minimum genes per bicluster
#' @param max_genes Maximum genes per bicluster
#' @return Filtered blocks
filter_biclusters <- function(blocks, min_genes = 4, max_genes = 1000) {

  gene_counts <- sapply(blocks$genes, length)
  keep <- (gene_counts >= min_genes) & (gene_counts <= max_genes)

  message(sprintf("Filtering biclusters: %d -> %d",
                  length(blocks$genes), sum(keep)))

  return(list(
    conds = blocks$conds[keep],
    genes = blocks$genes[keep]
  ))
}

#' Calculate cell type enrichment p-values
#' @param cell_list Character vector of cells in bicluster
#' @param cell_labels Data frame with Cell and Label columns
#' @return Data frame with p-values per cell type
calc_celltype_enrichment <- function(cell_list, cell_labels) {

  unique_labels <- unique(cell_labels$Label)
  n_celltypes <- length(unique_labels)

  pvalues <- sapply(unique_labels, function(ct) {
    # Cells in this cell type
    ct_cells <- cell_labels$Cell[cell_labels$Label == ct]

    # Hypergeometric test parameters
    m <- length(ct_cells)              # White balls (cells in cell type)
    n <- nrow(cell_labels) - m         # Black balls (cells not in cell type)
    k <- length(cell_list)             # Balls drawn (cells in bicluster)
    x <- sum(cell_list %in% ct_cells)  # White balls drawn (overlap)

    # Upper tail probability
    pval <- 1 - phyper(x - 1, m, n, k)

    return(pval)
  })

  # Bonferroni correction
  pvalues <- pmin(pvalues * n_celltypes, 1)

  return(data.frame(
    cell_type = unique_labels,
    pvalue = pvalues,
    stringsAsFactors = FALSE
  ))
}

#' Assign biclusters to cell types
#' @param blocks List with conds and genes
#' @param cell_labels Data frame with Cell and Label columns
#' @param pvalue_threshold Maximum p-value for assignment
#' @return List mapping cell types to gene lists
assign_to_celltypes <- function(blocks, cell_labels, pvalue_threshold = 0.05) {

  n_celltypes <- length(unique(cell_labels$Label))
  assignments <- vector("list", n_celltypes)
  names(assignments) <- sort(unique(cell_labels$Label))

  for (i in seq_along(blocks$conds)) {
    # Get enrichment
    enrich <- calc_celltype_enrichment(blocks$conds[[i]], cell_labels)

    # Skip if no valid enrichment results
    if (is.null(enrich) || nrow(enrich) == 0 || all(is.na(enrich$pvalue))) {
      next
    }

    # Assign to most enriched cell type (if significant)
    min_idx <- which.min(enrich$pvalue)
    if (length(min_idx) == 0) {
      next
    }

    best_ct <- enrich$cell_type[min_idx]
    best_pval <- enrich$pvalue[min_idx]

    if (!is.na(best_pval) && best_pval < pvalue_threshold) {
      if (is.null(assignments[[best_ct]])) {
        assignments[[best_ct]] <- list()
      }
      assignments[[best_ct]] <- c(assignments[[best_ct]], list(blocks$genes[[i]]))
    }
  }

  return(assignments)
}

#' Get promoter sequences for genes
#' @param gene_symbols Character vector of gene symbols
#' @param species "Human" or "Mouse"
#' @param upstream Base pairs upstream of TSS
#' @return DNAStringSet of promoter sequences
get_promoter_sequences <- function(gene_symbols, species, upstream = 1000) {

  db <- .genome_db[[species]]

  # Get gene coordinates
  genes_gr <- tryCatch({
    genes(db$txdb)
  }, error = function(e) {
    warning("Failed to get gene coordinates")
    return(NULL)
  })

  if (is.null(genes_gr)) return(NULL)

  # Convert gene symbols to Entrez IDs
  entrez_map <- AnnotationDbi::select(
    db$orgdb,
    keys = gene_symbols,
    columns = "ENTREZID",
    keytype = "SYMBOL"
  )

  # Filter to genes with coordinates
  entrez_ids <- entrez_map$ENTREZID[!is.na(entrez_map$ENTREZID)]
  genes_gr <- genes_gr[names(genes_gr) %in% entrez_ids]

  if (length(genes_gr) == 0) return(NULL)

  # Get promoter regions
  promoters_gr <- promoters(genes_gr, upstream = upstream, downstream = 0)

  # Extract sequences
  seqs <- tryCatch({
    getSeq(db$bsgenome, promoters_gr)
  }, error = function(e) {
    warning("Failed to extract sequences")
    return(NULL)
  })

  # Add gene symbol names
  if (!is.null(seqs)) {
    symbol_map <- entrez_map$SYMBOL[match(names(seqs), entrez_map$ENTREZID)]
    names(seqs) <- paste0(symbol_map, "_", names(seqs))
  }

  return(seqs)
}

#' Write FASTA file
#' @param sequences DNAStringSet
#' @param file_path Output file path
write_fasta <- function(sequences, file_path) {
  if (is.null(sequences) || length(sequences) == 0) {
    return(FALSE)
  }

  writeXStringSet(sequences, file_path, format = "fasta")
  return(TRUE)
}

#' Main gene module processing
#' @param params Parameters list
process_gene_modules <- function(params) {

  message("=== Gene Module Assignment ===")
  setwd(params$working_dir)

  # Read species
  species_file <- paste0(params$jobid, "_info.txt")
  if (file.exists(species_file)) {
    info <- readLines(species_file)
    species_line <- grep("species,", info, value = TRUE)
    species <- gsub("species,", "", species_line)
  } else {
    species <- "Human"  # Default
  }
  species <- normalize_species_name(species)
  message(paste("Species:", species))

  # Read cell labels
  cell_labels <- read.table(
    paste0(params$jobid, "_cell_label.txt"),
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )
  colnames(cell_labels) <- c("Cell", "Label")

  # Read gene names
  gene_names <- readLines(paste0(params$jobid, "_gene_name.txt"))

  # Read QUBIC blocks
  message("Reading QUBIC2 biclusters...")
  blocks <- read_qubic_blocks(params$jobid)

  # Filter biclusters
  blocks <- filter_biclusters(blocks, min_genes = 4, max_genes = 1000)

  # Assign to cell types
  message("Assigning biclusters to cell types...")
  assignments <- assign_to_celltypes(blocks, cell_labels)

  # Create output directories and FASTA files
  message("Generating promoter sequences...")
  n_celltypes <- length(assignments)

  for (ct_idx in seq_along(assignments)) {
    ct_name <- names(assignments)[ct_idx]
    ct_genes <- assignments[[ct_name]]

    if (length(ct_genes) == 0) next

    # Create directory
    ct_dir <- paste0(params$jobid, "_CT_", ct_idx, "_bic")
    dir.create(ct_dir, showWarnings = FALSE)

    # Process each bicluster
    for (bic_idx in seq_along(ct_genes)) {
      genes <- ct_genes[[bic_idx]]
      # Check if genes are indices (numeric strings) or names
      if (all(grepl("^\\d+$", genes))) {
        genes <- gene_names[as.integer(genes)]  # Convert indices to names
      }
      # Otherwise genes are already gene names from QUBIC2

      # Get promoter sequences
      seqs <- get_promoter_sequences(genes, species, params$promoter_len)

      if (!is.null(seqs) && length(seqs) > 0) {
        fasta_file <- file.path(ct_dir, paste0("bic", bic_idx, ".fa"))
        write_fasta(seqs, fasta_file)

        # Also save gene list
        gene_file <- file.path(ct_dir, paste0("bic", bic_idx, ".txt"))
        writeLines(genes, gene_file)
      }
    }

    message(sprintf("  Cell type %d: %d biclusters", ct_idx, length(ct_genes)))
  }

  # Save gene ID to name mapping
  gene_info <- convert_to_symbols(gene_names, species)
  write.table(
    gene_info,
    paste0(params$jobid, "_gene_id_name.txt"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Update info file
  write(paste0("total_ct,", n_celltypes),
        file = paste0(params$jobid, "_info.txt"),
        append = TRUE)

  # Create consolidated regulon gene symbol files for regulon_scoring.R
  message("Creating consolidated regulon files...")
  for (ct_idx in seq_along(assignments)) {
    ct_dir <- paste0(params$jobid, "_CT_", ct_idx, "_bic")

    # Find all bicluster gene files and sort numerically
    bic_files <- list.files(ct_dir, pattern = "^bic[0-9]+\\.txt$", full.names = TRUE)
    if (length(bic_files) == 0) next

    # Extract bicluster numbers for proper sorting
    bic_nums <- as.integer(gsub(".*bic([0-9]+)\\.txt$", "\\1", bic_files))
    bic_files <- bic_files[order(bic_nums)]

    # Read each bicluster and combine as tab-separated lines
    regulon_lines <- sapply(bic_files, function(f) {
      genes <- readLines(f)
      paste(genes, collapse = "\t")
    })

    # Write consolidated file
    output_file <- paste0("CT_", ct_idx, "_bic.regulon_gene_symbol.txt")
    writeLines(regulon_lines, output_file)
    message(sprintf("  Created %s with %d regulons", output_file, length(regulon_lines)))
  }

  message("=== Gene Module Assignment Complete ===")
}

# Run if called directly
if (!interactive()) {
  params <- parse_args()
  process_gene_modules(params)
}
