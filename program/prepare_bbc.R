#######  Read all motif result, convert to input for BBC ##########
# remove all empty files before this
library(stringi)
library(seqinr)
library(tidyverse)
args <- commandArgs(TRUE)
#setwd("/var/www/html/CeRIS/data/20191020160119")
#wd <- getwd()
#jobid <-20191020160119 
#motif_len <- 12
jobid <- args[1]
motif_len <- args[2]

wd <- paste("/var/www/html/CeRIS/data/",jobid,"/",sep="")
setwd(wd)
getwd()
workdir <- getwd()
alldir <- list.dirs(path = workdir)
alldir <- grep(".+_bic$",alldir,value=T)
#gene_info <- read.table("file:///D:/Users/flyku/Documents/CeRIS_data_backup/dminda/human_gene_start_info.txt")
species_id <-  as.character(read.table("species_main.txt")[1,1])
if(species_id == "Human"){
  gene_info <- read.table("/var/www/html/CeRIS/program/db/human_gene_start_info.txt")
} else if (species_id == "Mouse"){
  gene_info <- read.table("/var/www/html/CeRIS/program/db/mouse_gene_start_info.txt")
}

sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
}

sort_closure <- function(dir){
  tmp <- sort(dir)
  split <- strsplit(tmp, "/bic") 
  split <- as.numeric(sapply(split, function(x) x <- sub("\\D+", "", x[2])))
  return(tmp[order(split)])
}

sort_short_closure <- function(dir){
  tmp <- sort(dir)
  split <- strsplit(tmp, "bic") 
  split <- as.numeric(sapply(split, function(x) x <- sub("\\D+", "", x[2])))
  return(tmp[order(split)])
}

alldir <- sort_dir(alldir)
#convert_motif(all_closure[6])
#filepath<-all_closure[j]
convert_motif <- function(filepath){
  this_line <- data.frame()
  motif_file <- file(filepath,"r")
  line <- readLines(motif_file)
  # get pvalue and zscore and store it in motif_rank
  split_line <- unlist(strsplit(line," "))
  pval_value <- split_line[which(split_line == "Pvalue:")+2]
  pval_original <- split_line[which(split_line == "Pvalue:")+1]
  zscore_value <- split_line[which(split_line == "Zscore:")+1]
  if(length(pval_value)>0){
    pval_value <- as.numeric(gsub("\\((.+)\\)","\\1",pval_value))
    pval_name <- paste(">",basename(filepath),"-",seq(1:length(pval_value)),sep="")
    tmp_pval_df <- data.frame(pval_name,pval_value,zscore_value,pval_original)
    #motif_rank <- data.frame()
    motif_rank <<-rbind(motif_rank,tmp_pval_df)
    df <- line[substr(line,0,1) == ">"]
    df <- read.table(text=df,sep = "\t")
    colnames(df) <- c("MotifNum","Seq","start","end","Motif","Score","Info")
  } else {
    return (0)
  }
  close(motif_file)
  return(df)
}

#i=3
#j=31
#info = "bic1.txt.fa.closures-1"  
module_type <- sub(paste(".*_ *(.*?) *_.*",sep=""), "\\1", alldir)
#module_type <- rep("CT",6)
regulon_idx_module <- 0
result_gene_pos <- data.frame()
for (i in 1:length(alldir)) {
  combined_seq <- data.frame()
  combined_gene <- data.frame()
  motif_rank <- data.frame()
  all_closure <- list.files(alldir[i],pattern = "*.closures$",full.names = T)
  short_all_closure <- list.files(alldir[i],pattern = "*.closures$",full.names = F)
  all_closure <- sort_closure(all_closure)
  short_all_closure <- sort_short_closure(short_all_closure)
  if(length(all_closure) > 0){
    for (j in 1:length(all_closure)) {
      matches <- regmatches(short_all_closure[j], gregexpr("[[:digit:]]+", short_all_closure[j]))
      bic_idx <- as.numeric(unlist(matches))
      #test
      #motif_seq <- convert_motif(paste(all_closure[j],".test",sep = ""))[,c(1,5,7)]
      convert_result <- convert_motif(all_closure[j])
      if (any(convert_result != 0)) {
        motif_seq <- convert_result[,c(1,5,7)]
        motif_pos <- convert_result[,c(1,2,3,4,7)]
        gene_pos <- merge(motif_pos,gene_info,by.x = "Info",by.y = 'V2')
        gene_pos <-transform(gene_pos, min = pmin(start, end), max=pmax(start,end))
        if (nrow(gene_pos) > 1) {
          gene_pos[,4] <-  gene_pos[,7] + gene_pos[,8]
          gene_pos[,5] <-  gene_pos[,7] + gene_pos[,9]
          gene_pos[,10] <- module_type[i]
          gene_pos[,11] <- paste(i,bic_idx,sub(">Motif-","",gene_pos[,2]),sep = ",")
          if(module_type[i] == "module"){
            regulon_idx_module <- regulon_idx_module + 1
            gene_pos[,11] <- paste(regulon_idx_module,bic_idx,sub(">Motif-","",gene_pos[,2]),sep = ",")
          }
          #write.table(gene_pos[,c(6,4,5,1)],paste(alldir[i],"/bic",j,".bed",sep=""),sep = "\t" ,quote=F,row.names = F,col.names = F)
          result_gene_pos <- rbind(result_gene_pos,gene_pos[,c(6,4,5,1,10,11)])
          motif_seq[,1] <- gsub(">Motif","",motif_seq[,1])
          motif_seq[,4] <- as.factor(paste(short_all_closure[j],motif_seq[,1],sep=""))
          seq_file <- motif_seq[,c(4,3)]
          motif_seq <- motif_seq[,c(4,2)]
          colnames(motif_seq) <- c("info","seq")
          colnames(seq_file) <- c("info","genes")
          combined_seq <- rbind(combined_seq,motif_seq)
          combined_gene <- rbind(combined_gene,seq_file)
        }
      }
    }
    res <- paste(alldir[i],".bbc.txt",sep="")
    #res <- file("filename", "w")
    cat("", file=res)
    for (info in levels(combined_seq[,1])) {
      cat(paste(">",as.character(info),sep=""), file=res,sep="\n",append = T)
      if (length(as.character(combined_seq[which(combined_seq[,1]== info),2])) >= 100) {
        sequence <- as.character(combined_seq[which(combined_seq[,1]== info),2])[1:99]
      } else {
        sequence <- as.character(combined_seq[which(combined_seq[,1]== info),2])
      }
      cat(sequence, file=res,sep="\n",append = T)
    }
  } else {
    cat("", file= paste(alldir[i],".bbc.txt",sep=""),sep="\n",append = T)
  }
  write.table(combined_gene,paste(alldir[i],".motifgene.txt",sep=""),sep = "\t" ,quote=F,row.names = F,col.names = T)
  
  motif_rank <- motif_rank[!duplicated(motif_rank$pval_name),]
  #motif_rank_bc <- motif_rank
  #motif_rank<-motif_rank_bc
  #test_motif_rank <- motif_rank[!duplicated(motif_rank$pval_name),] 
  if(nrow(motif_rank) > 0){
    motif_rank[,5] <- seq(1:nrow(motif_rank))
    motif_rank <- motif_rank[order(as.numeric(as.character(motif_rank$zscore_value)),motif_rank$pval_value,decreasing = T),] 
    pval_idx <- motif_rank[,5]
    #write.table(motif_rank,paste(alldir[i],".pval.txt",sep=""),sep = "\t" ,quote=F,row.names = F,col.names = F)
    this_fasta <- read.fasta(paste(alldir[i],".bbc.txt",sep=""))
    this_fasta <- this_fasta[pval_idx]
    write.fasta(this_fasta,names(this_fasta),paste(alldir[i],".bbc.txt",sep=""),nbchar = 12)
  }
  cat(">end", file=paste(alldir[i],".bbc.txt",sep=""),sep="\n",append = T)
  
  
  this_bic <- gsub(">bic","",motif_rank[,1])
  this_bic <- gsub(".txt.fa.*","",this_bic)
  this_id <- gsub(".*closures-","",motif_rank[,1])
  motif_rank[,6] <- paste(i,this_bic,this_id,sep=",")
  write.table(motif_rank[,c(6,4,2,3)],paste(alldir[i],".motif_rank.txt",sep=""),sep = "\t" ,quote=F,row.names = F,col.names = F)
}

gene_id_name <- read.table(paste(jobid,"_gene_id_name.txt",sep=""),sep = "\t", header = T)

result_gene_pos <- merge(result_gene_pos,gene_id_name,by.x="Info",by.y="ENSEMBL")
result_gene_pos <- result_gene_pos[order(result_gene_pos$V11),]
result_gene_pos <- result_gene_pos[,c(2,3,4,7,5,6)]
write.table(result_gene_pos,paste("motif_position.bed",sep=""),sep = "\t" ,quote=F,row.names = F,col.names = F)


