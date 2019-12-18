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
#id <-"module1S-R1" 
#jobid <- "20190913134923"
srcDir <- args[1]
id <- args[2]
jobid <- args[3]
pt_size <- args[4]

Plot.cluster2D<-function(reduction.method="umap",customized=T,pt_size=1,...){
  # my.plot.source<-GetReduceDim(reduction.method = reduction.method,module = module,customized = customized)
  # my.module.mean<-colMeans(my.gene.module[[module]]@assays$RNA@data)
  # my.plot.source<-cbind.data.frame(my.plot.source,my.module.mean)
  
  if(customized==F){
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=as.factor(as.numeric(my.object$seurat_clusters)))
  }else{
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=Idents(my.object))
  }
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


Plot.regulon2D<-function(reduction.method="umap",regulon=1,cell.type=1,customized=T,pt_size=1,bic_type = "CT",...){
  #message("plotting regulon ",regulon," of cell type ",cell.type,"...")
  my.plot.regulon<-Get.RegulonScore(reduction.method = reduction.method,
                                    cell.type = cell.type,
                                    regulon = regulon,
                                    customized = customized,
                                    bic_type = bic_type)
  my.plot.regulon <- my.plot.regulon[order(my.plot.regulon$regulon.score),]
  
  # if(!customized){
  #   my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
  #                                        Cell_type=my.object$seurat_clusters)
  #   my.plot.all.source<-my.plot.all.source[,grep("*\\_[1,2,a-z]",colnames(my.plot.all.source))]
  # }else{
  #   my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
  #                                        Cell_type=as.factor(my.object$Customized.idents))
  #   my.plot.all.source<-my.plot.all.source[,grep("*\\_[1,2,a-z]",colnames(my.plot.all.source))]
  # }
  # my.plot.source.matchNumber<-match(rownames(my.plot.all.source),rownames(my.plot.regulon))
  # my.plot.source<-cbind.data.frame(my.plot.all.source,regulon.score=my.plot.regulon[my.plot.source.matchNumber,]$regulon.score)
  p.regulon <- ggplot(my.plot.regulon, aes(x=my.plot.regulon[,1],y=my.plot.regulon[,2])) + xlab(colnames(my.plot.regulon)[1]) + ylab(colnames(my.plot.regulon)[2])
  p.regulon <- p.regulon + geom_point(stroke=pt_size,size=pt_size,aes(col=my.plot.regulon[,"regulon.score"])) + scale_color_gradient(low = "grey",high = "red")
  # + scale_colour_distiller(palette = "YlOrRd", direction = 1)
  p.regulon <- p.regulon + theme_classic() + labs(col="Regulon\nscore")
  #message("finish!")
  
  p.regulon <- p.regulon + coord_fixed(ratio=1)
  p.regulon
}

Generate.Regulon<-function(cell.type=NULL,regulon=1,...){
  x<-Get.CellType(cell.type = cell.type, bic_type=bic_type)
  tmp.regulon<-subset(my.object,cells = colnames(my.object),features = x[[regulon]][-1])
  return(tmp.regulon)
}

Get.CellType<-function(cell.type=NULL,bic_type="CT",...){
  if(!is.null(cell.type)){
    my.cell.regulon.filelist<-list.files(pattern = paste(bic_type,".*bic.regulon_gene_symbol.txt",sep=""))
    my.cell.regulon.indicator<-grep(paste0("_",as.character(cell.type),"_bic"),my.cell.regulon.filelist)
    my.cts.regulon.raw<-readLines(my.cell.regulon.filelist[my.cell.regulon.indicator])
    my.regulon.list<-strsplit(my.cts.regulon.raw,"\t")
    return(my.regulon.list)
  }else{stop("please input a cell type")}
  
}


Get.RegulonScore<-function(reduction.method="tsne",cell.type=1,regulon=1,customized=F,bic_type="CT",...){
  my.regulon.number<-length(Get.CellType(cell.type = cell.type, bic_type=bic_type))
  if (regulon > my.regulon.number){
    stop(paste0("Regulon number exceeds the boundary. Under this cell type, there are total ", my.regulon.number," regulons"))
  } else {
    my.cts.regulon.S4<-Generate.Regulon(cell.type = cell.type,regulon=regulon)
    if(customized){
      my.cell.type<-my.cts.regulon.S4$Customized.idents
      message(c("using customized cell label: ","|", paste0(unique(as.character(my.cts.regulon.S4$Customized.idents)),"|")))
    }else{
      my.cell.type<-as.numeric(my.cts.regulon.S4$seurat_clusters) 
      message(c("using default cell label(seurat prediction): ","|", paste0(unique(as.character(my.cts.regulon.S4$seurat_clusters)),"|")))
    } 
    tmp_data<-as.data.frame(my.cts.regulon.S4@assays$RNA@data)
    geneSets<-list(GeneSet1=rownames(tmp_data))
    #cells_AUC<-AUCell_calcAUC(geneSets,cells_rankings,aucMaxRank = nrow(cells_rankings)*0.1)
    #cells_assignment<-AUCell_exploreThresholds(cells_AUC,plotHist = F,nCores = 1,assign = T)
    #my.auc.data<-as.data.frame(cells_AUC@assays@.xData$data$AUC)
    #my.auc.data<-t(my.auc.data[,colnames(tmp_data)])
    #regulon.score<-colMeans(tmp_data)/apply(tmp_data,2,sd)
    regulon.score<-t(as.matrix(activity_score[regulon,]))
    tmp.embedding<-Embeddings(my.object,reduction = reduction.method)[colnames(my.cts.regulon.S4),][,c(1,2)]
    my.choose.regulon<-cbind.data.frame(tmp.embedding,Cell_type=my.cell.type)
    my.choose.regulon <- cbind(my.choose.regulon, regulon.score=regulon.score[match(rownames(my.choose.regulon), rownames(regulon.score))])
    
    return(my.choose.regulon)
  }
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
  library(Seurat)
  my.object <- readRDS("seurat_obj.rds")
  
  png(width=2000, height=1500,res = 300, file=paste("regulon_id/",id,".png",sep = ""))
  print(Plot.regulon2D(cell.type=as.numeric(regulon_ct),regulon=as.numeric(regulon_id),customized = T,reduction.method="umap", pt_size = pt_size*1.3))
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/",id,".pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  print(Plot.regulon2D(cell.type=as.numeric(regulon_ct),regulon=as.numeric(regulon_id),customized = T,reduction.method="umap", pt_size = pt_size*3))
  quiet(dev.off())
  
}
#pdf(file = paste("regulon_id/overview_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
#Plot.cluster2D(reduction.method = "umap",customized = T)
#quiet(dev.off())


#emf(file=paste("regulon_id/overview_ct.emf",sep = ""),width=8,height = 6, emfPlus = FALSE)
#Plot.cluster2D(reduction.method = "tsne",customized = T)
#quiet(dev.off())
