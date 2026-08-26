#!/usr/bin/env Rscript
#' IRIS3 Motif Processing Module
#'
#' Processes motif discovery results (MEME/BoBro) and performs TOMTOM analysis.
#' Merges functionality from prepare_bbc.R and merge_tomtom.R.
#'
#' Input:
#'   - CT_*_bic/*.closures - Motif discovery output
#'   - tomtom/*.xml - TOMTOM comparison results
#'
#' Output:
#'   - CT_*_bic.motifgene.txt - Motif to gene mappings
#'   - CT_*_bic.regulon_motif.txt - Regulon motif information

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

# Load required libraries
load_iris3_libraries(c("core"))
library(xml2)

#' Parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  params <- list(
    working_dir = args[1],
    jobid = args[2],
    motif_length = as.integer(args[3])
  )

  return(params)
}

#' Read motif closure file (MEME/BoBro output)
#' @param closure_file Path to closure file
#' @return List with motif information
read_closure_file <- function(closure_file) {

  if (!file.exists(closure_file)) {
    return(NULL)
  }

  lines <- readLines(closure_file)

  # Parse MEME-format motif
  motifs <- list()
  current_motif <- NULL
  in_motif <- FALSE

  for (line in lines) {
    if (grepl("^MOTIF", line)) {
      if (!is.null(current_motif)) {
        motifs <- c(motifs, list(current_motif))
      }
      current_motif <- list(
        name = gsub("^MOTIF\\s+", "", line),
        matrix = c(),
        sequences = c()
      )
      in_motif <- TRUE
    } else if (grepl("^letter-probability matrix", line)) {
      # Skip header
    } else if (in_motif && grepl("^\\s*[0-9]", line)) {
      # PWM row
      current_motif$matrix <- rbind(current_motif$matrix, as.numeric(strsplit(trimws(line), "\\s+")[[1]]))
    } else if (grepl("^>", line)) {
      # Sequence header
      current_motif$sequences <- c(current_motif$sequences, gsub("^>", "", line))
    }
  }

  if (!is.null(current_motif)) {
    motifs <- c(motifs, list(current_motif))
  }

  return(motifs)
}

#' Parse TOMTOM XML results
#' @param xml_file Path to TOMTOM XML output
#' @return Data frame with motif matches
parse_tomtom_xml <- function(xml_file) {

  if (!file.exists(xml_file)) {
    return(NULL)
  }

  tryCatch({
    doc <- read_xml(xml_file)

    # Extract matches
    matches <- xml_find_all(doc, "//match")

    if (length(matches) == 0) {
      return(NULL)
    }

    result <- data.frame(
      query_id = xml_attr(matches, "query_id"),
      target_id = xml_attr(matches, "target_id"),
      pvalue = as.numeric(xml_attr(matches, "pvalue")),
      evalue = as.numeric(xml_attr(matches, "evalue")),
      qvalue = as.numeric(xml_attr(matches, "qvalue")),
      stringsAsFactors = FALSE
    )

    return(result)
  }, error = function(e) {
    warning(paste("Failed to parse TOMTOM XML:", e$message))
    return(NULL)
  })
}

#' Process motifs for a single cell type directory
#' @param ct_dir Cell type directory path
#' @param jobid Job identifier
#' @return Data frame with processed motif information
process_celltype_motifs <- function(ct_dir, jobid) {

  # Find closure files
  closure_files <- list.files(ct_dir, pattern = "\\.closures$", full.names = TRUE)

  if (length(closure_files) == 0) {
    return(NULL)
  }

  all_motifs <- list()

  for (cf in closure_files) {
    motifs <- read_closure_file(cf)
    if (!is.null(motifs)) {
      # Add bicluster info
      bic_name <- gsub("\\..*$", "", basename(cf))
      for (i in seq_along(motifs)) {
        motifs[[i]]$bicluster <- bic_name
        motifs[[i]]$source_file <- cf
      }
      all_motifs <- c(all_motifs, motifs)
    }
  }

  # Find corresponding gene lists
  gene_files <- list.files(ct_dir, pattern = "\\.txt$", full.names = TRUE)
  gene_files <- gene_files[grep("^bic[0-9]+\\.txt$", basename(gene_files))]

  # Create motif-gene mapping
  motif_gene_df <- data.frame()

  for (motif in all_motifs) {
    bic_num <- gsub("\\D", "", motif$bicluster)
    gene_file <- file.path(ct_dir, paste0("bic", bic_num, ".txt"))

    if (file.exists(gene_file)) {
      genes <- readLines(gene_file)
      for (gene in genes) {
        motif_gene_df <- rbind(motif_gene_df, data.frame(
          motif_name = motif$name,
          bicluster = motif$bicluster,
          gene = gene,
          stringsAsFactors = FALSE
        ))
      }
    }
  }

  return(motif_gene_df)
}

#' Main motif processing function
#' @param params Parameters list
process_motifs <- function(params) {

  message("=== Motif Processing ===")
  setwd(params$working_dir)

  # Find cell type directories
  ct_dirs <- list.dirs(".", recursive = FALSE)
  ct_dirs <- ct_dirs[grep(paste0(params$jobid, "_CT_[0-9]+_bic"), ct_dirs)]

  if (length(ct_dirs) == 0) {
    message("No cell type directories found")
    return()
  }

  message(paste("Found", length(ct_dirs), "cell type directories"))

  for (ct_dir in ct_dirs) {
    ct_name <- basename(ct_dir)
    message(paste("Processing:", ct_name))

    # Process motifs
    motif_gene <- process_celltype_motifs(ct_dir, params$jobid)

    if (!is.null(motif_gene) && nrow(motif_gene) > 0) {
      # Save motif-gene mapping
      output_file <- paste0(ct_name, ".motifgene.txt")
      write.table(
        motif_gene,
        output_file,
        sep = "\t",
        row.names = FALSE,
        quote = FALSE
      )

      message(sprintf("  Saved %d motif-gene pairs to %s",
                      nrow(motif_gene), output_file))
    }

    # Process TOMTOM results if available
    tomtom_dir <- file.path("tomtom", ct_name)
    tomtom_xml <- file.path(tomtom_dir, "tomtom.xml")

    if (file.exists(tomtom_xml)) {
      tomtom_results <- parse_tomtom_xml(tomtom_xml)

      if (!is.null(tomtom_results) && nrow(tomtom_results) > 0) {
        # Filter significant matches
        sig_matches <- tomtom_results[tomtom_results$evalue < 0.05, ]

        if (nrow(sig_matches) > 0) {
          # Save regulon motif info
          regulon_file <- paste0(ct_name, ".regulon_motif.txt")
          write.table(
            sig_matches,
            regulon_file,
            sep = "\t",
            row.names = FALSE,
            quote = FALSE
          )
        }
      }
    }
  }

  message("=== Motif Processing Complete ===")
}

# Run if called directly
if (!interactive()) {
  params <- parse_args()
  process_motifs(params)
}
