#######  Plot regulon ##########
#
#library(Seurat)
library(RColorBrewer)
library(Polychrome)
library(ggplot2)

args <- commandArgs(TRUE) 
#setwd("D:/IRIS3_data_test/CeRIS_Run/2.Yan/")
#setwd("/var/www/html/iris3/data/20191216203506")
#srcDir <- getwd()
#id <-"CT1S-R1" 
#jobid <- "20191216203506"
#########################################################################################
# yuzhou test
# setwd("/fs/project/PAS1475/Yuzhou_Chang/CeRIS/test_data/11.Klein/20190818121919/")
#srcDir <- getwd()
#id <-"CT1S-R1" 
#jobid <- "2019121412746"
##########################################################################################
srcDir <- args[1]
id <- args[2]
jobid <- args[3]

reset_par <- function(){
  op <- structure(list(xlog = FALSE, ylog = FALSE, adj = 0.5, ann = TRUE,
                       ask = FALSE, bg = "transparent", bty = "o", cex = 1, cex.axis = 1,
                       cex.lab = 1, cex.main = 1.2, cex.sub = 1, col = "black",
                       col.axis = "black", col.lab = "black", col.main = "black",
                       col.sub = "black", crt = 0, err = 0L, family = "", fg = "black",
                       fig = c(0, 1, 0, 1), fin = c(6.99999895833333, 6.99999895833333
                       ), font = 1L, font.axis = 1L, font.lab = 1L, font.main = 2L,
                       font.sub = 1L, lab = c(5L, 5L, 7L), las = 0L, lend = "round",
                       lheight = 1, ljoin = "round", lmitre = 10, lty = "solid",
                       lwd = 1, mai = c(1.02, 0.82, 0.82, 0.42), mar = c(5.1, 4.1,
                                                                         4.1, 2.1), mex = 1, mfcol = c(1L, 1L), mfg = c(1L, 1L, 1L,
                                                                                                                        1L), mfrow = c(1L, 1L), mgp = c(3, 1, 0), mkh = 0.001, new = FALSE,
                       oma = c(0, 0, 0, 0), omd = c(0, 1, 0, 1), omi = c(0, 0, 0,
                                                                         0), pch = 1L, pin = c(5.75999895833333, 5.15999895833333),
                       plt = c(0.117142874574832, 0.939999991071427, 0.145714307397962,
                               0.882857125425167), ps = 12L, pty = "m", smo = 1, srt = 0,
                       tck = NA_real_, tcl = -0.5, usr = c(0.568, 1.432, 0.568,
                                                           1.432), xaxp = c(0.6, 1.4, 4), xaxs = "r", xaxt = "s", xpd = FALSE,
                       yaxp = c(0.6, 1.4, 4), yaxs = "r", yaxt = "s", ylbias = 0.2), .Names = c("xlog",
                                                                                                "ylog", "adj", "ann", "ask", "bg", "bty", "cex", "cex.axis",
                                                                                                "cex.lab", "cex.main", "cex.sub", "col", "col.axis", "col.lab",
                                                                                                "col.main", "col.sub", "crt", "err", "family", "fg", "fig", "fin",
                                                                                                "font", "font.axis", "font.lab", "font.main", "font.sub", "lab",
                                                                                                "las", "lend", "lheight", "ljoin", "lmitre", "lty", "lwd", "mai",
                                                                                                "mar", "mex", "mfcol", "mfg", "mfrow", "mgp", "mkh", "new", "oma",
                                                                                                "omd", "omi", "pch", "pin", "plt", "ps", "pty", "smo", "srt",
                                                                                                "tck", "tcl", "usr", "xaxp", "xaxs", "xaxt", "xpd", "yaxp", "yaxs",
                                                                                                "yaxt", "ylbias"))
  par(op)
}

Get.cluster.Trajectory<-function(start.cluster=NULL,end.cluster=NULL,...){
  #labeling cell
  tmp.cell.type<-cell.label$label
  
  tmp.cell.name.index<-match(colnames(my.trajectory),cell.label$cell_name)
  tmp.cell.type<-tmp.cell.type[tmp.cell.name.index]
  colData(my.trajectory)$cell.label<-tmp.cell.type
  # run trajectory, first run the lineage inference
  my.trajectory <- slingshot(my.trajectory, clusterLabels = 'cell.label', reducedDim = 'DiffMap',
                             start.clus=start.cluster,end.clus=end.cluster)
  #summary(my.trajectory$slingPseudotime_1)
  return(my.trajectory)
}


Plot.Cluster.Trajectory<-function(customized=T,add.line=TRUE,start.cluster=NULL,end.cluster=NULL,show.constraints=F,...){
  tmp.trajectory.cluster<-Get.cluster.Trajectory(customized = customized,start.cluster=start.cluster,end.cluster=end.cluster)
  my.classification.color<-as.character(palette36.colors(36))[-2]
  par(mar=c(3.1, 3.1, 2.1, 5.1), xpd=TRUE)
  plot(reducedDims(tmp.trajectory.cluster)$DiffMap,
       col=alpha(my.classification.color[as.factor(tmp.trajectory.cluster$cell.label)],0.7),
       pch=20,frame.plot = FALSE,cex=(3/log(ncol(tmp.trajectory.cluster))),
       asp=1)
  #grid()
  tmp.color.cat<-cbind.data.frame(CellName=as.character(tmp.trajectory.cluster$cell.label),
                                  Color=my.classification.color[as.factor(tmp.trajectory.cluster$cell.label)])
  tmp.color.cat<-tmp.color.cat[!duplicated(tmp.color.cat$CellName),]
  tmp.color.cat<-tmp.color.cat[order(as.numeric(as.character(tmp.color.cat$CellName))),]
  # add legend
  if(length(tmp.color.cat$CellName)>10){
    legend("topright",legend = tmp.color.cat$CellName,
           inset=c(-0.05,0), ncol=2,
           col = as.character(tmp.color.cat$Color),pch = 19,
           cex=1.0,title="Cell type",bty='n')
  } else {legend("topright",legend = tmp.color.cat$CellName,
                 inset=c(-0.05,0), ncol=1,
                 col = as.character(tmp.color.cat$Color),pch = 19,
                 cex=1.0,title="Cell type",bty='n')}
  
  
  if(add.line==T){
    lines(SlingshotDataSet(tmp.trajectory.cluster), 
          lwd=1,pch=3, col=alpha('black',0.7),
          type="l",show.constraints=show.constraints)
  }
  reset_par()
}


Plot.Regulon.Trajectory<-function(regulon=1,start.cluster=NULL,end.cluster=NULL,bic_type = "CT",...){
  # get trajectary object which contains cell type, diffusion map info.
  tmp.trajectory.cluster<-Get.cluster.Trajectory(customized = customized,start.cluster=start.cluster,end.cluster=end.cluster)
  # get regulon score
  my.regulon <- activity_score[regulon,]
  tmp.cell.name<-colnames(tmp.trajectory.cluster)
  tmp.cell.name.index<-match(tmp.cell.name,names(my.regulon))
  val<-as.numeric(my.regulon)[tmp.cell.name.index]

  #
  
  layout(matrix(1:2,nrow=1),widths=c(0.7,0.3))
  grPal <- colorRampPalette(c("grey","red"))
  tmp.color<-grPal(10)[as.numeric(cut(val,breaks=10))]
  
  par(mar=c(5.1,2.1,1.1,2.1))
  plot(reducedDims(tmp.trajectory.cluster)$DiffMap,
       col=alpha(tmp.color,0.7),cex=(3/log(nrow(tmp.trajectory.cluster))),
       pch=20,frame.plot = FALSE,
       asp=1)
  lines(SlingshotDataSet(tmp.trajectory.cluster))
  #grid()
  xl <- 1
  yb <- 1
  xr <- 1.5
  yt <- 2
  
  par(mar=c(15.1,1.1,1.1,5.1))
  plot(NA,type="n",ann=F,xlim=c(1,2),ylim=c(1,2),xaxt="n",yaxt="n",bty="n")
  rect(
    xl,
    head(seq(yb,yt,(yt-yb)/50),-1),
    xr,
    tail(seq(yb,yt,(yt-yb)/50),-1),
    col=grPal(50),border=NA
  )
  
  my.Q<-round(as.numeric(quantile(val)),0)
 
  tmp.cor<-seq(yb,yt,(yt-yb)/50)
  mtext("Relugon Score", cex=1,side=1)
  mtext(c(
    paste0("min:",my.Q[1]),
    paste0("25%Q:",my.Q[2]),
    paste0("median:",my.Q[3]),
    paste0("75%Q:",my.Q[4]),
    paste0("max:",my.Q[5])
  ),
        at=c(tmp.cor[5],tmp.cor[15],tmp.cor[25],tmp.cor[35],tmp.cor[45]),
        side=2,las=1,cex=0.7)
  reset_par()
  
}



quiet <- function(x) {
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 

setwd(srcDir)

regulon_ct <-gsub( "-.*$", "", id)
regulon_ct <-gsub("[[:alpha:]]","",regulon_ct)
regulon_id <- gsub( ".*R", "", id)
regulon_id <- gsub("[[:alpha:]]","",regulon_id)
if (substr(id,1,2) == "mo") {
  bic_type <- "module"
} else {
  bic_type <- "CT"
}



if (!file.exists(paste("regulon_id/",id,".trajectory.png",sep = ""))){
  activity_score <- read.table(paste(jobid,"_CT_",regulon_ct,"_bic.regulon_activity_score.txt",sep = ""),row.names = 1,header = T,check.names = F)
  cell.label <- read.table(paste0(jobid,"_cell_label.txt"),header = T,stringsAsFactors = F)
  library(slingshot)
  library(SummarizedExperiment)
  suppressPackageStartupMessages(library(destiny))
  my.trajectory <- readRDS("trajectory_obj.rds")
  png(paste("regulon_id/",id,".trajectory.png",sep = ""),width=2000, height=1500,res = 300)
  reset_par()
  Plot.Regulon.Trajectory(cell.type = as.numeric(regulon_ct),regulon = as.numeric(regulon_id),start.cluster = NULL,end.cluster = NULL,customized = T, bic_type = bic_type)
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/",id,".trajectory.pdf",sep = ""), width = 10, height = 10,  pointsize = 18, bg = "white")
  reset_par()
  Plot.Regulon.Trajectory(cell.type = as.numeric(regulon_ct),regulon = as.numeric(regulon_id),start.cluster = NULL,end.cluster = NULL,customized = T, bic_type = bic_type)
  quiet(dev.off())
  
}
