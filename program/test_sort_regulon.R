
########## Sort regulon by regulon specificity score ##################
# used files:
# filtered exp matrix
# cell label
# regulon_gene_symbol, regulon_gene_id, regulon_motif, motif_ranks (from merge_bbc.R)
#library("ggpubr")
library(scales)
library(sgof)
library(ggplot2)
library(dabestr)
#args <- commandArgs(TRUE)
#wd <- args[1] # filtered expression file name
#jobid <- args[2] # user job id
#wd<-getwd()
####test
jobid <-20190906120624 

wd <- paste("/var/www/html/iris3/data/",jobid,sep="")
#wd <- paste("C:/Users/wan268/Documents/iris3_data/",jobid,sep="")
expFile <- paste(jobid,"_filtered_expression.txt",sep="")
labelFile <- paste(jobid,"_cell_label.txt",sep = "")
# wd <- getwd()
setwd(wd)
total_ct_number <- max(na.omit(as.numeric(stringr::str_match(list.files(path = wd), "_CT_(.*?)_bic")[,2])))


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
  rankings <- expr[, (colsNam):=lapply(-.SD, data.table::frankv,order=-1L, ties.method="random", na.last="keep"),
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
  score_vec <- apply(score_vec, 1, rescale)
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

calc_rss_pvalue <- function(this_rss=0.66,this_bootstrap_rss,ct=1){
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
  boot_ras <- normalize_ras(boot_ras)
  this_rss <- as.numeric(calc_rss(label_data=label_data,score_vec = boot_ras,num_ct = ct))
  return(this_rss)
}


sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
  
}

#alldir <- list.dirs(path = wd)
#alldir <- grep("*_bic$",alldir,value=T)
#alldir <- sort_dir(alldir)
#
#exp_data<- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
#exp_data <- as.matrix(exp_data)

#label_data <- read.table(paste(jobid,"_cell_label.txt",sep = ""),sep="\t",header = T)
#marker_data <- read.table("cell_type_unique_marker.txt",sep="\t",header = T)
total_motif_list <- vector()
total_gene_list <- vector()
total_rank <- vector()
total_gene_index <- 1
#i=1
## to speed up gsva process, read all genes  to one list

for (i in 1:total_ct_number) {
  regulon_gene_name_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_gene_symbol.txt",sep = ""),"r")
  regulon_gene_name <- readLines(regulon_gene_name_handle)
  close(regulon_gene_name_handle)
  
  regulon_rank_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),"r")
  regulon_rank <- readLines(regulon_rank_handle)
  close(regulon_rank_handle)
  
  total_gene_list <- append(total_gene_list,regulon_gene_name)
  total_rank <- append(total_rank,regulon_rank)
}

t1 <- "CT4S-R122"
length(grep("CT3.*?",t1))
length(grep("CT4.*?",t1))
total_gene_list<- lapply(strsplit(total_gene_list,"\\t"), function(x){x[-1]})

##########Scatter plot of rss##############
#total_rss_ct <- strsplit(total_rank,"\\t")
#total_rss_ct <- sapply(total_rss_ct, function(x){
#  if (length(grep("CT4.*?",x[1])) > 0){
#    return(c(x[1],as.numeric(x[5])))
#  }
#})
#df1 <- t(data.frame(score=total_rss_ct[228:352]))
#rownames(df1) <- as.character(df1[,1])
#colnames(df1) <- c("regulon","rss")
#
#
#df1 <- as.data.frame(df1)
#df1[,2] <- as.numeric(df1[,2])
#df1[,1]  <- factor(df1[,1] , levels = df1[,1][order(df1[,2],decreasing = T)])
#df2 <- df1[order(df1[,2],decreasing = T),]
#df2[,1]  <- as.character(df1[,1])
#df2[,1]  <- factor(df2[,1] , levels = df2[,1][order(df2[,2],decreasing = T)])
#rownames(df2) <- as.character(df1[,1])
#p1 <- ggplot(df2, aes(x=regulon, y=rss))+ 
#  geom_point( stat="identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1, size=6,color="#666666"),axis.title.y = element_text(size=12,color="#666666"),strip.text.x = element_text(size=14)) +
#  labs(y="Regulon specificity score",x="Regulon") +
#  theme(legend.title=element_blank())+
#  theme(plot.margin = unit(c(1,1,1,2), "cm")) + scale_y_continuous(breaks=c(0, 0.2, 0.4, 0.6, 0.8,1.0))
#png(paste("scatter.png",sep = ""),width=4000, height=1500,res = 300)
#p1
#quiet(dev.off())
#
########################

total_rank<- lapply(strsplit(total_rank,"\\t"), function(x){x[-1]})

regulon_with_marker_index <- lapply(total_rank, function(x){
  if(length(x) > 5){
    return(T)
  }else{
    return(F)
  }
})

  total_rss <- lapply(total_rank, function(x){
    return(x[5])
  })
  
  #total_ras <- calc_ras(expr = exp_data,genes=total_gene_list,method = "gsva")

  #activity_score <- read.table(paste(jobid,"_CT_",ct,"_bic.regulon_activity_score.txt",sep = ""),row.names = 1,header = T,check.names = F)

  #label_data <- label_data[order(label_data[,2]),]
  
  marker_vec <- ifelse(regulon_with_marker_index == T, "have_marker", "otherwise")
  #total_ras <- normalize_ras(total_ras)
  #ras <- total_ras
  #ras <- normalize_ras(ras)
  
  #rss <- calc_rss(label_data=label_data,score_vec = ras,num_ct = ct)
  df <- as.data.frame(cbind(as.numeric(total_rss),marker_vec))
  df[,1] <- as.numeric(as.vector(df[,1]))
  colnames(df) <- c("value","group")
  
  ###plot markers - non markers
  unpaired_mean_diff <- dabest(df,group, value,
                              idx =  c("have_marker","otherwise"),
                              paired = F,ci=95)
  
  plot(unpaired_mean_diff)
  
  total_regulon_marker_length <- lapply(total_rank, function(x){
    return(length(x)-4)
  })
  total_regulon_pvalue <- lapply(total_rank, function(x){
    return(x[2])
  })
  total_regulon_zscore <- lapply(total_rank, function(x){
    if(x[2] != x[3]) {
      return(x[3])
    } else {
      return(0)
    }
  })
  ##plot correlation number of markers
  df_marker_length <- data.frame(rss=as.numeric(unlist(total_rss)),length=as.numeric(unlist(total_regulon_marker_length)))
  df_marker_length <- df_marker_length[df_marker_length$length>0,]

  #ggscatter(df_marker_length, x = "length", y = "rss", 
  #         add = "reg.line", conf.int = TRUE, 
  #         cor.coef = TRUE, cor.method = "pearson",
  #         xlab = "Number of markers", ylab = "RSS value")
  
  total_regulon_length <- lapply(total_gene_list, function(x){
    return(length(x))
  })
    
    
  #hist(unlist(total_regulon_length),breaks = 50)
  ##plot correlation pvalue-rss
  
  #df_pval_rss <- data.frame(rss=as.numeric(unlist(total_rss)),pval=as.numeric(unlist(total_regulon_pvalue)))
  #df_pval_rss <- df_pval_rss[df_pval_rss$pval>100,]
  #ggscatter(df_pval_rss, x = "pval", y = "rss", 
  #          add = "reg.line", conf.int = TRUE, 
  #          cor.coef = TRUE, cor.method = "pearson",
  #          xlab = "P-value", ylab = "RSS value")
  #
  
  ##plot correlation z-score-rss
  
  #df_zscore_rss <- data.frame(rss=as.numeric(unlist(total_rss)),zscore=as.numeric(unlist(total_regulon_zscore)))
  #df_zscore_rss <- df_zscore_rss[df_zscore_rss$zscore>2,]
  #df_zscore_rss <- df_zscore_rss[df_zscore_rss$zscore<100,]
  #ggscatter(df_zscore_rss, x = "zscore", y = "rss", 
  #          add = "reg.line", conf.int = TRUE, 
  #          cor.coef = TRUE, cor.method = "pearson",
  #          xlab = "Zscore", ylab = "RSS value")
  
  

 # get cell type vector, add 1 if in this cell type
 #ct=1
 #ct_vec_rss <- ifelse(label_data[,2] %in% ct, 0, 1)
 #
 ## also normalize ct_vec to sum=1
 #sum_ct_vec <- sum(ct_vec_rss)
 #ct_vec_rss <- ct_vec_rss/sum_ct_vec
 #jsd_result <- apply(as.data.frame(ras), 1, function(x){
 #  return (calc_jsd(x,ct_vec_rss))
 #})
 ##calculate regulon specificity score (RSS); which defined by converting JSD to a similarity score
 #rss <- 1- sqrt(jsd_result)
#
#
 #ggplot_ras <- data.frame('score'=t(ras))
 #ggplot_ras[,2] <- label_data[,1]
 #ggplot_ras[,3] <- ifelse(label_data[,2] %in% ct, "this_cell_type", "others")
 #ggplot_ras[,4] <- ct_vec_rss
 #ggplot(ggplot_ras, aes(y=X1, x=V2, fill=ct_vec)) + 
 #  geom_bar( stat="identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1, size=12,color="#666666"),axis.title.y = element_text(size=14,color="#666666"),strip.text.x = element_text(size=16)) +
 #  labs(y="Regulon activity score",x="") +
 #  theme(legend.title=element_blank())+
 #  theme(plot.margin = unit(c(1,1,1,2), "cm"))
 #
 #ggplot(ggplot_ras, aes(y=V4, x=V2, fill=ct_vec)) + 
 #  geom_bar( stat="identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1, size=12,color="#666666"),axis.title.y = element_text(size=14,color="#666666"),strip.text.x = element_text(size=16)) +
 #  labs(y="Cell type",x="") +
 #  theme(legend.title=element_blank())+
 #  theme(plot.margin = unit(c(1,1,1,2), "cm"))
 

 #i=1
 ### check rss distribution
 #ras <- total_ras
 #ras <- normalize_ras(ras)
 #for (i in nrow(ras)) {
 #  rss_list <- calc_rss(label_data=label_data,score_vec = ras,num_ct = 1)
 #}
 #
 #barplot(as.matrix(ras[1,]))
 ##
  
  