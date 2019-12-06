#######  get TAD overlapped genes that not in this regulon ##########


args <- commandArgs(TRUE)
# setwd("D:/Users/flyku/Documents/CeRIS-data/test_missing_heatmap")
# srcDir <- getwd()
# tad_dir <- 'D:/Users/flyku/Documents/CeRIS-data/tad/mm10'
# regulon <- 'CT1S-R2'
# jobid <- '20190404232115'
# species <- 'Human'
srcDir <- args[1] # /var/www/html/CeRIS/data/20190404232115
regulon <- args[2] # CT3S-R5
species <- args[3] #Human, Mouse
jobid <- args[4]
setwd(srcDir)

if (species == "Human") {
  tad_dir <- '/var/www/html/CeRIS/program/db/tad/hg38'
} else if (species == "Mouse"){
  tad_dir <- '/var/www/html/CeRIS/program/db/tad/mm10'
}
# parse 'CT3S-R5' to 'CT', '3', '5'
#regulon_ct <- strsplit(regulon,"S-R")[[1]][1]
#regulon_ct <- gsub( "[0-9].*$", "", regulon )
# regulon= 'modul1-R2'
# regulon= 'CT1S-R2'
regulon_type <- gsub( "[0-9].*$", "", regulon)
regulon_type_id <-gsub( "S.*$", "", regulon)
regulon_type_id <-gsub( "-.*$", "", regulon_type_id)
regulon_type_id <-gsub("[[:alpha:]]","",regulon_type_id)
regulon_id <- gsub( ".*R", "", regulon)
regulon_id <- gsub("[[:alpha:]]","",regulon_id)
tad_files <- list.files(tad_dir,pattern = "*.bed.txt$",full.names = T)
motif_position <- read.delim("motif_position.bed",sep = '\t',header = F)
regulon_filename <- paste(jobid,"_",regulon_type,"_",regulon_type_id,"_bic.regulon_gene_id.txt",sep="")
gene_id_name <- read.table(paste(jobid,"_gene_id_name.txt",sep=""),header = T)
regulon_file_connection <- file(regulon_filename)
regulon_file <- strsplit(readLines(regulon_file_connection), "\t")
close(regulon_file_connection)
regulon_gene_list <- regulon_file[[as.numeric(regulon_id)]][-1]
# this <- as.matrix(motif_position[6,])
get_type_gene <- function (this,type,id){
  if(strsplit(as.character(this[6]),",")[[1]][1] == id && this[5] == type){
    return (1)
  } else {
    return (0)
  }
}
unique_gene_list_in_type_idx <- apply(as.matrix(motif_position), 1, get_type_gene, type=regulon_type, id=regulon_type_id)
unique_gene_list_in_type <- motif_position[which(unique_gene_list_in_type_idx == 1),]
unique_gene_list_in_type <- as.character(unique_gene_list_in_type[!duplicated(unique_gene_list_in_type[,4]),4])


# Total 3 genelists:
#   1. tad_files > tad_gene_list
#   2. unique_gene_list_in_type
#   3. regulon_gene_list

#this_tad_file <- tad_files[1]
get_result_gene_list <- function(this_tad_file){
  tad_file_connection <- file(this_tad_file)
  tad_gene_list <- strsplit(readLines(tad_file_connection), " ")
  close(tad_file_connection)
  regulon_tad_overlap_idx <- which(lapply(lapply(tad_gene_list, match, regulon_gene_list), any) == T)
  result_gene <- unlist(tad_gene_list[regulon_tad_overlap_idx])
  result_gene <- result_gene[!result_gene %in% regulon_gene_list]
  result_gene <- unique_gene_list_in_type[unique_gene_list_in_type %in% result_gene]
  #tst<- result_gene[result_gene %in% unique_gene_list_in_type]
  result_gene <- as.character(gene_id_name[gene_id_name[,1] %in% result_gene,2])
  tad_file_short_name <- gsub(".*mm10/","",this_tad_file)
  tad_file_short_name <- gsub(".*hg38/","",tad_file_short_name)
  tad_file_short_name <- gsub(".txt.bed.txt","",tad_file_short_name)
  tad_file_short_name <- gsub(".domains.bed.txt","",tad_file_short_name)
  if (length(result_gene) == 0){
    result_gene <- 'Not found'
  }
  return (c(tad_file_short_name,species,paste(result_gene,collapse = " ")))
}



invisible(capture.output(result_gene_list <- lapply(tad_files, get_result_gene_list)))
dir.create("tad", showWarnings = FALSE)

invisible(capture.output(file.create(paste("tad/",regulon,".tad.txt",sep = ""))))
invisible(capture.output(lapply(result_gene_list, write,paste("tad/",regulon,".tad.txt",sep = ""),sep="\t", append=TRUE, ncolumns=1000)))

### Generate gene list for all tad files
#i=1
#j=1932
#
#tad_files <- list.files( "D:/Users/flyku/Documents/CeRIS-data/tad/hg38",pattern = "*.bed$",full.names = T)
#for (i in 1:length(tad_files)) {
#  test_tad <- read.table(tad_files[i],header = F)
#  tad_gene_list <- list()
#  for (j in 1:max(test_tad[,4])) {
#    this_tad_gene_list <- as.character(test_tad[which(test_tad[,4] == j),8])
#    #this_tad_gene_list <- this_tad_gene_list[!duplicated(this_tad_gene_list)]
#    tad_gene_list[[j]] <- this_tad_gene_list
#  }
#  #lapply(tad_gene_list, function(x) write.table( data.frame(x), paste(tad_files[i],".txt",sep = "")  , append= T, sep='\t' ))
#  file.create(paste(tad_files[i],".txt",sep = ""))
#  lapply(tad_gene_list, write,paste(tad_files[i],".txt",sep = ""), append=TRUE, ncolumns=1000)
#}


