
library(tibble)
library(readr)
library(RColorBrewer)
library(Polychrome)
library(ggplot2)
library(scales)
library(Seurat)
suppressPackageStartupMessages(library(jsonlite))

args <- commandArgs(TRUE)
jobid <- args[1] # job id

delim <- args[2] 

if(is.na(delim)){
  delim <- ','
} else if(delim == 'tab'){
  delim <- '\t'
} else if(delim == 'space'){
  delim <- ' '
} else if(delim == 'semicolon'){
  delim <- ';'
}else {
  delim <- ','
}

#jobid <- 20191024223952
#delim <- ','
wd <- paste("/var/www/html/CeRIS/data/",jobid,"/",sep="")
setwd(wd)

info_file <- read_lines("info.txt")

label_file <- strsplit(info_file[grep("labelfile",info_file)],",")[[1]][2]
if (is.na(label_file)){
  label_file <- "1"
}
bic_inference <- gsub("[^0-9]","",strsplit(info_file[grep("bic_inference",info_file)],",")[[1]][2])

if(bic_inference == "1") {
  bic_inference <- "0" 
}

my.object <- readRDS("seurat_obj.rds")

system(paste("Rscript /var/www/html/CeRIS/program/ari_score.R", label_file,jobid, delim,bic_inference,sep=" "))

system(paste("Rscript /var/www/html/iris3/program/prepare_bbc.R", jobid, "12",sep=" "), intern=T)

system(paste("Rscript /var/www/html/iris3/program/sort_regulon.R",wd, jobid,sep=" "), intern=T)

system(paste("Rscript /var/www/html/CeRIS/program/generate_rss_scatter.R", jobid,sep=" "), intern=T)

system(paste("/var/www/html/iris3/program/get_atac_overlap.sh", wd,sep=" "), intern=T)

system(paste("Rscript /var/www/html/iris3/program/prepare_heatmap.R", wd,jobid, bic_inference,sep=" "), intern=T)

system(paste("Rscript /var/www/html/CeRIS/program/get_alternative_regulon.R ",jobid,sep=" "), intern=T)

system(paste("/var/www/html/iris3/program/build_clustergrammar.sh", wd,jobid, bic_inference,sep=" "), intern=T)


cat("\nk_arg,20\n", file=paste("info.txt",sep=""),append = T)


if (!file.exists(paste(jobid,"_marker_genes.json",sep=""))){
  
## get marker genes
my.cluster<-as.character(sort(unique(as.numeric(Idents(my.object)))))
my.marker<-FindAllMarkers(my.object,only.pos = T)
#my.marker <- read.table(paste(jobid,"_marker_genes.txt",sep=""),header=T)
my.top<-c()
for( i in 1:length(my.cluster)){
  my.cluster.data.frame<-my.marker[my.marker$cluster==my.cluster[i],]
  my.top.tmp<-list(my.cluster.data.frame$gene[1:100])
  my.top<-append(my.top,my.top.tmp)
}
names(my.top)<-paste0("CT",my.cluster)
my.top<-as.data.frame(my.top)
write.table(my.marker,paste(jobid,"_marker_genes.txt",sep=""),quote = F,col.names = T,row.names = F)

## save marker genes to json format, used in result page
my.marker_json <- list(NULL)
names(my.marker_json) <- 'data'
colnames(my.marker) <- NULL
my.marker[,6] <- paste("CT",my.marker[,6],sep = "")
my.marker <- my.marker[,c(6,7,1:5)]
my.marker_json$data <- my.marker
my.marker_json <- toJSON(my.marker_json,pretty = T, simplifyDataFrame =F)
write(my.marker_json, paste(jobid,"_marker_genes.json",sep=""))


sort_column <- function(df) {
  tmp <- colnames(df)
  split <- strsplit(tmp, "CT") 
  split <- as.numeric(sapply(split, function(x) x <- sub("", "", x[2])))
  return(order(split))
}

dir.create("regulon_id",showWarnings = F)
my.top <- my.top[,sort_column(my.top)]
write.table(my.top,file = "cell_type_unique_marker.txt",quote = F,row.names = F,sep = "\t")

}

quiet <- function(x) {
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 

Plot.cluster2D <- function(reduction.method="umap",customized=T,pt_size=1,reverse_color=F,...){
  # my.plot.source<-GetReduceDim(reduction.method = reduction.method,module = module,customized = customized)
  # my.module.mean<-colMeans(my.gene.module[[module]]@assays$RNA@data)
  # my.plot.source<-cbind.data.frame(my.plot.source,my.module.mean)
  
  if(customized==F){
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=as.factor(as.numeric(my.object$seurat_clusters)))
  } else{
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=Idents(my.object))
  }
  tmp.celltype <- levels(unique(my.plot.all.source$Cell_type))
  
  if(length(tmp.celltype) > 30) {
    color_array <- as.character(rainbow(length(tmp.celltype)))
  } else {
    color_array <- as.character(palette36.colors(36))[-2]
  }
  if (reverse_color == T) {
    color_array <- rev(color_array)
  }
  
  p.cluster <- ggplot(my.plot.all.source,
                      aes(x=my.plot.all.source[,1],y=my.plot.all.source[,2])) + 
    xlab(colnames(my.plot.all.source)[1])+ylab(colnames(my.plot.all.source)[2]) + 
    geom_point(stroke=pt_size,size=pt_size,aes(col=my.plot.all.source[,"Cell_type"])) + 
    guides(colour = guide_legend(override.aes = list(size=5))) + 
    scale_colour_manual(name  ="Cell type:(Cells)",values  = color_array[1:length(tmp.celltype)],
                        breaks=tmp.celltype,
                        labels=paste0(tmp.celltype,":(",as.character(summary(my.plot.all.source$Cell_type)),")")) +
    theme_classic() + 
    coord_fixed(ratio=1)
  return(p.cluster)
}


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

Get.cluster.Trajectory<-function(customized=T,start.cluster=NULL,end.cluster=NULL,...){
  #labeling cell
  if(customized==TRUE){
    tmp.cell.type<-my.object$Customized.idents
  }
  if(customized==FALSE){
    tmp.cell.type<-as.character(my.object$seurat_clusters)
  }
  tmp.cell.name.index<-match(colnames(my.trajectory),colnames(my.object))
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
       pch=20,frame.plot = FALSE,
       asp=1)
  #grid()
  tmp.color.cat<-cbind.data.frame(CellName=as.character(tmp.trajectory.cluster$cell.label),
                                  Color=my.classification.color[as.factor(tmp.trajectory.cluster$cell.label)])
  tmp.color.cat<-tmp.color.cat[!duplicated(tmp.color.cat$CellName),]
  tmp.color.cat<-tmp.color.cat[order(as.numeric(tmp.color.cat$CellName)),]
  # add legend
  if(length(tmp.color.cat$CellName)>10){
    legend("topright",legend = tmp.color.cat$CellName,
           inset=c(0.1,0), ncol=2,
           col = tmp.color.cat$Color,pch = 20,
           cex=0.8,title="cluster",bty='n')
  } else {legend("topright",legend = tmp.color.cat$CellName,
                 inset=c(0.1,0), ncol=1,
                 col = tmp.color.cat$Color,pch = 20,
                 cex=0.8,title="cluster",bty='n')}
  
  
  if(add.line==T){
    lines(SlingshotDataSet(tmp.trajectory.cluster), 
          lwd=1,pch=3, col=alpha('black',0.7),
          type="l",show.constraints=show.constraints)
  }
  reset_par()
}


# point size function from test datasets
x <- c(0,90,124,317,1000,2368,3005,4816,8298,50000,500000,5000000)
y <- c(1,1,0.89,0.33,0.30,0.25,0.235,0.205,0.18,0.1,0.1,0.1)
get_point_size <- approxfun(x, y)

pt_size <- get_point_size(ncol(my.object)) 
png(paste("regulon_id/overview_ct.png",sep = ""),width=2000, height=1500,res = 300)
Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size)
quiet(dev.off())


png(width=2000, height=1500,res = 300, file=paste("regulon_id/overview_predict_ct.png",sep = ""))
Plot.cluster2D(reduction.method = "umap",customized = F, pt_size = pt_size, reverse_color = T)
quiet(dev.off())

pdf(file = paste("regulon_id/overview_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
Plot.cluster2D(reduction.method = "umap",customized = T)
quiet(dev.off())

pdf(file = paste("regulon_id/overview_predict_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
Plot.cluster2D(reduction.method = "umap",customized = F, reverse_color = T)
quiet(dev.off())

png(paste("regulon_id/overview_provide_ct.png",sep = ""),width=2000, height=1500,res = 300)
Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size, reverse_color = F)
quiet(dev.off())

pdf(file = paste("regulon_id/overview_provide_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
Plot.cluster2D(reduction.method = "umap",customized = T, reverse_color = F)
quiet(dev.off())

if (bic_inference =='2'){
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delim)
  ## check if user's label has valid number of rows, if not just use predicted value
  original_cell_info <- as.factor(cell_info[,2])
  #cell_info[,2] <- as.numeric(as.factor(cell_info[,2]))
  cell_info[,2] <- as.factor(cell_info[,2])
  rownames(cell_info) <- cell_info[,1]
  tmp_names <- cell_info[,1]
  cell_info <- cell_info[,-1]
  names(cell_info) <- tmp_names
  my.object<-AddMetaData(my.object,as.factor(cell_info),col.name = "Customized.idents")
  Idents(my.object)<-as.factor(my.object$Customized.idents)
  table(as.factor(my.object$Customized.idents))
  
  png(paste("regulon_id/overview_provide_ct.png",sep = ""),width=2000, height=1500,res = 300)
  print(Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size, reverse_color = F))
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/overview_provide_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  print(Plot.cluster2D(reduction.method = "umap",customized = T, reverse_color = F))
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/overview_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  print(Plot.cluster2D(reduction.method = "umap",customized = T))
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/overview_predict_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  print(Plot.cluster2D(reduction.method = "umap",customized = F, reverse_color = T))
  quiet(dev.off())
} 

if (label_use_sc3 =='1'){
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delim)
  ## check if user's label has valid number of rows, if not just use predicted value
  original_cell_info <- as.factor(cell_info[,2])
  #cell_info[,2] <- as.numeric(as.factor(cell_info[,2]))
  cell_info[,2] <- as.factor(cell_info[,2])
  rownames(cell_info) <- cell_info[,1]
  tmp_names <- cell_info[,1]
  cell_info <- cell_info[,-1]
  names(cell_info) <- tmp_names
  my.object<-AddMetaData(my.object,as.factor(cell_info),col.name = "Customized.idents")
  Idents(my.object)<-as.factor(my.object$Customized.idents)
  table(as.factor(my.object$Customized.idents))
  png(paste("regulon_id/overview_provide_ct.png",sep = ""),width=2000, height=1500,res = 300)
  Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size, reverse_color = T)
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/overview_provide_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  Plot.cluster2D(reduction.method = "umap",customized = T, reverse_color = T)
  quiet(dev.off())
} 

library(slingshot)
library(Seurat)
library(SummarizedExperiment)
suppressPackageStartupMessages(library(destiny))
my.trajectory <- readRDS("trajectory_obj.rds")
#my.object <- readRDS("seurat_obj.rds")

png(paste("regulon_id/overview_ct.trajectory.png",sep = ""),width=2000, height=1500,res = 300)
Plot.Cluster.Trajectory(customized= T,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)
quiet(dev.off())

pdf(file = paste("regulon_id/overview_ct.trajectory.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
Plot.Cluster.Trajectory(customized= T,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)
quiet(dev.off())


################################################################################# trajectory
system(paste("rm ",jobid,".zip",sep=""))
system(paste("zip -R ",wd,"/",jobid," '*.regulon_gene_id.txt' '*.regulon_gene_symbol.txt' '*.regulon_rank.txt' '*.regulon_activity_score.txt' '*_cell_label.txt' '*.blocks' '*_blocks.conds.txt' '*_blocks.gene.txt' '*_filtered_expression.txt' '*_gene_id_name.txt' '*_marker_genes.txt' 'cell_type_unique_marker.txt' '*_combine_regulon.txt'",sep=""))

quiet(system("chmod -R 777 ."))

cat("\014")

