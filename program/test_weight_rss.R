
########## Test weighted RSS score ##################

library(tidyverse)

library(dabestr)

jobid <-20190915164515 

wd <- paste("/var/www/html/iris3/data/",jobid,sep="")
#wd <- paste("C:/Users/wan268/Documents/iris3_data/",jobid,sep="")
expFile <- paste(jobid,"_filtered_expression.txt",sep="")
labelFile <- paste(jobid,"_cell_label.txt",sep = "")
# wd <- getwd()
setwd(wd)


quiet <- function(x) { 
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 



sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
  
}

alldir <- list.dirs(path = wd)
alldir <- grep("*_bic$",alldir,value=T)
alldir <- sort_dir(alldir)

total_motif_list <- list()
total_rank_list <- list()
for (i in 1:length(alldir)) {
  regulon_motif_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),"r")
  regulon_motif <- readLines(regulon_motif_handle)
  close(regulon_motif_handle)
  motif_list <- lapply(strsplit(regulon_motif,"\\t"), function(x){x})
  
  regulon_rank_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),"r")
  regulon_rank <- readLines(regulon_rank_handle)
  close(regulon_rank_handle)
  
  rank_list <- lapply(strsplit(regulon_rank,"\\t"), function(x){x})
  total_motif_list <- append(total_motif_list,motif_list)
  total_rank_list <- append(total_rank_list,rank_list)
}

total_regulon <- length(total_motif_list)

regulon_rss <-  as.numeric(unlist(lapply(total_rank_list, function(x){
  return (x[[6]])
})))

regulon_pvalue <-  as.numeric(unlist(lapply(total_rank_list, function(x){
  return (x[[5]])
})))


df <- pv<- data.frame()
#df1 <- data.frame(value=as.numeric(regulon_rss),group="default")
#pv1 <- data.frame(value=as.numeric(regulon_pvalue),group="default")


#df2 <- data.frame(value=as.numeric(regulon_rss),group="x2")
#pv2 <- data.frame(value=as.numeric(regulon_pvalue),group="x2")


#df3 <- data.frame(value=as.numeric(regulon_rss),group="x5")
#pv3 <- data.frame(value=as.numeric(regulon_pvalue),group="x5")

#df4 <- data.frame(value=as.numeric(regulon_rss),group="x_total_ct=7")
#pv4 <- data.frame(value=as.numeric(regulon_pvalue),group="x_total_ct=7")


df <- rbind(df1,df2,df3,df4)

unpaired_regulon_rss <- dabest(df,group, value,
                             idx =  c("default","x2","x5","x_total_ct=7"),
                             paired = FALSE)
plot(unpaired_regulon_rss)




#pv <- rbind(pv1,pv2,pv3,pv4)
#
#unpaired_regulon_rss_pvalue <- dabest(pv,group, value,
#                             idx =  c("default","x2","x5","x_total_ct=7"),
#                             paired = FALSE)
#plot(unpaired_regulon_rss_pvalue)


pv <- rbind(pv1,pv4)

unpaired_regulon_rss_pvalue <- dabest(pv,group, value,
                                      idx =  c("default","x_total_ct=7"),
                                      paired = FALSE)
plot(unpaired_regulon_rss_pvalue)


