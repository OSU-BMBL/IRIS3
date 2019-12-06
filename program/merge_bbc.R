#######  Read [MotifNum,Genes], [Motif-Motif Similarity], convert to combined[Motif-Genes] ##########
# input: 
#1. Motif-Genes table from prepare_bbc.R
#2. BBC motif cluster
#output: regulon
library(seqinr)
args <- commandArgs(TRUE)
srcDir <- args[1]
jobid <- args[2]
motif_length <- args[3]
setwd(srcDir)
getwd()
#setwd("/home/www/html/CeRIS/data/2019030481235")
#setwd("D:/Users/flyku/Documents/CeRIS-data/new_example")
#srcDir <- getwd()
#jobid <-20190326211512 
#motif_length <- 12
sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
  
}
workdir <- getwd()
alldir <- list.dirs(path = workdir)
alldir <- grep("*_bic$",alldir,value=T)
alldir <- sort_dir(alldir)
short_dir <- grep("*_bic$",list.dirs(path = workdir,full.names = F),value=T) 
short_dir<- sort_dir(short_dir)
gene_id_name <- read.table(paste(jobid,"_gene_id_name.txt",sep=""))
#i=7;j=1;k=m=3
#

module_type <- sub(paste(".*",jobid,"_ *(.*?) *_.*",sep=""), "\\1", short_dir)
count_num_regulon<-0
regulon_idx_module <- 0
for (i in 1:length(alldir)) {
  res_id <- paste(short_dir[i],".regulon_gene_id.txt",sep="")
  res_symbol<- paste(short_dir[i],".regulon_gene_symbol.txt",sep="")
  res_motif<- paste(short_dir[i],".regulon_motif.txt",sep="")
  file.create(res_motif,showWarnings = F)
  cat("",file=res_id)
  this_ct <- i
  
  cluster_filename <- paste("./bg.BBC/bg.",short_dir[i],".bbc.txt.MC",sep="")
  motif_filename <- paste(short_dir[i],".motifgene.txt",sep="")
  sequence_filename <- paste(short_dir[i],".bbc.txt",sep="")
  
  mtry <- try(read.table(motif_filename, sep = ",", header = TRUE), silent = TRUE)
  if (class(mtry) != "try-error") {
    motif_file <- read.table(motif_filename,sep = "\t",header = T)
    cluster_file <- read.table(cluster_filename,sep = "\t",header = T)
    sequence_file <- read.fasta(sequence_filename,as.string = T)
    cat("",file=res_symbol)
    cat("",file=res_motif)
    regulon_idx <- 1
    if(module_type[i] == "module"){
      regulon_idx_module <- regulon_idx_module + 1
    }
    for (j in 1:max(cluster_file[,3])) {
      motif_num <- as.character(cluster_file[which(cluster_file[,3] == j),1])
      #sequence_out_name <- paste("ct",i,"motif",j,".fa",sep = "")
      sequence_info <- character()
      genes_num <- vector()
      idx <- 1
      #k= 'bic1.txt.fa.closures-1'
      for (k in motif_num) {
        genes_num <- c(genes_num,which(as.character(motif_file[,1]) == k))
        sequence_info_tmp <-as.character(sequence_file[names(sequence_file) %in% motif_num][idx])
        idx <- idx + 1
        sequence_info_tmp <- gsub(paste('(?=(?:.{',motif_length,'})+$)',sep=""), "\n", sequence_info_tmp, perl = TRUE)
        
        sequence_info <- paste(sequence_info,sequence_info_tmp,sep = "")
      }
      #write.table(sequence_info,sequence_out_name,col.names = F,row.names = F,quote = F)
      
      genes <- motif_file[genes_num,2]
      this_motifs <- motif_file[genes_num,1]
      #this_motifs <- as.character(this_motifs[!duplicated(this_motifs)])
      this_bic <- gsub("bic","",this_motifs)
      this_bic <- gsub(".txt.fa.*","",this_bic)
      this_id <- gsub(".*closures-","",this_motifs)
      this_motif_label <- paste(this_ct,this_bic,this_id,sep = ",")
      if(module_type[i] == "module"){
        this_motif_label <- paste(regulon_idx_module,this_bic,this_id,sep = ",")
      }
      this_motif_label <- unique(this_motif_label)
      genes <- as.character(genes[!duplicated(genes)])
      if(length(genes) > 100 | length(genes) < 5) {
        next
      }
      if(module_type[i] == "CT"){
        regulon_idx_label <- paste("CT",i,"S-R",regulon_idx,sep = "")
      }else{
        regulon_idx_label <- paste("module",regulon_idx_module,"-R",regulon_idx,sep = "")
      }
      
      cat(paste(regulon_idx_label,"\t",sep = ""),file=res_motif,append = T)
      this_combine_motif_label  <- paste(this_motif_label,"\t",sep = "")
      if (length(this_combine_motif_label) > 1) {
        this_last_label <- gsub("\t","",this_combine_motif_label[length(this_combine_motif_label)])
        cat(this_combine_motif_label[-length(this_combine_motif_label)],file=res_motif,sep = "",append = T)
        cat(this_last_label,file=res_motif,sep = "\t",append = T)
        
      } else{
        this_last_label <- gsub("\t","",this_combine_motif_label[length(this_combine_motif_label)])
        cat(this_last_label,file=res_motif,sep = "\t",append = T)
      }
      
      cat("\n",file=res_motif,append = T)
      
      cat(paste(regulon_idx_label,"\t",sep = ""),file=res_symbol,append = T)
      cat(as.character(gene_id_name[which(gene_id_name[,1] %in% genes),2]),file=res_symbol,sep = "\t",append = T)
      cat("\n",file=res_symbol,append = T)
      
      cat(paste(regulon_idx_label,"\t",sep = ""),file=res_id,append = T)
      cat(as.character(gene_id_name[which(gene_id_name[,1] %in% genes),1]),file=res_id,sep = "\t",append = T)
      cat("\n",file=res_id,append = T)
      
      regulon_idx <- regulon_idx + 1
    }
  } else {
    cat("",file=res_symbol)
  }
  count_num_regulon <- count_num_regulon + regulon_idx 
}
count_num_regulon <- count_num_regulon - length(alldir)
write(paste("total_ct,",as.character(length(alldir)),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("total_regulon,",as.character(count_num_regulon),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)

#regulon_file <- list.files(srcDir,pattern = "*.regulon_gene_id.txt")
#i = regulon_file[1]
#for ( i in regulon_file){
#  read.table(i)
#  
#}
#regulon_all_files <- list.files(path = workdir,pattern = "*bic.regulon.txt")
## get complex regulon from all regulons
#combined_regulon <- data.frame()
#i=2
#j=1
#max_column <- 0
#for (i in 1:length(regulon_all_files)) {
#  res_id <- paste(short_dir[i],".regulon.gene.txt",sep="")
#  res_final <- paste(short_dir[i],".complex.regulon.txt",sep="")
#  cat("",file=res_id)
#  regulo <- readLines(regulon_all_files[i])
#  combined_regulon <- read.table(text = regulo,sep = "\t",fill = T)
#  all_genes <- as.character(unlist(combined_regulon[,-1]))
#  all_genes <- all_genes[!duplicated(all_genes)]
#  all_genes <- all_genes[all_genes!=""]
#  for (j in 1:length(all_genes)) {
#    belong_regulon <- sort(which(combined_regulon[,-1]==all_genes[j],arr.ind = TRUE)[,1])
#    if(length(belong_regulon) > max_column){
#      max_column <- length(belong_regulon)
#    }
#    tmp <- data.frame(all_genes[j],t(as.data.frame(belong_regulon)))
#    cat(paste(all_genes[j],"\t",sep = ""),file=res_id,append = T)
#    cat(belong_regulon,file=res_id,append = T,sep = "\t")
#    cat("\n",file=res_id,append = T)
#  }
#  idx<-vector()
#  tmp_final <- data.frame()
#  sorted_res <- read.table(res_id,col.names = paste0("V",seq_len(max_column+1)),header = F,fill = T,comment.char = "")
#  tmp_res <- tmp_idx<- character()
#  index <- unique(sorted_res[,-1])
#  for (j in 1:nrow(sorted_res)) {
#    tmp <- paste(sorted_res[j,-1],sep = ",",collapse = ",")
#    tmp_res <- c(tmp_res,tmp)
#  }
#  cat("",file=res_final)
#  for (j in 1:nrow(index)) {
#    tmp <- paste(index[j,],sep = ",",collapse = ",")
#    tmp_idx <- as.character(index[j,])
#    tmp_idx <- tmp_idx[!(tmp_idx=="NA")]
#    if(length(tmp_idx) !=0){
#      tmp_gene <- as.character(sorted_res[which(tmp==tmp_res),1])
#      cat(tmp_gene,file=res_final,append = T,sep = "\t")
#      cat("\t",file=res_final,append = T)
#      cat(tmp_idx,file=res_final,append = T,sep = "\t")
#      cat("\n",file=res_final,append = T)
#    }
#  }
#}
