#######  Plot gene expression value for a gene in tsne map##########


library(RColorBrewer)
library(Polychrome)
library(ggplot2)
#library(monocle)
args <- commandArgs(TRUE) 
#setwd("/var/www/html/CeRIS/data/20190907182105")
#srcDir <- getwd()
#gene_symbol <-"Ccl4" 
#jobid <- "20190907182105"
srcDir <- args[1]
gene_symbol <- args[2]
jobid <- args[3]

Plot.GeneTSNE<-function(gene.name=NULL,pt_size=0.5){
  tmp.gene.expression<- my.object@assays$RNA@data
  tmp.dim<-as.data.frame(my.object@reductions$tsne@cell.embeddings)
  tmp.MatchIndex<- match(colnames(tmp.gene.expression),rownames(tmp.dim))
  tmp.dim<-tmp.dim[tmp.MatchIndex,]
  tmp.gene.name<-paste0("^",gene.name,"$")
  tmp.One.gene.value<-tmp.gene.expression[grep(tmp.gene.name,rownames(tmp.gene.expression)),]
  tmp.dim.df<-cbind.data.frame(tmp.dim,Gene=tmp.One.gene.value)
  g<-ggplot(tmp.dim.df,aes(x=tSNE_1,y=tSNE_2,color=Gene))
  g<-g+geom_point(stroke=pt_size,size=pt_size)+scale_color_gradient(low="grey",high = "red")
  g<-g+theme_classic()+labs(color=paste0(gene.name,"\nexpression\nvalue")) + coord_fixed(1)
  g
}

Plot.GeneUMAP<-function(gene.name=NULL,pt_size=0.5){
  tmp.gene.expression<- my.object@assays$RNA@data
  tmp.dim<-as.data.frame(my.object@reductions$umap@cell.embeddings)
  tmp.MatchIndex<- match(colnames(tmp.gene.expression),rownames(tmp.dim))
  tmp.dim<-tmp.dim[tmp.MatchIndex,]
  tmp.gene.name<-paste0("^",gene.name,"$")
  tmp.One.gene.value<-tmp.gene.expression[grep(tmp.gene.name,rownames(tmp.gene.expression)),]
  tmp.dim.df<-cbind.data.frame(tmp.dim,Gene=tmp.One.gene.value)
  g<-ggplot(tmp.dim.df,aes(x=UMAP_1,y=UMAP_2,color=Gene))
  g<-g+geom_point(stroke=pt_size,size=pt_size) + scale_color_gradient(low="grey",high = "red")
  g<-g+theme_classic()+labs(color=paste0(gene.name,"\nexpression\nvalue")) + coord_fixed(1)
  g
}

Plot.cluster2D<-function(reduction.method="umap",module=1,customized=T,pt_size=1,...){
  # my.plot.source<-GetReduceDim(reduction.method = reduction.method,module = module,customized = customized)
  # my.module.mean<-colMeans(my.gene.module[[module]]@assays$RNA@data)
  # my.plot.source<-cbind.data.frame(my.plot.source,my.module.mean)
  
  if(customized==F){
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=my.object$seurat_clusters)
  }else{
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=as.factor(my.object$Customized.idents))
  }
  tmp.celltype <- as.character(unique(my.plot.all.source$Cell_type))
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




Generate.Regulon<-function(cell.type=NULL,regulon=1,...){
  x<-Get.CellType(cell.type = cell.type)
  tmp.regulon<-subset(my.object,cells = colnames(my.object),features = x[[regulon]][-1])
  return(tmp.regulon)
}

Get.CellType<-function(cell.type=NULL,...){
  if(!is.null(cell.type)){
    my.cell.regulon.filelist<-list.files(pattern = "bic.regulon_gene_symbol.txt")
    my.cell.regulon.indicator<-grep(paste0("_",as.character(cell.type),"_bic"),my.cell.regulon.filelist)
    my.cts.regulon.raw<-readLines(my.cell.regulon.filelist[my.cell.regulon.indicator])
    my.regulon.list<-strsplit(my.cts.regulon.raw,"\t")
    return(my.regulon.list)
  }else{stop("please input a cell type")}
  
}



Get.RegulonScore<-function(reduction.method="tsne",cell.type=1,regulon=1,customized=F,...){
  my.regulon.number<-length(Get.CellType(cell.type = cell.type))
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

setwd(srcDir)


quiet(dir.create("regulon_id",showWarnings = F))


if (!file.exists(paste("regulon_id/",gene_symbol,".umap.pdf",sep = ""))){
  library(Seurat)
  my.object <- readRDS("seurat_obj.rds")
  pt_size <- get_point_size(ncol(my.object))
  
  png(width=2000, height=1500,res = 300, file=paste("regulon_id/",gene_symbol,".umap.png",sep = ""))
  print(Plot.GeneUMAP(gene_symbol,pt_size = pt_size * 1.2))
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/",gene_symbol,".umap.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
  print(Plot.GeneUMAP(gene_symbol,pt_size = pt_size * 3))
  quiet(dev.off())
  
}
#png(paste("regulon_id/overview_ct.png",sep = ""),width=2000, height=1500,res = 300)
#if (!file.exists(paste("regulon_id/overview_ct.png",sep = ""))){
#  if(!exists("my.object")){
#    library(Seurat)
#    my.object <- readRDS("seurat_obj.rds")
#  }
#  num_cells <- ncol(my.object)
#  pt_size <- get_point_size(num_cells)*2
#  Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size)
#}
#quiet(dev.off())