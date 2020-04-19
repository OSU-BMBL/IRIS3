
########## Generate RSS scatter plot ##################
# used files:
# regulon_motif
library(tidyverse)
library(ggplot2)
library(ggrepel)
library(xml2)
library(XML)
library(seqinr)
library(grid)

args <- commandArgs(TRUE)
jobid <- args[1] # job id
#jobid <-20200418142514 
wd <- paste("/var/www/html/iris3/data/",jobid,sep="")
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

allfiles <- list.files(path = "tomtom",pattern = "tomtom.xml",recursive = T,full.names = T)
total_motif_name <- data.frame()
for (i in 1:length(allfiles)) {
  motif_id <- strsplit(allfiles[i],"/")[[1]][2]
  xml_data <- read_xml(allfiles[i])
  tf_query <- xml_find_all(xml_data, ".//motif")
  tf_id <- xml_attr(tf_query, "id")
  tf_alt <- xml_attr(tf_query, "alt")
  tf_name <- as.character(mapply(function(x,y){
    if(is.na(y)){
      return(x)
    } else {
      return(y)
    }
  }, x=tf_id,y=tf_alt))
  motif_index <- xml_find_all(xml_data, ".//matches")
  motif_index <- xml_find_all(xml_data, ".//query")
  motif_index <- xml_find_all(xml_data, ".//target")
  motif_index <-as.numeric(xml_attr(motif_index, "idx")[1]) + 2
  if(!is.na(motif_index)){
    total_motif_name <- rbind(total_motif_name,data.frame(motif_id,tf_name[motif_index]))
  }
}
colnames(total_motif_name) <- c("motif_id","TF_name")

total_motif_name[,2] <- gsub("[_(].*","",total_motif_name[,2])

total_tf_list <- list()
for (i in 1:length(unique(total_motif_name[,2]))) {
  this_tf_index <- total_motif_name[,2] %in% unique(total_motif_name[,2])[i]
  tmp_list <- c(as.character(unique(total_motif_name[,2])[i]),as.character(total_motif_name[this_tf_index,1]))
  total_tf_list <- append(list(tmp_list),total_tf_list)
}
total_tf_name_list <- vector()
for (i in 1:length(alldir)) {
  regulon_motif_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),"r")
  regulon_motif <- readLines(regulon_motif_handle)
  close(regulon_motif_handle)
  
  regulon_rank_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),"r")
  regulon_rank <- readLines(regulon_rank_handle)
  close(regulon_rank_handle)
  
  if(length(regulon_motif) > 0){
    motif_list <- unlist(lapply(strsplit(regulon_motif,"\\t"), function(x){x[[2]]}))
    rank_list <- unlist(lapply(strsplit(regulon_rank,"\\t"), function(x){x[[6]]}))
    rss_pvalue_list <- as.numeric(unlist(lapply(strsplit(regulon_rank,"\\t"), function(x){x[[5]]})))
    
    motif_list <- lapply(strsplit(motif_list,","), function(x){
      paste("ct",x[[1]],"bic",x[[2]],"m",x[[3]],sep = "")
    })
    tf_idx <- unlist(lapply(motif_list, function(x){
      which(total_motif_name[,1] %in% x)    
    }))
    tf_names <- total_motif_name[tf_idx,2]
    legend_color <- c(rep("CTSR",length(tf_idx)-1),"insignificant")
    tf_rss <- tibble(index=seq(1:length(rank_list)),tf=total_motif_name[tf_idx,2],rss=rank_list,ctsr=rss_pvalue_list < 0.05, col=legend_color)
    #tf_rss <- tibble(index=seq(1:length(rank_list)),tf=total_motif_name[tf_idx,2],rss=rank_list,ctsr=rss_pvalue_list < 0.05)

    num_ctsr <- length(which(rss_pvalue_list < 0.05))
    total_tf_name_list <- append(total_tf_name_list,total_motif_name[tf_idx,2])
    rss_plot <- ggplot(tf_rss, aes(x=index, y=as.numeric(rss), label=ifelse(index<=num_ctsr,as.character(tf),''))) +
      geom_point(aes(color = col),fill="blue", show.legend = TRUE, size=3) +
      scale_color_manual(values=c('#2775b6','grey'))+
      geom_point(color=ifelse(tf_rss$index<=num_ctsr,"#2775b6",'grey'),size=3) + 
      scale_x_continuous("Regulon",breaks = scales::pretty_breaks(n = 4)) +
      geom_text_repel(point.padding = 0.2) +
      scale_y_continuous("Regulon specificity score",breaks = scales::pretty_breaks(n = 7)) +
      theme_linedraw() +
      theme(text = element_text(size=14), legend.position="bottom", legend.title = element_blank())
    
    png(paste("regulon_id/ct",i,"_rss_scatter.png",sep = ""),width=3500, height=2000,res = 300)
    print(rss_plot)
    quiet(dev.off())
  }
}


total_rank_list <- list()
total_gene_symbol_list <- list()
total_gene_id_list <- list()

for (i in 1:length(alldir)) {
  regulon_rank_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),"r")
  regulon_rank <- readLines(regulon_rank_handle)
  close(regulon_rank_handle)
  
  regulon_gene_symbol_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),"r")
  regulon_gene_symbol <- readLines(regulon_gene_symbol_handle)
  close(regulon_gene_symbol_handle)
  
  regulon_gene_id_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_id.txt",sep = ""),"r")
  regulon_gene_id <- readLines(regulon_gene_id_handle)
  close(regulon_gene_id_handle)
  
  gene_id_list <- lapply(strsplit(regulon_gene_id,"\\t"), function(x){x[-1]})
  gene_symbol_list <- lapply(strsplit(regulon_gene_symbol,"\\t"), function(x){x[-1]})
  rank_list <- lapply(strsplit(regulon_rank,"\\t"), function(x){x})
  
  total_rank_list <- append(total_rank_list,rank_list)
  total_gene_symbol_list <- append(total_gene_symbol_list,gene_symbol_list)
  total_gene_id_list <- append(total_gene_id_list,gene_id_list)
}

total_rank_list <- t(sapply(total_rank_list, function(x){
  if(as.numeric(x[4]) > 10){
    x[4] <- NA
  }
  return(x[1:6])
})
)

total_gene_symbol_list1 <- lapply(total_gene_symbol_list, function(x){
  paste(x,sep = ",")
})

combine_result <- data.frame(total_rank_list,total_tf_name_list)
combine_result[,8] <- sapply(total_gene_symbol_list, paste,collapse=",")
combine_result[,9] <- sapply(total_gene_id_list, paste,collapse=",")
combine_result <- combine_result[,c(1,7,6,5,8,9)]
colnames(combine_result) <- c("index","tf_name","rss","rss_pval","gene_symbol","gene_id")
write.table(combine_result,paste(jobid,"_combine_regulon.txt",sep = ""), sep="\t",row.names = F,col.names = T,quote = F)
