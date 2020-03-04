
########## Gene regulatory network evaluation ##################
# introduced in https://doi.org/10.1186/s12859-018-2217-z

# used files:
# filtered exp matrix
# cell label
# regulon_gene_name, regulon, regulon_motif

#BiocManager::install("minet")

library(minet)

args <- commandArgs(TRUE)
wd <- args[1] # filtered expression file name
jobid <- args[2] # user job id

###test
wd <- "C:/Users/wan268/Documents/iris3_data/20190617154456"
jobid <-20190617154456 
# expFile <- "20190617154456_filtered_expression.txt"
# labelFile <- "20190617154456_cell_label.txt"

setwd(wd)

sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
  
}

alldir <- list.dirs(path = wd)
alldir <- grep("*_bic$",alldir,value=T)
alldir <- sort_dir(alldir)

exp_data<- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
exp_data <- as.matrix(exp_data)
cells_rankings <- AUCell_buildRankings(exp_data) 
cells_rankings@assays@.xData$data@listData$ranking
label_data <- read.table(paste(jobid,"_cell_label.txt",sep = ""),sep="\t",header = T)
