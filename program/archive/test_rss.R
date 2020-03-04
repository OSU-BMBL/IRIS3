
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


wd <- "/var/www/html/iris3/data/20191003114503"
jobid <-20191003114503 
setwd(wd)

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


calc_rss_pvalue <- function(this_rss=0.1,this_bootstrap_rss,ct=1){
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




##Input regulon: total cell types; gene lists; and 
total_ct <- 7
total_gene_list <- list(c("ABCC12","ABCG5","ABCG8","ABO","ACAD11","ACTRT1","ADAM11","ADAM19","ADAMTS14","ADAMTS15","ADAMTS17","ADAMTS9","ADCY7","AGBL1","AGPAT4","AGR2","AIG1","ALDH1A2","ALOXE3","ALPK2","ALX3","ANKRD44","ANO2","AOC2","ARHGAP30","ARHGAP33","ARHGAP6","ARHGEF9","ARMC2","B3GNT4"),
                        c("B4GALT6","BCL11B","BDH2","BLK","BMP6","BMPER","BOC","BTBD9","BTG4","C12orf77","C20orf96","C6orf201","CABP5","CACNB4","CADPS2","CALHM1","CALML4","CALN1","CASS4","CCDC102B","CCDC114","CCDC60","CCDC88C","CCNJ","CD163L1","CD99L2","CDH5","CDK15","CDK18","CDKL5","CEND1","CEP120","CGA","CHRNA6","CHRNB4"))

i <- 1 # the regulon belongs to cell type 1

##Input data: Load expression and label data

exp_data<- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
exp_data <- as.matrix(exp_data)
label_data <- read.table(paste(jobid,"_cell_label.txt",sep = ""),sep="\t",header = T)
label_data <- label_data[order(label_data[,1]),]
cell_idx <- as.character(sort(label_data[,1]))
exp_data <- exp_data[,cell_idx]


## input 2 regulon gene list
print(Sys.time())

rankings <- calc_ranking(exp_data)

#### bootstrap resampling to calculate p-value
bootstrap_ras <- calc_bootstrap_ras(rankings=rankings,iteration=10000,regulon_size=40)

bootstrap_rss <- sapply (1:total_ct, function(x){
  norm_bootstrap_ras <- normalize_ras(label_data,bootstrap_ras,x,total_ct = total_ct)
  return(calc_bootstrap_rss(label_data,norm_bootstrap_ras,x))
})
colnames(bootstrap_rss) <- as.character(seq(1:total_ct))

bootstrap_rss <- as_tibble(as.matrix(bootstrap_rss))
bootstrap_rss <- gather(bootstrap_rss,CT,RSS) 

regulon_size=40
iteration=10000
ggplot(bootstrap_rss, aes(x=RSS,color=CT,fill=CT))+theme_bw() + geom_density(alpha=0.25)+ ggtitle(paste("Bootstrap RSS Density plot\nRegulon size:",regulon_size,"iteration:",iteration))

## calculate RSS for this regulon
ras <- calc_ras(expr = exp_data,genes=total_gene_list,method = "wmw_test",rankings = rankings)
ras <- normalize_ras(label_data, ras, num_ct = i,total_ct = total_ct)


this_bootstrap_rss <- bootstrap_rss %>%
    as_tibble()%>%
    dplyr::filter(CT==i)%>%
    pull(RSS)
  
rss_list <- calc_rss(label_data=label_data,score_vec = ras,num_ct = i)
rss_list <- as.list(rss_list)
rss_pvalue_list <- lapply(rss_list, calc_rss_pvalue,this_bootstrap_rss,i)

