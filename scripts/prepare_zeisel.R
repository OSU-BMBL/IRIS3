#!/usr/bin/env Rscript
# Download and prepare Zeisel dataset as Seurat object
# Zeisel et al. (2015) Science - Mouse brain single-cell RNA-seq

library(Seurat)

# Output path (use /data when running in Docker)
output_dir <- "/data"
output_file <- file.path(output_dir, "zeisel_seurat.rds")

# Check if already exists
if (file.exists(output_file)) {
  message("Zeisel Seurat object already exists: ", output_file)
  quit(status = 0)
}

message("Downloading Zeisel dataset...")

# Download from the original source (Linnarsson lab)
# URL: https://storage.googleapis.com/linnarsson-lab-www-blobs/blobs/cortex/expression_mRNA_17-Aug-2014.txt
url <- "https://storage.googleapis.com/linnarsson-lab-www-blobs/blobs/cortex/expression_mRNA_17-Aug-2014.txt"
temp_file <- tempfile(fileext = ".txt")

download.file(url, temp_file, method = "auto")

message("Reading expression data...")
# Read the data - first two rows are metadata
raw_data <- read.table(temp_file, header = FALSE, sep = "\t",
                       stringsAsFactors = FALSE, fill = TRUE, quote = "")

# Row 1: tissue type
# Row 2: cell group/cluster
# Row 3+: gene expression

# Extract cell metadata from first rows
cell_names <- as.character(raw_data[1, -c(1,2)])
tissue <- as.character(raw_data[1, -c(1,2)])
group1 <- as.character(raw_data[2, -c(1,2)])

# Extract expression matrix (skip first 2 metadata rows)
expr_data <- raw_data[-(1:2), ]
gene_names <- as.character(expr_data[, 1])
expr_matrix <- expr_data[, -c(1,2)]

# Convert to numeric matrix properly
expr_matrix <- apply(expr_matrix, 2, as.numeric)
rownames(expr_matrix) <- gene_names
colnames(expr_matrix) <- cell_names

# Replace any remaining NAs with 0
expr_matrix[is.na(expr_matrix)] <- 0

# Remove rows with NA gene names or all-zero expression
valid_genes <- !is.na(gene_names) & gene_names != "" & rowSums(expr_matrix, na.rm = TRUE) > 0
expr_matrix <- expr_matrix[valid_genes, , drop = FALSE]
gene_names <- gene_names[valid_genes]

message("After filtering: ", length(gene_names), " genes")
message("Duplicates: ", sum(duplicated(gene_names)))

# Handle duplicate gene names by summing their expression
if (any(duplicated(gene_names))) {
  message("Aggregating duplicate genes...")
  expr_df <- data.frame(gene = gene_names, expr_matrix, check.names = FALSE)
  expr_agg <- aggregate(. ~ gene, data = expr_df, FUN = sum)
  gene_names <- expr_agg$gene
  expr_matrix <- as.matrix(expr_agg[, -1])
}

# Set rownames
rownames(expr_matrix) <- gene_names

# Make all gene names unique to avoid any issues
gene_names_unique <- make.unique(gene_names)
rownames(expr_matrix) <- gene_names_unique

# Make cell names unique too
cell_names_unique <- make.unique(colnames(expr_matrix))
colnames(expr_matrix) <- cell_names_unique

message("Expression matrix: ", nrow(expr_matrix), " genes x ", ncol(expr_matrix), " cells")

# Load cell labels from IRIS3 data
label_file <- "/data/Zeisel_index_label.csv"
if (file.exists(label_file)) {
  labels_df <- read.csv(label_file, stringsAsFactors = FALSE)
  message("Loaded labels for ", nrow(labels_df), " cells")
} else {
  # Use the group1 as cell type
  labels_df <- data.frame(
    Cell = cell_names,
    Label = group1,
    stringsAsFactors = FALSE
  )
}

# Create mapping from unique cell names to original cell names (for label lookup)
# cell_names are the original names, cell_names_unique are the unique versions
cell_name_map <- data.frame(
  original = cell_names,
  unique = cell_names_unique,
  stringsAsFactors = FALSE
)

# Create Seurat object
message("Creating Seurat object...")
seurat_obj <- CreateSeuratObject(
  counts = expr_matrix,
  project = "Zeisel2015",
  min.cells = 3,
  min.features = 200
)

# Add cell type metadata
# Match using original cell names
original_names <- cell_name_map$original[match(colnames(seurat_obj), cell_name_map$unique)]
matched_labels <- labels_df$Label[match(original_names, labels_df$Cell)]
if (sum(!is.na(matched_labels)) > 0) {
  seurat_obj$cell_type <- matched_labels
  message("Added cell_type metadata: ", length(unique(na.omit(matched_labels))), " cell types")
} else {
  # Fallback: use group1 labels based on position
  message("Warning: Could not match cell labels, using original group labels")
  seurat_obj$cell_type <- group1[1:ncol(seurat_obj)]
}

# Standard preprocessing
message("Running Seurat preprocessing...")
seurat_obj <- NormalizeData(seurat_obj)
seurat_obj <- FindVariableFeatures(seurat_obj, selection.method = "vst", nfeatures = 5000)
seurat_obj <- ScaleData(seurat_obj)
seurat_obj <- RunPCA(seurat_obj, npcs = 20)
seurat_obj <- RunUMAP(seurat_obj, dims = 1:20)
seurat_obj <- FindNeighbors(seurat_obj, dims = 1:20)
seurat_obj <- FindClusters(seurat_obj, resolution = 0.5)

# Save
message("Saving Seurat object to: ", output_file)
saveRDS(seurat_obj, output_file)

message("Done!")
message("  Cells: ", ncol(seurat_obj))
message("  Genes: ", nrow(seurat_obj))
message("  Cell types: ", length(unique(seurat_obj$cell_type)))

# Clean up
unlink(temp_file)
