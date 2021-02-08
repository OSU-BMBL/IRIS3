install_all <- function(){
  bioc_packages <- c(
    "BSgenome.Hsapiens.UCSC.hg38", "TxDb.Hsapiens.UCSC.hg38.knownGene",
    "BSgenome.Mmusculus.UCSC.mm10", "TxDb.Mmusculus.UCSC.mm10.knownGene",
    "org.Mm.eg.db","org.Hs.eg.db",
    "monocle","GenomicAlignments","ensembldb"
  )
  cran_packages <- c(
    "seqinr","base","stringr","Seurat","tidyverse","rlist","hdf5r","Matrix","RColorBrewer","Polychrome","ggplot2"
  )
  bioc_np <- bioc_packages[!(bioc_packages %in% installed.packages()[,"Package"])]
  cran_np <- cran_packages[!(cran_packages %in% installed.packages()[,"Package"])]
  if (!require("BiocManager")) install.packages("BiocManager")
  BiocManager::install(bioc_np)
  install.packages(cran_np)
  
  
}

detach_all <- function() {
  
  basic.packages <- c("package:stats","package:graphics","package:grDevices","package:utils","package:datasets","package:methods","package:base")
  package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
  package.list <- setdiff(package.list,basic.packages)
  if (length(package.list)>0)  for (package in package.list) detach(package, character.only=TRUE)
}

