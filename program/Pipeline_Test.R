# input: 1. 500 cell sampling from 3000 cell*n genes 
#        2. 10% random sampling cluster. 


# 2. raw + normalization
# 3. raw + normalization + imputation
# 4. raw + normalization + imputation (+ LTMG)
# 5. sp2 (300*500) (raw > 300gene *500) +normalization + imputation. 

# 1. raw 
# 5. raw + imputation 
# 6. raw + imputation +LMTG
# 7. raw + LTMG


# 
# qubic2 -k min(c(15, 20, 25), 5%)
#        -f 0.5
#        -0 1000
# qubic2 
# 1. default 
# 2. -k 15, -f 0.5 -o 1000
# 3. -k 20,  -f 0.5 -0 1000
# 4. -k 25,  -f 0.5 -0 1000
# 5. -k 20,

# pre-load########################
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
        all_files <- list.files(x)
        barcode_file <- grep("barcodes",all_files)
        matrix_file <- grep("matrix",all_files)
        gene_file <- grep("genes",all_files)
        feature_file <- grep("features",all_files)
        
        
        tryCatch(file.rename(all_files[barcode_file],paste("barcodes",gsub(".*barcodes","",all_files[barcode_file]),sep = "")),error = function(e) 0)
        tryCatch(file.rename(all_files[matrix_file],paste("matrix",gsub(".*matrix","",all_files[matrix_file]),sep = "")),error = function(e) 0)
        tryCatch(file.rename(all_files[gene_file],paste("genes",gsub(".*genes","",all_files[gene_file]),sep = "")),error = function(e) 0)
        tryCatch(file.rename(all_files[feature_file],paste("features",gsub(".*features","",all_files[features]),sep = "")),error = function(e) 0)
        
        
        tmp_x<-tryCatch(Read10X(x),error = function(e) {
          all_files <- list.files(x)
          barcode_file <- grep("barcodes",all_files)
          matrix_file <- grep("matrix",all_files)
          gene_file <- grep("genes",all_files)
          feature_file <- grep("features",all_files)
          try(system(paste("gunzip",(all_files[barcode_file]))),silent = T)
          try(system(paste("gunzip",(all_files[matrix_file]))),silent = T)
          try(system(paste("gunzip",(all_files[gene_file]))),silent = T)
          try(system(paste("gunzip",(all_files[feature_file]))),silent = T)
        })
        tmp_x<-tryCatch(Read10X(x),error = function(e){
          0
        })
        return(tmp_x)
      } else if(read.method == "CellGene"){# read in cell * gene matrix, if there is error report, back to 18 line to run again.
        tmp_x<-read.delim(x,header = T,check.names = F,sep=sep,...)
        
        return(tmp_x)
      }
    }
  }else {stop("Missing 'x' argument, please input correct data")}
}

Data.Preprocessing<-function(TenX = FALSE,Species=c("human","mouse")) {
  if(TenX== TRUE){
    if(Species=="human"){
      my.object[["percent.mt"]] <- PercentageFeatureSet(my.object, pattern = "^MT-")
    }else {my.object[["percent.mt"]] <- PercentageFeatureSet(my.object, pattern = "^mt-")}
    
    my.object <- (subset(my.object, subset = nFeature_RNA > 200 & nFeature_RNA < 3000 & percent.mt < 5))
  }
  return(my.object)
}
run.analysis<-function(my.object=my.object){
  my.data<-log1p(my.object@assays$RNA@data)
  my.object@assays$RNA@data<-as.sparse(my.data)
  my.object<-FindVariableFeatures(my.object,selection.method = "vst",nfeatures = 2000)
  all.gene<-my.object@assays$RNA@var.features
  my.object<-ScaleData(my.object,features = all.gene)
  my.object<-RunPCA(my.object,rev.pca = F,features = VariableFeatures(object = my.object))
  my.object<-FindNeighbors(my.object,k.param = 20,dims = 1:30)
  my.object<-FindClusters(my.object,resolution = 0.5)
  return(my.object)
}
####
setwd("D:\\my_analysis\\Hazem_data_explore_parameters\\All_cell/S0021-Chen-A//")
x="D:\\my_analysis\\Hazem_data_explore_parameters\\All_cell/23.Fan/GSE110499_GEO_processed_MM_raw_TPM_matrix.txt"
#'TenX.h5','TenX.folder', or 'CellGene'
  my.raw<-read_data(x,read.method ="CellGene")
  # my.raw=my.raw[-which(duplicated(my.raw$cell_id)==T),]
  # rownames(my.raw)<-my.raw$cell_id
  # my.raw<-my.raw[,-1]
  my.object<-CreateSeuratObject(my.raw)
  my.object<-Data.Preprocessing(x=my.object,TenX = F,Species = "human")
  #my.raw2<-my.object@assays$RNA@counts
  #sum(my.raw2==0)/sum(my.raw2>=0)
  # VlnPlot(my.object, features = c("nFeature_RNA", "nCount_RNA", "percent.mt"), ncol = 3)
  # plot(log(1:ncol(my.object)),sort(colSums(my.object@assays$RNA@counts>0),decreasing = T))
  my.count.data<-GetAssayData(object = my.object[['RNA']],slot="counts")
  sce<-SingleCellExperiment(list(counts=my.count.data))
  if(all(as.numeric(unlist(my.count.data[1:nrow(my.count.data),]))%%1==0)){
    ## normalization##############################
    sce <- tryCatch(computeSumFactors(sce),error = function(e) computeSumFactors(sce, sizes=seq(21, 201, 5)))
    sce<-scater::normalize(sce,return_log=F)
    my.normalized.data <- normcounts(sce)
  } else {
    my.normalized.data <- my.count.data
  }
  my.export.for_LFMG<-my.normalized.data
  my.export.rownames<-c(rownames(my.normalized.data))
  my.export.for_LFMG<-data.frame(Gene=my.export.rownames, my.export.for_LFMG,check.names = F)
  #run the label
  my.object@assays$RNA@data<-my.normalized.data
  my.object<-run.analysis(my.object=my.object)
  normlize.cluster<-my.object$seurat_clusters
  cell.label<-data.frame(cell.name=as.character(colnames(my.object)),cell.lable=as.character(my.object$seurat_clusters))
  identical(as.character(cell.label$cell.name),colnames(my.export.for_LFMG)[-1])
  write.table(my.export.for_LFMG,"Raw_Nor.txt",quote = F,row.names=F,sep="\t")
  write.table(cell.label,"Raw_Nor_cell_label.txt",quote = F,row.names = F,sep = "\t")
  # doing imputation
  my.imputated.data <- DrImpute(as.matrix(my.normalized.data),ks=12,dists = "spearman")
  colnames(my.imputated.data)<-colnames(my.count.data)
  rownames(my.imputated.data)<-rownames(my.count.data)
  my.object@assays$RNA@data<-as.sparse(my.imputated.data)
  my.export.for_LFMG<-my.imputated.data
  my.export.rownames<-c(rownames(my.imputated.data))
  my.export.for_LFMG<-data.frame(Gene=my.export.rownames, my.export.for_LFMG,check.names = F)
  my.object<-run.analysis(my.object=my.object)
  # check imputation and normalization cluster label 
  impuation.cluster<-my.object$seurat_clusters
  identical(normlize.cluster,impuation.cluster)
  cell.label<-data.frame(cell.name=as.character(colnames(my.object)),cell.lable=as.character(my.object$seurat_clusters))
  identical(as.character(cell.label$cell.name),colnames(my.export.for_LFMG)[-1])
  write.table(my.export.for_LFMG,"Raw_Nor_imputation.txt",quote = F,row.names=F,sep="\t")
  write.table(cell.label,"Raw_Nor_imputation_cell_label.txt",quote = F,row.names = F,sep = "\t")
  

#  # generate Raw_norm 500 cells expression matrix

# 
# my.object<-Raw_Nor("GSE110499_GEO_processed_MM_raw_TPM_matrix.txt",read.method ="CellGene")
# my.normalized.data<-(my.object@assays$RNA@data)
# # set.seed(43)
# # index<-sample(1:ncol(my.object),500)
# # my.export.for_LFMG<-my.normalized.data[,index]
# my.export.for_LFMG<-my.normalized.data
# my.export.rownames<-c(rownames(my.normalized.data))
# my.export.for_LFMG<-data.frame(Gene=my.export.rownames, my.export.for_LFMG,check.names = F)
# #run the label
# my.object<-run.analysis(my.object=my.object)
# cell.label<-data.frame(cell.name=as.character(colnames(my.object)[index]),cell.lable=as.character(my.object$seurat_clusters[index]))
# identical(as.character(cell.label$cell.name),colnames(my.export.for_LFMG)[-1])
# write.table(my.export.for_LFMG,"Raw_Nor.txt",quote = F,row.names=F,sep="\t")
# write.table(cell.label,"Raw_Nor_cell_label.txt",quote = F,row.names = F,sep = "\t")
# 
# # generate Raw_norm_impute 500 cells expression matrix
# x="D:\\my_analysis\\Hazem_data_explore_parameters\\32.Hazem_D7_P14_Cl13_1/"
# 
# 
# my.object<-Raw_Nor_imputation(x,read.method ="TenX.folder")
# my.imputed.data<-(my.object@assays$RNA@data)
# # set.seed(43)
# # index<-sample(1:ncol(my.object),500)
# my.export.for_LFMG<-my.imputed.data[,index]
# my.export.rownames<-c(rownames(my.imputed.data))
# my.export.for_LFMG<-data.frame(Gene=my.export.rownames, my.export.for_LFMG,check.names = F)
# # run the label
# my.object<-run.analysis(my.object=my.object)
# cell.label<-data.frame(cell.name=as.character(colnames(my.object)[index]),cell.lable=as.character(my.object$seurat_clusters[index]))
# identical(as.character(cell.label$cell.name),colnames(my.export.for_LFMG)[-1])
# write.table(my.export.for_LFMG,"Raw_Nor_imputation.txt",quote = F,row.names=F,sep="\t")
# write.table(cell.label,"Raw_Nor_imputation_cell_label.txt",quote = F,row.names = F,sep = "\t")


###################pheatmap
# input imputed data, changable
setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/500_cell_10X/Raw_Nor_nonLTMG/QUBIC2_k15_f0.5__o1000/")
# input matrix changable
exp_data<- read.delim("Raw_Nor.txt",check.names = FALSE, header=TRUE,row.names = 1)
exp_data <- as.matrix(exp_data)
# label cell name, cluster
label_data <- read.table("Raw_Nor_cell_label.txt",sep="\t",header = T)
# module gene name
g.list<-readLines("_blocks.gene.txt")
g1.select<-g.list[c(1:50)]

g1 <- unlist(strsplit(g1.select," "))
g1 <- g1[-which(g1=="")]
length(g1)
which(duplicated(g1)==T)
#l1 <- c(3,4,6)
# label number
l1 <- c(3,8,1,2,0,7,9,11,4,5,10,6)
library(pheatmap)
library(RColorBrewer)
library(viridis)
library(Polychrome)

df1 <- exp_data[which(rownames(exp_data) %in% g1),]
label1 <- label_data[which(label_data[,2] %in% l1),]
df2 <- df1[,which(colnames(df1) %in% label1[,1])]

label1<-label1[order(label1$cell.lable),]
df2<-df2[,as.character(label1$cell.name)]

# Data frame with column annotations.
mat_col <- data.frame(group = label1[,2])
rownames(mat_col) <- colnames(df2)

# List with colors for each annotation.
mat_colors <- list(group = as.character(palette36.colors(36))[-2][1:length(l1)])
names(mat_colors$group) <- unique(label1[,2])

pheatmap(
  mat               = df2,
  color             = colorRampPalette(c("blue","white","red"))(n=100),
  scale = "row",
  border_color      = NA,
  show_colnames     = FALSE,
  show_rownames     = F,
  annotation_col    = mat_col,
  annotation_colors = mat_colors,
  drop_levels       = TRUE,
  fontsize          = 14,
  main              = "Expression Heatmap",
  cluster_cols=F,
  cluster_rows = F
)
##########################################
#########################################
######################################
###################pheatmap
# input imputed data, changable
setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/500_cell_10X/Raw_Nor_Imp_nonLTMG/QUBIC2_k15_f0.5__o1000/")
# input matrix changable
exp_data<- read.delim("Raw_Nor_imputation.txt",check.names = FALSE, header=TRUE,row.names = 1)
exp_data <- as.matrix(exp_data)
# label cell name, cluster
label_data <- read.table("Raw_Nor_imputation_cell_label.txt",sep="\t",header = T)
# module gene name
g.list<-readLines("_blocks.gene.txt")
g1.select<-g.list[c(1)]

g1 <- unlist(strsplit(g1.select," "))
g1 <- g1[-which(g1=="")]
length(g1)
which(duplicated(g1)==T)
#l1 <- c(3,4,6)
# label number
l1 <- c(3,8,1,2,0,7,9,11,4,5,10,6)
library(pheatmap)
library(RColorBrewer)
library(viridis)
library(Polychrome)

df1 <- exp_data[which(rownames(exp_data) %in% g1),]
label1 <- label_data[which(label_data[,2] %in% l1),]
df2 <- df1[,which(colnames(df1) %in% label1[,1])]

label1<-label1[order(label1$cell.lable),]
df2<-df2[,as.character(label1$cell.name)]

# Data frame with column annotations.
mat_col <- data.frame(group = label1[,2])
rownames(mat_col) <- colnames(df2)

# List with colors for each annotation.
mat_colors <- list(group = as.character(palette36.colors(36))[-2][1:length(l1)])
names(mat_colors$group) <- unique(label1[,2])

pheatmap(
  mat               = df2,
  color             = colorRampPalette(c("blue","white","red"))(n=100),
  scale = "row",
  border_color      = NA,
  show_colnames     = FALSE,
  show_rownames     = F,
  annotation_col    = mat_col,
  annotation_colors = mat_colors,
  drop_levels       = TRUE,
  fontsize          = 14,
  main              = "Expression Heatmap",
  cluster_cols=F,
  cluster_rows = F
)

setwd("D:\\my_analysis\\Hazem_data_explore_parameters\\All_cell/12.Zeisel/Raw_Nor_Imp_LTMG/")
x<-read.table("Raw_Nor_imputation.txt",header = T,row.names = 1)
x<-read.table(ble("Raw_Nor"))

 