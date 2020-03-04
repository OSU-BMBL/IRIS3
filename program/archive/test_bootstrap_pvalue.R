
########## Sort regulon by regulon specificity score ##################
# used files:
# filtered exp matrix
# cell label
# regulon_gene_symbol, regulon_gene_id, regulon_motif, motif_ranks (from merge_bbc.R)
#library(microbenchmark)
library(scales)
library(sgof)
require (reshape)
require (ggplot2)
require (tidyverse)
args <- commandArgs(TRUE)
wd <- args[1] # filtered expression file name
jobid <- args[2] # user job id

load_test_data <- function(){
  rm(list = ls(all = TRUE))
  # setwd("/var/www/html/iris3/data/2019083104715")
  wd <- "/var/www/html/iris3/data/20190915164515"
  jobid <- "20190915164515"
  setwd(wd)
}
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
  rankings <- expr[, (colsNam):=lapply(-.SD, data.table::frankv,order=-1L, ties.method="max", na.last="keep"),
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
normalize_ras <- function(score_vec){
  #normalize score_vec(regulon activity score) to range(0,1) and sum=1
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

calc_rss_pvalue <- function(this_rss=0.29828905,this_bootstrap_rss,ct=5){
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


calc_bootstrap_rss <- function(boot_ras,ct){
  this_rss <- as.numeric(calc_rss(label_data=label_data,score_vec = boot_ras,num_ct = ct))
  return(this_rss)
}
total_ct <- max(na.omit(as.numeric(stringr::str_match(list.files(path = wd), "_CT_(.*?)_bic")[,2])))

exp_data <- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
exp_data <- as.matrix(exp_data)

label_data <- read.table(paste(jobid,"_cell_label.txt",sep = ""),sep="\t",header = T)
label_data <- label_data[which(label_data[,2] == c(5,7)),]
exp_data <- exp_data[,which(colnames(exp_data) %in% label_data1[,1])]
marker_data <- read.table("cell_type_unique_marker.txt",sep="\t",header = T)
total_motif_list <- vector()
total_gene_list <- vector()
total_gene_index <- 1
#i=2
## to speed up gsva process, read all genes  to one list
#for (i in 1:total_ct) {
  for (i in c(5,7)) {
  regulon_gene_name_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),"r")
  regulon_gene_name <- readLines(regulon_gene_name_handle)
  close(regulon_gene_name_handle)
  total_gene_list <- append(total_gene_list,regulon_gene_name)
} 
print(Sys.time())
total_gene_list <- lapply(strsplit(total_gene_list,"\\t"), function(x){x[-1]})
#total_gene_list <- total_gene_list[1:10]
#total_ras <- calc_ras(expr = exp_data,genes=total_gene_list,method = "wmw_test")
rankings <- calc_ranking(exp_data)
total_ras <- calc_ras(expr = exp_data1,genes=total_gene_list,method = "wmw_test",rankings = rankings)

regulon_size <- 10
iteration <- 10000

library(foreach)
library(doParallel)
registerDoParallel(8)  # use multicore, set to the number of our cores


ras <- calc_bootstrap_ras(rankings,iteration,regulon_size)

norm_bootstrap_ras <- normalize_ras(ras)

##### Test performance enable parallel RSS
#microbenchmark(
#  rss<-foreach (i=1:total_ct) %dopar% {
#    calc_bootstrap_rss(ras,i)
#  },
#  rss <- sapply(seq(1:total_ct), function(x){
#    return(calc_bootstrap_rss(ras,x))
#  }),
#  times = 1
#)

bootstrap_rss <- sapply (1:total_ct, function(x){
  calc_bootstrap_rss(norm_bootstrap_ras,x)
})
colnames(bootstrap_rss) <- as.character(seq(1:total_ct))

bootstrap_rss <- as_tibble(as.matrix(bootstrap_rss))
bootstrap_rss <- gather(bootstrap_rss,CT,RSS) 

#ggplot(bootstrap_rss, aes(x=RSS,color=CT,fill=CT))+theme_bw() + geom_density(alpha=0.25)+ ggtitle(paste("Bootstrap RSS Density plot\nRegulon size:",regulon_size,"iteration:",iteration))

this_rss <- 0.40658853
this_ct <- "CT4"

res1 <- rss %>%
  as.tibble()%>%
  filter(CT==this_ct)%>%
  pull(RSS)
#%>%filter(cume_dist(RSS) > this_rss)
