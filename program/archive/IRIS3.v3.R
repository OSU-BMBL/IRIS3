# reset r plot paramemter
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
# set working directory, you may change the directory first.
# setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/13. Chung/")
# loading required packege
library(Seurat,lib.loc = "/users/PAS1475/cyz931123/R/Seurat/Seurat3.0/")

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

if (!require("dplyr")) {
  install.packages("dplyr")
  library(dplyr)
}

if(!require("DrImpute")){
  install.packages("DrImpute")
  library("DrImpute")
}

if (!require("scran")) {
  BiocManager::install("scran")
  library(scran)
}
if (!require("slingshot")){
  BiocManager::install("slingshot")
  library(slingshot)
}
if (!require("destiny")){
  BiocManager::install("destiny")
}
if(!require(gam)){
  install.packages("gam")
}
if(!require(LTMGSCA)){
  devtools::install_github("zy26/LTMGSCA")
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
          #improve later
          all_files <- list.files(getwd())
          barcode_file <- grep("barcodes",all_files)
          matrix_file <- grep("matrix",all_files)
          gene_file <- grep("genes",all_files)
          feature_file <- grep("features",all_files)
          
          
          all_files <- list.files(getwd())
          barcode_file <- grep("barcodes",all_files)
          matrix_file <- grep("matrix",all_files)
          gene_file <- grep("genes",all_files)
          feature_file <- grep("features",all_files)
          
          tryCatch(file.rename(all_files[barcode_file],paste("barcodes",gsub(".*barcodes","",all_files[barcode_file]),sep = "")),error = function(e) 0)
          tryCatch(file.rename(all_files[matrix_file],paste("matrix",gsub(".*matrix","",all_files[matrix_file]),sep = "")),error = function(e) 0)
          tryCatch(file.rename(all_files[gene_file],paste("genes",gsub(".*genes","",all_files[gene_file]),sep = "")),error = function(e) 0)
          tryCatch(file.rename(all_files[feature_file],paste("features",gsub(".*features","",all_files[features]),sep = "")),error = function(e) 0)
          
          
          tmp_x<-tryCatch(Read10X(getwd()),error = function(e) {
            all_files <- list.files(getwd())
            barcode_file <- grep("barcodes",all_files)
            matrix_file <- grep("matrix",all_files)
            gene_file <- grep("genes",all_files)
            feature_file <- grep("features",all_files)
            try(system(paste("gunzip",(all_files[barcode_file]))),silent = T)
            try(system(paste("gunzip",(all_files[matrix_file]))),silent = T)
            try(system(paste("gunzip",(all_files[gene_file]))),silent = T)
            try(system(paste("gunzip",(all_files[feature_file]))),silent = T)
          })
          tmp_x<-tryCatch(Read10X(getwd()),error = function(e){
            0
          })
          return(tmp_x)
        } else if(read.method == "CellGene"){# read in cell * gene matrix, if there is error report, back to 18 line to run again.
          tmp_x<-read.delim(x,header = T,row.names = NULL,check.names = F,sep=sep,...)
          
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
my.raw.data<-read_data(x = "20190830171050_raw_expression.txt",sep="\t",read.method = "CellGene")
######################################################
# create Seurat object
my.object<-CreateSeuratObject(my.raw.data)
# check how many cell and genes
dim(my.object)
#VlnPlot(my.object, features = c("nFeature_RNA", "nCount_RNA", "percent.mt"), ncol = 3)
#plot(log(1:length(my.object$nCount_RNA)),log(sort(my.object$nCount_RNA,decreasing = T)))
#################################################################
# filter some outlier gene, only for 10X data####################
#################################################################


Data.Preprocessing<-function(TenX = FALSE,Species=c("human","mouse")) {
  if(TenX== TRUE){
    if(Species=="human"){
      my.object[["percent.mt"]] <- PercentageFeatureSet(my.object, pattern = "^MT-")
    }else {my.object[["percent.mt"]] <- PercentageFeatureSet(my.object, pattern = "^mt-")}
    
    my.object <- (subset(my.object, subset = nFeature_RNA > 200 & nFeature_RNA < 3000 & percent.mt < 5))
  }
  return(my.object)
}
my.object<-Data.Preprocessing(TenX = F)
#################################################################
#####################################################
# get data in terms of "counts"(raw data), "data"(normalized data), "scale.data"(scaling the data)
# neglect quality check, may add on in the future

# Key part for customizing cell type: 
##############################################
# Add meta info(cell type) to seurat object###
##############################################
label_data<-read.delim("chung_cell_type.txt",sep = "\t",
                       header = T,check.names = F,stringsAsFactors = F)
my.meta.info<-read.delim("chung_cell_type.txt",row.names = 1,
                         sep = "\t",header = T,check.names = F,stringsAsFactors = F)
my.object<-AddMetaData(my.object,my.meta.info,col.name = "Customized.idents")
# look at current cell type info
Idents(my.object)
# activate customized cell type info
Idents(my.object)<-as.factor(my.object$Customized.idents)

# #######Cankun modification: first imputation, then normalization#########
# 
# my.object<-CreateSeuratObject(expFile)
# #my.object<-GetAssayData(object = my.object,slot = "counts")
# my.count.data<-GetAssayData(object = my.object[['RNA']],slot="counts")
# my.imputated.data <- DrImpute(as.matrix(my.count.data))
# colnames(my.imputated.data)<-colnames(my.count.data)
# rownames(my.imputated.data)<-rownames(my.count.data)
# my.imputated.data<- as.sparse(my.imputated.data)
# 
# sce<-SingleCellExperiment(list(counts=my.imputated.data))
# is.ercc.empty<-function(x) {return(length(grep("^ERCC",rownames(x)))==0)}
# if (is.ercc.empty(sce)){
#   isSpike(sce,"MySpike")<-grep("^ERCC",rownames(sce))
#   sce<-computeSpikeFactors(sce)
# } else {
#   sce<-computeSumFactors(sce)
# }
# 
# #my.object<-NormalizeData(my.object,normalization.method = "LogNormalize",scale.factor = 10000)
# sce <- scater::normalize(sce,return_log=F)
# my.normalized.data <-normcounts(sce)
# my.normalized.data<-log1p(my.normalized.data)
# #######Cankun modification: first imputation, then normalization#########






# get raw data################################  
my.count.data<-GetAssayData(object = my.object[['RNA']],slot="counts")
# normalization##############################
sce<-SingleCellExperiment(list(counts=my.count.data))

## if all values are integers, perform normalization, otherwise skip to imputation
if(all(as.numeric(unlist(my.count.data[nrow(my.count.data),]))%%1==0)){
  ## normalization##############################
  sce <- tryCatch(computeSumFactors(sce),error = function(e) computeSumFactors(sce, sizes=seq(21, 201, 5)))
  sce<-scater::normalize(sce,return_log=F)
  my.normalized.data <- normcounts(sce)
} else {
  my.normalized.data <- my.count.data
}

# imputation#################################

my.imputated.data <- DrImpute(as.matrix(my.normalized.data))
colnames(my.imputated.data)<-colnames(my.count.data)
rownames(my.imputated.data)<-rownames(my.count.data)
my.imputated.data<- as.sparse(my.imputated.data)
my.imputatedLog.data<-log1p(my.imputated.data)
my.object<-SetAssayData(object = my.object,slot = "data",new.data = my.imputatedLog.data,assay="RNA")
#######################################################################
# export data from seurat object(normalized, imputed) .################
#######################################################################
my.export.for_LFMG<-my.imputated.data
my.export.rownames<-c(rownames(my.imputated.data))
my.export.for_LFMG<-data.frame(Gene=my.export.rownames,my.imputated.data,check.names = F)
write.table(my.export.for_LFMG,"Imputated.expressionMatirx.txt",quote = F,row.names=F,sep="\t")
#######################################################################
##run pca, tnse, umap via ltmg matrix

# my.object@assays$RNA@data
my.ltmg<-read.delim("Imputated.expressionMatirx.txt.em.chars",header = T)
rownames(my.ltmg)<-my.ltmg$o
my.ltmg<-my.ltmg[,-1]
# judge index whether greater than 1, if so -1 for each element.
signal.replace<-function(x){
  tmp.GreatThanOne.index<-which(x>1)
  tmp.GreatThanOne.value<-as.numeric(x[which(x>1)])-1
  x[tmp.GreatThanOne.index]<-tmp.GreatThanOne.value
  return(x)
}
my.new.ltmg<- apply(my.ltmg, 2, signal.replace)

# setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/scRNA-Seq/32.Hazem_D7_P14_Cl13_1/ungiz/")
# x<-Read10X(data.dir = getwd())

my.object@assays$RNA@data<-as.sparse(my.ltmg.pure)

#######################################################################
# find high variable gene
my.object<-FindVariableFeatures(my.object,selection.method = "vst",nfeatures = 2000)
# before PCA, scale data to eliminate extreme value affect.
all.gene<-my.object@assays$RNA@var.features
my.object<-ScaleData(my.object,features = all.gene)
# after scaling, perform PCA
my.object<-RunPCA(my.object,rev.pca = F,features = VariableFeatures(object = my.object))
ElbowPlot(object = my.object)
###########################################
# CORE part: Run TSNE and UMAP######################
###########################################
my.object<-RunTSNE(my.object,dims = 1:10,perplexity=10,dim.embed = 3)
# run umap to get high dimension scatter plot at 2 dimensional coordinate system.
# my.object<-RunUMAP(object = my.object,dims = 1:30)
#clustering by using Seurat KNN. 
# clustering by using KNN, this is seurat cluster algorithm, this part only for cell categorization
# here has one problems: whether should we define the clustering number?
my.object<-FindNeighbors(my.object,k.param = 20,dims = 1:30)
# find clustering, there will be changing the default cell type, if want to use customized cell type. 
# use Idents() function.
my.object<-FindClusters(my.object,resolution = 0.5)
# DimPlot(my.object)
# input website CTS-R under a specific cell type
# in this example I let my.cts.regulon read in specific cell type 1 
# create gene Module, please provide a creat module format!
# M1  G1  G2.....#
# M2  G3  G4.....#
# M3  G5  G6.....#
#----------------#
## test data, input data path
# setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/2019062485208/")
# get cell and regulon information
Get.CellType<-function(cell.type=1,...){
  if(!is.null(cell.type)){
    my.cell.regulon.filelist<-list.files(pattern = "bic.regulon_gene_symbol.txt")
    my.cell.regulon.indicator<-grep(paste0("_",as.character(cell.type),"_bic"),my.cell.regulon.filelist)
    my.cts.regulon.raw<-readLines(my.cell.regulon.filelist[my.cell.regulon.indicator])
    my.regulon.list<-strsplit(my.cts.regulon.raw,"\t")
    return(my.regulon.list)
  }else{stop("please input a cell type")}
  
}
Get.CellType(cell.type = 1)
# get each regulon gene and corresponding expression data. 
Generate.Regulon<-function(cell.type=NULL,regulon=1,...){
  x<-Get.CellType(cell.type = cell.type)
  my.rowname<-rownames(my.object)
  gene.index<-sapply(x[[regulon]][-1],function(x) grep(paste0("^",x,"$"),my.rowname))
  # my.object@data stores normalized data
  tmp.regulon<-my.object@assays$RNA@data[gene.index,]
  return(tmp.regulon)
}

Generate.Regulon(cell.type = 1)

#######################################################
## here you need to calculate Regulon score outside R##
#######################################################


# get Regulon score from external folder. 
Get.RegulonScore<-function(cell.type=1,regulon=1,...){
  # recognize the regulon file pattern.
  tmp.FileList<-list.files(pattern = "regulon_activity_score")
  cell.type.index<-grep(paste0("_CT_",cell.type,"_bic"),tmp.FileList)
  tmp.RegulonScore<-read.delim(tmp.FileList[cell.type.index],sep = "\t",check.names = F)[regulon,]
  tmp.NameIndex<-match(rownames(my.object@reductions$tsne@cell.embeddings),names(tmp.RegulonScore))
  tmp.RegulonScore<-tmp.RegulonScore[tmp.NameIndex]
  tmp.RegulonScore.Numeric<- as.numeric(tmp.RegulonScore)
  my.plot.regulon<-cbind.data.frame(my.object@reductions$tsne@cell.embeddings[,c(1,2)],regulon.score=tmp.RegulonScore.Numeric)
  return(my.plot.regulon)
}
Get.RegulonScore()

##############################

Plot.cluster2D<-function(reduction.method="umap",customized=T,pt_size=1,...){
  # my.plot.source<-GetReduceDim(reduction.method = reduction.method,module = module,customized = customized)
  # my.module.mean<-colMeans(my.gene.module[[module]]@assays$RNA@data)
  # my.plot.source<-cbind.data.frame(my.plot.source,my.module.mean)
  
  if(customized==F){
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=my.object$seurat_clusters)
  }else{
    my.plot.all.source<-cbind.data.frame(Embeddings(my.object,reduction = reduction.method),
                                         Cell_type=Idents(my.object))
  }
  tmp.celltype <- levels(unique(my.plot.all.source$Cell_type))
  p.cluster <- ggplot(my.plot.all.source,
                      aes(x=my.plot.all.source[,1],y=my.plot.all.source[,2]))+xlab(colnames(my.plot.all.source)[1])+ylab(colnames(my.plot.all.source)[2])
  p.cluster <- p.cluster+geom_point(stroke=pt_size,size=pt_size,aes(col=my.plot.all.source[,"Cell_type"])) 
  
  if(my.plot.all.source[,"Cell_type"]>=10){
    p.cluster <- p.cluster + guides(colour = guide_legend(override.aes = list(size=5),ncol = 2))
  }else{
    p.cluster <- p.cluster + guides(colour = guide_legend(override.aes = list(size=5)))
  }
  
  p.cluster <- p.cluster + scale_colour_manual(name  ="Cell type:(Cells)",values  = as.character(palette36.colors(36))[-2][1:length(tmp.celltype)],
                                               breaks=tmp.celltype,
                                               labels=paste0(tmp.celltype,":(",as.character(summary(my.plot.all.source$Cell_type)),")"))
  
  # + labs(col="cell type")           
  p.cluster <- p.cluster + theme_classic() 
  p.cluster <- p.cluster + coord_fixed(ratio=1)
  p.cluster
}

# test plot cluster function. 
Plot.cluster2D(customized = T)

# plot CTS-R
# test Get.RegulonScore, output is matrix


Plot.regulon2D<-function(reduction.method="umap",regulon=1,cell.type=1,customized=T,pt_size=1,...){
  #message("plotting regulon ",regulon," of cell type ",cell.type,"...")
  my.plot.regulon<-Get.RegulonScore(reduction.method = reduction.method,
                                    cell.type = cell.type,
                                    regulon = regulon,
                                    customized = customized)
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
  p.regulon <- p.regulon + geom_point(stroke=pt_size,size=pt_size,aes(col=my.plot.regulon[,"regulon.score"])) + scale_colour_distiller(palette = "YlOrRd", direction = 1)
  #+ scale_color_gradient(low = "grey",high = "red")
  p.regulon <- p.regulon + theme_classic() + labs(col="Regulon\nscore")
  #message("finish!")
  
  p.regulon <- p.regulon + coord_fixed(ratio=1)
  p.regulon
}

Plot.regulon2D(cell.type=3,regulon=5,customized = T)
Plot.cluster2D(customized = T)

Get.MarkerGene<-function(customized=T){
  if(customized==T){
    Idents(my.object)<-my.object$Customized.idents
    my.marker<-FindAllMarkers(my.object,only.pos = T)
  } else {
    Idents(my.object)<-my.object$seurat_clusters
    my.marker<-FindAllMarkers(my.object,only.pos = T)
  }
  my.cluster<-unique(as.character(Idents(my.object)))
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
#####################################################################################################
# experiment for RAS * cell trajectory inference ####################################################
#####################################################################################################
my.RAS.filelist<-list.files(pattern = "_activity_score.txt")
my.order<- sapply(strsplit(my.RAS.filelist,"_"),"[",3)
my.regulon.cell.Matrix<-c()
for(i in 1:length(my.RAS.filelist)){
  tmp.file.index<-grep(my.order[i],paste0("_CT",my.order[i],"_bic.regulon_activity_score.txt$"))
  tmp.x<-read.delim(my.RAS.filelist[tmp.file.index])
  rownames(tmp.x)<-paste0("CT_",my.order[i],"_Regulon","_",1:nrow(tmp.x))
  my.regulon.cell.Matrix<-rbind.data.frame(my.regulon.cell.Matrix,tmp.x)
}



############################################################
# trajectory with slingshot. trajectory by cell count#######
############################################################

my.trajectory<-SingleCellExperiment(assays=List(counts=my.count.data))
# SummarizedExperiment::assays(my.trajectory)$norm<-GetAssayData(object = my.object,assay = "RNA",slot = "data")

Dim.Calculate<-function(Matrix.type="GEM",...){
  if(Matrix.type == "GEM"){
    dm<-DiffusionMap(t(as.matrix(GetAssayData(object = my.object,assay = "RNA",slot = "data"))))
    rd2 <- cbind(DC1 = dm$DC1, DC2 = dm$DC2)
    a <- SimpleList( DiffMap = rd2)
    print("using GEM.")
  } 
  # second mode Regulon score
  if(Matrix.type == "RSM") { 
    dm<-DiffusionMap(t(as.matrix(my.regulon.cell.Matrix)))
    rd2 <- cbind(DC1 = dm$DC1, DC2 = dm$DC2)
    a<-SimpleList( DiffMap = rd2)
    print("using Regulon score matrix") 
  }
  return(a)
}
# Dim.Calculate(Matrix.type="GEM")
# two mode GEM RSM
reducedDims(my.trajectory)<-Dim.Calculate(Matrix.type="GEM")
######## test ######################################
# Plot.Cluster.Trajectory(customized=T,add.line=TRUE,start.cluster=NULL,end.cluster=NULL,show.constraints=F)
# Plot.Regulon.Trajectory(customized=T,cell.type=4,regulon=1,start.cluster=NULL,end.cluster=NULL)

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

Plot.Cluster.Trajectory(customized= T,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)

Plot.Regulon.Trajectory<-function(customized=T,cell.type=1,regulon=1,start.cluster=NULL,end.cluster=NULL,...){
  tmp.trajectory.cluster<-Get.cluster.Trajectory(customized = customized,start.cluster=start.cluster,end.cluster=end.cluster)
  tmp.regulon.score<- Get.RegulonScore(cell.type = cell.type,regulon = regulon)
  tmp.cell.name<-colnames(tmp.trajectory.cluster)
  tmp.cell.name.index<-match(tmp.cell.name,rownames(tmp.regulon.score))
  tmp.regulon.score<-tmp.regulon.score[tmp.cell.name.index,]
  val<-tmp.regulon.score$regulon.score
  #
  
  layout(matrix(1:2,nrow=1),widths=c(0.7,0.3))
  grPal <- colorRampPalette(c("blue","red"))
  tmp.color<-grPal(10)[as.numeric(cut(val,breaks=10))]
  
  par(mar=c(5.1,2.1,1.1,2.1))
  plot(reducedDims(tmp.trajectory.cluster)$DiffMap,
       col=alpha(tmp.color,0.7),
       pch=20,frame.plot = FALSE,
       asp=1)
  lines(SlingshotDataSet(tmp.trajectory.cluster))
  #grid()
  xl <- 1
  yb <- 1
  xr <- 1.5
  yt <- 2
  
  par(mar=c(20.1,1.1,1.1,3.1))
  plot(NA,type="n",ann=F,xlim=c(1,2),ylim=c(1,2),xaxt="n",yaxt="n",bty="n")
  rect(
    xl,
    head(seq(yb,yt,(yt-yb)/50),-1),
    xr,
    tail(seq(yb,yt,(yt-yb)/50),-1),
    col=grPal(50),border=NA
  )
  tmp.min<-round(min(val),1)
  tmp.Nmean<-round(tmp.min/2,1)
  tmp.max<-round(max(val),1)
  tmp.Pmean<-round(tmp.max/2,1)
  tmp.cor<-seq(yb,yt,(yt-yb)/50)
  mtext("Relugon Score", cex=1,side=1)
  mtext(c(tmp.min,tmp.Nmean,0,tmp.Pmean,tmp.max),
        at=c(tmp.cor[5],tmp.cor[15],tmp.cor[25],tmp.cor[35],tmp.cor[45]),
        side=2,las=1,cex=0.7)
  wreset_par()
  
}
Plot.Regulon.Trajectory(cell.type = 1,regulon = 1,start.cluster = NULL,end.cluster = NULL)

###########################
### gene TSNE plot#########
###########################
# input as normalized data
Plot.GeneTSNE<-function(gene.name=NULL){
  tmp.gene.expression<- my.object@assays$RNA@data
  tmp.dim<-as.data.frame(my.object@reductions$tsne@cell.embeddings)
  tmp.MatchIndex<- match(colnames(tmp.gene.expression),rownames(tmp.dim))
  tmp.dim<-tmp.dim[tmp.MatchIndex,]
  tmp.gene.name<-paste0
  ("^",gene.name,"$")
  tmp.One.gene.value<-tmp.gene.expression[grep(tmp.gene.name,rownames(tmp.gene.expression)),]
  tmp.dim.df<-cbind.data.frame(tmp.dim,Gene=tmp.One.gene.value)
  g<-ggplot(tmp.dim.df,aes(x=tSNE_1,y=tSNE_2,color=Gene))
  g<-g+geom_point()+scale_color_gradient(low="grey",high = "red")
  g<-g+theme_bw()+labs(color=paste0(gene.name,"\nexpression\nvalue")) + coord_fixed(1)
  g
}
Plot.GeneTSNE("CA8")

############


