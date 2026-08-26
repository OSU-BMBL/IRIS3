#' IRIS3 Gene ID Cleanup Utilities
#'
#' Functions for cleaning and normalizing gene identifiers.
#' Handles version numbers, pipe-delimited IDs, and other common formats.
#'
#' Usage:
#'   source("utils/gene_id_cleanup.R")
#'   clean_ids <- cleanup_gene_ids(raw_ids)

#' Clean gene identifiers
#'
#' Removes version numbers from Ensembl IDs (e.g., ENSG00000141510.16 -> ENSG00000141510),
#' extracts gene names from pipe-delimited formats, and handles other common ID formats.
#'
#' @param gene_ids Character vector of gene identifiers
#' @return Character vector of cleaned gene identifiers
#' @export
cleanup_gene_ids <- function(gene_ids) {

  gene_ids <- as.character(gene_ids)

  # Remove Ensembl version numbers (Human: ENSG, Mouse: ENSMUSG)
  # Pattern: ENSG00000141510.16 -> ENSG00000141510
  gene_ids <- gsub("^(ENSG\\d+)\\.\\d+$", "\\1", gene_ids, ignore.case = TRUE)
  gene_ids <- gsub("^(ENSMUSG\\d+)\\.\\d+$", "\\1", gene_ids, ignore.case = TRUE)

  # Handle pipe-delimited IDs (e.g., "TP53|7157" -> "TP53")
  gene_ids <- gsub("\\|.+$", "", gene_ids)

  # Remove leading/trailing whitespace
  gene_ids <- trimws(gene_ids)

  # Remove any empty strings
  gene_ids[gene_ids == ""] <- NA

  return(gene_ids)
}

#' Remove version numbers from Ensembl IDs
#'
#' @param ensembl_ids Character vector of Ensembl gene IDs
#' @return Character vector without version numbers
#' @export
remove_ensembl_version <- function(ensembl_ids) {
  gsub("\\.\\d+$", "", ensembl_ids)
}

#' Extract gene symbol from pipe-delimited format
#'
#' Handles formats like "TP53|7157" common in some databases.
#'
#' @param gene_ids Character vector of gene identifiers
#' @return Character vector with only the gene symbol portion
#' @export
extract_symbol_from_pipe <- function(gene_ids) {
  sapply(strsplit(gene_ids, "\\|"), `[`, 1)
}

#' Detect ID format
#'
#' Identifies the format of gene identifiers.
#'
#' @param gene_ids Character vector of gene identifiers
#' @return Character describing the detected format
#' @export
detect_id_format <- function(gene_ids) {

  # Sample a few IDs
  sample_ids <- head(gene_ids[!is.na(gene_ids)], 100)

  # Check for Ensembl human (ENSG)
  if (any(grepl("^ENSG\\d+", sample_ids, ignore.case = TRUE))) {
    return("ENSEMBL_HUMAN")
  }

  # Check for Ensembl mouse (ENSMUSG)
  if (any(grepl("^ENSMUSG\\d+", sample_ids, ignore.case = TRUE))) {
    return("ENSEMBL_MOUSE")
  }

  # Check for Entrez IDs (all numeric)
  if (all(grepl("^\\d+$", sample_ids))) {
    return("ENTREZID")
  }

  # Check for pipe-delimited
  if (any(grepl("\\|", sample_ids))) {
    return("PIPE_DELIMITED")
  }

  # Check for versioned IDs
  if (any(grepl("\\.\\d+$", sample_ids))) {
    return("VERSIONED")
  }

  # Default to symbol
  return("SYMBOL")
}

#' Clean expression matrix row names
#'
#' Applies all cleanup steps to expression matrix row names.
#'
#' @param expr_matrix Expression matrix with gene IDs as row names
#' @return Expression matrix with cleaned row names
#' @export
clean_expr_matrix_rownames <- function(expr_matrix) {

  original_ids <- rownames(expr_matrix)

  # Apply cleanup
  cleaned_ids <- cleanup_gene_ids(original_ids)

  # Handle duplicates after cleanup
  if (any(duplicated(cleaned_ids[!is.na(cleaned_ids)]))) {
    # Keep first occurrence
    dup_idx <- duplicated(cleaned_ids) | is.na(cleaned_ids)
    expr_matrix <- expr_matrix[!dup_idx, , drop = FALSE]
    cleaned_ids <- cleaned_ids[!dup_idx]
  }

  rownames(expr_matrix) <- cleaned_ids
  return(expr_matrix)
}

#' Filter genes by expression
#'
#' Removes genes that are:
#' - Expressed in too few cells (rare)
#' - Expressed in too many cells (ubiquitous)
#'
#' @param expr_matrix Expression matrix (genes x cells)
#' @param min_cells Minimum number of cells a gene must be expressed in
#' @param min_pct Minimum percentage of cells (alternative to min_cells)
#' @param max_pct Maximum percentage of cells (for ubiquitous filtering)
#' @param expr_threshold Minimum expression value to count as "expressed"
#' @return Filtered expression matrix
#' @export
filter_genes_by_expression <- function(expr_matrix,
                                        min_cells = NULL,
                                        min_pct = 0.01,
                                        max_pct = 0.99,
                                        expr_threshold = 0) {

  n_cells <- ncol(expr_matrix)

  # Calculate cells where each gene is expressed
  expr_counts <- rowSums(expr_matrix > expr_threshold)

  # Determine minimum cells threshold
  if (is.null(min_cells)) {
    min_cells <- ceiling(n_cells * min_pct)
  }
  max_cells <- floor(n_cells * max_pct)

  # Filter
  keep <- (expr_counts >= min_cells) & (expr_counts <= max_cells)

  message(sprintf(
    "Gene filtering: %d -> %d genes (removed %d rare, %d ubiquitous)",
    nrow(expr_matrix),
    sum(keep),
    sum(expr_counts < min_cells),
    sum(expr_counts > max_cells)
  ))

  return(expr_matrix[keep, , drop = FALSE])
}

#' Remove ribosomal genes
#'
#' Filters out genes matching ribosomal gene patterns.
#'
#' @param gene_ids Character vector of gene identifiers
#' @return Logical vector (TRUE = keep, FALSE = ribosomal)
#' @export
is_not_ribosomal <- function(gene_ids) {
  # Common ribosomal gene patterns
  ribo_patterns <- c(
    "^RPL",   # Ribosomal protein L
    "^RPS",   # Ribosomal protein S
    "^MRPL",  # Mitochondrial ribosomal protein L
    "^MRPS"   # Mitochondrial ribosomal protein S
  )

  pattern <- paste(ribo_patterns, collapse = "|")
  !grepl(pattern, gene_ids, ignore.case = TRUE)
}

#' Remove mitochondrial genes
#'
#' Filters out mitochondrial genes.
#'
#' @param gene_ids Character vector of gene identifiers
#' @return Logical vector (TRUE = keep, FALSE = mitochondrial)
#' @export
is_not_mitochondrial <- function(gene_ids) {
  !grepl("^MT-", gene_ids, ignore.case = TRUE)
}
