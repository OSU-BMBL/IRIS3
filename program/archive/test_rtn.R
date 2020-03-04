library(AUCell)
library(RTNsurvival)
library(scales)
library(viper)
library(Fletcher2013b)
library(GSVA)
library(singscore)
library(ggplot2)
exp_data<- read.delim(paste(jobid,"_filtered_expression.txt",sep = ""),check.names = FALSE, header=TRUE,row.names = 1)
rankData <- rankGenes(exp_data, tiesMethod = "max" )
plot(density(as.matrix(exp_data)))
colnames(tgfb_expr_10_se)
head(rankData[,2,drop = FALSE])
cells_rankings <- AUCell_buildRankings(as.matrix(exp_data),plotStats = F) 

barplot(cells_rankings@assays@.xData$`.->data`$ranking[,1])
genes <- c("ANAPC11","APLP2","ATP6V1C2","DHCR7","GSPT1","HDGF","HMGA1")
aucRanks <- cells_rankings[which(rownames(cells_rankings) %in% genes),,drop=FALSE]
ssRanks <- rankData[which(rownames(rankData) %in% genes),,drop=FALSE]
barplot(ssRanks[,1])
barplot(aucRanks@assays@.xData$`.->data`$ranking[,1])

data(c2BroadSets)
gene.sets <- list(genes)

geneSets <- list(set1=paste(genes,  sep=""))



auc_auc <- .AUC.geneSet_norm(genes,rankings = as.data.frame(cells_rankings@assays@.xData$data$ranking),aucMaxRank=nrow(cells_rankings)*0.05)
df <- as.data.frame(auc_auc)
df[,2] <- rownames(df)
ggplot(data=df,aes(x=V2,y=auc_auc))+ geom_bar(stat = "identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1.1))

ss_auc <- .AUC.geneSet_norm(genes,rankings = as.data.frame(rankData),aucMaxRank=nrow(cells_rankings))
df <- as.data.frame(ss_auc)
df[,2] <- rownames(df)
ggplot(data=df,aes(x=V2,y=ss_auc))+ geom_bar(stat = "identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1))

ssgsea_score <- gsva(as.matrix(exp_data),gset=geneSets,method="ssgsea")
#ssgsea_auc <- .AUC.geneSet_norm(genes,rankings = as.data.frame(ssgsea_score),aucMaxRank=nrow(cells_rankings))
df <- as.data.frame(t(ssgsea_score))
df[,2] <- rownames(df)
ggplot(data=df,aes(x=V2,y=set1))+ geom_bar(stat = "identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1))


z_score <- gsva(as.matrix(exp_data),gset=genes,method="zscore")
#ssgsea_auc <- .AUC.geneSet_norm(genes,rankings = as.data.frame(ssgsea_score),aucMaxRank=nrow(cells_rankings))
df <- as.data.frame(t(z_score))
df[,57] <- rownames(df)
ggplot(data=df,aes(x=df[,57],y=df[,2]))+ geom_bar(stat = "identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1))

plage_score <- gsva(as.matrix(exp_data),gset=geneSets,method="plage")
#ssgsea_auc <- .AUC.geneSet_norm(genes,rankings = as.data.frame(ssgsea_score),aucMaxRank=nrow(cells_rankings))
df <- as.data.frame(t(plage_score))
df[,2] <- rownames(df)
ggplot(data=df,aes(x=V2,y=set1))+ geom_bar(stat = "identity")+ theme(axis.text.x = element_text(angle = 45, hjust = 1))


.AUC.geneSet_norm <- function(geneSet, rankings, aucMaxRank, gSetName="")
{
  geneSet <- unique(geneSet)
  nGenes <- length(geneSet)
  geneSet <- geneSet[which(geneSet %in% rownames(rankings))]
  missing <- nGenes-length(geneSet)
  
  gSetRanks <- rankings[which(rownames(rankings) %in% geneSet),,drop=FALSE]
  rm(rankings)
  
  aucThreshold <- round(aucMaxRank)
  ########### NEW version:  #######################
  x_th <- 1:nrow(gSetRanks)
  x_th <- sort(x_th[x_th<aucThreshold])
  y_th <- seq_along(x_th)
  maxAUC <- sum(diff(c(x_th, aucThreshold)) * y_th) 
  ############################################
  
  # Apply by columns (i.e. to each ranking)
  auc <- apply(gSetRanks, 2, .auc, aucThreshold, maxAUC)
  
  return(c(auc))
}


# oneRanking <- gSetRanks[,3, with=FALSE]
.auc <- function(oneRanking, aucThreshold, maxAUC)
{
  x <- unlist(oneRanking)
  
  x <- sort(x[x<aucThreshold])
  y <- seq_along(x)
  sum(diff(c(x, aucThreshold)) * y)/maxAUC
}


expr=exp_data
gset.idx.list <- geneSets<-list(r1=genes,r2=genes[-1])
method="gsva"
.gsva <- function(expr, gset.idx.list,
                  method=c("gsva", "ssgsea", "zscore", "plage"),
                  kcdf=c("Gaussian", "Poisson", "none"),
                  rnaseq=T,
                  abs.ranking=FALSE,
                  parallel.sz=0, 
                  parallel.type="SOCK",
                  mx.diff=TRUE,
                  tau=1,
                  kernel=TRUE,
                  ssgsea.norm=TRUE,
                  verbose=TRUE)
{
  if(length(gset.idx.list) == 0){
    stop("The gene set list is empty!  Filter may be too stringent.")
  }
  
  if (method == "ssgsea") {
    if(verbose)
      cat("Estimating ssGSEA scores for", length(gset.idx.list),"gene sets.\n")
    
    return(ssgsea(expr, gset.idx.list, alpha=tau, parallel.sz=parallel.sz,
                  parallel.type=parallel.type, normalization=ssgsea.norm,
                  verbose=verbose))
  }
  
  if (method == "zscore") {
    if (rnaseq)
      stop("rnaseq=TRUE does not work with method='zscore'.")
    
    if(verbose)
      cat("Estimating combined z-scores for", length(gset.idx.list),"gene sets.\n")
    
    return(zscore(expr, gset.idx.list, parallel.sz, parallel.type, verbose))
  }
  
  if (method == "plage") {
    if (rnaseq)
      stop("rnaseq=TRUE does not work with method='plage'.")
    
    if(verbose)
      cat("Estimating PLAGE scores for", length(gset.idx.list),"gene sets.\n")
    
    return(plage(expr, gset.idx.list, parallel.sz, parallel.type, verbose))
  }
  
  if(verbose)
    cat("Estimating GSVA scores for", length(gset.idx.list),"gene sets.\n")
  
  n.samples <- ncol(expr)
  n.genes <- nrow(expr)
  n.gset <- length(gset.idx.list)
  
  es.obs <- matrix(NaN, n.gset, n.samples, dimnames=list(names(gset.idx.list),colnames(expr)))
  colnames(es.obs) <- colnames(expr)
  rownames(es.obs) <- names(gset.idx.list)
  
  if (verbose)
    cat("Computing observed enrichment scores\n")
  es.obs <- compute.geneset.es(expr, gset.idx.list, 1:n.samples,
                               rnaseq=rnaseq, abs.ranking=abs.ranking, parallel.sz=parallel.sz,
                               parallel.type=parallel.type, mx.diff=mx.diff, tau=tau,
                               kernel=kernel, verbose=verbose)
  
  colnames(es.obs) <- colnames(expr)
  rownames(es.obs) <- names(gset.idx.list)
  
  es.obs
}


compute.gene.density <- function(expr, sample.idxs, rnaseq=FALSE, kernel=TRUE){
  n.test.samples <- ncol(expr)
  n.genes <- nrow(expr)
  n.density.samples <- length(sample.idxs)
  
  gene.density <- NA
  if (kernel) {
    A = .C("matrix_density_R",
           as.double(t(expr[ ,sample.idxs, drop=FALSE])),
           as.double(t(expr)),
           R = double(n.test.samples * n.genes),
           n.density.samples,
           n.test.samples,
           n.genes,
           as.integer(rnaseq))$R
    
    gene.density <- t(matrix(A, n.test.samples, n.genes))
  } else {
    gene.density <- t(apply(expr, 1, function(x, sample.idxs) {
      f <- ecdf(x[sample.idxs])
      f(x)
    }, sample.idxs))
    gene.density <- log(gene.density / (1-gene.density))
  }
  
  return(gene.density)	
}

compute.geneset.es <- function(expr, gset.idx.list, sample.idxs, rnaseq=FALSE,
                               abs.ranking, parallel.sz=0, parallel.type="SOCK",
                               mx.diff=TRUE, tau=1, kernel=TRUE, verbose=TRUE){
  num_genes <- nrow(expr)
  if (verbose) {
    if (kernel) {
      if (rnaseq)
        cat("Estimating ECDFs with Poisson kernels\n")
      else
        cat("Estimating ECDFs with Gaussian kernels\n")
    } else
      cat("Estimating ECDFs directly\n")
  }
  gene.density <- compute.gene.density(expr, sample.idxs, rnaseq, kernel)
  
  compute_rank_score <- function(sort_idx_vec){
    tmp <- rep(0, num_genes)
    tmp[sort_idx_vec] <- abs(seq(from=num_genes,to=1) - num_genes/2)
    return (tmp)
  }
  
  rank.scores <- rep(0, num_genes)
  sort.sgn.idxs <- apply(gene.density, 2, order, decreasing=TRUE) # n.genes * n.samples
  
  rank.scores <- apply(sort.sgn.idxs, 2, compute_rank_score)
  
  haveParallel <- .isPackageLoaded("parallel")
  haveSnow <- .isPackageLoaded("snow")
  
  if (parallel.sz > 1 || haveParallel) {
    if (!haveParallel && !haveSnow) {
      stop("In order to run calculations in parallel either the 'snow', or the 'parallel' library, should be loaded first")
    }
    
    if (haveSnow) {  ## use snow
      ## copying ShortRead's strategy, the calls to the 'get()' are
      ## employed to quieten R CMD check, and for no other reason
      makeCl <- get("makeCluster", mode="function")
      parSapp <- get("parSapply", mode="function")
      clEvalQ <- get("clusterEvalQ", mode="function")
      stopCl <- get("stopCluster", mode="function")
      
      if (verbose)
        cat("Allocating cluster\n")
      cl <- makeCl(parallel.sz, type = parallel.type) 
      clEvalQ(cl, library(GSVA))
      if (verbose) {
        cat("Estimating enrichment scores in parallel\n")
        if(mx.diff) {
          cat("Taking diff of max KS.\n")
        } else{
          cat("Evaluting max KS.\n")
        }
      }
      
      m <- t(parSapp(cl, gset.idx.list, ks_test_m,
                     gene.density=rank.scores, 
                     sort.idxs=sort.sgn.idxs,
                     mx.diff=mx.diff, abs.ranking=abs.ranking,
                     tau=tau, verbose=FALSE))
      if(verbose)
        cat("Cleaning up\n")
      stopCl(cl)
      
    } else if (haveParallel) {             ## use parallel
      
      mclapp <- get('mclapply', envir=getNamespace('parallel'))
      detCor <- get('detectCores', envir=getNamespace('parallel'))
      nCores <- detCor()
      options(mc.cores=nCores)
      if (parallel.sz > 0 && parallel.sz < nCores)
        options(mc.cores=parallel.sz)
      
      pb <- NULL
      if (verbose){
        cat("Using parallel with", getOption("mc.cores"), "cores\n")
        assign("progressBar", txtProgressBar(style=3), envir=globalenv()) ## show progress if verbose=TRUE
        assign("nGeneSets", ceiling(length(gset.idx.list) / getOption("mc.cores")), envir=globalenv())
        assign("iGeneSet", 0, envir=globalenv())
      }
      
      m <- mclapp(gset.idx.list, ks_test_m,
                  gene.density=rank.scores,
                  sort.idxs=sort.sgn.idxs,
                  mx.diff=mx.diff, abs.ranking=abs.ranking,
                  tau=tau, verbose=verbose)
      m <- do.call("rbind", m)
      colnames(m) <- colnames(expr)
      
      if (verbose) {
        close(get("progressBar", envir=globalenv()))
      }
    } else
      stop("In order to run calculations in parallel either the 'snow', or the 'parallel' library, should be loaded first")
    
  } else {
    if (verbose) {
      cat("Estimating enrichment scores\n")
      if (mx.diff) {
        cat("Taking diff of max KS.\n")
      } else{
        cat("Evaluting max KS.\n")
      }
    }
    pb <- NULL
    if (verbose){
      assign("progressBar", txtProgressBar(style=3), envir=globalenv()) ## show progress if verbose=TRUE
      assign("nGeneSets", length(gset.idx.list), envir=globalenv())
      assign("iGeneSet", 0, envir=globalenv())
    }
    
    m <- t(sapply(gset.idx.list, ks_test_m, rank.scores, sort.sgn.idxs,
                  mx.diff=mx.diff, abs.ranking=abs.ranking,
                  tau=tau, verbose=verbose))
    
    if (verbose) {
      setTxtProgressBar(get("progressBar", envir=globalenv()), 1)
      close(get("progressBar", envir=globalenv()))
    }
  }
  return (m)
}


ks_test_m <- function(gset_idxs, gene.density, sort.idxs, mx.diff=TRUE,
                      abs.ranking=FALSE, tau=1, verbose=TRUE){
  
  n.genes <- nrow(gene.density)
  n.samples <- ncol(gene.density)
  n.geneset <- length(gset_idxs)
  
  geneset.sample.es = .C("ks_matrix_R",
                         as.double(gene.density),
                         R = double(n.samples),
                         as.integer(sort.idxs),
                         n.genes,
                         as.integer(gset_idxs),
                         n.geneset,
                         as.double(tau),
                         n.samples,
                         as.integer(mx.diff),
                         as.integer(abs.ranking))$R
  
  if (verbose) {
    assign("iGeneSet", get("iGeneSet", envir=globalenv()) + 1, envir=globalenv())
    setTxtProgressBar(get("progressBar", envir=globalenv()),
                      get("iGeneSet", envir=globalenv()) / get("nGeneSets", envir=globalenv()))
  }
  
  return(geneset.sample.es)
}


## ks-test in R code - testing only
ks_test_Rcode <- function(gene.density, gset_idxs, tau=1, make.plot=FALSE){
  
  n.genes = length(gene.density)
  n.gset = length(gset_idxs)
  
  sum.gset <- sum(abs(gene.density[gset_idxs])^tau)
  
  dec = 1 / (n.genes - n.gset)
  
  sort.idxs <- order(gene.density,decreasing=T)
  offsets <- sort(match(gset_idxs, sort.idxs))
  
  last.idx = 0
  values <- rep(NaN, length(gset_idxs))
  current = 0
  for(i in seq_along(offsets)){
    current = current + abs(gene.density[sort.idxs[offsets[i]]])^tau / sum.gset - dec * (offsets[i]-last.idx-1)
    
    values[i] = current
    last.idx = offsets[i]
  }
  check_zero = current - dec * (n.genes-last.idx)
  #if(check_zero > 10^-15){ 
  #	stop(paste=c("Expected zero sum for ks:", check_zero))
  #}
  if(make.plot){ plot(offsets, values,type="l") } 
  
  max.idx = order(abs(values),decreasing=T)[1]
  mx.value <- values[max.idx]
  
  return (mx.value)
}

rndWalk <- function(gSetIdx, geneRanking, j, R, alpha) {
  indicatorFunInsideGeneSet <- match(geneRanking, gSetIdx)
  indicatorFunInsideGeneSet[!is.na(indicatorFunInsideGeneSet)] <- 1
  indicatorFunInsideGeneSet[is.na(indicatorFunInsideGeneSet)] <- 0
  stepCDFinGeneSet <- cumsum((abs(R[geneRanking, j]) * 
                                indicatorFunInsideGeneSet)^alpha) /
    sum((abs(R[geneRanking, j]) *
           indicatorFunInsideGeneSet)^alpha)
  stepCDFoutGeneSet <- cumsum(!indicatorFunInsideGeneSet) /
    sum(!indicatorFunInsideGeneSet)
  walkStat <- stepCDFinGeneSet - stepCDFoutGeneSet
  
  sum(walkStat) 
}

ssgsea <- function(X, geneSets, alpha=0.25, parallel.sz,
                   parallel.type, normalization=TRUE, verbose) {
  
  p <- nrow(X)
  n <- ncol(X)
  
  if (verbose) {
    assign("progressBar", txtProgressBar(style=3), envir=globalenv()) ## show progress if verbose=TRUE
    assign("nSamples", n, envir=globalenv())
    assign("iSample", 0, envir=globalenv())
  }
  
  R <- apply(X, 2, function(x,p) as.integer(rank(x)), p)
  
  haveParallel <- .isPackageLoaded("parallel")
  haveSnow <- .isPackageLoaded("snow")
  
  cl <- makeCl <- parSapp <- stopCl <- mclapp <- detCor <- nCores <- NA
  if (parallel.sz > 1 || haveParallel) {
    if (!haveParallel && !haveSnow) {
      stop("In order to run calculations in parallel either the 'snow', or the 'parallel' library, should be loaded first")
    }
    
    if (!haveParallel) {  ## use snow
      ## copying ShortRead's strategy, the calls to the 'get()' are
      ## employed to quieten R CMD check, and for no other reason
      makeCl <- get("makeCluster", mode="function")
      parSapp <- get("parSapply", mode="function")
      stopCl <- get("stopCluster", mode="function")
      
      if (verbose)
        cat("Allocating cluster\n")
      cl <- makeCl(parallel.sz, type = parallel.type) 
    } else {             ## use parallel
      
      mclapp <- get('mclapply', envir=getNamespace('parallel'))
      detCor <- get('detectCores', envir=getNamespace('parallel'))
      nCores <- detCor()
      options(mc.cores=nCores)
      if (parallel.sz > 0 && parallel.sz < nCores)
        options(mc.cores=parallel.sz)
      if (verbose)
        cat("Using parallel with", getOption("mc.cores"), "cores\n")
    }
  }
  
  es <- sapply(1:n, function(j, R, geneSets, alpha) {
    if (verbose) {
      assign("iSample", get("iSample", envir=globalenv()) + 1, envir=globalenv())
      setTxtProgressBar(get("progressBar", envir=globalenv()),
                        get("iSample", envir=globalenv()) / get("nSamples", envir=globalenv()))
    }
    geneRanking <- order(R[, j], decreasing=TRUE)
    es_sample <- NA
    if (parallel.sz == 1 || (is.na(cl) && !haveParallel))
      es_sample <- sapply(geneSets, rndWalk, geneRanking, j, R, alpha)
    else {
      if (is.na(cl))
        es_sample <- mclapp(geneSets, rndWalk, geneRanking, j, R, alpha)
      else
        es_sample <- parSapp(cl, geneSets, rndWalk, geneRanking, j, R, alpha)
    }
    
    unlist(es_sample)
  }, R, geneSets, alpha)
  
  if (length(geneSets) == 1)
    es <- matrix(es, nrow=1)
  
  if (normalization) {
    ## normalize enrichment scores by using the entire data set, as indicated
    ## by Barbie et al., 2009, online methods, pg. 2
    es <- apply(es, 2, function(x, es) x / (range(es)[2] - range(es)[1]), es)
  }
  
  if (length(geneSets) == 1)
    es <- matrix(es, nrow=1)
  
  rownames(es) <- names(geneSets)
  colnames(es) <- colnames(X)
  
  if (verbose) {
    setTxtProgressBar(get("progressBar", envir=globalenv()), 1)
    close(get("progressBar", envir=globalenv()))
  }
  
  if (!is.na(cl))
    stopCl(cl)
  
  es
}

combinez <- function(gSetIdx, j, Z) sum(Z[gSetIdx, j]) / sqrt(length(gSetIdx))

zscore <- function(X, geneSets, parallel.sz, parallel.type, verbose) {
  
  p <- nrow(X)
  n <- ncol(X)
  
  if (verbose) {
    assign("progressBar", txtProgressBar(style=3), envir=globalenv()) ## show progress if verbose=TRUE
    assign("nSamples", n, envir=globalenv())
    assign("iSample", 0, envir=globalenv())
  }
  
  Z <- t(apply(X, 1, function(x) (x-mean(x))/sd(x)))
  
  haveParallel <- .isPackageLoaded("parallel")
  haveSnow <- .isPackageLoaded("snow")
  
  cl <- makeCl <- parSapp <- stopCl <- mclapp <- detCor <- nCores <- NA
  if (parallel.sz > 1 || haveParallel) {
    if (!haveParallel && !haveSnow) {
      stop("In order to run calculations in parallel either the 'snow', or the 'parallel' library, should be loaded first")
    }
    
    if (!haveParallel) {  ## use snow
      ## copying ShortRead's strategy, the calls to the 'get()' are
      ## employed to quieten R CMD check, and for no other reason
      makeCl <- get("makeCluster", mode="function")
      parSapp <- get("parSapply", mode="function")
      stopCl <- get("stopCluster", mode="function")
      
      if (verbose)
        cat("Allocating cluster\n")
      cl <- makeCl(parallel.sz, type = parallel.type) 
    } else {             ## use parallel
      
      mclapp <- get('mclapply', envir=getNamespace('parallel'))
      detCor <- get('detectCores', envir=getNamespace('parallel'))
      nCores <- detCor()
      options(mc.cores=nCores)
      if (parallel.sz > 0 && parallel.sz < nCores)
        options(mc.cores=parallel.sz)
      if (verbose)
        cat("Using parallel with", getOption("mc.cores"), "cores\n")
    }
  }
  
  es <- sapply(1:n, function(j, Z, geneSets) {
    if (verbose) {
      assign("iSample", get("iSample", envir=globalenv()) + 1, envir=globalenv())
      setTxtProgressBar(get("progressBar", envir=globalenv()),
                        get("iSample", envir=globalenv()) / get("nSamples", envir=globalenv()))
    }
    es_sample <- NA
    if (parallel.sz == 1 || (is.na(cl) && !haveParallel))
      es_sample <- sapply(geneSets, combinez, j, Z)
    else {
      if (is.na(cl))
        es_sample <- mclapp(geneSets, combinez, j, Z)
      else
        es_sample <- parSapp(cl, geneSets, combinez, j, Z)
    }
    
    unlist(es_sample)
  }, Z, geneSets)
  
  if (length(geneSets) == 1)
    es <- matrix(es, nrow=1)
  
  rownames(es) <- names(geneSets)
  colnames(es) <- colnames(X)
  
  if (verbose) {
    setTxtProgressBar(get("progressBar", envir=globalenv()), 1)
    close(get("progressBar", envir=globalenv()))
  }
  
  if (!is.na(cl))
    stopCl(cl)
  
  es
}

rightsingularsvdvectorgset <- function(gSetIdx, Z) {
  s <- svd(Z[gSetIdx, ])
  s$v[, 1]
}

plage <- function(X, geneSets, parallel.sz, parallel.type, verbose) {
  
  p <- nrow(X)
  n <- ncol(X)
  
  if (verbose) {
    assign("progressBar", txtProgressBar(style=3), envir=globalenv()) ## show progress if verbose=TRUE
    assign("nGeneSets", length(geneSets), envir=globalenv())
    assign("iGeneSet", 0, envir=globalenv())
  }
  
  Z <- t(apply(X, 1, function(x) (x-mean(x))/sd(x)))
  
  haveParallel <- .isPackageLoaded("parallel")
  haveSnow <- .isPackageLoaded("snow")
  
  ## the masterDescriptor() calls are disabled since they are not available in windows
  ## they would help to report progress by just one of the processors. now all processors
  ## will reporting progress. while this might not be the right way to report progress in
  ## parallel it should not affect a correct execution and progress should be more or less
  ## being reported to some extent.
  cl <- makeCl <- parSapp <- stopCl <- mclapp <- detCor <- nCores <- NA ## masterDesc <- NA
  if(parallel.sz > 1 || haveParallel) {
    if(!haveParallel && !haveSnow) {
      stop("In order to run calculations in parallel either the 'snow', or the 'parallel' library, should be loaded first")
    }
    
    if (!haveParallel) {  ## use snow
      ## copying ShortRead's strategy, the calls to the 'get()' are
      ## employed to quieten R CMD check, and for no other reason
      makeCl <- get("makeCluster", mode="function")
      parSapp <- get("parSapply", mode="function")
      stopCl <- get("stopCluster", mode="function")
      
      if (verbose)
        cat("Allocating cluster\n")
      cl <- makeCl(parallel.sz, type = parallel.type) 
    } else {             ## use parallel
      
      mclapp <- get('mclapply', envir=getNamespace('parallel'))
      detCor <- get('detectCores', envir=getNamespace('parallel'))
      ## masterDesc <- get('masterDescriptor', envir=getNamespace('parallel'))
      nCores <- detCor()
      options(mc.cores=nCores)
      if (parallel.sz > 0 && parallel.sz < nCores)
        options(mc.cores=parallel.sz)
      if (verbose)
        cat("Using parallel with", getOption("mc.cores"), "cores\n")
    }
  }
  
  if (parallel.sz == 1 || (is.na(cl) && !haveParallel))
    es <- t(sapply(geneSets, function(gset, Z) {
      if (verbose) {
        assign("iGeneSet", get("iGeneSet", envir=globalenv()) + 1, envir=globalenv())
        setTxtProgressBar(get("progressBar", envir=globalenv()),
                          get("iGeneSet", envir=globalenv()) / get("nGeneSets", envir=globalenv()))
      }
      rightsingularsvdvectorgset(gset, Z)
    }, Z))
  else {
    if (is.na(cl)) {
      ## firstproc <- mclapp(as.list(1:(options("mc.cores")$mc.cores)), function(x) masterDesc())[[1]]
      es <- mclapp(geneSets, function(gset, Z) { ##, firstproc) {
        if (verbose) { ## && masterDesc() == firstproc) {
          assign("iGeneSet", get("iGeneSet", envir=globalenv()) + 1, envir=globalenv())
          setTxtProgressBar(get("progressBar", envir=globalenv()),
                            get("iGeneSet", envir=globalenv()) / get("nGeneSets", envir=globalenv()))
        }
        rightsingularsvdvectorgset(gset, Z)
      }, Z) ##, firstproc)
      es <- do.call(rbind, es)
    } else {
      if (verbose)
        message("Progress reporting for plage with a snow cluster not yet implemented")
      
      es <- parSapp(geneSets, function(gset, Z) {
        if (verbose) {
          assign("iGeneSet", get("iGeneSet", envir=globalenv()) + 1, envir=globalenv())
          setTxtProgressBar(get("progressBar", envir=globalenv()),
                            get("iGeneSet", envir=globalenv()) / get("nGeneSets", envir=globalenv()))
        }
        rightsingularsvdvectorgset(gset, Z)
      }, Z)
      es <- do.call(rbind, es)
    }
  }
  
  if (length(geneSets) == 1)
    es <- matrix(es, nrow=1)
  
  rownames(es) <- names(geneSets)
  colnames(es) <- colnames(X)
  
  if (verbose) {
    setTxtProgressBar(get("progressBar", envir=globalenv()), 1)
    close(get("progressBar", envir=globalenv()))
  }
  
  if (!is.na(cl))
    stopCl(cl)
  
  es
}

setGeneric("filterGeneSets", function(gSets, ...) standardGeneric("filterGeneSets"))

setMethod("filterGeneSets", signature(gSets="list"),
          function(gSets, min.sz=1, max.sz=Inf) {
            gSetsLen <- sapply(gSets,length)
            return (gSets[gSetsLen >= min.sz & gSetsLen <= max.sz])	
          })

setMethod("filterGeneSets", signature(gSets="GeneSetCollection"),
          function(gSets, min.sz=1, max.sz=Inf) {
            gSetsLen <- sapply(geneIds(gSets),length)
            return (gSets[gSetsLen >= min.sz & gSetsLen <= max.sz])	
          })

.isPackageLoaded <- function(name) {
  ## Purpose: is package 'name' loaded?
  ## --------------------------------------------------
  (paste("package:", name, sep="") %in% search()) ||
    (name %in% loadedNamespaces())
}

