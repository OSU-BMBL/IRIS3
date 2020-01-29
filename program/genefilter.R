####### preprocessing expression matrix based on SC3 ##########
options(check.names=F)
#removes genes/transcripts that are either expressed (expression value > 2) in less than X% of cells (rare genes/transcripts) 
#or expressed (expression value > 0) in at least (100 ??? X)% of cells (ubiquitous genes/transcripts). 
#By default, X is set at 6.

#library(GenomicAlignments)
#library(ensembldb)
#BiocManager::install("scran")

suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(hdf5r))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(SingleCellExperiment))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(scater))
suppressPackageStartupMessages(library(devEMF))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(Seurat))
suppressPackageStartupMessages(library(DrImpute))
suppressPackageStartupMessages(library(scran))
suppressPackageStartupMessages(library(slingshot))
suppressPackageStartupMessages(library(destiny))
suppressPackageStartupMessages(library(gam))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(Polychrome))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(cluster))

args <- commandArgs(TRUE)
srcFile <- args[1] # raw user filename
jobid <- args[2] # user job id
delim <- args[3] #delimiter
is_imputation <- args[4] #1 for enable imputation
label_file <- 1
label_file <- args[5] # user label file name or 1
delimiter <- args[6] 
param_k <- character()
param_k <- args[7] #k parameter for sc3
label_use_sc3 <- args[8] # 1 for have label use sc3, 2 for have label use label, 0 for no label use sc3


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
label_file

load_test_data <- function(){
  rm(list = ls(all = TRUE))
  # 
  # setwd("/var/www/html/CeRIS/data/20191020160119/")
  # srcFile = "5k_pbmc_protein_v3_filtered_feature_bc_matrix.h5"
  srcFile = "iris3_example_expression_matrix.csv"
  jobid <- "20191020160119"
  delim <- ","
  is_imputation <- 0
  label_file<-'iris3_example_expression_label.csv'
  delimiter <- ','
  param_k<-0
  label_use_sc3 <- 2
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
          try(system(paste("unzip",(all_files[barcode_file]))),silent = T)
          try(system(paste("unzip",(all_files[matrix_file]))),silent = T)
          try(system(paste("unzip",(all_files[gene_file]))),silent = T)
          try(system(paste("unzip",(all_files[feature_file]))),silent = T)
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

getwd()
upload_type <- as.character(read.table("upload_type.txt",stringsAsFactors = F)[1,1])
#expFile <- read_data(x = getwd(),read.method = "TenX.folder",sep = delim)
#expFile <- read_data(x = srcFile,read.method = "TenX.h5",sep = delim)
#upload_type <- "CellGene"
#expFile <- read_data(x = srcFile,read.method = "CellGene",sep = delim)
expFile <- read_data(x = srcFile,read.method = upload_type,sep = delim)
if(class(expFile) == "list"){
  expFile <- expFile[[1]]
}
colnames(expFile) <-  gsub('([[:punct:]])|\\s+','_',colnames(expFile))
dim(expFile)
##check if [1,1] is empty
if(colnames(expFile)[1] == ""){
  colnames(expFile)[1] = "Gene_ID"
}

total_gene_num <- nrow(expFile)

## deal with some edge cases on gene symbols/id 
if (upload_type == "CellGene"){
  is_imputation  <- '0'
  ## case: gene with id with ENSG########.X, remove part after dot, e.g:
  ## a <- c("ENSG00000064545.10","ENSG000031230064545","ENMUSG00003213004545.31234s")
  match_index <- grep("^ENSG.+\\.[0-9]",ignore.case = T,expFile[,1])
  if (length(match_index) > 0){
    match_rownames <- expFile[match_index,1]
    expFile[,1] <- as.character(expFile[,1])
    expFile[match_index,1] <- gsub('\\..+','',match_rownames)
  }
  
  ## case above but for mouse: ENSMUSGXXXXX.X
  match_index <- grep("^ENSMUSG.+\\.[0-9]",ignore.case = T,expFile[,1])
  if (length(match_index) > 0){
    match_rownames <- expFile[match_index,1]
    expFile[,1] <- as.character(expFile[,1])
    expFile[match_index,1] <- gsub('\\..+','',match_rownames)
  }
  
  ## case: genes with format like (AADACL3|chr1|12776118), remove part after |, e.g:
  ## a <- c("AADACL3|chr1|12776118","KLHDC8A|chr1|205305648","KIF21B|chr1|200938514")
  match_index <- grep("^[a-z].+\\|",ignore.case = T,expFile[,1])
  if (length(match_index) > 0){
    match_rownames <- expFile[match_index,1]
    expFile[,1] <- as.character(expFile[,1])
    expFile[match_index,1] <- gsub('\\|.+','',match_rownames)
  }
  
  ##remove duplicated rows with same gene 
  if(length(which(duplicated.default(expFile[,1]))) > 0 ){
    expFile <- expFile[-which(duplicated.default(expFile[,1])==T),]
  }	
  
  rownames(expFile) <- expFile[,1]
  expFile<- expFile[,-1]
}

total_cell_num <- ncol(expFile)


# detect rownames gene list with identifer by the largest number of matches: 1) gene symbol. 2)ensembl geneid. 3) ncbi entrez id. 4)

get_rowname_type <- function (l, db){
  res1 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "SYMBOL")),error = function(e) 0)
  res2 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "ENSEMBL")),error = function(e) 0)
  res3 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "ENTREZID")),error = function(e) 0)
  res4 <- tryCatch(nrow(AnnotationDbi::select(db, keys = l, columns = c("ENTREZID", "SYMBOL","ENSEMBL","ENSEMBLTRANS"),keytype = "ENSEMBLTRANS")),error = function(e) 0)
  result <- c("error","SYMBOL","ENSEMBL","ENTREZID","ENSEMBLTRANS")
  result_vec <- c(1,res1,res2,res3,res4)
  return(c(result[which.max(result_vec)],result_vec[which.max(result_vec)]))
  #write("No matched gene identifier found, please check your data.",file=paste(jobid,"_error.txt",sep=""),append=TRUE)
}

# detect species
# detect which types of identifer in rownames, 1)HGNC gene symbol 2)ensembl geneid 3) ncbi entrez id
# convert to symbol
species_file <- as.character(read.table("species.txt",header = F,stringsAsFactors = F)[,1])

# deprecated databases, about 10% of the gene id missing which cause a lot of genes filtered
suppressPackageStartupMessages(library(org.Dm.eg.db))
suppressPackageStartupMessages(library(org.Hs.eg.db))
suppressPackageStartupMessages(library(org.Mm.eg.db))
suppressPackageStartupMessages(library(org.Ce.eg.db))
suppressPackageStartupMessages(library(org.Sc.sgd.db))
suppressPackageStartupMessages(library(org.Dr.eg.db))
db <- c("Worm"=org.Ce.eg.db, "Fruit_fly"=org.Dm.eg.db, "Zebrafish"=org.Dr.eg.db,
        "Yeast"=org.Sc.sgd.db,"Mouse"=org.Mm.eg.db,"Human"=org.Hs.eg.db)

select_db <- db[which(names(db)%in%species_file)]
gene_identifier <- sapply(select_db, get_rowname_type, l=rownames(expFile))
main_species <- names(which.max(gene_identifier[2,]))
main_db <- db[which(names(db)%in%main_species)][[1]]
main_identifier <- as.character(gene_identifier[1,which.max(gene_identifier[2,])])

if(length(species_file) == 2) {
  second_species <- names(which.min(gene_identifier[2,]))
  write(paste("second_species,",second_species,sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
}
all_match <- AnnotationDbi::select(main_db, keys = rownames(expFile), columns = c("SYMBOL","ENSEMBL"),keytype = main_identifier)

expFile <- merge(expFile,all_match,by.x=0,by.y=main_identifier)
dim(expFile)
expFile <- na.omit(expFile)

## merge expression values with same gene names
if (main_identifier == "ENSEMBL") {
  expFile <- expFile[,-1]
  expFile <- aggregate(. ~ SYMBOL, expFile, sum)
} else if (main_identifier == "ENSEMBLTRANS") {
  expFile <- expFile[,c(-1,-(ncol(expFile)))]
  expFile <- aggregate(. ~ SYMBOL, expFile, sum)
} else {
  expFile <- expFile[,-(ncol(expFile))]
  expFile <- aggregate(. ~ Row.names, expFile, sum)
}
expFile <- expFile[!duplicated(expFile[,1]),]
rownames(expFile) <- expFile[,1]
expFile <- expFile[,-1]

## remove rows with empty gene name
if(length(which(rownames(expFile)=="")) > 0){
  expFile <- expFile[-which(rownames(expFile)==""),]
}

## keep the gene with number of non-0 expression value cells >= 5%
filter_gene_func <- function(this){
  if(length(which(this>0)) >= thres_cells){
    return (1)
  } else {
    return (0)
  }
}
# this <- expFile[,1]
## keep the cell with number of non-0 expression value gene >= 1%
filter_cell_func <- function(this){
  if(length(which(this>0)) >= thres_genes){
    return (1)
  } else {
    return (0)
  }
}

my.object<-CreateSeuratObject(expFile)

if (upload_type == "TenX.folder" | upload_type == "TenX.h5"){
  my.object[["percent.mt"]] <- PercentageFeatureSet(my.object, pattern = "^MT-")
  my.object <- (subset(my.object, subset = nFeature_RNA > 200 & nFeature_RNA < 4000 & percent.mt < 5))
}

## get raw data################################  
my.count.data<-GetAssayData(object = my.object[['RNA']],slot="counts")
sce<-SingleCellExperiment(list(counts=my.count.data))
write.table(as.data.frame(my.count.data),paste(jobid,"_raw_expression.txt",sep = ""), row.names = T,col.names = T,sep="\t",quote=FALSE)

## if all values are integers, perform normalization, otherwise skip to imputation
if(all(as.numeric(unlist(my.count.data[nrow(my.count.data),]))%%1==0)){
  ## normalization##############################
  sce <- tryCatch(computeSumFactors(sce),error = function(e1) {
    tryCatch(normalizeSCE(sce),error = function(e2){
      LogNormalize(my.count.data)
    })
    })
  if (class(sce)[1] == "dgCMatrix") {
    my.normalized.data <- sce
  } else {
    sce <- scater::normalize(sce,return_log=F)
    my.normalized.data <- normcounts(sce)
  }
  
} else {
  my.normalized.data <- my.count.data
}

## imputation#################################
if (is_imputation == '1') {
  my.imputated.data <- DrImpute(as.matrix(my.normalized.data),dists = "spearman")
} else {
  my.imputated.data <- my.normalized.data
}
rm(my.normalized.data)

colnames(my.imputated.data)<-colnames(my.count.data)
rownames(my.imputated.data)<-rownames(my.count.data)
rm(my.count.data)

my.imputated.data<- as.sparse(my.imputated.data)
my.imputated.data<-log1p(my.imputated.data)

dim(my.imputated.data)
dim(expFile)

#my.imputated.data <- as.matrix(exp_data)
my.object<-CreateSeuratObject(my.imputated.data)
my.object<-SetAssayData(object = my.object,slot = "data",new.data = my.imputated.data,assay="RNA")

cell_names <- colnames(my.object)
rm(my.imputated.data)

## calculate filtering rate
#filter_gene_num <- nrow(expFile)-nrow(my.object)
filter_gene_num <- total_gene_num-nrow(my.object)
filter_gene_rate <- formatC(filter_gene_num/total_gene_num,digits = 2)
filter_cell_num <- total_cell_num-ncol(my.object)
filter_cell_rate <- formatC(filter_cell_num/total_cell_num,digits = 2)
if(filter_cell_num == 0){
  filter_cell_rate <- '0'
}


exp_data <- GetAssayData(object = my.object,slot = "data")
write(paste("filter_gene_num,",as.character(filter_gene_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("total_gene_num,",as.character(total_gene_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("filter_gene_rate,",as.character(filter_gene_rate),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("filter_cell_num,",as.character(filter_cell_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("total_cell_num,",as.character(total_cell_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("filter_cell_rate,",as.character(filter_cell_rate),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("main_species,",main_species,sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write.table(data.frame("Gene"=rownames(exp_data),exp_data,check.names = F),paste(jobid,"_filtered_expression.txt",sep = ""), row.names = F,sep="\t",quote=FALSE)
gene_name <- rownames(exp_data)
write.table(gene_name,paste(jobid,"_gene_name.txt",sep = ""), sep="\t",row.names = F,col.names = F,quote = F)

rm(expFile)
rm(sce)
rm(db)

if (label_file == 0 | label_file==1){
  cell_info <- colnames(exp_data)
} else {
  if(delimiter == 'tab'){
    delimiter <- '\t'
  }
  if(delimiter == 'space'){
    delimiter <- ' '
  }
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delimiter)
  cell_info[,2] <- as.factor(cell_info[,2])
}

my.object<-FindVariableFeatures(my.object,selection.method = "vst",nfeatures = 5000)

# before PCA, scale data to eliminate extreme value affect.
all.gene<-rownames(my.object)
my.object<-ScaleData(my.object,features = all.gene)
# after scaling, perform PCA

my.object<-RunPCA(my.object,rev.pca = F,features = VariableFeatures(object = my.object), npcs = 10)


my.object<-FindNeighbors(my.object,dims = 1:10)
my.object<-FindClusters(my.object)
if (length(levels(my.object$seurat_clusters)) == 1) {
  my.object<-FindClusters(my.object, resolution = 1)
}
cell_info <- my.object$seurat_clusters
cell_info <- as.factor(as.numeric(cell_info))
cell_label <- cbind(cell_names,cell_info)
colnames(cell_label) <- c("cell_name","label")
cell_label <- cell_label[order(cell_label[,2]),]
write.table(cell_label,paste(jobid,"_sc3_label.txt",sep = ""),quote = F,row.names = F,sep = "\t")


###########################################
#  Run TSNE and UMAP ######################
###########################################
#my.object<-RunTSNE(my.object,dims = 1:30,perplexity=10,dim.embed = 3)
# run umap to get high dimension scatter plot at 2 dimensional coordinate system.
my.object<-RunUMAP(object = my.object,dims = 1:10,umap.method="uwot")
#clustering by using Seurat KNN. 
# clustering by using KNN, this is seurat cluster algorithm, this part only for cell categorization
# here has one problems: whether should we define the clustering number?

# find clustering, there will be changing the default cell type, if want to use customized cell type. 
# use Idents() function.


#dist.matrix <- dist(x = Embeddings(object = my.object[['pca']])[,1:30])
dist.matrix <- dist(x = Embeddings(object = my.object[['pca']]))
sil <- silhouette(x = as.numeric(x = cell_info), dist = dist.matrix)
if (!is.na(sil)){
  silh_out <- cbind(cell_info,cell_names,sil[,3])
  silh_out <- silh_out[order(as.numeric(silh_out[,1])),]
} else {
  silh_out <- cbind(cell_info,cell_names,rep(0,length(cell_info)))
  silh_out <- silh_out[order(as.numeric(silh_out[,1])),]
}

# set max row,
if (ncol(my.object) > 500) {
  this_bin <- ncol(my.object) %/% 500
  small_cell_idx <- seq(1,ncol(my.object),by=this_bin)
  silh_out <- silh_out[small_cell_idx,]
} 
write.table(silh_out,paste(jobid,"_silh.txt",sep=""),sep = ",",quote = F,col.names = F,row.names = F)

#write.table(cell_label,paste(jobid,"_cell_label.txt",sep = ""),quote = F,row.names = F,sep = "\t")

if (label_use_sc3 =='2'){
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delimiter)
  ## check if user's label has valid number of rows, if not just use predicted value
  if (nrow(cell_info) == nrow(cell_label)){
    original_cell_info <- as.factor(cell_info[,2])
    cell_info[,2] <- as.numeric(as.factor(cell_info[,2]))
    rownames(cell_info) <- cell_info[,1]
    cell_info <- cell_info[,-1]
  } else {
    cell_info <-  my.object$seurat_clusters
    #cell_info <- as.factor(mydata1$MMdetail)
  }
} 

my.object<-AddMetaData(my.object,cell_info,col.name = "Customized.idents")
Idents(my.object)<-as.factor(my.object$Customized.idents)

## get marker genes
my.cluster<-as.character(sort(unique(as.numeric(Idents(my.object)))))
my.marker<-FindAllMarkers(my.object,only.pos = T)

mt <- my.marker[order(my.marker$p_val_adj), ]
d <- by(mt, mt["cluster"], head, n=100)
my.marker <- Reduce(rbind, d)

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

dir.create("regulon_id")
my.top <- my.top[,sort_column(my.top)]
write.table(my.top,file = "cell_type_unique_marker.txt",quote = F,row.names = F,sep = "\t")
saveRDS(my.object,file="seurat_obj.rds")

###### Remove Monocle trajectory ###########
#cds<-importCDS(my.object,import_all = T)
#cds<- estimateSizeFactors(cds)
#cds<-reduceDimension(cds,max_components = 2, method='DDRTree')
# test time and RAM
# library(profvis)
# profvis({
#   monocle_obj<-reduceDimension(monocle_obj,max_components = 2, method='DDRTree')
# })
#cds<-orderCells(cds)
#saveRDS(cds,file="monocle_obj.rds")
###### Remove Monocle trajectory ###########


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
                        labels=paste0(tmp.celltype,":(",as.character(summary(my.plot.all.source$Cell_type)),")")[1:length(tmp.celltype)]) +
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
    tmp.cell.type<-as.character(as.numeric(my.object$seurat_clusters))
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

if (label_use_sc3 =='1' | label_use_sc3 =='2'){
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delimiter)
  ## check if user's label has valid number of rows, if not just use predicted value
  original_cell_info <- as.factor(cell_info[,2])
  cell_info[,2] <- as.factor(cell_info[,2])
  rownames(cell_info) <- cell_info[,1]
  cell_info <- cell_info[,-1]
  
  
  my.object<-AddMetaData(my.object,cell_info,col.name = "Customized.idents")
  Idents(my.object)<-as.factor(my.object$Customized.idents)
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

my.object<-AddMetaData(my.object,cell_info,col.name = "Customized.idents")
Idents(my.object)<-as.factor(my.object$Customized.idents)
png(paste("regulon_id/overview_provide_ct.png",sep = ""),width=2000, height=1500,res = 300)
Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size, reverse_color = F)
quiet(dev.off())

pdf(file = paste("regulon_id/overview_provide_ct.pdf",sep = ""), width = 16, height = 12,  pointsize = 12, bg = "white")
Plot.cluster2D(reduction.method = "umap",customized = T, reverse_color = F)
quiet(dev.off())

## save top 10 marker plots
#for (i in 1:length(levels(Idents(my.object)))) {
#  png(paste("regulon_id/CT",i,"_top10_marker_violin.png",sep = ""),width=4000, height=1500,res = 300)
#  print(VlnPlot(my.object, features = my.top[1:10,i],assay = "RNA",ncol=5))
#  quiet(dev.off())
#  pdf(file = paste("regulon_id/CT",i,"_top10_marker_violin.pdf",sep = ""), width = 20, height = 7,  pointsize = 12, bg = "white")
#  print(VlnPlot(my.object, features = my.top[1:10,i],assay = "RNA",ncol=5))
#  quiet(dev.off())
#  png(paste("regulon_id/CT",i,"_top10_marker_heatmap.png",sep = ""),width=2500, height=1200,res = 300)
#  print(DoHeatmap(my.object, features = as.character(my.top[1:10,i]),assay = "RNA"))
#  quiet(dev.off())
#  pdf(file = paste("regulon_id/CT",i,"_top10_marker_heatmap.pdf",sep = ""), width = 16, height = 8,  pointsize = 12, bg = "white")
#  print(DoHeatmap(my.object, features = as.character(my.top[1:10,i]),assay = "RNA"))
#  quiet(dev.off())
#}
#

#my.trajectory<-SingleCellExperiment(assays=List(counts=GetAssayData(object = my.object[['RNA']],slot="counts")))
my.trajectory<-SingleCellExperiment(
  assays = list(
    counts = GetAssayData(object = my.object[['RNA']],slot="counts")
  ), 
  colData = Idents(my.object)
)
SummarizedExperiment::assays(my.trajectory)$norm<-GetAssayData(object = my.object,slot = "data")

dm<-DiffusionMap(t(as.matrix(SummarizedExperiment::assays(my.trajectory)$norm)))
rd2 <- cbind(DC1 = dm$DC1, DC2 = dm$DC2)
reducedDims(my.trajectory) <- SimpleList(DiffMap = rd2)
saveRDS(my.trajectory,file="trajectory_obj.rds")

png(paste("regulon_id/overview_ct.trajectory.png",sep = ""),width=2000, height=1500,res = 300)
Plot.Cluster.Trajectory(customized= T,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)
quiet(dev.off())

pdf(file = paste("regulon_id/overview_ct.trajectory.pdf",sep = ""), width = 10, height = 10,  pointsize = 18, bg = "white")
Plot.Cluster.Trajectory(customized= T,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)
quiet(dev.off())


if (label_use_sc3 =='1' ){
  png(paste("regulon_id/overview_ct.trajectory.png",sep = ""),width=2000, height=1500,res = 300)
  Plot.Cluster.Trajectory(customized= F,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)
  quiet(dev.off())
  
  pdf(file = paste("regulon_id/overview_ct.trajectory.pdf",sep = ""), width = 10, height = 10,  pointsize = 18, bg = "white")
  Plot.Cluster.Trajectory(customized= F,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)
  quiet(dev.off())
} 
