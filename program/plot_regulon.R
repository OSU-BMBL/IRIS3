#######  Plot regulon ##########
library(RColorBrewer)
library(Polychrome)
library(ggplot2)
library(scales)

#library(Cairo) 

args <- commandArgs(TRUE) 
#setwd("/var/www/html/CeRIS/data/20190913134923")
#setwd("/fs/project/PAS1475/Yuzhou_Chang/CeRIS/test_data/20190830171050")
#srcDir <- getwd()
#id <-"CT1-R1" 
#jobid <- "20200218132456"
srcDir <- args[1]
id <- args[2]
jobid <- args[3]
pt_size <- args[4]

Plot.cluster2D<-function(pt_size=1,...){
  # my.plot.source<-GetReduceDim(reduction.method = reduction.method,module = module,customized = customized)
  # my.module.mean<-colMeans(my.gene.module[[module]]@assays$RNA@data)
  # my.plot.source<-cbind.data.frame(my.plot.source,my.module.mean)
  # my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
  #                                   Cell_type=as.factor(as.numeric(my.object$seurat_clusters)))
  # match cell label embedding
  index.cellLabel_embedding <-match(cell.label$cell_name,rownames(cor.embedding))
  embeding <- cor.embedding[index.cellLabel_embedding,]
  # identical(rownames(embeding),cell.label$cell_name)
  my.plot.all.source <- cbind(embeding,Cell_type = as.factor(cell.label$label))
  tmp.celltype <- levels(unique(my.plot.all.source$Cell_type))
  p.cluster <- ggplot(my.plot.all.source,
                      aes(x=my.plot.all.source[,1],y=my.plot.all.source[,2]))+xlab(colnames(my.plot.all.source)[1])+ylab(colnames(my.plot.all.source)[2])
  p.cluster <- p.cluster+geom_point(stroke=pt_size,size=pt_size,aes(col=my.plot.all.source[,"Cell_type"])) 
  
  p.cluster <- p.cluster + guides(colour = guide_legend(override.aes = list(size=5)))
  
  if (length(tmp.celltype) > 30){
    p.cluster <- p.cluster + scale_colour_manual(name  ="Cell type:(Cells)",values  = as.character(rainbow(length(tmp.celltype))),
                                                 breaks=tmp.celltype,
                                                 labels=paste0(tmp.celltype,":(",as.character(summary(my.plot.all.source$Cell_type)),")"))
  } else {
    p.cluster <- p.cluster + scale_colour_manual(name  ="Cell type:(Cells)",values  = as.character(palette36.colors(36))[-2][1:length(tmp.celltype)],
                                                 breaks=tmp.celltype,
                                                 labels=paste0(tmp.celltype,":(",as.character(summary(my.plot.all.source$Cell_type)),")"))
  }
  
  
  # + labs(col="cell type")           
  p.cluster <- p.cluster + theme_classic() 
  p.cluster <- p.cluster + coord_fixed(ratio=1)
  p.cluster
}


Plot.regulon2D<-function(regulon=regulon_id,pt_size=1, ...){
  my.regulon <- activity_score[regulon,]
  index.regulon_embedding <- match(colnames(activity_score),rownames(cor.embedding))
  embeding <- cor.embedding[index.regulon_embedding,]
  #identical(colnames(activity_score),rownames(embeding))
  
  my.plot.regulon <- cbind(embeding,regulon.score = as.numeric(my.regulon))
  
  
  
  p.regulon <- ggplot(my.plot.regulon, aes(x=my.plot.regulon[,1],y=my.plot.regulon[,2])) + xlab(colnames(my.plot.regulon)[1]) + ylab(colnames(my.plot.regulon)[2])
  p.regulon <- p.regulon + geom_point(stroke=pt_size,size=pt_size,aes(col=my.plot.regulon[,"regulon.score"])) + scale_color_gradient(low = "grey",high = "red")
  # + scale_colour_distiller(palette = "YlOrRd", direction = 1)
  p.regulon <- p.regulon + theme_classic() + labs(col="Regulon\nscore")
  #message("finish!")
  
  p.regulon <- p.regulon + coord_fixed(ratio=1)
  p.regulon
}




quiet <- function(x) {
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 


# point size function from test datasets
x <- c(0,90,124,317,1000,2368,3005,4816,8298,50000,500000,5000000)
y <- c(1,1,0.89,0.33,0.30,0.25,0.235,0.205,0.18,0.1,0.1,0.1)
get_point_size <- approxfun(x, y)

#curve(get_point_size,100,5000)

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

activity_score <- read.table(paste(jobid,"_CT_",regulon_ct,"_bic.regulon_activity_score.txt",sep = ""),row.names = 1,header = T,check.names = F)
#activity_score <- activity_score ^ 1
#activity_score <- as.data.frame(rescale(as.matrix(activity_score),c(1,10)))
num_cells <- ncol(activity_score)

quiet(dir.create("regulon_id",showWarnings = F))
pt_size <- get_point_size(num_cells)

#png(width=2000, height=1500,res = 300, file=paste("regulon_id/overview_ct.png",sep = ""))
#Plot.cluster2D(reduction.method = "umap",customized = T, pt_size = pt_size)
#quiet(dev.off())

if (!file.exists(paste("regulon_id/",id,".png",sep = ""))){
  cell.label <- read.table(paste0(jobid,"_cell_label.txt"),header = T,stringsAsFactors = F)
  cor.embedding <- read.table(paste0(jobid,"_umap_embeddings.txt"),header = T, stringsAsFactors = F)
  rownames(cor.embedding) <- cor.embedding$cell_name
  cor.embedding <- cor.embedding[,c(4,5)]
  png(width=2000, height=1500,res = 300, file=paste("regulon_id/",id,".png",sep = ""))
  print(Plot.regulon2D(cell.type=as.numeric(regulon_ct),regulon=as.numeric(regulon_id), pt_size = pt_size*1.3))
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/",id,".pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  print(Plot.regulon2D(regulon=as.numeric(regulon_id), pt_size = pt_size*3))
  quiet(dev.off())
  
}
#pdf(file = paste("regulon_id/overview_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
#Plot.cluster2D(reduction.method = "umap",customized = T)
#quiet(dev.off())


#emf(file=paste("regulon_id/overview_ct.emf",sep = ""),width=8,height = 6, emfPlus = FALSE)
#Plot.cluster2D(reduction.method = "tsne",customized = T)
#quiet(dev.off())
