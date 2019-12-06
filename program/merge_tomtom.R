#######  Read [MotifNum,Genes], [TOMTOM all comparison result], convert to combined[Motif-Genes] ##########
# input: 
#1. Motif-Genes table from prepare_bbc.R
#2. TOMTOM motif cluster
#output: regulon
require(xml2)
require(XML)
library(seqinr)
args <- commandArgs(TRUE)
wd <- args[1]
jobid <- args[2]
motif_length <- args[3]
setwd(wd)
getwd()
#setwd("/var/www/html/CeRIS/data/20191107110621")
#wd <- getwd()
#jobid <-20191107110621 
#motif_length <- 12
sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
  
}

wd <- getwd()
alldir <- list.dirs(path = wd)
alldir <- grep("*_bic$",alldir,value=T)
alldir <- sort_dir(alldir)
short_dir <- grep("*_bic$",list.dirs(path = wd,full.names = F),value=T) 
short_dir<- sort_dir(short_dir)
gene_id_name <- read.table(paste(jobid,"_gene_id_name.txt",sep=""))
#i=7;j=1;k=m=3
#
total_ct <- max(na.omit(as.numeric(stringr::str_match(list.files(path = wd), "_CT_(.*?)_bic")[,2])))

module_type <- sub(paste(".*",jobid,"_ *(.*?) *_.*",sep=""), "\\1", short_dir)

#xml_text(motif_name)
#i=260
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
total_motif_list <- vector()
regulon_idx_module <- 0
count_num_regulon<-0
for (i in 1:length(alldir)) {
  res_id <- paste(short_dir[i],".regulon_gene_id.txt",sep="")
  res_symbol<- paste(short_dir[i],".regulon_gene_symbol.txt",sep="")
  res_motif<- paste(short_dir[i],".regulon_motif.txt",sep="")
  file.create(res_motif,showWarnings = F)
  cat("",file=res_id)
  this_ct <- i
  
  #cluster_filename <- paste("./bg.BBC/bg.",short_dir[i],".bbc.txt.MC",sep="")
  motif_filename <- paste(short_dir[i],".motifgene.txt",sep="")
  sequence_filename <- paste(short_dir[i],".bbc.txt",sep="")
  
  mtry <- try(read.table(motif_filename, sep = ",", header = TRUE), silent = TRUE)
  if (class(mtry) != "try-error") {
    motif_file <- read.table(motif_filename,sep = "\t",header = T)
    #cluster_file <- read.table(cluster_filename,sep = "\t",header = T)
    sequence_file <- read.fasta(sequence_filename,as.string = T)
    cat("",file=res_symbol)
    cat("",file=res_motif)
    regulon_idx <- 1
    if(module_type[i] == "module"){
      regulon_idx_module <- regulon_idx_module + 1
    }
    #j=25
    for (j in 1:length(total_tf_list)) {
      this_tf_name <- total_tf_list[[j]][1]
      motif_num <- as.character(total_tf_list[[j]][-1])
      if(module_type[i] == "module"){
        motif_num <- motif_num[grep("module",motif_num)]
      }
      motif_num <- strsplit(gsub("[^0-9.-]+", " ", as.character(motif_num))," ")
      motif_num <- lapply(motif_num,function(x){
        tmp <- x[-1]
        if (tmp[1] == i){
          result <- paste("bic",tmp[2],".txt.fa.closures-",tmp[3],sep = "")
          return(result)
        } else if(module_type[i] == "module" && tmp[1] == i-total_ct){
          result <- paste("bic",tmp[2],".txt.fa.closures-",tmp[3],sep = "")
          return(result)
        } else {
          return(NA)
        }
      })
      motif_num <- lapply(motif_num, function(x) x[!is.na(x)])
      #sequence_out_name <- paste("ct",i,"motif",j,".fa",sep = "")
      sequence_info <- character()
      genes_num <- vector()
      if(length(motif_num) == 0 ){
        motif_num <- list(NA)
      }
      idx <- 1
      #k= 1
      for (k in 1:length(motif_num)) {
        genes_num <- c(genes_num,which(as.character(motif_file[,1]) == motif_num[[k]]))
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
      total_motif_list <- append(total_motif_list,this_motif_label)
      genes <- as.character(genes[!duplicated(genes)])
      if(length(genes) > 10000000 | length(genes) < 5) {
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

tmp_list <- strsplit(unique(total_motif_list),",")
tmp_list <- unlist(sapply(tmp_list, function(x){
  if(length(x) > 2) {
    paste("ct",x[1],"bic",x[2],"m",x[3],sep = "")
  }
}))
remove_motifs <- paste("tomtom/",list.files("tomtom")[!list.files("tomtom") %in% tmp_list],sep = "")
remove_motifs <- remove_motifs[-grep("module",remove_motifs)]
unlink(remove_motifs, recursive = TRUE)

## remove unused motifs

