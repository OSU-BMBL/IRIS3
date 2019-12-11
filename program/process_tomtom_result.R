library(seqinr)
args <- commandArgs(TRUE)

jobid <- args[1]


#jobid <-20191210150257
wd <- paste("/var/www/html/iris3/data/",jobid,sep="")
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
short_dir <- grep("*_bic$",list.dirs(path = wd,full.names = F),value=T)
short_dir<- sort_dir(short_dir)
#gene_id_name <- read.table(paste(jobid,"_gene_id_name.txt",sep=""))
#i=1

total_ct <- max(na.omit(as.numeric(stringr::str_match(list.files(path = wd), "_CT_(.*?)_bic")[,2])))
module_type <- sub(paste(".*",jobid,"_ *(.*?) *_.*",sep=""), "\\1", short_dir)
allfiles <- list.files(path = "tomtom",pattern = "tomtom.tsv",recursive = T,full.names = T)
total_tomtom_result <- data.frame()
if (length(allfiles) > 0) {
  for (i in 1:length(allfiles)) {
    motif_id <- strsplit(allfiles[i],"/")[[1]][2]
    tomtom_handle <- file(allfiles[i],"r")
    tomtom <- readLines(tomtom_handle)
    close(tomtom_handle)

    tf_query <- c(motif_id, strsplit(tomtom[2],"\t")[[1]][c(2,3,4,5,6)])
    if(all(!is.na(tf_query))){
      total_tomtom_result <- rbind(total_tomtom_result,t(data.frame(tf_query)))
    }
  }
  #colnames(total_tomtom_result) <- c("motif_id","TF_name","p_value","e_value","q_value")

  #total_tomtom_result[,2] <- gsub("[_(].*","",total_tomtom_result[,2])
  write.table(total_tomtom_result,paste(jobid,"_tomtom_result.txt",sep = ""), sep="\t",row.names = F,col.names = F,quote = F)
}
