#' IRIS3 Library Loader
#'
#' Centralized library loading to eliminate redundant suppressPackageStartupMessages
#' calls across multiple scripts.
#'
#' Usage:
#'   source("utils/library_loader.R")
#'   load_iris3_libraries("seurat")  # Load specific module
#'   load_iris3_libraries("all")     # Load all libraries

# Define package groups by functionality
.iris3_packages <- list(
  # Core data manipulation
  core = c(
    "stringr",
    "dplyr",
    "tidyverse",
    "jsonlite",
    "data.table"
  ),


  # Seurat and single-cell analysis
  seurat = c(
    "Seurat",
    "SingleCellExperiment",
    "scater",
    "scran",
    "hdf5r"
  ),

  # Gene annotation databases (Human + Mouse only)
  annotation = c(
    "AnnotationDbi",
    "org.Hs.eg.db",
    "org.Mm.eg.db"
  ),

  # Trajectory analysis (optional)
  trajectory = c(
    "slingshot",
    "destiny",
    "gam"
  ),

  # Regulon scoring
  scoring = c(
    "AUCell",
    "scales",
    "sgof",
    "foreach",
    "doParallel"
  ),

  # Visualization
 visualization = c(
    "ggplot2",
    "RColorBrewer",
    "Polychrome",
    "cluster"
  ),

  # Imputation (optional)
  imputation = c(
    "DrImpute"
  ),

  # File I/O utilities
  io = c(
    "reader",
    "xfun",
    "devEMF"
  )
)

#' Load IRIS3 libraries by module
#'
#' @param modules Character vector of module names to load, or "all" for everything
#' @param quiet Logical, suppress all messages if TRUE
#' @return Invisibly returns list of loaded packages
#' @export
load_iris3_libraries <- function(modules = "all", quiet = TRUE) {

  if ("all" %in% modules) {
    modules <- names(.iris3_packages)
  }

  loaded <- character()
  failed <- character()

  for (mod in modules) {
    if (!mod %in% names(.iris3_packages)) {
      warning(paste("Unknown module:", mod))
      next
    }

    pkgs <- .iris3_packages[[mod]]
    for (pkg in pkgs) {
      result <- tryCatch({
        if (quiet) {
          suppressPackageStartupMessages(
            library(pkg, character.only = TRUE, quietly = TRUE)
          )
        } else {
          library(pkg, character.only = TRUE)
        }
        loaded <- c(loaded, pkg)
        TRUE
      }, error = function(e) {
        failed <- c(failed, pkg)
        FALSE
      })
    }
  }

  if (length(failed) > 0 && !quiet) {
    warning(paste("Failed to load packages:", paste(failed, collapse = ", ")))
  }

  invisible(list(loaded = unique(loaded), failed = unique(failed)))
}

#' Check if required packages are installed
#'
#' @param modules Character vector of module names to check
#' @return Data frame with package names and installation status
#' @export
check_iris3_packages <- function(modules = "all") {

  if ("all" %in% modules) {
    modules <- names(.iris3_packages)
  }

  all_pkgs <- unique(unlist(.iris3_packages[modules]))

  status <- data.frame(
    package = all_pkgs,
    installed = sapply(all_pkgs, function(p) {
      requireNamespace(p, quietly = TRUE)
    }),
    stringsAsFactors = FALSE
  )

  return(status)
}

#' Install missing IRIS3 packages
#'
#' @param modules Character vector of module names
#' @export
install_iris3_packages <- function(modules = "all") {

  status <- check_iris3_packages(modules)
  missing <- status$package[!status$installed]

  if (length(missing) == 0) {
    message("All packages are installed.")
    return(invisible(NULL))
  }

  message(paste("Installing", length(missing), "missing packages..."))

  # Check for BiocManager
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
  }

  # Bioconductor packages
  bioc_pkgs <- c("org.Hs.eg.db", "org.Mm.eg.db", "AnnotationDbi",
                 "SingleCellExperiment", "scater", "scran",
                 "AUCell", "slingshot", "destiny")

  bioc_missing <- intersect(missing, bioc_pkgs)
  cran_missing <- setdiff(missing, bioc_pkgs)

  if (length(bioc_missing) > 0) {
    BiocManager::install(bioc_missing, ask = FALSE, update = FALSE)
  }

  if (length(cran_missing) > 0) {
    install.packages(cran_missing, repos = "https://cloud.r-project.org")
  }
}

# Set global options
options(check.names = FALSE)
options(stringsAsFactors = FALSE)
