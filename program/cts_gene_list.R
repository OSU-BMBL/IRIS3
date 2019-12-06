#Generate gene list by 
#1. raw expression file or jobid_filtered_expression.txt
#2. jobid_blocks.conds.txt
#3. jobid_blocks.gene.txt
#4. cell label
#output:
#1. jobid_gene_name.txt
#2. jobid_CT_ClusterIndex_bic.txt
library(tidyverse)
library(rlist)
#######  Convert gene name -> Ensembl gene id -> fasta file ##########
#######  Create a folder by filename, inside folder create each module by clusters  ##########

#if (!requireNamespace("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")
#BiocManager::install("GenomicAlignments", version = "3.8")
#BiocManager::install("ensembldb", version = "3.8")
#BiocManager::install("EnsDb.Hsapiens.v86", version = "3.8")
#BiocManager::install("EnsDb.Mmusculus.v79", version = "3.8")
library(GenomicAlignments)
library(ensembldb)
suppressPackageStartupMessages(library(BSgenome.Celegans.UCSC.ce11))
suppressPackageStartupMessages(library(BSgenome.Hsapiens.UCSC.hg38))
suppressPackageStartupMessages(library(BSgenome.Mmusculus.UCSC.mm10))
suppressPackageStartupMessages(library(BSgenome.Scerevisiae.UCSC.sacCer3))
suppressPackageStartupMessages(library(BSgenome.Drerio.UCSC.danRer10))
suppressPackageStartupMessages(library(BSgenome.Dmelanogaster.UCSC.dm6))
suppressPackageStartupMessages(library(TxDb.Celegans.UCSC.ce11.refGene))
suppressPackageStartupMessages(library(TxDb.Hsapiens.UCSC.hg38.knownGene))
suppressPackageStartupMessages(library(TxDb.Mmusculus.UCSC.mm10.knownGene))
suppressPackageStartupMessages(library(TxDb.Scerevisiae.UCSC.sacCer3.sgdGene))
suppressPackageStartupMessages(library(TxDb.Drerio.UCSC.danRer10.refGene))
suppressPackageStartupMessages(library(TxDb.Dmelanogaster.UCSC.dm6.ensGene))
suppressPackageStartupMessages(library(org.Dm.eg.db))
suppressPackageStartupMessages(library(org.Hs.eg.db))
suppressPackageStartupMessages(library(org.Mm.eg.db))
suppressPackageStartupMessages(library(org.Ce.eg.db))
suppressPackageStartupMessages(library(org.Sc.sgd.db))
suppressPackageStartupMessages(library(org.Dr.eg.db))


args <- commandArgs(TRUE)
wd <- args[1]
jobid <- args[2] # user job id
promoter_len <- args[3]
gene_module_file <- args[4] # 
delim_gene_module <- args[5] # gene module file delimter


promoter_len <- as.numeric(promoter_len)
if (!is.na(args[5])) {
if(delim_gene_module == 'tab'){
  delim_gene_module <- '\t'
}
if(delim_gene_module == 'space'){
  delim_gene_module <- ' '
}
}
setwd(wd)
getwd()
expFile <- paste(jobid,"_filtered_expression.txt",sep="")
label_file <- paste(jobid,"_cell_label.txt",sep = "")

# jobid <-20191107110621
# wd <- paste("/var/www/html/CeRIS/data/",jobid,sep="")
# gene_module_file <- 'Yan_2013_example_gene_module.csv'
# delim_gene_module <- 'tab'
# promoter_len <- 250
conds_file_handle <- file(paste(jobid,"_blocks.conds.txt",sep = ""),"r")
conds_file <- readLines(conds_file_handle)
close(conds_file_handle)
conds_file <- strsplit(conds_file," ")
conds_file <- lapply(conds_file, function(x) x[-1])

#gene_file <- read.delim(paste(jobid,"_blocks.gene.txt",sep = ""),sep=" ",header = F)[,-1]

gene_file_handle <- file(paste(jobid,"_blocks.gene.txt",sep = ""),"r")
gene_file <- readLines(gene_file_handle)
close(gene_file_handle)
gene_file <- strsplit(gene_file," ")
gene_file <- lapply(gene_file, function(x) x[-1])
len <- sapply(gene_file,length)

filter_bic_index <- sapply(gene_file, function(x){
  if (length(x) <= 500 & length(x) > 3){
    return (T)
  } else {
    return (F)
  }
})
gene_file <- gene_file[filter_bic_index]
conds_file <- conds_file[filter_bic_index]


cell_label <- read.table(label_file,sep="\t",header = T)
#exp_data <- read.table(expFile,sep="\t",header = T,row.names = 1,check.names = F)
#gene_name <- rownames(exp_data)
#write.table(gene_name,paste(jobid,"_gene_name.txt",sep = ""), sep="\t",row.names = F,col.names = F,quote = F)
gene_name <- as.character(read.table(paste(jobid,"_gene_name.txt",sep = ""),header = F,stringsAsFactors = F)[,1])

#conds_label <- conds_file%>%
#  t()%>%
#  as.tibble()%>%
#  gather(id,conds,V1:ncol(.))%>%
#  drop_na()%>%
#  mutate(id=as.numeric(str_extract(id,"[0-9]+")))%>%
#  select(conds,id)
  
colnames(cell_label) <- c("cell","label")
count_cluster <- length(levels(as.factor(cell_label$label)))

#test
#i=4
#df=conds_file[14]
get_pvalue <- function(df){
  count_cluster <- length(levels(as.factor(cell_label$label)))
  tmp_pvalue <- 0
  result_pvalue <- vector()
  result <- list()
  for (i in 1:count_cluster) {
    A <- as.character(unlist(cell_label[which(cell_label$label==i),1]))
    B <- df
    m=length(A)
    n=nrow(cell_label)-m
    x=length(A[(A%in%B)])
    k=length(B)-1
    tmp_pvalue <- 1 - phyper(x,m,n,k)
    result_pvalue[i] <- tmp_pvalue
    
  }
  ## use benjamini-Hochberg (B&H) correction?
  #t1 <- sgof::BH(result_pvalue)
  #result_pvalue <- t1$Adjusted.pvalues[order(match(t1$data,result_pvalue))]
  
  return (list(pvalue=result_pvalue,cell_type=seq(1:count_cluster)))
}

pv <- lapply(conds_file,get_pvalue)
get_pvalue_df <- function(lis,num){
  result <- lis$pvalue
  ct <- lis$cell_type
  for (i in ct) {
    if(i == num){
      return(result[i])
    }
  }
}

#test get_bic_in_ct function
#lis=pv[[28]]
#num=4
get_bic_in_ct <- function(lis,num){
  pval <- lis$pvalue
  result <- lis$cell_type
  for (i in result) {
    if(i == num && pval[i] <= pvalue_thres){
      return (pval[i])
    }
  }
}
total_bic <- length(conds_file)
#i=1;j=1


#####convert bicluster to fasta files

get_row_num <- function (this){
  num = 0
  for (i in 1:length(this)) {
    if(nchar(as.character(this[i]))>0){
      num = num +  1
    }
  }
  return (num)
}
get_rowname_type <- function (l, db){
  res1 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "SYMBOL")),error = function(e) 0)
  res2 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "ENSEMBL")),error = function(e) 0)
  res3 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "ENTREZID")),error = function(e) 0)
  res4 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "ENSEMBLTRANS")),error = function(e) 0)
  result <- c("error","SYMBOL","ENSEMBL","ENTREZID","ENSEMBLTRANS")
  result_vec <- c(1,res1,res2,res3,res4)
  return(c(result[which.max(result_vec)],result_vec[which.max(result_vec)]))
  #write("No matched gene identifier found, please check your data.",file=paste(jobid,"_error.txt",sep=""),append=TRUE)
}

species_file <- as.character(read.table("species.txt",header = F,stringsAsFactors = F)[,1])

db <- c("Worm"=org.Ce.eg.db, "Fruit_fly"=org.Dm.eg.db, "Zebrafish"=org.Dr.eg.db,
        "Yeast"=org.Sc.sgd.db,"Mouse"=org.Mm.eg.db,"Human"=org.Hs.eg.db)
db_txdb <- c("Worm"=TxDb.Celegans.UCSC.ce11.refGene, "Fruit_fly"=TxDb.Dmelanogaster.UCSC.dm6.ensGene, "Zebrafish"=TxDb.Drerio.UCSC.danRer10.refGene,
             "Yeast"=TxDb.Scerevisiae.UCSC.sacCer3.sgdGene,"Mouse"=TxDb.Mmusculus.UCSC.mm10.knownGene,"Human"=TxDb.Hsapiens.UCSC.hg38.knownGene)
db_bsgenome <- c("Worm"=BSgenome.Celegans.UCSC.ce11, "Fruit_fly"=BSgenome.Dmelanogaster.UCSC.dm6, "Zebrafish"=BSgenome.Drerio.UCSC.danRer10,
                 "Yeast"=BSgenome.Scerevisiae.UCSC.sacCer3,"Mouse"=BSgenome.Mmusculus.UCSC.mm10,"Human"=BSgenome.Hsapiens.UCSC.hg38)



select_db <- db[which(names(db)%in%species_file)]
gene_identifier <- sapply(select_db, get_rowname_type, l=gene_name)
main_species <- names(which.max(gene_identifier[2,]))
write(main_species,"species_main.txt")
main_db <- db[which(names(db)%in%main_species)][[1]]
main_txdb <- db_txdb[which(names(db)%in%main_species)][[1]]
main_txdb <-  keepStandardChromosomes(main_txdb)
main_bsgenome <- db_bsgenome[which(names(db)%in%main_species)][[1]]
main_identifier <- as.character(gene_identifier[1,which.max(gene_identifier[2,])])
main_grangelist <- transcriptsBy (main_txdb, by = "gene")

if(length(species_file) == 2) {
  second_species <- names(which.min(gene_identifier[2,]))
  second_db <- db[which(names(db)%in%second_species)][[1]]
  second_txdb <- db_txdb[which(names(db)%in%second_species)][[1]]
  second_txdb <-  keepStandardChromosomes(second_txdb)
  second_bsgenome <- db_bsgenome[which(names(db)%in%second_species)][[1]]
  second_identifier <- as.character(gene_identifier[1,which.min(gene_identifier[2,])])
  second_grangelist <- transcriptsBy (second_txdb, by = "gene")
}
#i=1


gene_df <- select(main_db, keys = gene_name, columns = c("ENSEMBL","SYMBOL"),keytype = "SYMBOL")
gene_df <- gene_df[!duplicated(gene_df[,1]),]
gene_df <- na.omit(gene_df)

if(length(species_file) == 2) {
  tryCatch(tmp <- select(second_db, keys = gene_name, columns = c("ENSEMBL","SYMBOL"),keytype = "SYMBOL")
           ,error = function(e) tmp <<- list())
  if (length(na.omit(tmp)) != 0) {
    tmp <- tmp[!duplicated(tmp[,1]),]
    tmp <- na.omit(tmp)
    gene_df <- rbind(gene_df,tmp)
  }
}
gene_df <- gene_df[,c(2,1)]
#colnames(gene_df) <- c('gene_id','gene_name')
if(length(which(gene_df[,2]=='')) > 0){
  gene_df <- gene_df[-which(gene_df[,2]==''),]
}

write.table(gene_df,paste(jobid,"_gene_id_name.txt",sep=""),sep = "\t",quote = F,col.names = T,row.names = F)


######## Generate cell type specific gene module and fasta sequences
for (j in 1:count_cluster) {
pvalue_thres <- 0.05
uniq_li <- sapply(pv, get_bic_in_ct,num=j)
#uniq_bic <- gene_file[which(uniq_li==1),]%>%
#  t%>%
#  as.vector()%>%
#  unique()%>%
#  write.table(.,paste(jobid,"_CT_",j,"_bic_unique.txt",sep = ""),sep="\t",row.names = F,col.names = F,quote = F)

names(uniq_li) <- seq_along(uniq_li) #preserve index of the non-null values
uniq_li <- compact(unlist(uniq_li))
while (is.null(uniq_li)) { # if result is null, increase pvalue to make at least have bicusters in cell type
  pvalue_thres <- pvalue_thres  + 0.01
  uniq_li <- sapply(pv, get_bic_in_ct,num=j)
  names(uniq_li) <- seq_along(uniq_li) #preserve index of the non-null values
  uniq_li <- compact(unlist(uniq_li))
}

#uniq_bic <- gene_file[names(uniq_li),]%>%
#  t%>%
#  as.vector()%>%
#  table()%>%
#  as.data.frame()%>%
#  write.table(.,paste(jobid,"_CT_",j,"_bic_unique.txt",sep = ""),sep="\t",row.names = F,col.names = F,quote = F)

#pvalue_df <- unlist(sapply(pv, get_pvalue_df,num=j))
#pvalue_thres <- as.numeric(quantile(pvalue_df[pvalue_df <1], 0.05)) # 0.05 for 5% quantile )

li <- sapply(pv, get_bic_in_ct,num=j)
names(li) <- seq_along(li) #preserve index of the non-null values
li <- compact(unlist(li))

gene_bic <- gene_file[as.numeric(names(li))]

#tmp_gene_bic <- c(rep(NA,100))
#test1 <- sapply(gene_bic, function(x){
#  tmp_gene_bic <- cbind(tmp_gene_bic,x)
#  return(tmp_gene_bic)
#})
#
#test2 <- data.frame(as.matrix(test1))
gene_bic <- lapply(gene_bic, function(x) {gsub("_.", "", x)})


if(length(gene_bic) > 0) {
  names(gene_bic) <- paste0("bic",names(li))
  #gene_name <- read.table(paste(jobid,"_gene_name.txt",sep = ""),header = F,stringsAsFactors = F)
  #get_gene_name_overlap <- function(df){
  #  match <- gene_name$V1 %in% nas.character(df)
  #  return (match)
  #}
  #gene_overlap <- gene_name
  #for (i in 1:ncol(gene_bic)) {
  #  tmp_match <- gene_name$V1%in%as.character(gene_bic[,i])
  #  gene_overlap[,i+1] <- ifelse(tmp_match,1,0)
  #}
  #ncol(gene_overlap)
  #colnames(gene_overlap) <- c("geneid",colnames(gene_bic))
  #gene_overlap[,"weight"] <- rowSums(as.data.frame(gene_overlap[,-1]))
  #total_bic <- total_bic + ncol(gene_bic) #total gene modules
  #write.table(gene_bic,paste(jobid,"_CT_",j,"_bic.txt",sep = ""),sep="\t",row.names = F,col.names = T,na = "",quote = F)
  #write.table(gene_overlap,paste("gene_overlap",j,".txt",sep = ""),row.names = F,col.names = T,quote = F)
}
new_dir <- paste(wd,"/",jobid,"_CT_",j,"_bic",sep="")
dir.create(new_dir, showWarnings = FALSE)

  for (k in 1:length(gene_bic)) {
    this_name <- names(gene_bic[k])
    this_bic_idx <- paste("bic",k,sep = "")
    this_genes <- gene_bic[[k]]
    this_genes <- this_genes[!this_genes==""]
    this_genes <- this_genes[!is.na(this_genes)]
    
    if(length(this_genes) > 0){
      all_match <- select(main_db, keys = this_genes, columns = c("SYMBOL","ENSEMBL","ENTREZID"),keytype = "SYMBOL")
      all_match <- all_match[!duplicated(all_match[,3]),]
      all_match <- na.omit(all_match)
      this_genes_id <- all_match[!duplicated(all_match[,3]),3]
      this_grangelist <-  main_grangelist[which(names(main_grangelist) %in% this_genes_id)]
      promoter_seqs <- getPromoterSeq(this_grangelist,main_bsgenome, upstream=promoter_len, downstream=0)
      result <-  DNAStringSet(sapply(promoter_seqs, `[[`, 1)) 
      names(result) <- all_match[match(names(result),all_match[,3]),2]
      if(length(species_file) == 2) {
        #this_genes <- c("TRP53","TNF",'TLR2',"TNIK","Rdh1")
        tryCatch(all_match <- select(second_db, keys = this_genes, columns = c("SYMBOL","ENSEMBL","ENTREZID"),keytype = "SYMBOL")
                 ,error = function(e) all_match <<- list())
        if (length(na.omit(all_match)) != 0) {
          all_match <- all_match[!duplicated(all_match[,3]),]
          all_match <- na.omit(all_match)
          if (nrow(all_match) > 0) {
            this_genes_id <- all_match[!duplicated(all_match[,3]),3]
            this_grangelist <-  second_grangelist[which(names(second_grangelist) %in% this_genes_id)]
            promoter_seqs <- getPromoterSeq(this_grangelist,second_bsgenome, upstream=promoter_len, downstream=0)
            tmp <-  DNAStringSet(sapply(promoter_seqs, `[[`, 1)) 
            names(tmp) <- all_match[match(names(tmp),all_match[,3]),2]
            result <- append(result,tmp)
          }
        }
      }
      if(length(result) < 350 & length(result) > 3){
        writeXStringSet(result, paste(new_dir,"/","bic",k,".txt.fa",sep=""),format = "fasta",width=promoter_len)
        #write.table(tmp, paste(new_dir,"/",colnames(tmp),".txt.fa",sep=""),sep="\t",quote = F ,col.names=FALSE,row.names=FALSE)
      }
    }
  }
}

write(paste("total_label,",nrow(cell_label),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("total_bic,",total_bic,sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)

##if exist gene module file, save gene list to jobid_module_#.txt
if(nchar(gene_module_file) > 1 && !is.na(gene_module_file)){
  gene_module <- read.delim(gene_module_file,header = F,sep = delim_gene_module)
  for (i in 1:ncol(gene_module)) {
    #write.table(gene_module[,i],paste(jobid,"_module_",i,"_bic.txt",sep = ""),quote = F,col.names = F,row.names = F)
    new_dir <- paste(wd,"/",jobid,"_module_",i,"_bic",sep="")
    dir.create(new_dir, showWarnings = FALSE)
    gene_bic <- list(gene_module[,i])
    for (k in 1:length(gene_bic)) {
      this_name <- paste("module",k,sep="")
      this_genes <- gene_bic[[k]]
      this_genes <- this_genes[!this_genes==""]
      this_genes <- this_genes[!is.na(this_genes)]
      
      if(length(this_genes) > 0){
        all_match <- select(main_db, keys = this_genes, columns = c("SYMBOL","ENSEMBL","ENTREZID"),keytype = "SYMBOL")
        all_match <- all_match[!duplicated(all_match[,3]),]
        all_match <- na.omit(all_match)
        this_genes_id <- all_match[!duplicated(all_match[,3]),3]
        this_grangelist <-  main_grangelist[which(names(main_grangelist) %in% this_genes_id)]
        promoter_seqs <- getPromoterSeq(this_grangelist,main_bsgenome, upstream=promoter_len, downstream=0)
        result <-  DNAStringSet(sapply(promoter_seqs, `[[`, 1)) 
        names(result) <- all_match[match(names(result),all_match[,3]),2]
        
        if(length(result) < 500 & length(result) > 3){
          writeXStringSet(result, paste(new_dir,"/","bic",k,".txt.fa",sep=""),format = "fasta",width=promoter_len)
          #write.table(tmp, paste(new_dir,"/",colnames(tmp),".txt.fa",sep=""),sep="\t",quote = F ,col.names=FALSE,row.names=FALSE)
        }
      }
    }
  }
}

