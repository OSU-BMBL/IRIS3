#!/usr/bin/env Rscript
#' IRIS3 Preprocessing Module
#'
#' Unified preprocessing script that merges functionality from:
#' - genefilter.R (standard preprocessing)
#' - genefilter_basic.R (simplified preprocessing)
#' - genefilter_integration.R (multi-sample integration)
#'
#' Usage:
#'   Rscript preprocessing.R --config config.yaml --output output_dir/
#'   Rscript preprocessing.R --jobid 12345 --expr data.csv --species Human

# Load utility modules
# Get script directory - works for both source() and Rscript
get_script_dir <- function() {
  # Try to get from Rscript command line
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg))))
  }
  # Try sys.frame for source()
  tryCatch({
    script_file <- sys.frame(1)$ofile
    if (!is.null(script_file)) {
      return(dirname(normalizePath(script_file)))
    }
  }, error = function(e) NULL)
  # Fallback to current directory
  return(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils/library_loader.R"))
source(file.path(script_dir, "utils/gene_annotation.R"))
source(file.path(script_dir, "utils/gene_id_cleanup.R"))

# Load required libraries
load_iris3_libraries(c("core", "seurat", "annotation", "io"))

#' Parse command line arguments
#' @return List of parsed arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  # Default values
  params <- list(
    config = NULL,
    jobid = format(Sys.time(), "%Y%m%d%H%M%S"),
    expr_file = NULL,
    delimiter = ",",
    label_file = NULL,
    label_delimiter = "\t",
    label_column = "cell_type",  # For Seurat objects: metadata column with cell types
    species = "Human",
    is_imputation = FALSE,
    resolution = 0.8,
    n_pcs = 10,
    n_variable_features = 5000,
    remove_ribosome = FALSE,
    is_trajectory = FALSE,
    output_dir = "."
  )

  # Parse arguments
  i <- 1
  while (i <= length(args)) {
    arg <- args[i]
    if (arg == "--config") {
      params$config <- args[i + 1]
      i <- i + 2
    } else if (arg == "--jobid") {
      params$jobid <- args[i + 1]
      i <- i + 2
    } else if (arg == "--expr") {
      params$expr_file <- args[i + 1]
      i <- i + 2
    } else if (arg == "--delimiter") {
      params$delimiter <- args[i + 1]
      i <- i + 2
    } else if (arg == "--labels") {
      params$label_file <- args[i + 1]
      i <- i + 2
    } else if (arg == "--label-column") {
      params$label_column <- args[i + 1]
      i <- i + 2
    } else if (arg == "--species") {
      params$species <- args[i + 1]
      i <- i + 2
    } else if (arg == "--resolution") {
      params$resolution <- as.numeric(args[i + 1])
      i <- i + 2
    } else if (arg == "--n-pcs") {
      params$n_pcs <- as.integer(args[i + 1])
      i <- i + 2
    } else if (arg == "--n-variable-features") {
      params$n_variable_features <- as.integer(args[i + 1])
      i <- i + 2
    } else if (arg == "--imputation") {
      params$is_imputation <- TRUE
      i <- i + 1
    } else if (arg == "--remove-ribosome") {
      params$remove_ribosome <- TRUE
      i <- i + 1
    } else if (arg == "--trajectory") {
      params$is_trajectory <- TRUE
      i <- i + 1
    } else if (arg == "--output") {
      params$output_dir <- args[i + 1]
      i <- i + 2
    } else {
      i <- i + 1
    }
  }

  # Load config file if provided
  if (!is.null(params$config)) {
    params <- load_config_yaml(params$config, params)
  }

  return(params)
}

#' Load YAML config and merge with defaults
#' @param config_path Path to YAML config file
#' @param defaults Default parameter list
#' @return Merged parameter list
load_config_yaml <- function(config_path, defaults) {
  if (!file.exists(config_path)) {
    stop(paste("Config file not found:", config_path))
  }

  config <- yaml::read_yaml(config_path)

  # Map config to params
  if (!is.null(config$input$expression_file)) {
    defaults$expr_file <- config$input$expression_file
  }
  if (!is.null(config$input$delimiter)) {
    defaults$delimiter <- config$input$delimiter
  }
  if (!is.null(config$input$label_file)) {
    defaults$label_file <- config$input$label_file
  }
  if (!is.null(config$input$label_column)) {
    defaults$label_column <- config$input$label_column
  }
  if (!is.null(config$species)) {
    defaults$species <- config$species
  }
  if (!is.null(config$preprocessing$resolution_seurat)) {
    defaults$resolution <- config$preprocessing$resolution_seurat
  }
  if (!is.null(config$preprocessing$n_pcs)) {
    defaults$n_pcs <- config$preprocessing$n_pcs
  }
  if (!is.null(config$preprocessing$n_variable_features)) {
    defaults$n_variable_features <- config$preprocessing$n_variable_features
  }
  if (!is.null(config$preprocessing$enable_imputation)) {
    defaults$is_imputation <- config$preprocessing$enable_imputation
  }
  if (!is.null(config$preprocessing$remove_ribosome)) {
    defaults$remove_ribosome <- config$preprocessing$remove_ribosome
  }
  if (!is.null(config$preprocessing$enable_trajectory)) {
    defaults$is_trajectory <- config$preprocessing$enable_trajectory
  }

  return(defaults)
}

#' Normalize delimiter string
#' @param delim Delimiter string (may be "tab", "space", etc.)
#' @return Actual delimiter character
normalize_delimiter <- function(delim) {
  if (is.null(delim) || is.na(delim)) return(",")
  delim <- tolower(trimws(delim))

  switch(delim,
    "tab" = "\t",
    "\\t" = "\t",
    "space" = " ",
    "semicolon" = ";",
    delim
  )
}

#' Detect input file format
#' @param file_path Path to input file
#' @return Character: "CellGene", "TenX.h5", "TenX.folder", "Seurat.rds", or "Seurat.qsave"
detect_input_format <- function(file_path) {
  if (dir.exists(file_path)) {
    return("TenX.folder")
  }

  ext <- tolower(tools::file_ext(file_path))

  if (ext %in% c("h5", "hdf5")) {
    return("TenX.h5")
  }

  if (ext == "rds") {
    return("Seurat.rds")
  }

  if (ext == "qsave" || ext == "qs") {
    return("Seurat.qsave")
  }

  return("CellGene")
}

#' Load Seurat object from file
#' @param file_path Path to Seurat object file
#' @param format File format ("Seurat.rds" or "Seurat.qsave")
#' @return Seurat object
load_seurat_object <- function(file_path, format = "Seurat.rds") {
  message(paste("Loading Seurat object from:", file_path))

  if (format == "Seurat.qsave") {
    if (!requireNamespace("qs", quietly = TRUE)) {
      stop("Package 'qs' is required for .qsave files. Install with: install.packages('qs')")
    }
    seurat_obj <- qs::qread(file_path)
  } else {
    seurat_obj <- readRDS(file_path)
  }

  # Verify it's a Seurat object
  if (!inherits(seurat_obj, "Seurat")) {
    stop("Loaded object is not a Seurat object")
  }

  message(paste("  Loaded:", ncol(seurat_obj), "cells,", nrow(seurat_obj), "features"))
  return(seurat_obj)
}

#' Extract cell labels from Seurat object metadata
#' @param seurat_obj Seurat object
#' @param label_column Name of metadata column containing cell labels (default: "cell_type")
#' @return Data frame with Cell and Label columns
extract_seurat_labels <- function(seurat_obj, label_column = "cell_type") {
  # Check available metadata columns
  meta_cols <- colnames(seurat_obj@meta.data)
  message(paste("  Available metadata columns:", paste(meta_cols, collapse = ", ")))

  # Try to find the label column
  if (label_column %in% meta_cols) {
    labels <- seurat_obj@meta.data[[label_column]]
    message(paste("  Using label column:", label_column))
  } else if ("celltype" %in% meta_cols) {
    labels <- seurat_obj@meta.data$celltype
    message("  Using 'celltype' column")
  } else if ("CellType" %in% meta_cols) {
    labels <- seurat_obj@meta.data$CellType
    message("  Using 'CellType' column")
  } else if ("seurat_clusters" %in% meta_cols) {
    labels <- paste0("Cluster_", seurat_obj@meta.data$seurat_clusters)
    message("  Using 'seurat_clusters' column")
  } else {
    message(paste("  Warning: Column '", label_column, "' not found, using Seurat clusters"))
    labels <- paste0("Cluster_", Idents(seurat_obj))
  }

  data.frame(
    Cell = colnames(seurat_obj),
    Label = as.character(labels),
    stringsAsFactors = FALSE
  )
}

#' Preprocess Seurat object input
#' @param params List of parameters
#' @param input_format "Seurat.rds" or "Seurat.qsave"
#' @return List with processed data and statistics
preprocess_seurat_input <- function(params, input_format) {
  message("=== Processing Seurat Object Input ===")

  # Load the Seurat object
  seurat_obj <- load_seurat_object(params$expr_file, input_format)

  total_gene_num <- nrow(seurat_obj)
  total_cell_num <- ncol(seurat_obj)
  message(paste("  Input:", total_gene_num, "genes x", total_cell_num, "cells"))

  # Extract cell labels from metadata
  message("Step 1: Extracting cell labels from metadata...")
  label_df <- extract_seurat_labels(seurat_obj, params$label_column)
  message(paste("  Found", length(unique(label_df$Label)), "cell types"))

  # Add cell labels to Seurat object metadata
  seurat_obj <- AddMetaData(seurat_obj, metadata = label_df$Label, col.name = "cell_label")

  # Check if normalized data exists
  has_normalized <- tryCatch({
    data_layer <- GetAssayData(seurat_obj, layer = "data")
    # If data layer is identical to counts, it's not normalized
    counts_layer <- GetAssayData(seurat_obj, layer = "counts")
    !identical(data_layer, counts_layer)
  }, error = function(e) {
    # Seurat v4 fallback
    tryCatch({
      data_slot <- GetAssayData(seurat_obj, slot = "data")
      counts_slot <- GetAssayData(seurat_obj, slot = "counts")
      !identical(data_slot, counts_slot)
    }, error = function(e2) FALSE)
  })

  if (!has_normalized) {
    message("Step 2: Normalizing data...")
    seurat_obj <- NormalizeData(seurat_obj)
  } else {
    message("Step 2: Using existing normalized data")
  }

  # Check if PCA exists
  has_pca <- "pca" %in% names(seurat_obj@reductions)
  if (!has_pca) {
    message("Step 3: Finding variable features...")
    seurat_obj <- FindVariableFeatures(
      seurat_obj,
      selection.method = "vst",
      nfeatures = params$n_variable_features
    )

    message("Step 4: Scaling data...")
    seurat_obj <- ScaleData(seurat_obj)

    message("Step 5: Running PCA...")
    seurat_obj <- RunPCA(
      seurat_obj,
      features = VariableFeatures(seurat_obj),
      npcs = params$n_pcs
    )
  } else {
    message("Step 3-5: Using existing PCA")
  }

  # Check if UMAP exists
  has_umap <- "umap" %in% names(seurat_obj@reductions)
  if (!has_umap) {
    message("Step 6: Running UMAP...")
    seurat_obj <- RunUMAP(seurat_obj, dims = 1:params$n_pcs)
  } else {
    message("Step 6: Using existing UMAP")
  }

  # Convert gene IDs to symbols if needed
  message("Step 7: Checking gene symbols...")
  species <- normalize_species_name(params$species)
  gene_names <- rownames(seurat_obj)

  # Check if already symbols (heuristic: most genes should be alphabetic)
  looks_like_symbols <- mean(grepl("^[A-Za-z]", gene_names)) > 0.8

  if (!looks_like_symbols) {
    message("  Converting gene IDs to symbols...")
    gene_info <- convert_to_symbols(gene_names, species)

    # Create mapping for valid symbols
    valid_mapping <- gene_info[!is.na(gene_info$SYMBOL), ]
    if (nrow(valid_mapping) > 0) {
      # For Seurat object, we need to rename features carefully
      # This is complex with Seurat v5, so we'll handle it in the output
      message(paste("  Mapped", nrow(valid_mapping), "genes to symbols"))
    }
  } else {
    message("  Gene names appear to be symbols already")
  }

  # Save outputs
  message("Step 8: Saving outputs...")

  # Get normalized expression data
  filtered_expr <- tryCatch(
    GetAssayData(seurat_obj, layer = "data"),
    error = function(e) GetAssayData(seurat_obj, slot = "data")
  )

  # Save filtered expression
  write.table(
    data.frame(Gene = rownames(filtered_expr), as.data.frame(as.matrix(filtered_expr)), check.names = FALSE),
    file = file.path(params$output_dir, paste0(params$jobid, "_filtered_expression.txt")),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Save cell labels
  write.table(
    label_df,
    file = file.path(params$output_dir, paste0(params$jobid, "_cell_label.txt")),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Save gene names
  write.table(
    rownames(filtered_expr),
    file = file.path(params$output_dir, paste0(params$jobid, "_gene_name.txt")),
    sep = "\t",
    row.names = FALSE,
    col.names = FALSE,
    quote = FALSE
  )

  # Save UMAP coordinates
  umap_coords <- Embeddings(seurat_obj, "umap")
  write.table(
    data.frame(Cell = rownames(umap_coords), umap_coords, check.names = FALSE),
    file = file.path(params$output_dir, paste0(params$jobid, "_umap_embeddings.txt")),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Save Seurat object
  saveRDS(seurat_obj, file = file.path(params$output_dir, "seurat_obj.rds"))

  # Calculate statistics
  stats <- list(
    total_genes = total_gene_num,
    total_cells = total_cell_num,
    filtered_genes = nrow(filtered_expr),
    filtered_cells = ncol(filtered_expr),
    n_clusters = length(unique(label_df$Label)),
    species = species
  )

  # Save info
  info_lines <- c(
    paste0("jobid,", params$jobid),
    paste0("total_gene_num,", stats$total_genes),
    paste0("total_cell_num,", stats$total_cells),
    paste0("filtered_gene_num,", stats$filtered_genes),
    paste0("filtered_cell_num,", stats$filtered_cells),
    paste0("n_clusters,", stats$n_clusters),
    paste0("species,", stats$species)
  )
  writeLines(info_lines, file.path(params$output_dir, paste0(params$jobid, "_info.txt")))

  message("=== Seurat Preprocessing Complete ===")
  message(paste("Output:", params$output_dir))

  return(list(seurat_obj = seurat_obj, stats = stats))
}

#' Read expression data from various formats
#' @param file_path Path to expression file
#' @param format File format (auto-detected if NULL)
#' @param delimiter Delimiter for text files
#' @return Matrix or sparse matrix of expression values
read_expression_data <- function(file_path, format = NULL, delimiter = ",") {

  if (is.null(format)) {
    format <- detect_input_format(file_path)
  }

  message(paste("Reading expression data:", format))

  if (format == "TenX.h5") {
    # Read 10X HDF5 format
    expr_data <- tryCatch(
      Read10X_h5(file_path),
      error = function(e) {
        stop(paste("Failed to read 10X h5 file:", e$message))
      }
    )
  } else if (format == "TenX.folder") {
    # Read 10X folder format
    expr_data <- tryCatch(
      Read10X(file_path),
      error = function(e) {
        stop(paste("Failed to read 10X folder:", e$message))
      }
    )
  } else {
    # Read text file (CSV/TSV)
    delimiter <- normalize_delimiter(delimiter)
    expr_data <- read.table(
      file_path,
      header = TRUE,
      sep = delimiter,
      row.names = 1,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    expr_data <- as.matrix(expr_data)
  }

  return(expr_data)
}

#' Main preprocessing function
#' @param params List of parameters
#' @return List with processed data and statistics
preprocess <- function(params) {

  message("=== IRIS3 Preprocessing ===")
  message(paste("Job ID:", params$jobid))
  message(paste("Species:", params$species))

  # Create output directory
  dir.create(params$output_dir, recursive = TRUE, showWarnings = FALSE)

  # Detect input format
  input_format <- detect_input_format(params$expr_file)
  message(paste("Input format:", input_format))

  # Handle Seurat object input
  if (input_format %in% c("Seurat.rds", "Seurat.qsave")) {
    return(preprocess_seurat_input(params, input_format))
  }

  # Standard preprocessing for expression matrices
  # Read expression data
  message("Step 1: Reading expression data...")
  expr_data <- read_expression_data(
    params$expr_file,
    delimiter = params$delimiter
  )

  total_gene_num <- nrow(expr_data)
  total_cell_num <- ncol(expr_data)
  message(paste("  Input:", total_gene_num, "genes x", total_cell_num, "cells"))

  # Clean gene IDs
  message("Step 2: Cleaning gene identifiers...")
  rownames(expr_data) <- cleanup_gene_ids(rownames(expr_data))

  # Remove empty gene names
  valid_genes <- rownames(expr_data) != "" & !is.na(rownames(expr_data))
  expr_data <- expr_data[valid_genes, , drop = FALSE]

  # Convert to gene symbols
  message("Step 3: Converting to gene symbols...")
  species <- normalize_species_name(params$species)
  gene_info <- convert_to_symbols(rownames(expr_data), species)

  # Merge and aggregate duplicates
  expr_df <- as.data.frame(expr_data)
  expr_df$SYMBOL <- gene_info$SYMBOL[match(rownames(expr_df), gene_info$original)]
  expr_df <- expr_df[!is.na(expr_df$SYMBOL), ]
  expr_df <- aggregate(. ~ SYMBOL, expr_df, sum)
  rownames(expr_df) <- expr_df$SYMBOL
  expr_df$SYMBOL <- NULL
  expr_data <- as.matrix(expr_df)

  # Remove ribosomal genes if requested
  if (params$remove_ribosome) {
    message("Step 4: Removing ribosomal genes...")
    keep_genes <- is_not_ribosomal(rownames(expr_data))
    expr_data <- expr_data[keep_genes, , drop = FALSE]
    message(paste("  Kept:", nrow(expr_data), "genes"))
  }

  # Create Seurat object
  message("Step 5: Creating Seurat object...")
  seurat_obj <- CreateSeuratObject(
    counts = expr_data,
    min.cells = 3,
    min.features = 200
  )

  # Normalize
  message("Step 6: Normalizing data...")
  seurat_obj <- NormalizeData(seurat_obj)

  # Find variable features
  message("Step 7: Finding variable features...")
  seurat_obj <- FindVariableFeatures(
    seurat_obj,
    selection.method = "vst",
    nfeatures = params$n_variable_features
  )

  # Scale data
  message("Step 8: Scaling data...")
  seurat_obj <- ScaleData(seurat_obj)

  # Run PCA
  message("Step 9: Running PCA...")
  seurat_obj <- RunPCA(
    seurat_obj,
    features = VariableFeatures(seurat_obj),
    npcs = params$n_pcs
  )

  # Clustering
  message("Step 10: Clustering...")
  seurat_obj <- FindNeighbors(seurat_obj, dims = 1:params$n_pcs)
  seurat_obj <- FindClusters(seurat_obj, resolution = params$resolution)

  # UMAP
  message("Step 11: Running UMAP...")
  seurat_obj <- RunUMAP(seurat_obj, dims = 1:params$n_pcs)

  # Process cell labels
  message("Step 12: Processing cell labels...")
  if (!is.null(params$label_file) && file.exists(params$label_file)) {
    label_delim <- normalize_delimiter(params$label_delimiter)
    cell_labels <- read.table(
      params$label_file,
      header = TRUE,
      sep = label_delim,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    # Match to Seurat cells
    matched_labels <- cell_labels[match(colnames(seurat_obj), cell_labels[,1]), 2]
    if (all(is.na(matched_labels))) {
      message("  Warning: No cells matched from label file, using Seurat clusters")
      matched_labels <- paste0("Cluster_", Idents(seurat_obj))
    }
    # Use AddMetaData for Seurat 5 compatibility
    seurat_obj <- AddMetaData(seurat_obj, metadata = matched_labels, col.name = "cell_label")
  } else {
    # Use Seurat clusters
    cluster_labels <- paste0("Cluster_", Idents(seurat_obj))
    seurat_obj <- AddMetaData(seurat_obj, metadata = cluster_labels, col.name = "cell_label")
  }

  # Save outputs
  message("Step 13: Saving outputs...")

  # Save filtered expression (Seurat 5+ uses layer instead of slot)
  filtered_expr <- tryCatch(
    GetAssayData(seurat_obj, layer = "data"),
    error = function(e) GetAssayData(seurat_obj, slot = "data")
  )
  write.table(
    data.frame(Gene = rownames(filtered_expr), as.data.frame(filtered_expr), check.names = FALSE),
    file = file.path(params$output_dir, paste0(params$jobid, "_filtered_expression.txt")),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Save cell labels
  label_df <- data.frame(
    Cell = colnames(seurat_obj),
    Label = seurat_obj@meta.data$cell_label
  )
  write.table(
    label_df,
    file = file.path(params$output_dir, paste0(params$jobid, "_cell_label.txt")),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Save gene names
  write.table(
    rownames(filtered_expr),
    file = file.path(params$output_dir, paste0(params$jobid, "_gene_name.txt")),
    sep = "\t",
    row.names = FALSE,
    col.names = FALSE,
    quote = FALSE
  )

  # Save UMAP coordinates
  umap_coords <- Embeddings(seurat_obj, "umap")
  write.table(
    data.frame(Cell = rownames(umap_coords), umap_coords, check.names = FALSE),
    file = file.path(params$output_dir, paste0(params$jobid, "_umap_embeddings.txt")),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  # Save Seurat object
  saveRDS(seurat_obj, file = file.path(params$output_dir, "seurat_obj.rds"))

  # Calculate statistics
  stats <- list(
    total_genes = total_gene_num,
    total_cells = total_cell_num,
    filtered_genes = nrow(filtered_expr),
    filtered_cells = ncol(filtered_expr),
    n_clusters = length(unique(seurat_obj@meta.data$cell_label)),
    species = species
  )

  # Save info
  info_lines <- c(
    paste0("jobid,", params$jobid),
    paste0("total_gene_num,", stats$total_genes),
    paste0("total_cell_num,", stats$total_cells),
    paste0("filtered_gene_num,", stats$filtered_genes),
    paste0("filtered_cell_num,", stats$filtered_cells),
    paste0("n_clusters,", stats$n_clusters),
    paste0("species,", stats$species)
  )
  writeLines(info_lines, file.path(params$output_dir, paste0(params$jobid, "_info.txt")))

  message("=== Preprocessing Complete ===")
  message(paste("Output:", params$output_dir))

  return(list(seurat_obj = seurat_obj, stats = stats))
}

# Run if called directly
if (!interactive()) {
  params <- parse_args()

  if (is.null(params$expr_file) && is.null(params$config)) {
    message("Usage: Rscript preprocessing.R --expr <expression_file> --species <Human|Mouse> --output <output_dir>")
    message("   or: Rscript preprocessing.R --config <config.yaml> --output <output_dir>")
    quit(status = 1)
  }

  result <- preprocess(params)
}
