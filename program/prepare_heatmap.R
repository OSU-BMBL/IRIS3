#######  Combine all bbc results for clustergrammer input ##########


library(magic)
library(Matrix)
library(reshape2)
library(rlist)
library(dplyr)
library(stringr)
library(scales)
library(sgof)

args <- commandArgs(TRUE)

wd <- args[1]
jobid <- args[2]
label_use_prediction <- args[3]
#setwd("/var/www/html/iris3/data/20191024223404")
#wd <- getwd()
#jobid <-20191024223404
#label_use_prediction <- 2
setwd(wd)
getwd()
dir.create('heatmap',showWarnings = F)
sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
}

BinMean <- function (vec, every, na.rm = FALSE) {
  n <- length(vec)
  x <- .colMeans(vec, every, n %/% every, na.rm)
  r <- n %% every
  if (r) x <- c(x, mean.default(vec[(n - r + 1):n], na.rm = na.rm))
  x
}

all_regulon <- sort_dir(list.files(path = wd,pattern = "._bic.regulon_gene_symbol.txt$"))
all_label <- sort_dir(list.files(path = wd,pattern = ".+cell_label.txt$")[1])
label_data <- read.table(all_label,header = T)
exp_data <- read.table(paste(jobid,"_filtered_expression.txt",sep = ""),stringsAsFactors = F,header = T,check.names = F,row.names = 1)
#exp_data<- read.delim(paste(jobid,"_raw_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
label_data <- label_data[order(label_data[,2]),]

cell_idx <- as.character(label_data[,1])
exp_data <- exp_data[,cell_idx]


if (ncol(exp_data) > 300) {
  this_bin <- ncol(exp_data) %/% 300
  small_cell_idx <- seq(1,ncol(exp_data),by=this_bin)
  small_exp_data <<- t(apply(exp_data, 1, function(x){
    BinMean(x, every = this_bin)
  }))
  small_cell_label <- label_data[small_cell_idx,]
  
  # if any cell type not in the small list
  if(length(unique(small_cell_label[,2])) != length(unique(label_data[,2]))){
    for (i in 1: length(unique(label_data[,2]))) {
      if (!any(small_cell_label[,2] %in% i)) {
        if (length(which(label_data[,2] == i)) > 3){
          add_cell_idx <- which(label_data[,2] == i)[1:3]
        } else {
          add_cell_idx <- which(label_data[,2] == i)
        }
        small_cell_idx <- c(small_cell_idx, add_cell_idx)
        small_cell_label <- label_data[small_cell_idx,]
        small_exp_data <- cbind(small_exp_data, exp_data[,add_cell_idx])
        colnames(small_exp_data) <- colnames(exp_data)[small_cell_idx]
      }
    }
  }
  
} else {
  small_cell_idx <- seq(1:ncol(exp_data))
  small_exp_data <- exp_data
  small_cell_label <- label_data[small_cell_idx,]
  
}


#small_exp_data <- exp_data[,small_cell_idx]
#######exp_data <- small_exp_data

short_dir <- grep("*_bic$",list.dirs(path = wd,full.names = F),value=T) 
short_dir <- sort_dir(short_dir)
module_type <- sub(paste(".*",jobid,"_ *(.*?) *_.*",sep=""), "\\1", short_dir)

exp_data <- log1p(exp_data)
exp_data <- (exp_data - rowMeans(exp_data))

small_exp_data <- log1p(small_exp_data)
small_exp_data <- (small_exp_data - rowMeans(small_exp_data))

#/rowSds(as.matrix(exp_data), na.rm=TRUE)

user_label_name <- read.table(paste(jobid,"_user_label_name.txt",sep = ""),stringsAsFactors = F,header = F,check.names = F)
small_user_label_name <- user_label_name[small_cell_idx,]

i=j=k=1
#i=2
#j=19

combine_regulon_label<-list()

#index_gene_name<-index_cell_type <- vector()
regulon_gene <- data.frame()
regulon_label_index <- 1
gene <- character()

total_ct <- length(which(module_type=="CT"))
for (i in 1:length(all_regulon)) {
  this_label_index <- which(label_data[,2] == i)
  if (length(this_label_index) > 300){
    this_label_index <- this_label_index[1:300]
    this_label_data <- label_data[this_label_index,]
    this_exp_data <- exp_data[,this_label_index]
    this_user_label_name <- user_label_name[this_label_index,]
  } else {
    this_label_data <- label_data
    this_exp_data <- exp_data[,this_label_index]
    this_user_label_name <- user_label_name[this_label_index,]
    
  }
  
  ## different number of cells should be different numbers of category 
  if (label_use_prediction == 0 | label_use_prediction == 1 ) {
    category <- paste("Predicted label:",paste("_",this_label_data[,2],"_",sep=""),sep = " ")
  } else {
    category <- paste("User's label:",paste("_",as.character(unlist(this_user_label_name)),"_",sep=""),sep = " ")
  }
  
  
  regulon_file_obj <- file(all_regulon[i],"r")
  regulon_file_line <- readLines(regulon_file_obj)
  close(regulon_file_obj)
  regulon_file <- strsplit(regulon_file_line,"\t")
  for (regulon_row in regulon_file) {
    tmp_gene <- regulon_row[-1]
    gene <- c(gene,tmp_gene)
  }
  gene <- unique(gene[gene!=""])
  regulon_gene <- rbind(regulon_gene,as.data.frame(gene))
  #For each regulon.txt, convert ENSG -> gene name
  name_idx <- 1
  if(length(regulon_file) > 0){
    for (j in 1:length(regulon_file)) {
      regulon_gene_symbol <- regulon_file[[j]][-1]
      regulon_gene_symbol <- regulon_gene_symbol[regulon_gene_symbol!=""]
      if(length(regulon_gene_symbol)>1000 | length(regulon_gene_symbol) <=1){
        next
      }
      regulon_heat_matrix <- subset(exp_data,rownames(exp_data) %in% regulon_gene_symbol)
      regulon_heat_matrix <- rbind(category,regulon_heat_matrix)
      if(i <= total_ct) {
        regulon_heat_matrix_filename <- paste("heatmap/CT",i,"-R",name_idx,".heatmap.txt",sep="")
        ct_index <- gsub(".*_CT_","",short_dir[i])
        ct_index <- as.numeric(gsub("_bic","",ct_index))
        regulon_label <- paste("CT",ct_index,"-R",name_idx,": ",sep = "")
        ct_colnames <- this_label_data[which(this_label_data[,2]==ct_index),1]
        regulon_heat_matrix <- as.data.frame(regulon_heat_matrix[,colnames(regulon_heat_matrix) %in% ct_colnames])
        rownames(regulon_heat_matrix)[-1] <- paste("Genes:",rownames(regulon_heat_matrix)[-1],sep = " ")
        rownames(regulon_heat_matrix)[1] <- ""
        colnames(regulon_heat_matrix) <- paste("Cells:",colnames(regulon_heat_matrix),sep = " ")
        write.table(regulon_heat_matrix,regulon_heat_matrix_filename,quote = F,sep = "\t", col.names=NA)
        # if # of lines=13, clustergrammer fails. add a line break
        if(nrow(regulon_heat_matrix) == 13) {
          write('\n',file=regulon_heat_matrix_filename,append=TRUE)
        }
        #save regulon label to one list
        combine_regulon_label<-list.append(combine_regulon_label,regulon_gene_symbol)
        names(combine_regulon_label)[regulon_label_index] <- regulon_label
        regulon_label_index <- regulon_label_index + 1
        name_idx <- name_idx + 1
      } else {
        regulon_heat_matrix_filename <- paste("heatmap/module",i-total_ct,"-R",name_idx,".heatmap.txt",sep="")
        module_index <- i - total_ct
        regulon_label <- paste("module",module_index,"-R",name_idx,": ",sep = "")
        module_colnames <- this_label_data[,1]
        rownames(regulon_heat_matrix)[-1] <- paste("Genes:",rownames(regulon_heat_matrix)[-1],sep = " ")
        rownames(regulon_heat_matrix)[1] <- ""
        colnames(regulon_heat_matrix) <- paste("Cells:",colnames(regulon_heat_matrix),sep = " ")
        write.table(regulon_heat_matrix,regulon_heat_matrix_filename,quote = F,sep = "\t", col.names=NA)
        # if # of lines=14, clustergrammer fails. add a line break
        if(nrow(regulon_heat_matrix) == 14) {
          write('\n',file=regulon_heat_matrix_filename,append=TRUE)
        }
        #save regulon label to one list
        combine_regulon_label<-list.append(combine_regulon_label,regulon_gene_symbol)
        names(combine_regulon_label)[regulon_label_index] <- regulon_label
        regulon_label_index <- regulon_label_index + 1
        name_idx <- name_idx + 1
      }
    }
  }
}
regulon_gene<- unique(regulon_gene)
heat_matrix <- data.frame(matrix(ncol = ncol(small_exp_data), nrow = 0))
heat_matrix <- subset(small_exp_data, rownames(small_exp_data) %in% as.character(regulon_gene[,1]))

#heat_matrix <- heat_matrix[,order(heat_matrix[1,])]
i=1

#i=j=1 
# get CT#-regulon1-# heat matrix
for(i in 1: length(unique(small_cell_label[,2]))){
  gene_row <- character()
  this_total_regulon <- 0
  for (m in length(combine_regulon_label):1) {
    if(i == as.numeric(strsplit(names(combine_regulon_label[m]), "\\D+")[[1]][-1])[1]){
      
      this_regulon_num <- as.numeric(strsplit(names(combine_regulon_label[m]), "\\D+")[[1]][-1])[2]
      if (this_regulon_num > this_total_regulon) {
        this_total_regulon <- this_regulon_num
      }
    }
  }
  if (this_total_regulon >=10) {
    max_show <- 10
  } else {
    max_show <- this_total_regulon
  }
  for (j in 1:max_show) {
    this_regulon_name <- paste("CT",i,"-R",j,": ",sep = "")
    gene_row <- append(gene_row,as.character(unlist(combine_regulon_label[which(names(combine_regulon_label) == this_regulon_name)])))
  }
  k=0
  gene_row <- unique(gene_row)
  file_heat_matrix <- heat_matrix[rownames(heat_matrix) %in% unique(gene_row),]
  if (nrow(file_heat_matrix) == 0) {
    next
  }
  if (label_use_prediction == 0 ) {
    category <- paste("Predicted label:",paste("_",small_cell_label[,2],"_",sep=""),sep = " ")
    file_heat_matrix <- rbind(category,file_heat_matrix)
  } else if (label_use_prediction == 1) {
    category1 <- paste("Predicted label:",paste("_",small_cell_label[,2],"_",sep=""),sep = " ")
    category2 <- paste("User's label:",paste("_",as.character(unlist(small_user_label_name)),"_",sep=""),sep = " ")
    file_heat_matrix <- rbind(category1,category2,file_heat_matrix)
  } else {
    predict_label <- read.table(paste(jobid,"_predict_label.txt",sep=""),header = T)
    predict_label <- predict_label[order(match(predict_label[,1],colnames(exp_data))),]
    category1 <- paste("User's label:",paste("_",as.character(unlist(small_user_label_name)),"_",sep=""),sep = " ")
    category2 <- paste("Predicted label:",paste("_",predict_label[,2],"_",sep=""),sep = " ")
    colnames(file_heat_matrix)
    predict_label <- predict_label[which(as.character(predict_label[,1]) %in% colnames(file_heat_matrix)),]
    
    file_heat_matrix <- rbind(category1,category2,file_heat_matrix)
  }
  
  #file_heat_matrix <- file_heat_matrix[,order(file_heat_matrix[1,])]
  #j=84
  for (j in 1:length(combine_regulon_label)) {
    if(i == as.numeric(strsplit(names(combine_regulon_label[j]), "\\D+")[[1]][-1])[1] && str_detect(names(combine_regulon_label[j]),"CT")){
      regulon_label_col <- as.data.frame(paste(names(combine_regulon_label[j]),(rownames(file_heat_matrix) %in% unlist(combine_regulon_label[j]) )*1,sep = ""),stringsAsFactors=F)
      #print(regulon_label_col)
      #regulon_label_col[1,1] <- ""
      file_heat_matrix <- cbind(regulon_label_col,file_heat_matrix)
      k <- k + 1
      if(k>=10){
        #file_heat_matrix <- file_heat_matrix[,-10]
        break
      }
    }
  }
  file_heat_matrix<- tibble::rownames_to_column(file_heat_matrix, "rowname")
  if (label_use_prediction == 0 ) {
    file_heat_matrix[1,1:k+1] <- ""
    file_heat_matrix[1,1] <- ""
    colnames(file_heat_matrix)[1:k+1] <- ""
    colnames(file_heat_matrix)[1] <- ""
  } else {
    file_heat_matrix[1:2,1:k+1] <- ""
    file_heat_matrix[1:2,1] <- ""
    colnames(file_heat_matrix)[1:k+1] <- ""
    colnames(file_heat_matrix)[1] <- ""
  }
  
  write.table(file_heat_matrix,paste("heatmap/CT",i,".heatmap.txt",sep = ""),row.names = F,quote = F,sep = "\t", col.names=T)
  # if # of lines=13, clustergrammer fails. add a line break
  if(nrow(file_heat_matrix) == 13) {
    write('\n',file=paste("heatmap/CT",i,".heatmap.txt",sep = ""),append=TRUE)
  }
  
}
#i=j=1
if ((length(all_regulon)-total_ct) > 0) {
  for(i in 1: (length(all_regulon)-total_ct)){
    gene_row <- character()
    this_total_regulon <- sum(str_count(names(combine_regulon_label), paste("module",i,"-R",sep="")))
    
    if (this_total_regulon >=10) {
      max_show <- 10
    } else {
      max_show <- this_total_regulon
    }
    for (j in 1:max_show) {
      this_regulon_name <- paste("module",i,"-R",j,": ",sep = "")
      gene_row <- append(gene_row,as.character(unlist(combine_regulon_label[which(names(combine_regulon_label) == this_regulon_name)])))
    }
    k=0
    gene_row <- unique(gene_row)
    file_heat_matrix <- heat_matrix[rownames(heat_matrix) %in% unique(gene_row),]
    
    if (label_use_prediction == 0 ) {
      category <- paste("Predicted label:",paste("_",small_cell_label[,2],"_",sep=""),sep = " ")
      file_heat_matrix <- rbind(category,file_heat_matrix)
    } else if (label_use_prediction == 1) {
      category1 <- paste("Predicted label:",paste("_",small_cell_label[,2],"_",sep=""),sep = " ")
      category2 <- paste("User's label:",paste("_",as.character(unlist(small_user_label_name)),"_",sep=""),sep = " ")
      file_heat_matrix <- rbind(category1,category2,file_heat_matrix)
    } else {
      predict_label <- read.table(paste(jobid,"_predict_label.txt",sep=""),header = T)
      predict_label <- predict_label[order(match(predict_label[,1],colnames(exp_data))),]
      category1 <- paste("User's label:",paste("_",as.character(unlist(small_user_label_name)),"_",sep=""),sep = " ")
      category2 <- paste("Predicted label:",paste("_",predict_label[,2],"_",sep=""),sep = " ")
      file_heat_matrix <- rbind(category1,category2,file_heat_matrix)
    }
    
    #file_heat_matrix <- file_heat_matrix[,order(file_heat_matrix[1,])]
    
    for (j in 1:length(combine_regulon_label)) {
      if(i == as.numeric(strsplit(names(combine_regulon_label[j]), "\\D+")[[1]][-1])[1] && str_detect(names(combine_regulon_label[j]),"module")){
        regulon_label_col <- as.data.frame(paste(names(combine_regulon_label[j]),(rownames(file_heat_matrix) %in% unlist(combine_regulon_label[j]) )*1,sep = ""),stringsAsFactors=F)
        #print(regulon_label_col)
        #regulon_label_col[1,1] <- ""
        file_heat_matrix <- cbind(regulon_label_col,file_heat_matrix)
        k <- k + 1
        if(k>=10){
          #file_heat_matrix <- file_heat_matrix[,-10]
          break
        }
      }
    }
    file_heat_matrix<- tibble::rownames_to_column(file_heat_matrix, "rowname")
    if (label_use_prediction == 0 ) {
      file_heat_matrix[1,1:k+1] <- ""
      file_heat_matrix[1,1] <- ""
      colnames(file_heat_matrix)[1:k+1] <- ""
      colnames(file_heat_matrix)[1] <- ""
    } else {
      file_heat_matrix[1:2,1:k+1] <- ""
      file_heat_matrix[1:2,1] <- ""
      colnames(file_heat_matrix)[1:k+1] <- ""
      colnames(file_heat_matrix)[1] <- ""
    }
    
    write.table(file_heat_matrix,paste("heatmap/module",i,".heatmap.txt",sep = ""),row.names = F,quote = F,sep = "\t", col.names=T)
    # if # of lines=13, clustergrammer fails. add a line break
    if(nrow(file_heat_matrix) == 13) {
      write('\n',file=paste("heatmap/module",i,".heatmap.txt",sep = ""),append=TRUE)
    }
  }
}

#rownames(heat_matrix)[-1] <- paste("Gene:",rownames(heat_matrix)[-1],sep = " ")
#colnames(heat_matrix) <- paste("Cell:",colnames(heat_matrix),sep = " ")

