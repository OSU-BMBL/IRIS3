
########## Sort regulon by regulon specificity score ##################
# used files:
# filtered exp matrix
# cell label
# regulon_gene_symbol, regulon_gene_id, regulon_motif, motif_ranks (from merge_bbc.R)

library(scales)
library(sgof)
library(foreach)
library(tidyverse)
library(doParallel)
registerDoParallel(8)  # use multicore, set to the number of our cores

args <- commandArgs(TRUE)
wd <- args[1] # filtered expression file name
jobid <- args[2] # user job id
# wd<-getwd()
####test
# wd <- "/var/www/html/CeRIS/data/2019110595153"
# jobid <-2019110595153 
# setwd(wd)

quiet <- function(x) { 
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 


# calculate Jensen-Shannon Divergence (JSD), used to calculate regulon specificity score (RSS)
calc_jsd <- function(v1,v2) {
  H <- function(v) {
    v <- v[v > 0]
    return(sum(-1 * v * log(v)))
  }
  return (H(v1/2+v2/2) - (H(v1)+H(v2))/2)
}


calc_ranking <- function(expr){
  require(data.table)
  if(!data.table::is.data.table(expr))
    expr <- data.table::data.table(expr, keep.rownames=TRUE)
  data.table::setkey(expr, "rn") # (reorders rows)
  colsNam <- colnames(expr)[-1] # 1=row names
  #names(genes) <- 1:length(genes)
  rankings <- expr[, (colsNam):=lapply(-.SD, data.table::frankv,order=-1L, ties.method="min", na.last="keep"),
                   .SDcols=colsNam]
  rn <- rankings$rn
  rankings <- as.matrix(rankings[,-1])
  rownames(rankings) <- rn
  return(rankings)
}


#num_ct <- 1
#genes <- c("ANAPC11","APLP2","ATP6V1C2","DHCR7","GSPT1","HDGF","HMGA1")
#calculate regulon activity score (RAS) 
# expr <- exp_data
# genes <- total_gene_list
calc_ras <- function(expr=NULL, genes,method=c("aucell","zscore","plage","ssgsea","custom_auc"), rankings) {
  print(Sys.time())
  if (method=="aucell"){ #use top 10% cutoff
    require(AUCell)
    expr <- as.matrix(expr)
    names(genes) <- 1:length(genes)
    cells_rankings <- AUCell_buildRankings(expr,plotStats = F) 
    cells_AUC <- AUCell_calcAUC(genes, cells_rankings, aucMaxRank=nrow(cells_rankings)*0.1)
    #score_vec <- cells_AUC@assays@data@listData[['AUC']]
    #score_vec <- cells_AUC@assays@.xData$data$AUC
    ## AUCell modified object structure
    tryCatch(score_vec <- cells_AUC@assays@data@listData[['AUC']],error = function(e) score_vec <- cells_AUC@assays@.xData$data$AUC)
    
  } else if (method=="zscore"){
    require("GSVA")
    score_vec <- gsva(expr,gset=genes,method="zscore")
  } else if (method=="plage"){
    require("GSVA")
    score_vec <- gsva(expr,gset=genes,method="plage")
  } else if (method=="ssgsea"){
    require("GSVA")
    score_vec <- gsva(expr,gset=genes,method="ssgsea")
  } else if (method=="gsva"){
    require("GSVA")
    require("snow")
    score_vec <- gsva(expr,gset=genes,method="gsva",kcdf="Gaussian",abs.ranking=F,verbose=T,parallel.sz=8)
  } else if (method=="wmw_test"){
    require(BioQC)
    require(data.table)
    geneset <- as.data.frame(lapply(genes, function(x){
      return(rownames(rankings) %in% x)
    }))
    names(geneset) <- 1:ncol(geneset)
    dim(geneset)
    score_vec <- wmwTest(rankings, geneset, valType="abs.log10p.greater", simplify = T)
    
    #score_vec[score_vec < 1] <- 0
    #for (i in 1:nrow(score_vec)) {
    #  tmp <- as.numeric(quantile(score_vec[i,])[2])
    #  #tmp2 <- mean(score_vec[i,])
    #  #tmp3 <- median(score_vec[i,])
    #  #snr1 <- mean(score_vec[i,])/sd(score_vec[i,])
    #  score_vec[i,which(as.numeric(score_vec[i,]) < tmp)] <- 0
    #  #c1 <- pass.filt(score_vec[i,], W=0.05, type="stop", method="ChebyshevI")
    #  #barplot(score_vec[i,])
    #  #barplot(c1)
    #}
    
    #barplot(score_vec1[1,])
    ##### test two u-test function speed
    #library(microbenchmark)
    #microbenchmark(
    #  sapply(indx, function(i) wmwTest(rankings[,i], set_in_list, valType="p.two.sided")),times = 10
    #)
    #microbenchmark(
    #  sapply(indx, function(i) wilcox.test(gSetRanks[,i], other_ranking[,i])$p.value),times = 10
    #)
    #
  }
  print(Sys.time())
  return(score_vec)
}


#normalization
normalize_ras <- function(label_data=NULL,score_vec=NULL, num_ct=1, total_ct=7){
  #normalize score_vec(regulon activity score) to range(0,1) and sum=1
  ct_vec <- ifelse(label_data[,2] %in% num_ct, 1, 0)
  score_vec[,which(ct_vec==1)] <- score_vec[,which(ct_vec==1)] * 2
  score_vec <- tryCatch(apply(score_vec, 1, rescale), error=function(e){
    rescale(score_vec)
  })
  score_vec <- t(score_vec)
  
  score_vec <- as.data.frame(t(apply(data.frame(score_vec), 1, function(x){
    x <- x/sum(x)
  })))
  return(score_vec)
}


# [Deprecated].test if difference in ras among two groups (whether in this cell type), FDR=0.05(default) used by Benjamini-Hochberg procedure
calc_ras_pval <- function(label_data=NULL,score_vec=NULL, num_ct=1){
  # get cell type vector, add 1 if in this cell type
  ct_vec <- ifelse(label_data[,2] %in% num_ct, 1, 0)
  group1 <- score_vec[,which(ct_vec==1)]
  group0 <- score_vec[,which(ct_vec==0)]
  
  ## two sample t-test
  #pval <- apply(data.frame(1:nrow(group1)),1, function(x){
  #  return (t.test(group1[x,],group0[x,])$p.value)
  #})
  
  ## wilcox rank sum test
  pval <- apply(data.frame(1:nrow(group1)),1, function(x){
    return (wilcox.test(as.numeric(group1[x,]),as.numeric(group0[x,]))$p.value)
  })
  ##Benjamini-Hochberg procedure
  pval_correction <- sgof::BH(pval)
  adj_pval <-pval_correction$Adjusted.pvalues[order(match(pval_correction$data,pval))]
  return(adj_pval)
  
  ## plots for test 
  #new_regulon_filter_by_fdr <- !which(adj_pval>0.05) %in% which(pval>0.05)
  #if (isTRUE(any(new_regulon_filter_by_fdr))){
  #  s1<-score_vec[which(result_pvalue>0.05)[!which(result_pvalue>0.05) %in% which(r1>0.05)],]
  #  for (i in 1:16) {
  #    barplot(as.matrix(s1[i,]))
  #  }
  #} else {
  #  pval_order <- order(adj_pval)
  #  
  #  s2 <- score_vec[pval_order,]
  #  for (i in 1:16) {
  #    barplot(as.matrix(s2[i,]))
  #  }
  #}
}

calc_rss_pvalue <- function(this_rss=0.31,this_bootstrap_rss,ct=1){
  #ef <- ecdf(this_bootstrap_rss)
  #pvalue <- 1 - ef(this_rss)
  pvalue <- length(which(this_rss < this_bootstrap_rss))/length(this_bootstrap_rss)
  return(pvalue)
}

# calculate regulon specificity score (RSS), based on regulon activity score and cell type specific infor,
calc_rss <- function (label_data=NULL,score_vec=NULL, num_ct=1){
  
  # get cell type vector, add 1 if in this cell type
  ct_vec <- ifelse(label_data[,2] %in% num_ct, 1, 0)
  
  # also normalize ct_vec to sum=1
  sum_ct_vec <- sum(ct_vec)
  ct_vec <- ct_vec/sum_ct_vec
  jsd_result <- apply(as.data.frame(score_vec), 1, function(x){
    return (calc_jsd(x,ct_vec))
  })
  #calculate regulon specificity score (RSS); which defined by converting JSD to a similarity score
  rss <- 1- sqrt(jsd_result)
  return(rss)
}

calc_bootstrap_ras <- function(rankings,iteration=100,regulon_size=45){
  random_genes <- as.data.frame(replicate(iteration, sample.int(nrow(rankings), regulon_size)))
  boot_vec <- wmwTest(rankings, random_genes, valType="abs.log10p.greater", simplify = T)
  #random_genes <- replicate(iteration, list(rownames(rankings)[sample.int(nrow(rankings), regulon_size)]))
  #boot_vec <- gsva(exp_data,gset=random_genes,method="zscore")
  return(boot_vec)
}


calc_bootstrap_rss <- function(label_data,score_vec,num_ct){
  this_rss <- as.numeric(calc_rss(label_data=label_data,score_vec = score_vec,num_ct = num_ct))
  return(this_rss)
}

total_ct <- max(na.omit(as.numeric(stringr::str_match(list.files(path = wd), "_CT_(.*?)_bic")[,2])))

exp_data<- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
exp_data <- as.matrix(exp_data)
label_data <- read.table(paste(jobid,"_cell_label.txt",sep = ""),sep="\t",header = T)
label_data <- label_data[order(label_data[,1]),]

colnames(exp_data)
cell_idx <- as.character(sort(label_data[,1]))

exp_data <- exp_data[,cell_idx]


marker_data <- read.table("cell_type_unique_marker.txt",sep="\t",header = T)
total_motif_list <- vector()
total_gene_list <- vector()

#i=2
## to speed up gsva process, read all genes  to one lists
for (i in 1:total_ct) {
  regulon_gene_name_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),"r")
  regulon_gene_name <- readLines(regulon_gene_name_handle)
  close(regulon_gene_name_handle)
  total_gene_list <- append(total_gene_list,regulon_gene_name)
} 
print(Sys.time())
total_gene_list <- lapply(strsplit(total_gene_list,"\\t"), function(x){x[-1]})
rankings <- calc_ranking(exp_data)

#total_ras <- calc_ras(expr = exp_data,genes=total_gene_list,method = "wmw_test")
total_ras <- calc_ras(expr = exp_data,genes=total_gene_list,method = "wmw_test",rankings = rankings)
total_ras1 <- total_ras 

# set Inf RAS to column max value
for (j in 1:ncol(total_ras)) {
  this_ras <- total_ras[which(total_ras[,j] < Inf),j]
  total_ras[is.infinite(total_ras[,j]),j] <- max(this_ras)
}


#### bootstrap resampling to calculate p-value
bootstrap_ras <- calc_bootstrap_ras(rankings=rankings,iteration=10000,regulon_size=20)

#bootstrap_rss <- foreach (i=1:total_ct) %dopar% {
#  calc_bootstrap_rss(norm_bootstrap_ras,i)
#} 

bootstrap_rss <- sapply (1:total_ct, function(x){
  norm_bootstrap_ras <- normalize_ras(label_data,bootstrap_ras,x,total_ct = total_ct)
  return(calc_bootstrap_rss(label_data,norm_bootstrap_ras,x))
})
colnames(bootstrap_rss) <- as.character(seq(1:total_ct))

bootstrap_rss <- as_tibble(as.matrix(bootstrap_rss))
bootstrap_rss <- gather(bootstrap_rss,CT,RSS) 


#ggplot(bootstrap_rss, aes(x=RSS,color=CT,fill=CT))+theme_bw() + geom_density(alpha=0.25)+ ggtitle(paste("Bootstrap RSS Density plot\nRegulon size:",40,"iteration:",10000))

#i=1
# genes=x= gene_name_list[[1]]
total_gene_index <- 1
for (i in 1:total_ct) {
  regulon_gene_name_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),"r")
  regulon_gene_name <- readLines(regulon_gene_name_handle)
  close(regulon_gene_name_handle)
  
  regulon_gene_id_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_id.txt",sep = ""),"r")
  regulon_gene_id <- readLines(regulon_gene_id_handle)
  close(regulon_gene_id_handle)
  
  regulon_motif_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),"r")
  regulon_motif <- readLines(regulon_motif_handle)
  close(regulon_motif_handle)
  
  
  motif_rank <- read.table(paste(jobid,"_CT_",i,"_bic.motif_rank.txt",sep = ""))
  
  gene_name_list <- lapply(strsplit(regulon_gene_name,"\\t"), function(x){x[-1]})
  gene_id_list <- lapply(strsplit(regulon_gene_id,"\\t"), function(x){x[-1]})
  motif_list <- lapply(strsplit(regulon_motif,"\\t"), function(x){x[-1]})
  
  if (length(gene_name_list) > 0){
    ras <- total_ras[total_gene_index:(total_gene_index + length(gene_name_list) - 1),]
    if (length(motif_list) == 1) {
      ras <- t(as.matrix(ras))
    } 
    total_gene_index <- total_gene_index + length(gene_name_list) 
    originak_ras <- ras
    ras <- normalize_ras(label_data, ras, num_ct = i,total_ct = total_ct)
    
    this_bootstrap_rss <- bootstrap_rss %>%
      as_tibble()%>%
      dplyr::filter(CT==i)%>%
      pull(RSS)
    
    rss_list <- calc_rss(label_data=label_data,score_vec = ras,num_ct = i)
    rss_list <- as.list(rss_list)
    
    # calculate to be removed regulons index
    rss_keep_index <- lapply(rss_list, function(x){
      if(is.na(x))
        return (1)
      else return(0)
    })
    
    if (length(motif_list) > 0) {
      rss_keep_index <- which(unlist(rss_keep_index) == 0)
      rss_list <- rss_list[rss_keep_index]
      gene_name_list <- gene_name_list[rss_keep_index]
      gene_id_list <- gene_id_list[rss_keep_index]
      motif_list <- motif_list[rss_keep_index]
      ras <- ras[rss_keep_index,]
      originak_ras <- originak_ras[rss_keep_index,]
      
      rss_rank <- order(unlist(rss_list),decreasing = T)
      # x <- gene_name_list[[1]]
      gene_name_list <- gene_name_list[rss_rank]
      gene_id_list <- gene_id_list[rss_rank]
      motif_list <- motif_list[rss_rank]
      ras <- ras[rss_rank,]
      if (length(rss_rank) == 1){
        originak_ras<- t(as.data.frame(originak_ras))
      } else {
        originak_ras <- originak_ras[rss_rank,]
      }
      rss_list <- rss_list[rss_rank]
      
      
      marker <- lapply(gene_name_list, function(x){
        x[which(x%in%marker_data[,i])]
      })
      # 
      # if(sum(sapply(marker, length))>0){
      #   rss_rank<-order(sapply(marker,length),decreasing=T)
      #   marker <- marker[rss_rank]
      #   rss_list <- rss_list[rss_rank]
      #   gene_name_list <- gene_name_list[rss_rank]
      #   gene_id_list <- gene_id_list[rss_rank]
      #   # put marker genes on top
      #   gene_id_list <- mapply(function(X,Y,Z){
      #     id <- which(Y %in% X)
      #     return(unique(append(Z[id],Z)))
      #   },X=marker,Y=gene_name_list,Z=gene_id_list)
      #   
      #   gene_name_list <- mapply(function(X,Y){
      #     return(unique(append(X,Y)))
      #   },X=marker,Y=gene_name_list)
      #   
      #   motif_list <- motif_list[rss_rank]
      #   ras <- ras[rss_rank,]
      #   originak_ras <- originak_ras[rss_rank,]
      # }
      # 
    } 
    
    #colnames(ras) <- label_data[,1]
    #colnames(originak_ras) <- label_data[,1]
    rownames(originak_ras)
    total_motif_list <- append(total_motif_list,unlist(motif_list))
    rss_pvalue_list <- lapply(rss_list, calc_rss_pvalue,this_bootstrap_rss,i)
    
    for (j in 1:length(gene_name_list)) {
      regulon_tag <- paste("CT",i,"S-R",j,sep = "")
      gene_name_list[[j]] <- append(regulon_tag,gene_name_list[[j]])
      gene_id_list[[j]] <- append(regulon_tag,gene_id_list[[j]])
      motif_list[[j]] <- append(regulon_tag,motif_list[[j]])
      #rss_list[[j]] <- append(regulon_tag,rss_list[[j]])
      rss_list[[j]] <- append(rss_list[[j]],marker[[j]])
    }
    options(stringsAsFactors=FALSE)
    regulon_rank_result <- data.frame()
    for (j in 1:length(gene_name_list)) {
      regulon_tag <- paste("CT",i,"S-R",j,sep = "")
      this_motif_value <- motif_rank[which(motif_rank[,1] == motif_list[[j]][2]),-1]
      this_motif_value <- cbind(regulon_tag,this_motif_value)
      regulon_rank_result <- rbind(regulon_rank_result,this_motif_value)
    }
    
    rownames(originak_ras) <- regulon_rank_result[,1]
    write.table(as.data.frame(originak_ras),paste(jobid,"_CT_",i,"_bic.regulon_activity_score.txt",sep = ""),sep = "\t",col.names = NA,row.names = T,quote = F)
    
    ## calculate rss p-value
    
    #write.table(regulon_rank_result,paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),sep = "\t",col.names = F,row.names = F,quote = F)
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""))
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_gene_id.txt",sep = ""))
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""))
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""))
    for (j in 1:length(gene_name_list)) {
      cat(gene_name_list[[j]],file=paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),append = T,sep = "\t")
      cat("\n",file=paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),append = T)
      
      cat(gene_id_list[[j]],file=paste(jobid,"_CT_",i,"_bic.regulon_gene_id.txt",sep = ""),append = T,sep = "\t")
      cat("\n",file=paste(jobid,"_CT_",i,"_bic.regulon_gene_id.txt",sep = ""),append = T)
      
      cat(motif_list[[j]],file=paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),append = T,sep = "\t")
      cat("\n",file=paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),append = T)
      
      cat(as.character(regulon_rank_result[j,]),file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),append = T,sep = "\t")
      cat("\t",file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),append = T)
      cat(rss_pvalue_list[[j]],file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),append = T,sep = "\t")
      
      cat("\t",file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),append = T)
      cat(rss_list[[j]],file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),append = T,sep = "\t")
      
      cat("\n",file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),append = T)
    }
  } else {
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""))
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_gene_id.txt",sep = ""))
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""))
    cat("",file=paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""))
  }
}
tmp_list <- strsplit(total_motif_list,",")
tmp_list <- lapply(tmp_list, function(x){
  paste("ct",x[1],"bic",x[2],"m",x[3],sep = "")
})

write.table(unlist(tmp_list),"total_motif_list.txt",quote = F,row.names = F,col.names = F)

##.AUC.geneSet_norm <- function(geneSet=genes, rankings=cells_rankings, aucMaxRank=nrow(cells_rankings)*0.05, gSetName="")
##{
##  geneSet <- unique(geneSet)
##  nGenes <- length(geneSet)
##  geneSet <- geneSet[which(geneSet %in% rownames(rankings))]
##  missing <- nGenes-length(geneSet)
##  '%notin%' <- Negate('%in%')
##  gSetRanks <- rankings[which(rownames(rankings) %in% geneSet),,drop=FALSE]
##  other_ranking <- rankings[which(rownames(rankings) %notin% geneSet),,drop=FALSE]
##  
##  rm(rankings)
##  
##  aucThreshold <- round(aucMaxRank)
##  ########### NEW version:  #######################
##  x_th <- 1:nrow(gSetRanks)
##  x_th <- sort(x_th[x_th<aucThreshold])
##  y_th <- seq_along(x_th)
##  maxAUC <- sum(diff(c(x_th, aucThreshold)) * y_th) 
##  ############################################
##  
##  # Apply by columns (i.e. to each ranking)
##  auc <- apply(gSetRanks@assays@.xData$data$ranking, 2, .auc2, aucThreshold, maxAUC)
##  pval_correction <- sgof::BH(auc)
##  adj_pval <-pval_correction$Adjusted.pvalues[order(match(pval_correction$data,auc))]
##  names(adj_pval) <- names(auc)
##  return(c(auc, missing=missing, nGenes=nGenes))
##}
##
##.auc <- function(oneRanking=gSetRanks@assays@.xData$data$ranking[,90], aucThreshold, maxAUC)
##{
##  x <- unlist(oneRanking)[1]
##  y <- seq_along(x)
##  sum(diff(c(x, aucThreshold)) * y)/maxAUC
##}
##
##
##barplot(-1*log10(auc))
##barplot(-1*log10(adj_pval))
##calc_rss(label_data,adj_pval,1)
##
##exp_data[which(rownames(exp_data) == "ANAPC11"),1]
##
##
##
##.AUCell_buildRankings <- function(exprMat=exp_data, plotStats=TRUE, nCores=8, keepZeroesAsNA=FALSE, verbose=TRUE)
##{
##  #### Optional. TODO: test thoroughly!
##  if(keepZeroesAsNA){
##    exprMat[which(exprMat==0, arr.ind=TRUE)] <- NA 
##  }
##  #### 
##  
##  if(!data.table::is.data.table(exprMat))
##    exprMat <- data.table::data.table(exprMat, keep.rownames=TRUE)
##  # TO DO: Replace by sparse matrix??? (e.g. dgTMatrix)
##  data.table::setkey(exprMat, "rn") # (reorders rows)
##  
##  nGenesDetected <- numeric(0)
##  msg <- tryCatch(plotGeneCount(exprMat[,-"rn", with=FALSE], plotStats=plotStats, verbose=verbose),
##                  error = function(e) {
##                    return(e)
##                  })
##  if("error" %in% class(msg)) {
##    warning("There has been an error in plotGeneCount() [Message: ",
##            msg$message, "]. Proceeding to calculate the rankings...", sep="")
##  }else{
##    if(is.numeric(nGenesDetected))
##      nGenesDetected <- msg
##  }
##  
##  colsNam <- colnames(exprMat)[-1] # 1=row names
##  if(nCores==1)
##  {
##    # The rankings are saved in exprMat (i.e. By reference)
##    exprMat[, (colsNam):=lapply(-.SD, data.table::frank, ties.method="random", na.last="keep"),
##            .SDcols=colsNam]
##    
##  }else
##  {
##    # doRNG::registerDoRNG(nCores)
##    doParallel::registerDoParallel()
##    options(cores=nCores)
##    
##    if(verbose)
##      message("Using ", foreach::getDoParWorkers(), " cores.")
##    
##    # Expected warning: Not multiple
##    suppressWarnings(colsNamsGroups <- split(colsNam,
##                                             (seq_along(colsNam)) %% nCores))
##    rowNams <- exprMat$rn
##    
##    colsGr <- NULL
##    "%dopar%"<- foreach::"%dopar%"
##    suppressPackageStartupMessages(exprMat <-
##                                     doRNG::"%dorng%"(foreach::foreach(colsGr=colsNamsGroups,
##                                                                       .combine=cbind),
##                                                      {
##                                                        # Edits by reference: how to make it work in paralell...?
##                                                        subMat <- exprMat[,colsGr, with=FALSE]
##                                                        subMat[, (colsGr):=lapply(-.SD, data.table::frank, ties.method="random", na.last="keep"),
##                                                               .SDcols=colsGr]
##                                                      }))
##    # Keep initial order & recover rownames
##    exprMat <- data.table::data.table(rn=rowNams, exprMat[,colsNam, with=FALSE])
##    data.table::setkey(exprMat, "rn")
##  }
##  
##  rn <- exprMat$rn
##  exprMat <- as.matrix(exprMat[,-1])
##  rownames(exprMat) <- rn
##  
##  # return(matrixWrapper(matrix=exprMat, rowType="gene", colType="cell",
##  #                      matrixType="Ranking", nGenesDetected=nGenesDetected))
##  names(dimnames(exprMat)) <- c("genes", "cells")
##  new("aucellResults",
##      SummarizedExperiment::SummarizedExperiment(assays=list(ranking=exprMat)),
##      nGenesDetected=nGenesDetected)
##}
