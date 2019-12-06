library(seqinr)
library(tidyverse)
args <- commandArgs(TRUE)
#setwd("d:/Users/flyku/Documents/CeRIS-data/test_meme")
#srcDir <- getwd()
#jobid <-20190731144519 
#motif_len <- 12
srcDir <- args[1]
motif_len <- args[2]
setwd(srcDir)
getwd()
workdir <- getwd()
alldir <- list.dirs(path = workdir)
alldir <- grep(".+_bic$",alldir,value=T)

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
#filepath <- all_closure[22]
# i <- 1
convert_meme <- function(filepath){
  this_line <- matrix(0,ncol = 6)
  this_line <- data.frame(this_line)
  motif_result <- tibble()
  line<-0
  motif_file <- file(filepath,"r")
  line = readLines(motif_file)
  close(motif_file)
  if (nchar(line[1]) != 57 & !is.na(line[1])) {
    df <- line[substr(line,0,3) == "ENS"|substr(line,0,3) == "ens"]
    for (i in 1:length(df)) {
      this_line <- strsplit(df[i],"\\s+")[[1]]
      if(length(grep("[ATCG]",this_line[5])) == 1 | grepl("^\\.", this_line[5])){
        tmp_bind <- t(data.frame(this_line))
        if(ncol(tmp_bind) < 7) {
          if (nchar(as.character(tmp_bind[6])) < motif_len){
            tmp_bind <- cbind(tmp_bind,"A")
            tmp <- tmp_bind[5]
            tmp_bind[5] <- tmp_bind[6]
            tmp_bind[6] <- tmp
          } else {
            tmp_bind <- cbind(tmp_bind,"A")
          }
        }
        motif_result <- rbind(motif_result,tmp_bind)
      }
    }
    
    df_info = line[substr(line,0,5) == "MOTIF"]
    all_motif_index <- 1
    #filepath=paste(filepath,".test",sep = "")
    cat("", file=filepath)
    #i=j=1
    for (i in 1:length(df_info)) {
      this_info <- strsplit(df_info[i],"\\s+")[[1]]
      this_consensus <- this_info[2]
      this_index <- i
      this_motif_length <- this_info[6]
      this_num_sites <- as.numeric(this_info[9])
      this_pval <- this_info[15]
      this_pval <- as.numeric(this_pval)
      motif_idx_range <- seq(all_motif_index,all_motif_index + this_num_sites - 1)
      all_motif_index <- all_motif_index + this_num_sites
      this_motif_align <- motif_result[motif_idx_range,]
      this_motif_name <- paste(">Motif-",i,sep = "")
      this_motif_align <- cbind(this_motif_align,this_motif_name)
      this_motif_align[,5] <- as.numeric(as.character(this_motif_align[,3])) + as.numeric(this_motif_length) - 1
      this_seq_idx <- seq(1:this_num_sites)
      this_motif_align[,7] <- this_seq_idx
      colnames(this_motif_align) <- (c("V1","V2","V3","V4","V5","V6","V7","V8"))
      this_motif_align <- this_motif_align[,c(8,7,3,5,6,4,1)]
      this_motif_align[, ] <- lapply(this_motif_align[, ], as.character)
      cat("*********************************************************\n", file=filepath,append = T)
      cat(paste(" Candidate Motif   ",this_index,sep=""), file=filepath,append = T)
      cat("\n*********************************************************\n\n", file=filepath,append = T)
      cat(paste(" Motif length: ",this_motif_length,"\n Motif number: ",this_num_sites,
                "\n Motif Pvalue: ",this_pval," (",-1*(100*log10(this_pval)),")\n Seed Zscore: ",-1*(100*log10(this_pval)),"\n",sep=""), file=filepath,append = T)
      cat(paste("\n------------------- Consensus sequences------------------\n",this_consensus,"\n\n",sep=""), file=filepath,append = T)
      cat("------------------- Aligned Motif ------------------\n#Motif	Seq	start	end	Motif		Score	Info\n", file=filepath,append = T)
      for (j in 1:nrow(this_motif_align)) {
        cat( as.character(this_motif_align[j, ]), file=filepath,append = T,sep = "\t")
        cat("\n", file=filepath,append = T)
      }
      cat("----------------------------------------------------\n\n", file=filepath,append = T)
    }
  }
}


module_type <- sub(paste(".*_ *(.*?) *_.*",sep=""), "\\1", alldir)
#module_type <- rep("CT",6)
regulon_idx_module <- 0
result_gene_pos <- data.frame()
#i=j=1
#
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
        convert_meme(all_closure[j])
    }
  } else {
    cat("", file= paste(alldir[i],".bbc.txt",sep=""),sep="\n",append = T)
  }
}

