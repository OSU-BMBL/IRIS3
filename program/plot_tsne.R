#######  Plot tsne, umap, pca ##########

args <- commandArgs(TRUE)
#setwd("D:/Users/flyku/Documents/IRIS3-data/test_zscore")
#setwd("/var/www/html/iris3/data/2019052895653/")
#srcDir <- getwd()
#jobid <-2019052895653 
srcDir <- args[1]
jobid <- args[2] 

if(!require(Seurat)) {
  install.packages("Seurat")
} 
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
        tmp_x<-as.sparse(tmp_x)
        return(tmp_x)
      }
    }
  }else {stop("Missing 'x' argument, please input correct data")}
}
#####################  
# read.data function:#
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
my.raw.data<-read_data(x = paste(jobid,"_filtered_expression.txt",sep = ""),read.method = "CellGene")
my.meta.info<-read.table(paste(jobid,"_cell_label.txt",sep = ""),sep = "\t",row.names = 1,header = T,stringsAsFactors = F)
######################################################

my.object<-CreateSeuratObject(my.raw.data)
my.object<-AddMetaData(my.object,my.meta.info,col.name = "Customized.idents")
Idents(my.object)
Idents(my.object)<-my.object$Customized.idents
my.object<-FindVariableFeatures(my.object,selection.method = "vst",nfeatures = 5000)
VariableFeaturePlot(my.object)

####  pca
# before PCA, scale data to eliminate extreme value affect.
all.gene<-rownames(my.object)
my.object<-ScaleData(my.object,features = all.gene)
# after scaling, perform PCA
my.object<-RunPCA(my.object,rev.pca = F,features = VariableFeatures(object = my.object))
png("pca.png",width=700, height=700)
DimPlot(my.object,reduction = "pca")
dev.off()

####  tsne
# Elbowplot help to choose "dim" 
ElbowPlot(my.object,ndims = 30)
my.object<-RunTSNE(my.object,dims = 1:15,perplexity=10,dim.embed = 3)
png("tsne.png",width=700, height=700)
DimPlot(my.object,reduction = "tsne")
dev.off()

####  UMAP
# run umap to get high dimension scatter plot at 2 dimensional coordinate system.
my.object<-RunUMAP(object = my.object,dims = 1:20)
png("umap_1.png",width=700, height=700)
DimPlot(my.object,reduction = "umap")
dev.off()
# clustering by using KNN, this is seurat cluster algorithm, this part only for cell categorization
my.object<-FindNeighbors(my.object,k.param = 6,dims = 1:20)
# find clustering, there will be changing the default cell type, if want to use customized cell type. 
# use Idents() function.
my.object<-FindClusters(my.object,resolution = 0.5)
png("umap_2.png",width=1200, height=1200)
DimPlot(my.object,reduction = "umap")
dev.off()
## umap based on input string, this ident could be automatically regonized by cell name from input cell-gene matrix.
# in the seurat, the original category stores in orig.ident
Idents(my.object)<-my.object$orig.ident
png("umap_3.png",width=1200, height=1200)
DimPlot(my.object,reduction = "umap")
dev.off()



