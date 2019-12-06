
########## Get alternative regulon heatmap txt ##################


library(scales)
library(sgof)
library(ggplot2)
library(dabestr)
require(xml2)
require(XML)
library(seqinr)
library(doParallel)
registerDoParallel(16) 
args <- commandArgs(TRUE)
#wd <- args[1] # filtered expression file name
jobid <- args[1] # user job id
#wd<-getwd()
####test
#jobid <- 20191018130101   
label_use_sc3 <- 0

dir.create("heatmap",showWarnings = F)

wd <- paste("/var/www/html/CeRIS/data/",jobid,sep="")
#wd <- paste("C:/Users/wan268/Documents/CeRIS_data/",jobid,sep="")
expFile <- paste(jobid,"_filtered_expression.txt",sep="")
labelFile <- paste(jobid,"_cell_label.txt",sep = "")
# wd <- getwd()
setwd(wd)

species_file <- as.character(read.table("species.txt",header = F,stringsAsFactors = F)[,1])


total_ct_number <- max(na.omit(as.numeric(stringr::str_match(list.files(path = wd), "_CT_(.*?)_bic")[,2])))
exp_data<- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
#exp_data<- as.data.frame(my.count.data)
#exp_data<- read.delim(paste(jobid,"_raw_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)

exp_data <- as.matrix(exp_data)


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

total_motif_list <- vector()
total_gene_list <- vector()
total_rank <- vector()
total_gene_index <- 1

for (i in 1:total_ct_number) {
  regulon_gene_name_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),"r")
  regulon_gene_name <- readLines(regulon_gene_name_handle)
  close(regulon_gene_name_handle)
  
  regulon_rank_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),"r")
  regulon_rank <- readLines(regulon_rank_handle)
  close(regulon_rank_handle)
  
  regulon_motif_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),"r")
  regulon_motif <- readLines(regulon_motif_handle)
  close(regulon_motif_handle)
  
  total_gene_list <- append(total_gene_list,regulon_gene_name)
  total_motif_list <- append(total_motif_list,regulon_motif)
  total_rank <- append(total_rank,regulon_rank)
}

#t1 <- "CT4S-R122"
#length(grep("CT3.*?",t1))
#length(grep("CT4.*?",t1))
total_gene_list<- lapply(strsplit(total_gene_list,"\\t"), function(x){x[-1]})
total_motif_list<- lapply(strsplit(total_motif_list,"\\t"), function(x){x[-1]})
total_rank<- strsplit(total_rank,"\\t")
total_rank_df <- vector()

for (i in 1:length(total_rank)) {
  this_ct <- strsplit(strsplit(total_rank[[i]][1],"CT")[[1]][2],"S")[[1]][1]
  total_rank_df <- rbind(total_rank_df,c(total_rank[[i]][c(1,5,6)],this_ct))
  colnames(total_rank_df) <- c("regulon_id","rss_pval","rss","cell_type")
}


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
count_num_regulon<-0
regulon_idx_module <- 0
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

regulon_tf_name <- lapply(total_motif_list, function (x){
  motif <- x[1]
  str <- strsplit(motif,",")[[1]]
  t1 <- paste("ct",str[1],"bic",str[2],"m",str[3],sep="")
  t2 <- lapply(total_tf_list, match,t1)
  t2 <- which(lapply(t2, function(x) x[!is.na(x)]) == 1)
  return(total_tf_list[[t2]][1])
})

tf_name_regulon <- data.frame(tf=unlist(regulon_tf_name),idx=seq(1:length(regulon_tf_name)))
tf_name_regulon <- cbind(tf_name_regulon,total_rank_df)
#tf_name_regulon <- tf_name_regulon[,-2]

ct_seq=seq(1:total_ct)
select_idx <- paste("CT",ct_seq,"S-R",sep="")
select_idx_result<-vector()
#x=total_rank[[1]]
for (i in ct_seq) {
  num_regulons_in_this_ct <- length(which(unlist(lapply(total_rank,function(x){
    return(any(grepl(select_idx[i],x)))
  }))))
  if (num_regulons_in_this_ct > 0) {
    tmp <- paste(select_idx[i],seq(1:num_regulons_in_this_ct),sep="")
  }
  select_idx_result <- c(select_idx_result,tmp)
}

## run atac
species_file 
#foreach (i=1:length(select_idx_result)) %dopar% {system(paste("/var/www/html/CeRIS/program/count_peak_overlap_single_file.sh", getwd(),select_idx_result[i],species_file ,sep = " "))}

alternative_regulon_result <- vector()
for (i in 1:length(select_idx_result)) {
  tf_idx <- which(tf_name_regulon$regulon_id == select_idx_result[i])
  this_tf <- as.character(tf_name_regulon$tf[tf_idx])
  all_tf_idx <- which(tf_name_regulon$tf == this_tf)
  all_alternative_regulon <- tf_name_regulon[all_tf_idx,]
  for (j in 1:length(all_tf_idx)) {
    all_alternative_regulon[j,7] <- length(total_gene_list[[all_tf_idx[j]]])
    all_alternative_regulon[j,8] <- as.list(paste(total_gene_list[[all_tf_idx[j]]],",",collapse = "",sep = ""))
  }
  tmp_df <- data.frame(tf=rep(this_tf,total_ct),cell_type=seq(1:total_ct))
  tmp_result <- merge(tmp_df,all_alternative_regulon,by.x=2,by.y=6,all=T)
  alternative_regulon_result <- rbind(alternative_regulon_result,tmp_result)
}
alternative_regulon_result <- alternative_regulon_result[c(-3,-4)]
names(alternative_regulon_result)[6] <- "num_genes"
names(alternative_regulon_result)[7] <- "genes"
names(alternative_regulon_result)[2] <- "tf"
alternative_regulon_result <- alternative_regulon_result[!duplicated(alternative_regulon_result), ]

top_n_idx <- function(x, n=10) {
  nx <- length(x)
  p <- nx-n
  xp <- sort(x, partial=p)[p]
  rev(which(x > xp)[order(x[which(x > xp)])])
  
}

##atac_result <- vector()
##for (i in 1:length(select_idx_result)) {
##  this_regulon <- select_idx_result[i]
##  fn <- paste("atac/",select_idx_result[i],".atac_overlap_result.txt",sep = "")
##  fn_handle <- file(fn,"r")
##  fn_data <- readLines(fn_handle)
##  close(fn_handle)
##  fn_data <- strsplit(fn_data,"\\t")
##  #x=fn_data[[1]]
##  rank_value <- as.numeric(unlist(lapply(fn_data, function(x){
##    return(length(strsplit(x[8]," ")[[1]]))
##  })))
##  this_atac_result <- vector()
##  top_idx <- top_n_idx(rank_value)
##  if (length(top_idx) > 0){
##    for (j in 1:length(top_idx)) {
##      this_data <- fn_data[[top_idx[j]]]
##      tmp_result <- c(this_data[1],length(strsplit(this_data[8]," ")[[1]]))
##      this_atac_result <- rbind(this_atac_result,tmp_result)
##    }
##    this_tissue <- as.character(paste(this_atac_result[,1],sep = "",collapse = ","))
##    this_num_overlap_genes <- as.character(paste(this_atac_result[,2],sep = "",collapse = ","))
##    tmp_df <- data.frame(regulon_id=this_regulon,atac_tissue=this_tissue,num_overlap_genes=this_num_overlap_genes,stringsAsFactors = F)
##  } else {
##    tmp_df <- data.frame(regulon_id=this_regulon,atac_tissue=NA,num_overlap_genes=NA)
##  }
##  tmp_df <- as.list(tmp_df)
##  atac_result <- rbind(atac_result,tmp_df)
##}
##atac_result <- as.data.frame(atac_result)
##alternative_regulon_result <- merge(alternative_regulon_result,atac_result,by.x=3,by.y=1,all = T)
##alternative_regulon_result <- alternative_regulon_result[c(1,2,3,4,5,6,8,9,7)]
alternative_regulon_result <- alternative_regulon_result[order(alternative_regulon_result$tf, alternative_regulon_result$cell_type),]
alternative_regulon_result <- apply(alternative_regulon_result, 2, as.character)
write.table(alternative_regulon_result,paste(jobid,"_alternative_regulon_result.txt",sep = ""),col.names = T,row.names = F,quote = F,sep = "\t")


colnames(alternative_regulon_result)
regulon_tf_vector <- unique(alternative_regulon_result[,2])

BinMean <- function (vec, every, na.rm = FALSE) {
  n <- length(vec)
  x <- .colMeans(vec, every, n %/% every, na.rm)
  r <- n %% every
  if (r) x <- c(x, mean.default(vec[(n - r + 1):n], na.rm = na.rm))
  x
}

label_data <- read.table(paste(jobid,"_cell_label.txt",sep = ""),sep="\t",header = T)
label_data <- label_data[order(label_data[,2]),]

cell_idx <- as.character(label_data[,1])
exp_data <- exp_data[,cell_idx]


rate_ct <- sapply(seq(1:total_ct), function(x){
  length(which(label_data[,2] %in% x)) / nrow(label_data)
})

if (ncol(exp_data) > 500) {
  #small_cell_idx <- sample.int(ncol(exp_data), 500)
  small_cell_idx <- seq(1,ncol(exp_data),by=5)
  small_exp_data <<- t(apply(exp_data, 1, function(x){
    BinMean(x, every = 5)
  }))
  small_cell_label <- label_data[small_cell_idx,]
  colnames(small_exp_data) <- small_cell_label[,1]
  nrow(small_cell_label) == ncol(small_exp_data)
} else {
  small_cell_idx <- seq(1,ncol(exp_data))
  small_exp_data <- exp_data
}

#small_exp_data <- exp_data[,small_cell_idx]
exp_file <- small_exp_data
label_file <- label_data[which(as.character(label_data[,1]) %in% colnames(small_exp_data)),]

rate_small_ct <- sapply(seq(1:total_ct), function(x){
  length(which(label_file[,2] %in% x)) / nrow(label_file)
})

short_dir <- grep("*_bic$",list.dirs(path = wd,full.names = F),value=T) 
short_dir <- sort_dir(short_dir)
module_type <- sub(paste(".*",jobid,"_ *(.*?) *_.*",sep=""), "\\1", short_dir)
library(matrixStats)

#exp_file <- exp_file - rowMeans(exp_file)

exp_file <- (exp_file - rowMeans(exp_file))/rowSds(as.matrix(exp_file), na.rm=TRUE)
#exp_file <- exp_file ^ 3
user_label_name <- read.table(paste(jobid,"_user_label_name.txt",sep = ""),stringsAsFactors = F,header = F,check.names = F)
user_label_name <- user_label_name[small_cell_idx,]
i=j=k=1
#i=2
#j=19

combine_regulon_label<-list()
heat_matrix_cell_idx <- as.character(sort(label_file[,1]))
label_idx <- label_file[,1]
exp_file <- exp_file[,heat_matrix_cell_idx]


rownames(label_file) <- label_file[,1]
label_file <- label_file[heat_matrix_cell_idx,]
label_file[1,1]==colnames(exp_file)[1]
#index_gene_name<-index_cell_type <- vector()
regulon_gene <- data.frame()
regulon_label_index <- 1
gene <- character()
if (label_use_sc3 == 0 | label_use_sc3 == 1 ) {
  category <- paste("Predicted label:",paste("_",label_file[,2],"_",sep=""),sep = " ")
} else {
  category <- paste("User's label:",paste("_",as.character(unlist(user_label_name)),"_",sep=""),sep = " ")
}
total_ct <- length(which(module_type=="CT"))

##regulon_gene<- unique(regulon_gene)
#heat_matrix <- data.frame(matrix(ncol = ncol(exp_file), nrow = 0))
#heat_matrix <- subset(exp_file, rownames(exp_file) %in% as.character(regulon_gene[,1]))
heat_matrix <- exp_file
#heat_matrix <- heat_matrix[,order(heat_matrix[1,])]
heat_matrix <- heat_matrix[,heat_matrix_cell_idx]

# get CT#-regulon1-# heat matrix
regulon_tf_vector <- na.omit(regulon_tf_vector)
#i <- which(regulon_tf_vector == "EGR4")
for(i in 1: length(regulon_tf_vector)){
  this_tf_name <- regulon_tf_vector[i]
  alternative_regulon_result <- as.data.frame(alternative_regulon_result)
  this_alternative_regulon_result <- alternative_regulon_result[alternative_regulon_result$tf == this_tf_name,]
  this_alternative_regulon_result <- this_alternative_regulon_result[!is.na(this_alternative_regulon_result$regulon_id),c(3,7)]
  this_alternative_regulon_result[,2] <- as.character(this_alternative_regulon_result[,2])
  gene_row <- character()
  ct_row <- character()
  this_total_regulon <- 0
  
  for (j in 1:nrow(this_alternative_regulon_result)) {
  #for (j in c(1,3)) {
    this_regulon_name <- paste(this_alternative_regulon_result[j,1],": ",sep = "")
    gene_row <- append(gene_row,strsplit(as.character(this_alternative_regulon_result[j,2]),",")[[1]])
    regulon_ct <-gsub( "-.*$", "", this_regulon_name)
    regulon_ct <-gsub("[[:alpha:]]","",regulon_ct)
    regulon_id <- gsub( ".*R", "", this_regulon_name)
    regulon_id <- gsub("[[:alpha:]]","",regulon_id)
    regulon_id <- gsub(":.+?$","",regulon_id)
    ct_row <- append(ct_row,regulon_ct)
  }
  gene_row <- unique(gene_row)
  
  k=0
  data.list <- lapply(as.list(as.character(this_alternative_regulon_result[,2])), function (x){
    return(strsplit(x,",")[[1]])
  })
  names(data.list) <- this_alternative_regulon_result[,1]
  #saveRDS(data.list,file=paste(this_tf_name,"_TF_genes.rds",sep=""))
  
  overlaps <- sapply(data.list, function(g1) 
    sapply(data.list, function(g2)
    {round(length(intersect(g1, g2)) / length(g2) * 100)}))
  
  if(any(overlaps > 0 & overlaps < 1000) & length(gene_row) < 5000){
    
    file_heat_matrix <- heat_matrix[rownames(heat_matrix) %in% unique(gene_row),label_file[,2] %in% ct_row]
    dim(file_heat_matrix)
    label_file
    #write.table(label_file,paste(this_tf_name,"_TF_cell_label.txt",sep=""),quote = F,col.names = T,row.names = F)
    
    #write.table(data.frame("Gene"=rownames(file_heat_matrix),file_heat_matrix,check.names = F),paste(this_tf_name,"_TF_expression.txt",sep=""),quote = F,col.names = T,row.names = F)
    length(gene_row) ==  nrow(file_heat_matrix)
    if (label_use_sc3 == 0 ) {
      category <- paste("Cell label:",paste("_",label_file[label_file[,2] %in% ct_row,2],"_",sep=""),sep = " ")
      file_heat_matrix <- rbind(category,file_heat_matrix)
      file_heat_matrix <- file_heat_matrix[,order(file_heat_matrix[1,])]
    } 
    
    #file_heat_matrix <- file_heat_matrix[,order(file_heat_matrix[1,])]
    #j=84
  for (j in 1:nrow(this_alternative_regulon_result)) {
  #for (j in c(1,3)) {
      regulon_label_col <- as.data.frame(paste(this_alternative_regulon_result[j,1],": ",(rownames(file_heat_matrix) %in% strsplit(this_alternative_regulon_result[j,2],",")[[1]])*1,sep = ""),stringsAsFactors=F)
      #print(regulon_label_col)
      #regulon_label_col[1,1] <- ""
      file_heat_matrix <- cbind(regulon_label_col,file_heat_matrix)
      
    }
    file_heat_matrix<- tibble::rownames_to_column(file_heat_matrix, "rowname")
    file_heat_matrix <- file_heat_matrix[order(file_heat_matrix[,2],file_heat_matrix[,3]),,]
    if (label_use_sc3 == 0 ) {
      file_heat_matrix[1,1:length(ct_row)+1] <- ""
      #file_heat_matrix[1,1:2+1] <- ""
      file_heat_matrix[1,1] <- ""
      colnames(file_heat_matrix)[1:length(ct_row)+1] <- ""
      #colnames(file_heat_matrix)[1:2+1] <- ""
      colnames(file_heat_matrix)[1] <- ""
    } 
    write.table(file_heat_matrix,paste("heatmap/",this_tf_name,".heatmap.txt",sep = ""),row.names = F,quote = F,sep = "\t", col.names=T)
    #write.table(file_heat_matrix,paste("heatmap/",this_tf_name,".heatmap.txt",sep = ""),row.names = F,quote = F,sep = "\t", col.names=T)
    
  }
  
}


