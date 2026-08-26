#!/usr/bin/env Rscript
#' IRIS3 Visualization Module
#'
#' Prepares heatmap data for visualization (clustergrammer format).
#' Refactored from prepare_heatmap.R with simplified logic.
#'
#' Input:
#'   - {jobid}_filtered_expression.txt
#'   - {jobid}_cell_label.txt
#'   - CT_*_bic.regulon_gene_symbol.txt
#'
#' Output:
#'   - heatmap/CT{n}.heatmap.txt - Combined heatmaps per cell type
#'   - heatmap/CT{n}-R{m}.heatmap.txt - Individual regulon heatmaps

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

suppressPackageStartupMessages({
  library(scales)
  library(tibble)
})

#' Parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  params <- list(
    working_dir = args[1],
    jobid = args[2],
    label_mode = ifelse(length(args) >= 3, as.integer(args[3]), 0),
    max_cells = ifelse(length(args) >= 4, as.integer(args[4]), 300),
    max_regulons = ifelse(length(args) >= 5, as.integer(args[5]), 10)
  )

  return(params)
}

#' Sort directories by cell type number
#' @param dirs Character vector of directory names
#' @return Sorted character vector
sort_ct_dirs <- function(dirs) {
  if (length(dirs) == 0) return(dirs)

  # Extract CT number from pattern like "jobid_CT_1_bic"
  ct_nums <- sapply(dirs, function(d) {
    match <- regmatches(d, regexpr("CT_([0-9]+)", d))
    if (length(match) > 0) {
      as.numeric(gsub("CT_", "", match))
    } else {
      Inf
    }
  })

  dirs[order(ct_nums)]
}

#' Downsample expression matrix for visualization
#' @param expr Expression matrix (genes x cells)
#' @param labels Data frame with Cell and Label columns
#' @param max_cells Maximum cells to keep
#' @return List with downsampled expr and labels
downsample_for_visualization <- function(expr, labels, max_cells = 300) {

  n_cells <- ncol(expr)

  if (n_cells <= max_cells) {
    return(list(expr = expr, labels = labels))
  }

  # Bin cells
  bin_size <- n_cells %/% max_cells
  keep_idx <- seq(1, n_cells, by = bin_size)

  # Ensure all cell types are represented
  unique_labels <- unique(labels$Label)

  for (ct in unique_labels) {
    ct_cells <- which(labels$Label == ct)
    if (!any(keep_idx %in% ct_cells)) {
      # Add some cells from this type
      add_n <- min(3, length(ct_cells))
      keep_idx <- c(keep_idx, ct_cells[1:add_n])
    }
  }

  keep_idx <- sort(unique(keep_idx))

  # Bin expression values
  binned_expr <- t(apply(expr, 1, function(x) {
    # Mean of each bin
    n <- length(x)
    bins <- split(x, ceiling(seq_along(x) / bin_size))
    sapply(bins, mean, na.rm = TRUE)
  }))

  # Subset to kept indices
  binned_expr <- binned_expr[, seq_len(min(ncol(binned_expr), length(keep_idx)))]
  colnames(binned_expr) <- colnames(expr)[keep_idx[seq_len(ncol(binned_expr))]]

  return(list(
    expr = binned_expr,
    labels = labels[keep_idx[seq_len(ncol(binned_expr))], ]
  ))
}

#' Read all regulon files
#' @param working_dir Working directory
#' @return List of regulons with names like "CT1-R1"
read_all_regulons <- function(working_dir) {

  regulon_files <- list.files(working_dir,
                               pattern = "_bic\\.regulon_gene_symbol\\.txt$",
                               full.names = TRUE)
  regulon_files <- sort_ct_dirs(regulon_files)

  all_regulons <- list()

  for (rf in regulon_files) {
    # Extract CT number
    ct_num <- as.numeric(gsub(".*CT_([0-9]+).*", "\\1", basename(rf)))

    # Read regulon lines
    lines <- readLines(rf, warn = FALSE)

    for (i in seq_along(lines)) {
      genes <- strsplit(lines[i], "\t")[[1]]
      genes <- genes[genes != ""]

      if (length(genes) > 1 && length(genes) <= 1000) {
        regulon_name <- sprintf("CT%d-R%d", ct_num, i)
        all_regulons[[regulon_name]] <- genes
      }
    }
  }

  return(all_regulons)
}

#' Normalize expression for heatmap
#' @param expr Expression matrix
#' @return Normalized matrix (log + mean-centered)
normalize_for_heatmap <- function(expr) {
  expr <- log1p(expr)
  expr <- expr - rowMeans(expr)
  return(expr)
}

#' Create heatmap file for clustergrammer
#' @param expr Expression matrix (genes x cells)
#' @param genes Character vector of genes to include
#' @param labels Data frame with Cell and Label columns
#' @param output_file Output file path
#' @param regulon_cols Optional list of regulon membership columns
create_heatmap_file <- function(expr, genes, labels, output_file,
                                 regulon_cols = NULL) {

  # Subset to genes present in expression
  genes_present <- genes[genes %in% rownames(expr)]

  if (length(genes_present) == 0) {
    return(FALSE)
  }

  heat_matrix <- expr[genes_present, , drop = FALSE]

  # Add category row
  category <- paste0("Predicted label: _", labels$Label, "_")
  heat_matrix <- rbind(category, heat_matrix)

  # Format for clustergrammer
  rownames(heat_matrix)[-1] <- paste0("Genes:", rownames(heat_matrix)[-1])
  rownames(heat_matrix)[1] <- ""
  colnames(heat_matrix) <- paste0("Cells:", colnames(heat_matrix))

  # Add regulon membership columns if provided
  if (!is.null(regulon_cols) && length(regulon_cols) > 0) {
    for (reg_name in names(regulon_cols)) {
      membership <- as.integer(rownames(heat_matrix) %in%
                                paste0("Genes:", regulon_cols[[reg_name]]))
      membership[1] <- 0
      col_name <- paste0(reg_name, ": ", membership)
      heat_matrix <- cbind(col_name, heat_matrix)
    }
  }

  # Convert to data frame with row names as column
  heat_df <- tibble::rownames_to_column(as.data.frame(heat_matrix), "rowname")
  heat_df[1, 1] <- ""

  # Write output
  write.table(
    heat_df,
    output_file,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Clustergrammer bug workaround: 13 lines causes issues
  if (nrow(heat_df) == 13) {
    write("\n", file = output_file, append = TRUE)
  }

  return(TRUE)
}

#' Main visualization function
#' @param params Parameters list
prepare_heatmaps <- function(params) {

  message("=== Visualization Preparation ===")
  setwd(params$working_dir)
  dir.create("heatmap", showWarnings = FALSE)

  # Read expression data
  message("Loading expression data...")
  expr_file <- paste0(params$jobid, "_filtered_expression.txt")
  expr_data <- read.table(expr_file, header = TRUE, sep = "\t",
                          row.names = 1, check.names = FALSE)
  expr_data <- as.matrix(expr_data)

  # Read cell labels
  label_file <- paste0(params$jobid, "_cell_label.txt")
  cell_labels <- read.table(label_file, header = TRUE, sep = "\t",
                            stringsAsFactors = FALSE)
  colnames(cell_labels) <- c("Cell", "Label")

  # Sort by label
  cell_labels <- cell_labels[order(cell_labels$Label), ]
  expr_data <- expr_data[, cell_labels$Cell]

  # Read all regulons
  message("Reading regulon files...")
  all_regulons <- read_all_regulons(params$working_dir)

  if (length(all_regulons) == 0) {
    message("No regulons found")
    return()
  }

  message(sprintf("Found %d regulons", length(all_regulons)))

  # Downsample for visualization
  message("Preparing visualization data...")
  viz_data <- downsample_for_visualization(expr_data, cell_labels,
                                            params$max_cells)
  viz_expr <- normalize_for_heatmap(viz_data$expr)
  viz_labels <- viz_data$labels

  # Also normalize full expression
  full_expr <- normalize_for_heatmap(expr_data)

  # Get unique cell types
  unique_cts <- sort(unique(cell_labels$Label))
  n_cts <- length(unique_cts)

  # Create heatmaps for each cell type
  message("Creating heatmap files...")

  for (ct in unique_cts) {
    # Find regulons for this cell type
    ct_regulons <- all_regulons[grep(sprintf("^CT%d-R", ct), names(all_regulons))]

    if (length(ct_regulons) == 0) next

    # Limit to max_regulons
    ct_regulons <- head(ct_regulons, params$max_regulons)

    # Get all genes from these regulons
    all_genes <- unique(unlist(ct_regulons))

    # Create combined heatmap
    output_file <- sprintf("heatmap/CT%d.heatmap.txt", ct)
    success <- create_heatmap_file(
      viz_expr, all_genes, viz_labels, output_file,
      regulon_cols = ct_regulons
    )

    if (success) {
      message(sprintf("  Created CT%d heatmap (%d genes, %d regulons)",
                      ct, length(all_genes), length(ct_regulons)))
    }

    # Create individual regulon heatmaps
    ct_cells <- cell_labels$Cell[cell_labels$Label == ct]
    ct_expr <- full_expr[, ct_cells[ct_cells %in% colnames(full_expr)]]
    ct_labels <- cell_labels[cell_labels$Label == ct, ]

    # Limit cells for individual heatmaps
    if (ncol(ct_expr) > params$max_cells) {
      keep_idx <- seq(1, ncol(ct_expr), length.out = params$max_cells)
      ct_expr <- ct_expr[, keep_idx]
      ct_labels <- ct_labels[keep_idx, ]
    }

    for (reg_name in names(ct_regulons)) {
      reg_num <- as.integer(gsub(".*R", "", reg_name))
      output_file <- sprintf("heatmap/CT%d-R%d.heatmap.txt", ct, reg_num)

      create_heatmap_file(
        ct_expr,
        ct_regulons[[reg_name]],
        ct_labels,
        output_file
      )
    }
  }

  message("=== Visualization Preparation Complete ===")
}

# Run if called directly
if (!interactive()) {
  params <- parse_args()
  prepare_heatmaps(params)
}
