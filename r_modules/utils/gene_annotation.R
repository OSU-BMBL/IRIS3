#' IRIS3 Gene Annotation Utilities
#'
#' Functions for detecting gene identifier types, species detection,
#' and gene symbol conversion. Supports Human and Mouse only.
#'
#' Usage:
#'   source("utils/gene_annotation.R")
#'   result <- detect_gene_identifier_type(gene_list, "Human")
#'   symbols <- convert_to_symbols(gene_ids, "Human", "ENSEMBL")

# Ensure annotation packages are loaded
suppressPackageStartupMessages({
  library(AnnotationDbi)
  library(org.Hs.eg.db)
  library(org.Mm.eg.db)
})

# Database mapping for supported species
.species_db <- list(
  Human = org.Hs.eg.db,
  Mouse = org.Mm.eg.db
)

# Valid identifier types
.valid_keytypes <- c("SYMBOL", "ENSEMBL", "ENTREZID", "ENSEMBLTRANS")

#' Get annotation database for species
#'
#' @param species Character, "Human" or "Mouse"
#' @return OrgDb object
#' @export
get_species_db <- function(species) {
  species <- normalize_species_name(species)
  if (!species %in% names(.species_db)) {
    stop(paste("Unsupported species:", species, ". Only Human and Mouse are supported."))
  }
  return(.species_db[[species]])
}

#' Normalize species name to standard form
#'
#' @param species Character, species name (case-insensitive)
#' @return Character, normalized species name ("Human" or "Mouse")
#' @export
normalize_species_name <- function(species) {
  species_lower <- tolower(trimws(species))
  if (species_lower %in% c("human", "homo sapiens", "hs", "hg38", "hg19")) {
    return("Human")
  } else if (species_lower %in% c("mouse", "mus musculus", "mm", "mm10", "mm9")) {
    return("Mouse")
  } else {
    stop(paste("Unknown species:", species))
  }
}

#' Detect gene identifier type by matching against database
#'
#' Determines whether gene identifiers are SYMBOL, ENSEMBL, ENTREZID, or ENSEMBLTRANS
#' by testing which keytype produces the most matches.
#'
#' @param gene_list Character vector of gene identifiers
#' @param species Character, "Human" or "Mouse"
#' @return List with 'keytype' and 'match_count'
#' @export
detect_gene_identifier_type <- function(gene_list, species) {

  db <- get_species_db(species)

  # Sample genes if list is very long (for performance)
  if (length(gene_list) > 1000) {
    gene_list <- sample(gene_list, 1000)
  }

  # Test each keytype
  results <- sapply(.valid_keytypes, function(kt) {
    tryCatch({
      matches <- AnnotationDbi::select(
        db,
        keys = gene_list,
        columns = c("SYMBOL"),
        keytype = kt
      )
      nrow(matches)
    }, error = function(e) 0)
  })

  best_idx <- which.max(results)

  return(list(
    keytype = names(results)[best_idx],
    match_count = results[best_idx],
    all_counts = results
  ))
}

#' Auto-detect species from gene identifiers
#'
#' Tests gene list against Human and Mouse databases to determine species.
#'
#' @param gene_list Character vector of gene identifiers
#' @return Character, "Human" or "Mouse"
#' @export
detect_species <- function(gene_list) {

  # Sample genes if list is very long
  if (length(gene_list) > 500) {
    gene_list <- sample(gene_list, 500)
  }

  human_result <- detect_gene_identifier_type(gene_list, "Human")
  mouse_result <- detect_gene_identifier_type(gene_list, "Mouse")

  if (human_result$match_count >= mouse_result$match_count) {
    return("Human")
  } else {
    return("Mouse")
  }
}

#' Convert gene identifiers to symbols
#'
#' @param gene_ids Character vector of gene identifiers
#' @param species Character, "Human" or "Mouse"
#' @param from_keytype Character, source keytype (auto-detected if NULL)
#' @return Data frame with original IDs and symbols
#' @export
convert_to_symbols <- function(gene_ids, species, from_keytype = NULL) {

  db <- get_species_db(species)

  # Auto-detect keytype if not provided
  if (is.null(from_keytype)) {
    detected <- detect_gene_identifier_type(gene_ids, species)
    from_keytype <- detected$keytype
  }

  # Already symbols
  if (from_keytype == "SYMBOL") {
    return(data.frame(
      original = gene_ids,
      SYMBOL = gene_ids,
      stringsAsFactors = FALSE
    ))
  }

  # Convert to symbols
  result <- tryCatch({
    AnnotationDbi::select(
      db,
      keys = gene_ids,
      columns = c("SYMBOL", "ENSEMBL"),
      keytype = from_keytype
    )
  }, error = function(e) {
    warning(paste("Conversion failed:", e$message))
    return(NULL)
  })

  if (is.null(result)) {
    return(data.frame(
      original = gene_ids,
      SYMBOL = gene_ids,
      stringsAsFactors = FALSE
    ))
  }

  # Rename columns and remove duplicates
  colnames(result)[1] <- "original"
  # Ensure SYMBOL column exists
  if (!"SYMBOL" %in% colnames(result)) {
    result$SYMBOL <- result$original
  }
  result <- result[!duplicated(result$original), ]
  result <- result[!is.na(result$SYMBOL), ]

  return(result)
}

#' Get promoter sequences for genes
#'
#' Retrieves promoter region coordinates (upstream of TSS).
#'
#' @param gene_symbols Character vector of gene symbols
#' @param species Character, "Human" or "Mouse"
#' @param upstream Integer, base pairs upstream of TSS (default 1000)
#' @return Data frame with gene coordinates
#' @export
get_promoter_regions <- function(gene_symbols, species, upstream = 1000) {

  # This is a placeholder - full implementation requires TxDb packages
  # which add significant size. For now, return a stub.

  warning("get_promoter_regions not fully implemented - requires TxDb packages")

  return(data.frame(
    symbol = gene_symbols,
    chr = NA,
    start = NA,
    end = NA,
    strand = NA,
    stringsAsFactors = FALSE
  ))
}

#' Validate gene list
#'
#' Check what percentage of genes are found in the annotation database.
#'
#' @param gene_list Character vector of gene identifiers
#' @param species Character, "Human" or "Mouse"
#' @return List with validation statistics
#' @export
validate_gene_list <- function(gene_list, species) {

  detected <- detect_gene_identifier_type(gene_list, species)

  return(list(
    total_genes = length(gene_list),
    matched_genes = detected$match_count,
    match_rate = detected$match_count / length(gene_list),
    keytype = detected$keytype,
    species = species
  ))
}
