install_all <- function(){
  bioc_packages <- c(
    "BSgenome.Celegans.UCSC.ce11", "TxDb.Celegans.UCSC.ce11.refGene",
    "BSgenome.Hsapiens.UCSC.hg38", "TxDb.Hsapiens.UCSC.hg38.knownGene",
    "BSgenome.Mmusculus.UCSC.mm10", "TxDb.Mmusculus.UCSC.mm10.knownGene",
    "BSgenome.Scerevisiae.UCSC.sacCer3", "TxDb.Scerevisiae.UCSC.sacCer3.sgdGene",
    "BSgenome.Drerio.UCSC.danRer10","TxDb.Drerio.UCSC.danRer10.refGene",
    "BSgenome.Dmelanogaster.UCSC.dm6","TxDb.Dmelanogaster.UCSC.dm6.ensGene",
    "org.Ce.eg.db", "org.Dm.eg.db", "org.Dr.eg.db", "org.Sc.sgd.db", "org.Mm.eg.db","org.Hs.eg.db",
    "monocle","GenomicAlignments","ensembldb","kebabs"
    
  )
  cran_packages <- c(
    "seqinr","base","stringr","Seurat","tidyverse","rlist","hdf5r","Matrix","plotly","RColorBrewer","Polychrome","ggplot2"
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

