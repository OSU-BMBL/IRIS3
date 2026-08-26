#!/usr/bin/env Rscript
#' IRIS3 Regulon Scoring Module
#'
#' Calculates Regulon Activity Score (RAS) and Regulon Specificity Score (RSS)
#' for discovered regulons.
#'
#' Methods supported:
#' - AUCell (default): Area Under Curve scoring
#' - WMW test: Wilcoxon-Mann-Whitney test
#' - GSVA methods: zscore, plage, ssgsea
#'
#' Input:
#'   - {jobid}_filtered_expression.txt
#'   - {jobid}_cell_label.txt
#'   - CT_*_bic.regulon_gene_symbol.txt
#'
#' Output:
#'   - CT_*_bic.regulon_activity_score.txt
#'   - CT_*_bic.regulon_rank.txt

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
load_iris3_libraries(c("core", "scoring"))

# Additional libraries for scoring
suppressPackageStartupMessages({
  library(AUCell)
  library(BioQC)
  library(data.table)
})

#' Parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  params <- list(
    working_dir = args[1],
    jobid = args[2],
    method = ifelse(length(args) >= 3, args[3], "wmw_test"),
    n_cores = ifelse(length(args) >= 4, as.integer(args[4]), 8)
  )

  return(params)
}

#' Calculate Jensen-Shannon Divergence
#' @param v1 First probability distribution
#' @param v2 Second probability distribution
#' @return JSD value
calc_jsd <- function(v1, v2) {
  # Entropy function
  H <- function(v) {
    v <- v[v > 0]
    return(sum(-1 * v * log(v)))
  }

  # JSD
  return(H(v1/2 + v2/2) - (H(v1) + H(v2))/2)
}

#' Calculate gene rankings for expression matrix
#' @param expr Expression matrix (genes x cells)
#' @return Rankings matrix
calc_rankings <- function(expr) {

  if (!data.table::is.data.table(expr)) {
    expr <- data.table::data.table(expr, keep.rownames = TRUE)
  }

  data.table::setkey(expr, "rn")
  cols <- colnames(expr)[-1]

  # Rank genes per cell (higher expression = lower rank)
  rankings <- expr[, (cols) := lapply(-.SD, data.table::frankv,
                                       order = -1L,
                                       ties.method = "min",
                                       na.last = "keep"),
                    .SDcols = cols]

  rn <- rankings$rn
  rankings <- as.matrix(rankings[, -1])
  rownames(rankings) <- rn

  return(rankings)
}

#' Calculate Regulon Activity Score (RAS)
#' @param expr Expression matrix (genes x cells)
#' @param gene_sets List of gene sets (regulons)
#' @param method Scoring method
#' @param rankings Pre-computed rankings (for wmw_test)
#' @return Matrix of activity scores
calc_ras <- function(expr, gene_sets, method = "wmw_test", rankings = NULL) {

  message(paste("Calculating RAS using method:", method))

  if (method == "aucell") {
    # AUCell scoring
    expr <- as.matrix(expr)
    names(gene_sets) <- seq_along(gene_sets)

    cells_rankings <- AUCell_buildRankings(expr, plotStats = FALSE)
    cells_AUC <- AUCell_calcAUC(gene_sets, cells_rankings,
                                 aucMaxRank = nrow(cells_rankings) * 0.1)

    score_vec <- tryCatch(
      cells_AUC@assays@data@listData[['AUC']],
      error = function(e) cells_AUC@assays@.xData$data$AUC
    )

  } else if (method == "wmw_test") {
    # Wilcoxon-Mann-Whitney test
    if (is.null(rankings)) {
      rankings <- calc_rankings(as.data.frame(expr))
    }

    # Create gene set membership matrix
    geneset_matrix <- as.data.frame(lapply(gene_sets, function(genes) {
      rownames(rankings) %in% genes
    }))
    names(geneset_matrix) <- seq_along(gene_sets)

    # WMW test
    score_vec <- wmwTest(rankings, geneset_matrix,
                         valType = "abs.log10p.greater",
                         simplify = TRUE)

  } else if (method %in% c("zscore", "plage", "ssgsea")) {
    # GSVA methods
    library(GSVA)
    score_vec <- gsva(as.matrix(expr), gset = gene_sets, method = method)

  } else {
    stop(paste("Unknown method:", method))
  }

  return(score_vec)
}

#' Calculate Regulon Specificity Score (RSS)
#' @param ras_matrix RAS matrix (regulons x cells)
#' @param cell_labels Data frame with Cell and Label columns
#' @return Data frame with RSS per regulon per cell type
calc_rss <- function(ras_matrix, cell_labels) {

  unique_ct <- sort(unique(cell_labels$Label))
  n_regulons <- nrow(ras_matrix)
  n_ct <- length(unique_ct)

  # Normalize RAS to [0,1]
  ras_norm <- t(apply(ras_matrix, 1, function(x) {
    x <- scales::rescale(x, to = c(0, 1))
    x / sum(x)
  }))

  # Calculate mean RAS per cell type
  ct_means <- sapply(unique_ct, function(ct) {
    ct_cells <- cell_labels$Cell[cell_labels$Label == ct]
    ct_idx <- which(colnames(ras_matrix) %in% ct_cells)
    rowMeans(ras_norm[, ct_idx, drop = FALSE])
  })

  # Calculate RSS using JSD
  rss <- matrix(0, nrow = n_regulons, ncol = n_ct)
  rownames(rss) <- rownames(ras_matrix)
  colnames(rss) <- unique_ct

  for (ct_idx in seq_len(n_ct)) {
    # Reference distribution (uniform for one cell type)
    ref <- rep(0, n_ct)
    ref[ct_idx] <- 1

    for (reg_idx in seq_len(n_regulons)) {
      obs <- ct_means[reg_idx, ]
      obs <- obs / sum(obs)  # Normalize
      rss[reg_idx, ct_idx] <- 1 - sqrt(calc_jsd(ref, obs))
    }
  }

  return(rss)
}

#' Main regulon scoring function
#' @param params Parameters list
score_regulons <- function(params) {

  message("=== Regulon Scoring ===")
  setwd(params$working_dir)

  # Setup parallel processing
  library(doParallel)
  registerDoParallel(params$n_cores)
  message(paste("Using", params$n_cores, "cores"))

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

  # Pre-compute rankings if using WMW
  rankings <- NULL
  if (params$method == "wmw_test") {
    message("Computing gene rankings...")
    rankings <- calc_rankings(as.data.frame(expr_data))
  }

  # Find regulon files
  regulon_files <- list.files(".", pattern = "\\.regulon_gene_symbol\\.txt$")

  if (length(regulon_files) == 0) {
    message("No regulon files found")
    return()
  }

  message(paste("Found", length(regulon_files), "regulon files"))

  # Process each cell type
  for (rf in regulon_files) {
    ct_name <- gsub("\\.regulon_gene_symbol\\.txt$", "", rf)
    message(paste("Processing:", ct_name))

    # Read regulon genes
    regulons_raw <- readLines(rf)
    regulons <- lapply(strsplit(regulons_raw, "\t"), function(x) x[x != ""])

    if (length(regulons) == 0) {
      next
    }

    # Calculate RAS
    ras <- tryCatch({
      calc_ras(expr_data, regulons, method = params$method, rankings = rankings)
    }, error = function(e) {
      warning(paste("RAS calculation failed:", e$message))
      NULL
    })

    if (is.null(ras)) {
      next
    }

    # Save RAS
    ras_file <- paste0(ct_name, ".regulon_activity_score.txt")
    write.table(
      data.frame(Regulon = rownames(ras), ras, check.names = FALSE),
      ras_file,
      sep = "\t",
      row.names = FALSE,
      quote = FALSE
    )

    # Calculate RSS
    rss <- calc_rss(ras, cell_labels)

    # Rank regulons by RSS (for each cell type)
    ct_num <- as.integer(gsub("\\D", "", ct_name))

    if (!is.na(ct_num) && ct_num <= ncol(rss)) {
      regulon_ranks <- data.frame(
        Regulon = rownames(rss),
        RSS = rss[, ct_num],
        Rank = rank(-rss[, ct_num])
      )
      regulon_ranks <- regulon_ranks[order(regulon_ranks$Rank), ]

      rank_file <- paste0(ct_name, ".regulon_rank.txt")
      write.table(
        regulon_ranks,
        rank_file,
        sep = "\t",
        row.names = FALSE,
        quote = FALSE
      )

      message(sprintf("  %d regulons ranked", nrow(regulon_ranks)))
    }
  }

  message("=== Regulon Scoring Complete ===")
}

# Run if called directly
if (!interactive()) {
  params <- parse_args()
  score_regulons(params)
}
