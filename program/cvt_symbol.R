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


#setwd("C:/Users/flyku/Desktop/CeRIS")
args <- commandArgs(TRUE)
wd <- args[1]
expFile <- args[2]
jobid <-args[3]
promoter_len <- args[4]
setwd(wd)
getwd()
# setwd("/home/www/html/CeRIS/data/2019030481235")
# setwd("d:/Users/flyku/Documents/CeRIS-data/test_id")
# jobid <-20190408222612
# wd <-  getwd()
# expFile <- "20190408222612_filtered_expression.txt"
# promoter_len <- '1000'
srcFile <- list.files(wd,pattern = "*_bic.txt")
expFile <- read.table(expFile,sep="\t",header = T,row.names = 1,check.names = F)
promoter_len <- as.numeric(promoter_len)

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
  res1 <- tryCatch(nrow(select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL"),keytype = "SYMBOL")),error = function(e) 0)
  res2 <- tryCatch(nrow(select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL"),keytype = "ENSEMBL")),error = function(e) 0)
  res3 <- tryCatch(nrow(select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL"),keytype = "ENTREZID")),error = function(e) 0)
  result <- c("error","SYMBOL","ENSEMBL","ENTREZID")
  result_vec <- c(1,res1,res2,res3)
  return(c(result[which.max(result_vec)],result_vec[which.max(result_vec)]))
  #write("No matched gene identifier found, please check your data.",file=paste(outFile,"_error.txt",sep=""),append=TRUE)
}

species_file <- as.character(read.table("species.txt",header = F,stringsAsFactors = F)[,1])

db <- c("Worm"=org.Ce.eg.db, "Fruit_fly"=org.Dm.eg.db, "Zebrafish"=org.Dr.eg.db,
        "Yeast"=org.Sc.sgd.db,"Mouse"=org.Mm.eg.db,"Human"=org.Hs.eg.db)
db_txdb <- c("Worm"=TxDb.Celegans.UCSC.ce11.refGene, "Fruit_fly"=TxDb.Dmelanogaster.UCSC.dm6.ensGene, "Zebrafish"=TxDb.Drerio.UCSC.danRer10.refGene,
             "Yeast"=TxDb.Scerevisiae.UCSC.sacCer3.sgdGene,"Mouse"=TxDb.Mmusculus.UCSC.mm10.knownGene,"Human"=TxDb.Hsapiens.UCSC.hg38.knownGene)
db_bsgenome <- c("Worm"=BSgenome.Celegans.UCSC.ce11, "Fruit_fly"=BSgenome.Dmelanogaster.UCSC.dm6, "Zebrafish"=BSgenome.Drerio.UCSC.danRer10,
        "Yeast"=BSgenome.Scerevisiae.UCSC.sacCer3,"Mouse"=BSgenome.Mmusculus.UCSC.mm10,"Human"=BSgenome.Hsapiens.UCSC.hg38)



select_db <- db[which(names(db)%in%species_file)]
gene_identifier <- sapply(select_db, get_rowname_type, l=rownames(expFile))
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

#filename <- as.data.frame(srcFile)[3,1]
generate_seq_file <- function(filename){
  print(filename)
  genes <- read.table(as.character(filename),header = T,sep = "\t");
  new_dir <- paste(wd,"/",gsub(".txt", "", filename,".txt"),sep="")
  dir.create(new_dir, showWarnings = FALSE)
  #i=1
  for (i in 1:ncol(genes)) {
    this_genes <- as.character(genes[,i])
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
      if(length(result)>3){
        writeXStringSet(result, paste(new_dir,"/","bic",i,".txt.fa",sep=""),format = "fasta",width=2000)
        #write.table(tmp, paste(new_dir,"/",colnames(tmp),".txt.fa",sep=""),sep="\t",quote = F ,col.names=FALSE,row.names=FALSE)
      }
    }
  }
}

gene_name <- rownames(expFile)
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

lapply(srcFile, generate_seq_file)


