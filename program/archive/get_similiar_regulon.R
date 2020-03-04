#######  get TAD overlapped genes that not in this regulon ##########


args <- commandArgs(TRUE)
# setwd("D:/Users/flyku/Documents/CeRIS-data/test_similar_regulon")
# srcDir <- getwd()
# regulon <- 'CT1S-R2'
# jobid <- '20190406210706'
srcDir <- args[1] # /var/www/html/CeRIS/data/20190406210706
regulon <- args[2] # CT3S-R5
jobid <- args[3]
setwd(srcDir)

# parse 'CT3S-R5' to 'CT', '3', '5'
# regulon_ct <- strsplit(regulon,"S-R")[[1]][1]
# regulon_ct <- gsub( "[0-9].*$", "", regulon )
# regulon= 'modul1-R2'
# regulon= 'CT3S-R9'
regulon_type <- gsub( "[0-9].*$", "", regulon)
regulon_type_id <- gsub( "S.*$", "", regulon)
regulon_type_id <- gsub( "-.*$", "", regulon_type_id)
regulon_type_id <- gsub("[[:alpha:]]","",regulon_type_id)
regulon_id <- gsub( ".*R", "", regulon)
regulon_id <- gsub("[[:alpha:]]","",regulon_id)

regulon_motif_filename<- paste(jobid,"_",regulon_type,"_",regulon_type_id,"_bic.regulon_motif.txt",sep="")

file_connection <- file(regulon_motif_filename)
regulon_motif_file <- strsplit(readLines(file_connection), "\t")
close(file_connection)

file_connection <- file('combine_regulon_motif.txt')
all_regulon_motif_file <- strsplit(readLines(file_connection), "\t")
close(file_connection)

# select first motif
regulon_motif_info <- regulon_motif_file[[as.numeric(regulon_id)]][2]
regulon_motif_bic <- strsplit(regulon_motif_info,",")[[1]][2]
regulon_motif_closure <- strsplit(regulon_motif_info,",")[[1]][3]
regulon_name_in_combine_bbc <- paste(regulon_type,"_",regulon_type_id,"-bic",regulon_motif_bic,".txt.fa.closures-",regulon_motif_closure,sep = "")

combine_bbc <- read.table("bg.BBC/bg.combine_bbc.bbc.txt.MC",header = T)

similar_regulon_idx <- combine_bbc[combine_bbc$Name %in% regulon_name_in_combine_bbc,3]
similiar_regulon <- as.character(combine_bbc[combine_bbc[,3] %in% similar_regulon_idx,1])
similiar_regulon_motif_info <- strsplit(gsub("[^[:digit:]]", ",", unlist(similiar_regulon)), ",")
similiar_regulon_motif_info <- lapply(similiar_regulon_motif_info, function(x) x[!x %in% ""])
similiar_regulon_motif_info <- lapply(similiar_regulon_motif_info,paste,collapse=",")

result_idx <- which(lapply(lapply(all_regulon_motif_file,match,similiar_regulon_motif_info), any) == T)
result_regulon <- unlist(all_regulon_motif_file[result_idx])
result_regulon <- result_regulon[startsWith(result_regulon,"CT")]

if (length(result_regulon) <= 1) {
  result_regulon <- paste("No similar CTS-R found in other cell types",sep = '\t')
} else {
  result_regulon <- result_regulon[! result_regulon %in% regulon]
  result_regulon <- paste(result_regulon,sep = '\t')
}

dir.create("similar_regulon", showWarnings = FALSE)
invisible(capture.output(write.table(result_regulon,paste("similar_regulon/",regulon,".similar.txt",sep = ""),sep="\t", append=F, quote = F,eol = " ",col.names = F,row.names = F)
))
