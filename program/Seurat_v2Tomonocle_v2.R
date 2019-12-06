# set working directory, you may change the directory first.
setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/2.Yan/")
# loading required packege
# loading Seurat version 2, you need reinstall the version 2

library(Seurat, lib.loc="~/R/Seurat/Seurat2.3/")
if(!require(hdf5r)) {
  install.packages("hdf5r")
} 

if(!require(Matrix)) {
  install.packages("Matrix")
}
if(!require(plotly)){
  install.packages("plotly")
}
if (!require("RColorBrewer")) {
  install.packages("RColorBrewer")
}
if (!require("Polychrome")) {
  install.packages("Polychrome")
  library(Polychrome)
}
if (!require("AUCell")) {
  BiocManager::install("AUCell")
  library(AUCell)
}
if (!require("dplyr")) {
  install.packages("dplyr")
  library(dplyr)
}
# require monocle2
library(monocle)
if(!require("Linnorm")){
  BiocManager::install("Linnorm")
}
# import monocle version2
if(!require("monocle")){
  source("http://bioconductor.org/biocLite.R")
  BiocManager::install("monocle")
}
if(!require("Rmagic")){
  install.packages("Rmagic")
}
#pre-optional
options(stringsAsFactors = F)
options(check.names = F)
##############################
# define a fucntion for reading in 10X hd5f data and cell gene matrix by input (TenX) or (CellGene)
read_data<-function(x=NULL,read.method=NULL,sep="\t",...){
  if(!is.null(x)){
    if(!is.null(read.method)){
      if(read.method !="TenX.h5"&&read.method!="CellGene"&&read.method!="TenX.folder"){
        stop("wrong 'read.method' argument, please choose 'TenX.h5','TenX.folder', or 'CellGene'!")}
      if(read.method == "TenX.h5"){
        tmp_x<-Read10X_h5(x)
        return(tmp_x)
      }else if(read.method =="TenX.folder"){
        tmp_x<-Read10X(x)
        return(tmp_x)
      } else if(read.method == "CellGene"){# read in cell * gene matrix, if there is error report, back to 18 line to run again.
        tmp_x<-read.delim(x,header = T,row.names = 1,check.names = F,sep=sep,...)
        tmp_x<-Matrix(as.matrix(tmp_x),sparse = T)
        return(tmp_x)
      }
    }
  }else {stop("Missing 'x' argument, please input correct data")}
}
#####################  
# rad.data function:#
#####################
# Two input arguments.
# 1. input files are gene(row)*cell(column) matrix, h5 file, and folder which 
#     contains 3 gz files(barcodes.tsv.gz, features.tsv.gz,matrix.mtx.gz)
# 2. input methods selection (3 modes)
#|-----------------|---------------|
#|x                |read.method    |
#|-----------------|---------------|
#|Gene Cell matrix |CellGene       |
#|10X h5df file    |TenX.h5        |
#|10X folder       |TenX.folder    |
#|-----------------|---------------|

#Read in data ###################################################
my.raw.data<-read_data(x = "Biase_expression.csv",sep=",",read.method = "CellGene")
######################################################
# create Seurat object
my.object<-CreateSeuratObject(my.raw.data)
# check how many cell and genes
dim(my.object@raw.data)
#####################################################
# get data in terms of "counts"(raw data), "data"(normalized data), "scale.data"(scaling the data)
# neglect quality check, may add on in the future
##################################
# export raw data from seurat object.#
##################################
my.expression.data<-my.object@raw.data
write.table(my.expression.data,
            file = "RNA_RAW_EXPRESSION.txt",
            quote = F,
            sep = "\t")
#################################

# Key part for customizing cell type: 
##############################################
# Add meta info(cell type) to seurat object###
##############################################
setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/2019062485208/")
label_data<-read.delim("Biase_cell_label.csv",sep = "\t",
                       header = T)
# read cell label file
my.meta.info<-read.delim("Biase_cell_label.csv",row.names = 1,
                         sep = ",",header = T,check.names = F,stringsAsFactors = F)
#rownames(my.meta.info)<-paste0(rownames(my.meta.info),"s")

my.idents.index<-match(colnames(my.object@raw.data),rownames(my.meta.info))
Customized.idents<-as.factor(my.meta.info[my.idents.index,1])
my.object@meta.data$Customized.idents<-Customized.idents
# look at current cell type info
my.object@meta.data$Customized.idents
# activate customized cell type info
my.object<-SetIdent(my.object,ident.use = my.object@meta.data$Customized.idents)
############################################## normalize data 
my.unnormalized.data<-GetAssayData(object = my.object,assay.type = "RNA",slot = "raw.data")

my.normalized.data<-
my.object<-SetAssayData(object = my.object,assay.type = "RNA",slot = "data",new.data =my.normalized.data )
######################################################################
my.object<-NormalizeData(my.object,normalization.method = "LogNormalize",scale.factor = 10000)
# find high variable gene
my.object<-FindVariableGenes(my.object,do.plot=F)
# before PCA, scale data to eliminate extreme value affect.
all.gene<-rownames(my.object@raw.data)
my.object<-ScaleData(my.object,genes.use= all.gene)
# after scaling, perform PCA
my.object<-RunPCA(my.object)
###########################################
# CORE part: Run TSNE and UMAP######################
###########################################
my.object<-RunTSNE(my.object,dims.use = 1:10,perplexity=10,do.fast=F)
# find clustering, there will be changing the default cell type, if want to use customized cell type. 
# cluster by KNN enbeded in Seurat
my.object<-FindClusters(my.object)


# input website CTS-R under a specific cell type
# in this example I let my.cts.regulon read in specific cell type 1 
# create gene Module, please provide a creat module format!
# M1  G1  G2.....#
# M2  G3  G4.....#
# M3  G5  G6.....#
#----------------#
# generate regulon
setwd("//fs/project/PAS1475/Yuzhou_Chang/IRIS3/2019062485208/")
Get.CellType<-function(cell.type=NULL,...){
  if(!is.null(cell.type)){
    my.cell.regulon.filelist<-list.files(pattern = "bic.regulon_gene_symbol.txt")
    my.cell.regulon.indicator<-grep(paste0("_",as.character(cell.type),"_bic"),my.cell.regulon.filelist)
    my.cts.regulon.raw<-readLines(my.cell.regulon.filelist[my.cell.regulon.indicator])
    my.regulon.list<-strsplit(my.cts.regulon.raw,"\t")
    return(my.regulon.list)
  }else{stop("please input a cell type")}
  
}
Get.CellType(cell.type = 1,regulon=1)

Generate.Regulon<-function(cell.type=NULL,regulon=1,...){
  x<-Get.CellType(cell.type = cell.type)
  my.rowname<-rownames(my.object@data)
  gene.index<-sapply(x[[regulon]][-1],function(x) grep(paste0("^",x,"$"),my.rowname))
  # my.object@data stores normalized data
  tmp.regulon<-my.object@data[,][gene.index,]
  return(tmp.regulon)
}
Generate.Regulon(cell.type = 1,regulon = 1)

##############################

Plot.cluster2D<-function(customized=F,...){
  # my.plot.source<-GetReduceDim(reduction.method = reduction.method,module = module,customized = customized)
  # my.module.mean<-colMeans(my.gene.module[[module]]@assays$RNA@data)
  # my.plot.source<-cbind.data.frame(my.plot.source,my.module.mean)
  tmp.dim<-as.data.frame(my.object@dr$tsne@cell.embeddings)
  tmp.MatchIndex<- match(my.object@cell.names,rownames(tmp.dim))
  tmp.dim<-tmp.dim[tmp.MatchIndex,]
  if(customized==FALSE){
    tmp.colname<-grep("^res.",colnames(my.object@meta.data),value = T)[1]
    my.plot.all.source<-cbind.data.frame(tmp.dim,
                                         Cell_type=my.object@meta.data[,tmp.colname])
  }else{
    my.plot.all.source<-cbind.data.frame(tmp.dim,
                                         Cell_type=as.factor(my.object@meta.data$Customized.idents))
  }
  p.cluster<-ggplot(my.plot.all.source,
                    aes(x=my.plot.all.source[,1],y=my.plot.all.source[,2]))+xlab(colnames(my.plot.all.source)[1])+ylab(colnames(my.plot.all.source)[2])
  p.cluster<-p.cluster+geom_point(aes(col=my.plot.all.source[,"Cell_type"]))+scale_color_manual(values  = as.character(palette36.colors(36))[-2])
  #p.cluster<-theme_linedraw()
  p.cluster<-p.cluster + labs(col="cell type")
  p.cluster+theme_light()+scale_fill_continuous(name="cell type")
  
}

# test plot cluster function. 
Plot.cluster2D(customized = T)

# test Get.RegulonScore, output is matrix


Plot.regulon2D<-function(reduction.method="tsne",regulon=1,cell.type=1,customized=F,...){
  message("plotting regulon ",regulon," of cell type ",cell.type,"...")
  tmp.FileList<-list.files(pattern = "regulon_activity_score")
  tmp.RegulonScore<-read.delim(tmp.filelist[cell.type],sep = "\t",check.names = F)[regulon,]
  tmp.NameIndex<-match(rownames(my.object@dr$tsne@cell.embeddings),names(tmp.RegulonScore))
  tmp.RegulonScore<-tmp.RegulonScore[tmp.NameIndex]
  tmp.RegulonScore.Numeric<- as.numeric(tmp.RegulonScore)
  my.plot.regulon<-cbind.data.frame(my.object@dr$tsne@cell.embeddings,regulon.score=tmp.RegulonScore.Numeric)
  p.regulon<-ggplot(my.plot.regulon,
                    aes(x=my.plot.regulon[,1],y=my.plot.regulon[,2]))+xlab(colnames(my.plot.regulon)[1])+ylab(colnames(my.plot.regulon)[2])
  p.regulon<-p.regulon+geom_point(aes(col=my.plot.regulon[,"regulon.score"]))+scale_color_gradient(low = "grey",high = "red")
  #p.cluster<-theme_linedraw()
  p.regulon<-p.regulon + labs(col="regulon score")
  message("finish!")
  p.regulon
  
  
}
Plot.regulon2D(cell.type=5,regulon=4,customized = T)


Get.MarkerGene<-function(customized=T){
  if(customized==T){
    my.object<-SetIdent(my.object,ident.use = my.object@meta.data$Customized.idents)
    my.marker<-FindAllMarkers(my.object,only.pos = T)
  } else {
    my.object<-SetIdent(my.object,ident.use = my.object@meta.data$res.0.8)
    my.marker<-FindAllMarkers(my.object,only.pos = T)
  }
  my.cluster<-unique(as.character(my.object@ident))
  my.top.20<-c()
  for( i in 1:length(my.cluster)){
    my.cluster.data.frame<-filter(my.marker,cluster==my.cluster[i])
    my.top.20.tmp<-list(my.cluster.data.frame$gene[1:100])
    my.top.20<-append(my.top.20,my.top.20.tmp)
  }
  names(my.top.20)<-paste0("CT",my.cluster)
  my.top.20<-as.data.frame(my.top.20)
  return(my.top.20)
}
my.cluster.uniq.marker<-Get.MarkerGene(customized = T)
write.table(my.cluster.uniq.marker,file = "cell_type_unique_marker.txt",quote = F,row.names = F,sep = "\t")

#sad
# regulon genes t-sne



# test plot cluster function. 
Plot.cluster2D(reduction.method = "tsne",customized = T,cell.type=2)# "tsne" ,"pca","umap"
Plot.regulon2D(reduction.method = "tsne",regulon = 1,customized = T,cell.type=3)  

# import monocle
cds<-importCDS(my.object,import_all = T)
cds<- estimateSizeFactors(cds)
cds<-reduceDimension(cds,max_components = 2, method='DDRTree')
# test time and RAM
# library(profvis)
# profvis({
#   cds<-reduceDimension(cds,max_components = 2, method='DDRTree')
# })
cds<-orderCells(cds)
plot_cell_trajectory(cds,color_by="Customized.idents")
#customized the color by regulon score


Plot.TrajectoryByCellType<-function(customized=T){
  if (customized==TRUE){
    g<-plot_cell_trajectory(cds,color_by = "Customized.idents")
  }
  if (customized==FALSE){
    tmp.colname.phenoData<-colnames(cds@phenoData@data)
    color_by<-grep("^res.*",tmp.colname.phenoData,value = T)[1]
    g<-plot_cell_trajectory(cds,color_by = color_by )
  }
  g+scale_color_manual(values  = as.character(palette36.colors(36))[-2])
}

Plot.TrajectoryByCellType()  
Plot.TrajectoryByRegulon<-function(cell.type=1,regulon=1){
  tmp.FileList<-list.files(pattern = "regulon_activity_score")
  tmp.RegulonScore<-read.delim(tmp.filelist[cell.type],sep = "\t",check.names = F)[regulon,]
  tmp.NameIndex<-match(rownames(cds@phenoData@data),names(tmp.RegulonScore))
  tmp.RegulonScore<-tmp.RegulonScore[tmp.NameIndex]
  tmp.RegulonScore.Numeric<- as.numeric(tmp.RegulonScore)
  cds@phenoData@data$RegulonScore<-tmp.RegulonScore.Numeric
  plot_cell_trajectory(cds,color_by = "RegulonScore")+ scale_color_gradient(low = "grey",high = "red")
}

Plot.TrajectoryByCellType(customized = T)
Plot.TrajectoryByRegulon(cell.type = 6,regulon = 1)

##############################################
##gene expression in t-SNE####################
##############################################
# input gene name = rowname( raw data) 
Plot.GeneTSNE<-function(gene.name=NULL){
  tmp.gene.expression<- my.object@data
  tmp.dim<-as.data.frame(my.object@dr$tsne@cell.embeddings)
  tmp.MatchIndex<- match(my.object@cell.names,rownames(tmp.dim))
  tmp.dim<-tmp.dim[tmp.MatchIndex,]
  tmp.gene.name<-paste0("^",gene.name,"$")
  tmp.One.gene.value<-tmp.gene.expression[grep(tmp.gene.name,rownames(tmp.gene.expression)),]
  tmp.dim.df<-cbind.data.frame(tmp.dim,Gene=tmp.One.gene.value)
  g<-ggplot(tmp.dim.df,aes(x=tSNE_1,y=tSNE_2,color=Gene))
  g<-g+geom_point()+scale_color_gradient(low="grey",high = "red")
  g<-g+theme_bw()+labs(color=paste0(gene.name,"\nexpression\nvalue"))
  g
}
Plot.GeneTSNE("CA8")


cds@phenoData@data















