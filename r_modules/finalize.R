#!/usr/bin/env Rscript
#' IRIS3 Finalize Module
#'
#' Consolidates all pipeline outputs into a single summary table.
#' Maps cluster IDs to actual cell type names and creates a unified
#' regulons.tsv file with all statistics.
#'
#' Input:
#'   - {jobid}_cell_label.txt
#'   - CT_*_bic.regulon_gene_symbol.txt
#'   - CT_*_bic.regulon_rank.txt
#'   - CT_*_bic.regulon_activity_score.txt
#'   - tomtom/ (optional, for TF matching)
#'
#' Output:
#'   - regulons.tsv (consolidated summary table)

# Load utility modules
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

load_iris3_libraries("core")

suppressPackageStartupMessages({
  library(data.table)
})

#' Parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  params <- list(
    working_dir = args[1],
    jobid = args[2],
    keep_intermediates = ifelse(length(args) >= 3, as.logical(args[3]), FALSE)
  )

  return(params)
}

#' Infer cell type name from cell IDs
#'
#' Given a vector of cell IDs (e.g., "OoCyte_1", "8_Cell_embryo_2_Cell_3"),
#' extract the most common biological prefix as the cell type name.
#'
#' @param cell_ids Character vector of cell IDs
#' @return Most common cell type prefix
infer_celltype_name <- function(cell_ids) {
  # Extract prefix by removing trailing numbers and cell indices
  # Pattern: remove _[0-9]+$ or _Cell_[0-9]+$ from the end
  prefixes <- gsub("_\\d+$", "", cell_ids)
  prefixes <- gsub("_Cell_\\d+$", "", prefixes)
  # For patterns like "8_Cell_embryo_2_Cell_3", get "8_Cell_embryo"
  prefixes <- gsub("_\\d+_Cell$", "", prefixes)
  prefixes <- gsub("_\\d+$", "", prefixes)

  # Get most common prefix
  prefix_table <- table(prefixes)
  most_common <- names(prefix_table)[which.max(prefix_table)]

  return(most_common)
}

#' Build cluster to cell type name mapping
#'
#' @param cell_labels Data frame with Cell and Label columns
#' @return Named vector: cluster -> cell type name
build_cluster_mapping <- function(cell_labels) {
  clusters <- unique(cell_labels$Label)

  mapping <- sapply(clusters, function(cluster) {
    cells_in_cluster <- cell_labels$Cell[cell_labels$Label == cluster]
    infer_celltype_name(cells_in_cluster)
  })

  names(mapping) <- clusters
  return(mapping)
}

#' Load JASPAR motif ID to TF name mapping
#'
#' @return Named vector mapping JASPAR IDs to TF names
load_jaspar_mapping <- function() {
  # Check for JASPAR database in environment
  db_path <- Sys.getenv("IRIS3_MOTIF_DB", "")

  if (db_path == "" || !file.exists(db_path)) {
    # Try common paths
    possible_paths <- c(
      "/opt/meme/db/JASPAR2024_CORE_vertebrates_non-redundant_pfms_meme.txt",
      "/opt/meme/db/JASPAR2024_CORE_non-redundant_pfms_meme.txt"
    )
    for (p in possible_paths) {
      if (file.exists(p)) {
        db_path <- p
        break
      }
    }
  }

  if (db_path == "" || !file.exists(db_path)) {
    return(NULL)
  }

  # Parse MEME format database file for MOTIF lines
  # Format: MOTIF MA0004.1 Arnt
  lines <- readLines(db_path)
  motif_lines <- grep("^MOTIF ", lines, value = TRUE)

  # Extract ID and name
  mapping <- sapply(motif_lines, function(line) {
    parts <- strsplit(line, "\\s+")[[1]]
    if (length(parts) >= 3) {
      return(c(parts[2], parts[3]))  # ID, Name
    }
    return(c(NA, NA))
  }, USE.NAMES = FALSE)

  mapping <- data.frame(
    jaspar_id = mapping[1, ],
    tf_name = mapping[2, ],
    stringsAsFactors = FALSE
  )
  mapping <- mapping[!is.na(mapping$jaspar_id), ]

  # Create named vector
  result <- setNames(mapping$tf_name, mapping$jaspar_id)
  message(sprintf("Loaded %d JASPAR ID to TF name mappings", length(result)))
  return(result)
}

#' Load TOMTOM results if available
#'
#' @param working_dir Working directory
#' @param jaspar_map JASPAR ID to TF name mapping
#' @return Data frame with TF matches or NULL
load_tomtom_results <- function(working_dir, jaspar_map = NULL) {
  tomtom_dir <- file.path(working_dir, "tomtom")

  if (!dir.exists(tomtom_dir)) {
    return(NULL)
  }

  # Look for tomtom.tsv files
  tomtom_files <- list.files(tomtom_dir, pattern = "tomtom\\.tsv$",
                              recursive = TRUE, full.names = TRUE)

  if (length(tomtom_files) == 0) {
    return(NULL)
  }

  # Parse TOMTOM results
  tf_matches <- lapply(tomtom_files, function(f) {
    tryCatch({
      df <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                       comment.char = "#", fill = TRUE)
      if (nrow(df) > 0 && "Target_ID" %in% colnames(df)) {
        # Extract bicluster name from path: tomtom/bic1/tomtom.tsv -> bic1
        bicluster <- basename(dirname(f))

        # Target_ID is JASPAR motif ID (e.g., "MA0002.2")
        df$tf_motif <- df$Target_ID

        # Look up TF name from JASPAR mapping
        if (!is.null(jaspar_map)) {
          df$tf_name <- jaspar_map[df$Target_ID]
          df$tf_name[is.na(df$tf_name)] <- df$Target_ID[is.na(df$tf_name)]
        } else {
          df$tf_name <- df$Target_ID
        }

        df$bicluster <- bicluster
        return(df[, c("bicluster", "tf_name", "tf_motif", "E.value")])
      }
      return(NULL)
    }, error = function(e) NULL)
  })

  tf_matches <- do.call(rbind, tf_matches[!sapply(tf_matches, is.null)])

  if (is.null(tf_matches) || nrow(tf_matches) == 0) {
    return(NULL)
  }

  # Keep best match per bicluster (lowest E-value)
  tf_matches <- tf_matches[order(tf_matches$E.value), ]
  tf_matches <- tf_matches[!duplicated(tf_matches$bicluster), ]

  return(tf_matches)
}

#' Calculate enrichment p-value for regulon-cell type association
#'
#' Uses hypergeometric test to assess if cells expressing the regulon
#' are enriched in a specific cell type.
#'
#' @param ras_vector Vector of RAS values for one regulon
#' @param cell_labels Cell labels data frame
#' @param target_ct Target cell type
#' @return P-value
calc_enrichment_pval <- function(ras_vector, cell_labels, target_ct) {
  # Threshold: cells with RAS > median are "expressing"
  threshold <- median(ras_vector, na.rm = TRUE)
  expressing_cells <- names(ras_vector)[ras_vector > threshold]

  # Get cell type assignments
  target_cells <- cell_labels$Cell[cell_labels$Label == target_ct]

  # Hypergeometric test
  # x = expressing cells in target CT
  # m = total cells in target CT
  # n = total cells NOT in target CT
  # k = total expressing cells
  x <- sum(expressing_cells %in% target_cells)
  m <- length(target_cells)
  n <- nrow(cell_labels) - m
  k <- length(expressing_cells)

  pval <- phyper(x - 1, m, n, k, lower.tail = FALSE)

  return(pval)
}

#' Main finalize function
#'
#' @param params Parameters list
finalize_outputs <- function(params) {

  message("=== Finalizing IRIS3 Outputs ===")
  setwd(params$working_dir)

  # Read cell labels
  message("Loading cell labels...")
  label_file <- paste0(params$jobid, "_cell_label.txt")
  if (!file.exists(label_file)) {
    stop(paste("Cell label file not found:", label_file))
  }
  cell_labels <- read.table(label_file, header = TRUE, sep = "\t",
                            stringsAsFactors = FALSE)
  colnames(cell_labels) <- c("Cell", "Label")

  # Build cluster -> cell type mapping
  cluster_mapping <- build_cluster_mapping(cell_labels)
  message("Cluster to cell type mapping:")
  for (cl in names(cluster_mapping)) {
    message(sprintf("  %s -> %s", cl, cluster_mapping[cl]))
  }

  # Create mapped labels column
  cell_labels$CellType <- cluster_mapping[cell_labels$Label]

  # Get unique cell types for RAS columns
  unique_cts <- sort(unique(cell_labels$CellType))
  message(sprintf("Found %d cell types: %s", length(unique_cts),
                  paste(unique_cts, collapse = ", ")))

  # Load JASPAR ID to TF name mapping
  jaspar_map <- load_jaspar_mapping()

  # Load TOMTOM results
  tf_matches <- load_tomtom_results(params$working_dir, jaspar_map)
  if (!is.null(tf_matches)) {
    message(sprintf("Loaded %d TF matches from TOMTOM", nrow(tf_matches)))
  } else {
    message("No TOMTOM results found, TF names will be 'Unknown'")
  }

  # Find regulon files
  rank_files <- list.files(".", pattern = "\\.regulon_rank\\.txt$")

  if (length(rank_files) == 0) {
    stop("No regulon rank files found")
  }

  message(sprintf("Found %d cell type regulon files", length(rank_files)))

  # Process each cell type
  all_regulons <- list()

  for (rf in rank_files) {
    # Extract cell type from filename (e.g., "CT_1_bic" from "CT_1_bic.regulon_rank.txt")
    ct_prefix <- gsub("\\.regulon_rank\\.txt$", "", rf)
    ct_num <- as.integer(gsub("\\D", "", ct_prefix))

    # Map CT number to actual cluster name
    # CT_1 = Cluster_0, CT_2 = Cluster_1, etc.
    cluster_name <- paste0("Cluster_", ct_num - 1)
    ct_name <- cluster_mapping[cluster_name]

    if (is.na(ct_name)) {
      message(sprintf("  Warning: Could not map %s to cell type", ct_prefix))
      ct_name <- ct_prefix
    }

    message(sprintf("Processing %s (%s)...", ct_prefix, ct_name))

    # Read rank file
    rank_data <- read.table(rf, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

    # Read gene symbol file
    gene_file <- paste0(ct_prefix, ".regulon_gene_symbol.txt")
    if (!file.exists(gene_file)) {
      message(sprintf("  Warning: Gene file not found: %s", gene_file))
      next
    }
    gene_lines <- readLines(gene_file)

    # Read activity score file
    ras_file <- paste0(ct_prefix, ".regulon_activity_score.txt")
    if (!file.exists(ras_file)) {
      message(sprintf("  Warning: RAS file not found: %s", ras_file))
      next
    }
    ras_data <- read.table(ras_file, header = TRUE, sep = "\t",
                           row.names = 1, check.names = FALSE)

    # Process each regulon
    for (i in seq_len(nrow(rank_data))) {
      regulon_num <- rank_data$Regulon[i]
      rss <- rank_data$RSS[i]
      rank_val <- rank_data$Rank[i]

      # Get genes for this regulon
      if (regulon_num <= length(gene_lines)) {
        genes <- unlist(strsplit(gene_lines[regulon_num], "\t"))
        genes <- genes[genes != ""]
      } else {
        genes <- character(0)
      }

      # Get RAS values for this regulon
      ras_row_name <- as.character(regulon_num)
      if (ras_row_name %in% rownames(ras_data)) {
        ras_vector <- as.numeric(ras_data[ras_row_name, ])
        names(ras_vector) <- colnames(ras_data)
      } else {
        ras_vector <- rep(NA, ncol(ras_data))
        names(ras_vector) <- colnames(ras_data)
      }

      # Calculate mean RAS per cell type
      ras_per_ct <- sapply(unique_cts, function(target_ct) {
        ct_cells <- cell_labels$Cell[cell_labels$CellType == target_ct]
        ct_cells <- intersect(ct_cells, names(ras_vector))
        if (length(ct_cells) > 0) {
          mean(ras_vector[ct_cells], na.rm = TRUE)
        } else {
          NA
        }
      })

      # Calculate enrichment p-value
      enrichment_pval <- tryCatch({
        calc_enrichment_pval(ras_vector, cell_labels, cluster_name)
      }, error = function(e) NA)

      # Get TF name from TOMTOM (if available)
      tf_name <- "Unknown"
      tf_motif <- NA
      if (!is.null(tf_matches)) {
        # Match by bicluster name with cell type context
        # TOMTOM dirs are named like "CT_1_bic_bic1" (ct_prefix + "_bic" + regulon_num)
        bicluster_name <- paste0(ct_prefix, "_bic", regulon_num)
        idx <- which(tf_matches$bicluster == bicluster_name)
        if (length(idx) > 0) {
          tf_name <- tf_matches$tf_name[idx[1]]
          tf_motif <- tf_matches$tf_motif[idx[1]]
        }
      }

      # Create regulon ID
      regulon_id <- sprintf("%s_R%d", ct_name, rank_val)

      # Build regulon record
      record <- data.frame(
        cell_type = ct_name,
        regulon_id = regulon_id,
        tf_name = tf_name,
        tf_motif = ifelse(is.na(tf_motif), "", tf_motif),
        n_genes = length(genes),
        rss = rss,
        ras_mean = ras_per_ct[ct_name],
        stringsAsFactors = FALSE
      )

      # Add per-cell-type RAS columns
      for (target_ct in unique_cts) {
        col_name <- paste0("ras_", gsub("[^a-zA-Z0-9]", "_", target_ct))
        record[[col_name]] <- ras_per_ct[target_ct]
      }

      # Add remaining columns
      record$enrichment_pval <- enrichment_pval
      record$rank <- rank_val
      record$genes <- paste(genes, collapse = ",")

      all_regulons[[length(all_regulons) + 1]] <- record
    }
  }

  # Combine all regulons
  if (length(all_regulons) == 0) {
    stop("No regulons processed")
  }

  regulon_table <- do.call(rbind, all_regulons)

  # Sort by cell type, then by rank
  regulon_table <- regulon_table[order(regulon_table$cell_type, regulon_table$rank), ]

  # Write output
  output_file <- "regulons.tsv"
  write.table(regulon_table, output_file, sep = "\t", row.names = FALSE, quote = FALSE)

  message(sprintf("Wrote %d regulons to %s", nrow(regulon_table), output_file))

  # Summary statistics
  message("\nSummary:")
  ct_counts <- table(regulon_table$cell_type)
  for (ct in names(ct_counts)) {
    message(sprintf("  %s: %d regulons", ct, ct_counts[ct]))
  }

  # Cleanup intermediate files if requested
  if (!params$keep_intermediates) {
    cleanup_intermediates(params$working_dir, params$jobid)
  }

  message("=== Finalization Complete ===")
}

#' Clean up intermediate files
#'
#' @param working_dir Working directory
#' @param jobid Job ID
cleanup_intermediates <- function(working_dir, jobid) {
  message("\nCleaning up intermediate files...")

  # QUBIC2 temp files
  qubic_patterns <- c(
    paste0(jobid, "_filtered_expression.txt.chars"),
    paste0(jobid, "_filtered_expression.txt.rules"),
    paste0(jobid, "_filtered_expression.txt.blocks")
  )

  for (pattern in qubic_patterns) {
    f <- file.path(working_dir, pattern)
    if (file.exists(f)) {
      file.remove(f)
      message(sprintf("  Removed: %s", pattern))
    }
  }

  # Bicluster directories
  bic_dirs <- list.files(working_dir, pattern = paste0(jobid, "_CT_.*_bic$"),
                         full.names = TRUE)
  bic_dirs <- bic_dirs[dir.exists(bic_dirs)]

  for (bic_dir in bic_dirs) {
    unlink(bic_dir, recursive = TRUE)
    message(sprintf("  Removed directory: %s", basename(bic_dir)))
  }

  # Redundant mapping files
  mapping_files <- c(
    paste0(jobid, "_gene_name.txt"),
    paste0(jobid, "_gene_id_name.txt")
  )

  for (mf in mapping_files) {
    f <- file.path(working_dir, mf)
    if (file.exists(f)) {
      file.remove(f)
      message(sprintf("  Removed: %s", mf))
    }
  }

  # Old regulon files (now in regulons.tsv)
  old_files <- list.files(working_dir, pattern = "CT_.*_bic\\.regulon_.*\\.txt$")
  for (of in old_files) {
    file.remove(file.path(working_dir, of))
    message(sprintf("  Removed: %s", of))
  }

  message("Cleanup complete.")
}

# Run if called directly
if (!interactive()) {
  params <- parse_args()
  finalize_outputs(params)
}
