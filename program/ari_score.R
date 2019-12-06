#######  Calculate ARI score if user provide their cell label ##########


args <- commandArgs(TRUE)
srcFile <- args[1] # raw user filename
jobid <- args[2] # job id
delim <- args[3] #label file delimiter 

label_use_sc3 <- 0 #default 0
label_use_sc3 <- args[4] # 1 for have label use sc3, 2 for have label use label, 0 for no label use sc3
#delim <- args[3]

# srcFile = "Seurat-cellInfo.txt"
# jobid <- "20191003114503"
# delim <- "\t"
# label_use_sc3 <- 1
if(delim == 'tab'){
  delim <- '\t'
}
if(delim == 'space'){
  delim <- ' '
}
#install.packages("NMF")
#install.packages("clues")
#install.packages("igraph")
#install.packages("MLmetrics")
#install.packages("AUC")
#install.packages("ROSE")
#devtools::install_github("sachsmc/plotROC")
#install.packages("networkD3")
#library(reader)
library(plotROC)
library("NMF")
library("clues")
library("igraph")
library("MLmetrics")
library("AUC")
library("ROSE")
library("ggplot2")
library(networkD3)
library(tidyr)
library(gdata)
library(data.table)
library(stringr)


predict_cluster <- read.table(paste(jobid,"_sc3_label.txt",sep=""),header=T,sep='\t',check.names = FALSE)
# srcFile <- 'Zeisel_cell_label.csv'

#2nd input
#user_label <- read.delim(srcFile,header=T,sep=delim,check.names = FALSE)
if (srcFile == '1') {
  user_label_file <- predict_cluster
} else {
  user_label_file <- read.delim(srcFile,header=T,sep=delim,check.names = FALSE)
}


user_label_index <- 2
user_cellname_index <- 1
user_label <- data.frame(user_label_file[,user_cellname_index],user_label_file[,user_label_index],stringsAsFactors = F)


user_label_name <- user_label[order(user_label[,2]),2]
predict_cluster <- predict_cluster[order(predict_cluster[,2]),]


user_label <- user_label[order(user_label[,2]),]
user_label[,2] <- factor(user_label[,2])
user_label[,1] <-  gsub('([[:punct:]])|\\s+','_',user_label[,1])

label_order <- unique(user_label[,2])
levels(user_label[,2]) <- 1: length(levels(user_label[,2]))
colnames(predict_cluster) <- c("cell_name","cluster")
colnames(user_label) <- c("cell_name","label")

write.table(predict_cluster, paste(jobid,"_sc3_label.txt",sep = ""),sep = "\t", row.names = F,col.names = T,quote = F)

if (label_use_sc3 == 2) {
  is_evaluation <- 'yes'
  #write.table(user_label_file,paste(jobid,"_sc3_label.txt",sep = ""),quote = F,row.names = F,sep = "\t")
  write.table(user_label, paste(jobid,"_cell_label.txt",sep = ""),sep = "\t", row.names = F,col.names = T,quote = F)
  write.table(str_replace(user_label_name," ","_"), paste(jobid,"_user_label_name.txt",sep = ""),sep = "\t", row.names = F,col.names = F,quote = F)
  write(paste("provide_label,",length(levels(as.factor(user_label_name))),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
  write(paste("predict_label,",max(predict_cluster[,2]),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
  
} else if (label_use_sc3 == 1){
  is_evaluation <- 'yes'
  write.table(predict_cluster, paste(jobid,"_cell_label.txt",sep = ""),sep = "\t", row.names = F,col.names = T,quote = F)
  write.table(user_label_name, paste(jobid,"_user_label_name.txt",sep = ""),sep = "\t", row.names = F,col.names = F,quote = F)
  write(paste("provide_label,",length(levels(as.factor(user_label_name))),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
  write(paste("predict_label,",max(predict_cluster[,2]),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
  
} else {
  is_evaluation <- 'no'
  write.table(user_label, paste(jobid,"_cell_label.txt",sep = ""),sep = "\t", row.names = F,col.names = T,quote = F)
  write.table(predict_cluster[,2], paste(jobid,"_user_label_name.txt",sep = ""),sep = "\t", row.names = F,col.names = F,quote = F)
  write(paste("provide_label,","0",sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
  write(paste("predict_label,",max(predict_cluster[,2]),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
  
}

write(paste("is_evaluation,",is_evaluation,sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)

# prepare data for sankey plot
if (label_use_sc3 == 2 | label_use_sc3 == 1) {
  predict_cluster <- predict_cluster[order(predict_cluster[,1]),]
  user_label_index <- order(user_label[,1])
  user_label <- user_label[user_label_index,]
  user_label_name <- user_label_name[user_label_index]

  target <- merge(predict_cluster,user_label,by.x = "cell_name",by.y = "cell_name" )
  clustering_purity <- purity(as.factor(target$cluster),as.factor(target$label))
  clustering_entropy <- entropy(as.factor(target$cluster),as.factor(target$label))
  clustering_nmi <- igraph::compare(as.factor(target$cluster),as.factor(target$label),method="nmi")
  clustering_ARI <- igraph::compare(as.factor(target$cluster),as.factor(target$label),method="adjusted.rand")
  clustering_RI <-adjustedRand(as.numeric(target$cluster),as.numeric(target$label),  randMethod = "Rand")  # calculate Rand Index
  clustering_JI <-adjustedRand(as.numeric(target$cluster),as.numeric(target$label),  randMethod = "Jaccard")  # calculate Jaccard
  clustering_FMI <-adjustedRand(as.numeric(target$cluster),as.numeric(target$label),  randMethod = "FM")  # calculate Fowlkes Mallows Index
  #clustering_F1_Score <- F1_Score(as.numeric(target$cluster),as.numeric(target$label))
  #clustering_Precision <- Precision(as.factor(target$cluster),as.factor(target$label))
  #clustering_Recall <- Recall(as.factor(target$cluster),as.factor(target$label))
  clustering_Accuracy <- Accuracy(as.numeric(target$cluster),as.numeric(target$label))
  clustering_Accuracy <- Accuracy(as.numeric(target$cluster),as.numeric(target$label))
  #clustering_sensitivity <- sensitivity(as.numeric(target$cluster),as.numeric(target$label))
  #clustering_specificity <- specificity(as.numeric(target$cluster),as.numeric(target$label))
  
  #res <- cbind(clustering_ARI,clustering_RI,clustering_JI,clustering_FMI,clustering_F1_Score,
  #clustering_Accuracy,clustering_Precision,clustering_Recall,clustering_entropy,clustering_purity)
  
  #remove f1,precision,recall
  res <- cbind(clustering_ARI,clustering_RI,clustering_JI,clustering_FMI,
               clustering_Accuracy,clustering_entropy,clustering_purity)
  
  res_colname <- colnames(res)
  res_colname <- gsub(".*\\_","",res_colname)
  colnames(res) <- res_colname
  write.table(format(t(res), digits=4), paste(jobid,"_predict_cluster_evaluation.txt",sep = ""),sep = ",", row.names = T,col.names = F,quote = F)
  
  # step2 change label names
  user_label$label <- sub("^", "User label:", user_label_name )
  predict_cluster$cluster <- sub("^", "Predicted label:", predict_cluster$cluster )
  
  # step3 rbind two labels to create node matrix
  comb.label.list <- as.data.frame(rbind(matrix(user_label$label),matrix(predict_cluster$cluster)))
  colnames(comb.label.list) <- c("name")
  comb.label.list[,1] <- as.character(comb.label.list[,1])
  i=1
  for (i in 1:nrow(comb.label.list)) {
    idx <- which(colnames(table(user_label_name,user_label$label)) == as.character(comb.label.list[i,1]))
    if(length(idx)==1){
      comb.label.list[i,1] <- as.character(comb.label.list[i,1])
      #comb.label.list[i,2] <- as.character(rownames(table(user_label_name,user_label$label))[idx])
    }
  }
  comb.label.list[,1] <- as.factor(comb.label.list[,1])
  # step4 give number to each label by all label groups, and extract unique nodes
  map.label <- mapLevels(x=comb.label.list)
  map.label <- c(unlist(map.label$name))
  map.label <- map.label-1
  
  nodes <- data.table(name=names(map.label))
  name1 <- gsub("\\(.+", "",  nodes$name)
  predict_idx <-  order(as.numeric(gsub("[^0-9.]", "",  name1[grep("Predict.*",  name1)])))
  user_idx <-  order(as.numeric(gsub("[^0-9.]", "",  name1[grep("User.*",  name1)]))) + length(predict_idx)
  new_index <- c(predict_idx,user_idx)
  nodes <- nodes[new_index,]
  
  # step5 create link matrix
  links <- as.data.frame(cbind(user_label$label,predict_cluster$cluster))
  #link_test<- links
  #links<- link_test
  colnames(links) <- c("label","pred_label")
  links <- unite(links, newcol, c(label, pred_label), remove=FALSE,sep = "^&")
  links <- aggregate(links$label~links$newcol, data=links, FUN=length)
  colnames(links) <- c("type","value")
  links <- separate(data = links, col = type, into = c("type1", "type2"), sep = "\\^&")
  i=1
  for (i in 1:nrow(links)) {
    idx <- which(colnames(table(user_label_name,user_label$label)) == as.character(links[i,1]))
    if(length(idx)==1){
      links[i,1] <- as.character(links[i,1])
      #links[i,1] <- as.character(rownames(table(user_label_name,user_label$label))[idx])
    }
  }
  # change types into numbers as map.label
  links <- data.table(
    src = map.label[(links$type1)],
    target = map.label[(links$type2)],
    value = links$value
  )
  txtsrc <- links[, .(total = sum(value)), by=c('src')]
  nodes[txtsrc$src+1L, name := paste0(name, ' (', txtsrc$total, ')')]
  
  txttarget <- links[, .(total = sum(value)), by=c('target')]
  nodes[txttarget$target+1L, name := paste0(name, ' (', txttarget$total, ')')]
  
  # create sankey dengram use nodes and links
  
  sankeyNetwork(Links = links, Nodes = nodes,
                Source = "src", Target = "target",
                Value = "value", NodeID = "name",
                fontSize= 12, nodeWidth =30)
  
  
  cat("",file=paste(jobid,"_sankey.txt",sep=""),append=F)
  write(paste("nodes,",nodes$name,sep=""),file=paste(jobid,"_sankey.txt",sep=""),append=TRUE)
  write(paste("src,",links$src,sep=""),file=paste(jobid,"_sankey.txt",sep=""),append=TRUE)
  write(paste("target,",links$target,sep=""),file=paste(jobid,"_sankey.txt",sep=""),append=TRUE)
  write(paste("value,",links$value,sep=""),file=paste(jobid,"_sankey.txt",sep=""),append=TRUE)
  write(paste("label_order,",order(label_order),sep=""),file=paste(jobid,"_sankey.txt",sep=""),append=TRUE)
  # title left: cell label; right:sc3 cluster
  
}


