####### preprocessing expression matrix based on Seurat ##########
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
suppressPackageStartupMessages(library(xfun))
suppressPackageStartupMessages(library(reader))
suppressPackageStartupMessages(library(harmony))

args <- commandArgs(TRUE)
jobid <- args[1] # user job id
expr_file <- args[2] # raw user filename
delim <- args[3] #delimiter for expr matrix
label_file <- 1
label_file <- args[4] # user label file name or 1
delimiter <- args[5] # delimter for cell label
is_imputation <- args[6] #1 for enable imputation
resolution_seurat <- args[7] # resolution for seurat clustering
n_pc <- args[8] # number of principle components
n_variable_feature <- args[9] # number of highly variable genes 
label_use_predict <- args[10] # 0 for using Seurat clusters, 2 for using user's label,
remove_ribosome <- args[11] # Yes or No
integration_method <- args[12] # Integration method

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
  # setwd("C:/Users/flyku/Desktop/liyang")
  setwd("/var/www/html/iris3/data/20200916202630")
  jobid <- "20200916202630"
  delim <- ","
  label_file <- "1"
  delimiter <- '\t'
  is_imputation <- 'No'
  n_pc <- "10"
  n_variable_feature <- "5000"
  resolution_seurat <- 0.5
  label_use_predict <- '0'
  remove_ribosome <- 'No'
  integration_method <- 'Seurat'
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
        
        all_files <- list.files(getwd())
        barcode_file <- grep("barcodes",all_files)
        matrix_file <- grep("matrix",all_files)
        gene_file <- grep("genes",all_files)
        feature_file <- grep("features",all_files)
        
        #Check users upload single zipped file, by counting detected filename, if less than 3 we think users uploads zipped file
        if((length(barcode_file) + length(matrix_file) + length(gene_file) + length(feature_file)) < 3) {
          dir.create("tmp",showWarnings = F)
          if (file_ext(x) == "7z") {
            try(system(paste("7za x", x, "-aoa -otmp")),silent = T)
          }
          try(system(paste("unzip -o", x, "-d tmp")),silent = T)
          try(system(paste("tar xzvf", x, "--directory tmp")),silent = T)
          
          # check if the file is gz instead of tar.gz
          max_file <- which.max(file.info(list.files("tmp",full.names = T,recursive = T))[,1])
          this_files <- list.files("tmp",full.names = T,recursive = T)[max_file]
          if(is.na(this_files) || file_ext(this_files) == "tar" || length(this_files) == 0) {
            system("rm -R tmp/*")
            this_filename <- gsub(".gz","",basename(x))
            try(system(paste("gunzip -c ", x, " > tmp/",this_filename,sep="")),silent = T)
            max_file <- which.max(file.info(list.files("tmp",full.names = T,recursive = T))[,1])
            this_files <- list.files("tmp",full.names = T,recursive = T)[max_file]
            this_delim <- reader::get.delim(this_files)
            tmp_z <- tryCatch(read.delim(paste0(this_files),header = T,row.names = NULL,check.names = F,sep=this_delim),error = function(e) 0)
            upload_type <<- "CellGene"
            return(tmp_z)
          }
          
          max_file <- which.max(file.info(list.files("tmp",full.names = T,recursive = T))[,1])
          this_files <- list.files("tmp",full.names = T,recursive = T)[max_file]
          
          
          # incase folder contains 10X files
          tmp_x <- tryCatch(Read10X(gsub(basename(this_files),"",this_files)),error = function(e) 0)
          
          if (typeof(tmp_x) == "S4") {
            system("rm -R tmp/*")
            return(tmp_x)
          } else if(file_ext(this_files) == "h5" || file_ext(this_files) == "hdf5") {
            tmp_y <- tryCatch(Read10X_h5(this_files),error = function(e) 0)
            upload_type <<- "TenX.h5"
            system("rm -R tmp/*")
            return(tmp_y)
          } else {
            this_delim <- reader::get.delim(this_files)
            tmp_z <- tryCatch(read.delim(paste0(this_files),header = T,row.names = NULL,check.names = F,sep=this_delim),error = function(e) 0)
            upload_type <<- "CellGene"
            system("rm -R tmp/*")
            return(tmp_z)
          }
          
        }
        
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
##############################


getwd()

input_dir <- list.dirs("input")[-1]
input_gene_file <- list.files("input",recursive = T,pattern = "genes.tsv.gz$")

all_files <- list.files("input",recursive = T)

fileConn<-file("integration_input.txt")
writeLines(all_files, fileConn)
close(fileConn)

# For old files named as genes.tsv.gz
if(length(input_gene_file) > 0) {
  for (i in 1:length(input_gene_file)) {
    tmp_dir <- strsplit(input_gene_file,"/")[[1]][1]
    system(paste0("cp input/",input_gene_file[i], " input/",tmp_dir,"/features.tsv.gz"))
  }
}



raw_sample <- list()
current_tmp_type <- ""
for (i in 1:length(input_dir)) {
  # First try to load 10X folder, then 10X h5
  tmp <- tryCatch(Read10X(input_dir[i]),error=function(e1){
    h5_file_name <- list.files(input_dir[i], pattern = "h5|hdf5",full.names = T)[1]
    csv_file_name <- list.files(input_dir[i], pattern = "csv|tsv",full.names = T)[1]
    zip_csv_file_name <- list.files(input_dir[i], pattern = ".gz|.tar.gz|.zip",full.names = T)[1]
    if(!is.na(h5_file_name)) {
      return(Read10X_h5(h5_file_name))
    } else if (!is.na(csv_file_name)) {
      current_tmp_type <<- "CellGene"
      return(read_data(csv_file_name, read.method = "CellGene",sep = get.delim(csv_file_name)))
    } else if (!is.na(zip_csv_file_name)) {
      current_tmp_type <<- "CellGene"
      return(read_data(zip_csv_file_name, read.method = "TenX.folder",sep = ","))
    }
  })
  
  # Prevent multi mordality in a single file
  if(class(tmp) == "list"){
    tmp <- tmp[[1]]
  }
  
  if (current_tmp_type == "CellGene"){
    ## case: gene with id with ENSG########.X, remove part after dot, e.g:
    ## a <- c("ENSG00000064545.10","ENSG000031230064545","ENMUSG00003213004545.31234s")
    match_index <- grep("^ENSG.+\\.[0-9]",ignore.case = T,tmp[,1])
    if (length(match_index) > 0){
      match_rownames <- tmp[match_index,1]
      tmp[,1] <- as.character(tmp[,1])
      tmp[match_index,1] <- gsub('\\..+','',match_rownames)
    }
    
    ## case above but for mouse: ENSMUSGXXXXX.X
    match_index <- grep("^ENSMUSG.+\\.[0-9]",ignore.case = T,tmp[,1])
    if (length(match_index) > 0){
      match_rownames <- tmp[match_index,1]
      tmp[,1] <- as.character(tmp[,1])
      tmp[match_index,1] <- gsub('\\..+','',match_rownames)
    }
    
    ## case: genes with format like (AADACL3|chr1|12776118), remove part after |, e.g:
    ## a <- c("AADACL3|chr1|12776118","KLHDC8A|chr1|205305648","KIF21B|chr1|200938514")
    match_index <- grep("^[a-z].+\\|",ignore.case = T,tmp[,1])
    if (length(match_index) > 0){
      match_rownames <- tmp[match_index,1]
      tmp[,1] <- as.character(tmp[,1])
      tmp[match_index,1] <- gsub('\\|.+','',match_rownames)
    }
    
    ##remove duplicated rows with same gene 
    if(length(which(duplicated.default(tmp[,1]))) > 0 ){
      tmp <- tmp[-which(duplicated.default(tmp[,1])==T),]
    }	
    
    ##Filter rows if gene name equals to NA
    if(length(which(is.na(tmp[,1]))) > 0){
      tmp <- tmp[-which(is.na(tmp[,1])),]
    }
    rownames(tmp) <- tmp[,1]
    tmp<- tmp[,-1]
  }
  
  ## Rename column incase specital characters
  colnames(tmp) <-  gsub('([[:punct:]])|\\s+','_',colnames(tmp))
  colnames(tmp) <- paste0("s",i,"_",colnames(tmp))
  
  
  # For testing, subset the matrix
  # tmp <- tmp[1:10000,1:1000]
  # Prevent users upload raw feature barcode matrix, which contains 730k cells
  if (ncol(tmp) > 700000) {
    raw_sample[i] <- CreateSeuratObject(tmp, assay = "RNA", min.cells = 3, min.features = 200, project = paste0("Sample",i))
  } else {
    raw_sample[i] <- CreateSeuratObject(tmp, assay = "RNA", project = paste0("Sample",i))
  }
}

expFile <- GetAssayData(Reduce(merge, raw_sample),slot = "counts")

total_gene_num <- nrow(expFile)
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
#species_file <- 'Human'
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

all_match <- AnnotationDbi::select(main_db, keys = rownames(expFile), columns = c("SYMBOL","ENSEMBL"),keytype = main_identifier)
all_match <- na.omit(all_match)

# Removed old merging method since it is very likely to exceed R matrix size limit when performing data integration
expFile <- expFile[rownames(expFile) %in% all_match[,1],]

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

## remove ribosome genes first if user selected#################################
if(exists("remove_ribosome")) {
  if (remove_ribosome == "Yes") {
    if(length(grep("^Rp[sl][[:digit:]]", rownames(expFile))) > 0) {
      expFile <- expFile[-grep("^Rp[sl][[:digit:]]", rownames(expFile)),]
    }
  }
}


my.object <- CreateSeuratObject(expFile)
my.object[["percent.mt"]] <- PercentageFeatureSet(my.object, pattern = "^MT-")
my.object <- (subset(my.object, subset = nCount_RNA > 200 & nFeature_RNA < 5000 & percent.mt < 15))

## calculate filtering rate
#filter_gene_num <- nrow(expFile)-nrow(my.object)
filter_gene_num <- total_gene_num-nrow(my.object)
filter_gene_rate <- formatC(filter_gene_num/total_gene_num,digits = 2)
filter_cell_num <- total_cell_num-ncol(my.object)
filter_cell_rate <- formatC(filter_cell_num/total_cell_num,digits = 2)
if(filter_cell_num == 0){
  filter_cell_rate <- '0'
}



write(paste("filter_gene_num,",as.character(filter_gene_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("total_gene_num,",as.character(total_gene_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("filter_gene_rate,",as.character(filter_gene_rate),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("filter_cell_num,",as.character(filter_cell_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("total_cell_num,",as.character(total_cell_num),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("filter_cell_rate,",as.character(filter_cell_rate),sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
write(paste("main_species,",main_species,sep=""),file=paste(jobid,"_info.txt",sep=""),append=TRUE)
gene_name <- rownames(my.object)
write.table(gene_name,paste(jobid,"_gene_name.txt",sep = ""), sep="\t",row.names = F,col.names = F,quote = F)
cat("cell_cluster_prediction", file="running_status.txt")
#rm(expFile)

rm(db)

if (label_file == 0 | label_file==1){
  cell_info <- colnames(my.object)
} else {
  if(delimiter == 'tab'){
    delimiter <- '\t'
  }
  if(delimiter == 'space'){
    delimiter <- ' '
  }
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delimiter)
  cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
  cell_info[,2] <- as.factor(cell_info[,2])
  ## when users did not provide header
  if(nrow(cell_info) == ncol(my.object) - 1) {
    cell_info <- read.table(label_file,check.names = FALSE, header=F,sep = delimiter)
    cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
    cell_info[,2] <- as.factor(cell_info[,2])
  }
  ## when users uploads label with #1,2,3 as rownames
  if(ncol(cell_info) > 2 && cell_info[1,1] == 1) {
    cell_info <- read.table(label_file,check.names = FALSE, header=T,sep = delimiter, row.names = 1)
    cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
    cell_info[,2] <- as.factor(cell_info[,2])
  }
}


if(n_variable_feature == "all" | as.numeric(n_variable_feature) > nrow(my.object)) {
  n_variable_feature <- nrow(my.object)
}

if(as.numeric(n_pc) > ncol(my.object)) {
  n_pc <- ncol(my.object)
}

## Add sample information after pre-processing
cell_sample_identifier <- sapply(strsplit(colnames(my.object),"_"), function(x){
  return(x[[1]])
})
names(cell_sample_identifier) <- colnames(my.object)
cell_sample_identifier <- as.factor(cell_sample_identifier)
my.object <- AddMetaData(my.object, cell_sample_identifier, col.name = "sample")

#my.object <- my.object1
if(integration_method == "Seurat") {
  combine.list <- SplitObject(my.object, split.by = "sample")
  combine.list <- lapply(X = combine.list, FUN = function(x) {
    x <- NormalizeData(x)
    x <- FindVariableFeatures(x, selection.method = "vst", nfeatures = 2000)
  }) 
  
  combine.anchors <- FindIntegrationAnchors(object.list = combine.list, dims = 1:30)
  my.object <- IntegrateData(anchorset = combine.anchors, dims = 1:30)
  my.object <- ScaleData(my.object, verbose = FALSE) 
  my.object <- RunPCA(my.object, npcs = as.numeric(n_pc), verbose = F)
  my.object <- RunUMAP(my.object, reduction = "pca", dims = 1:as.numeric(n_pc))
  my.object <- FindNeighbors(my.object,reduction = "pca",dims = 1:as.numeric(n_pc))
  my.object <- FindClusters(my.object, resolution = as.numeric(resolution_seurat))
  if (length(levels(my.object$seurat_clusters)) == 1) {
    my.object<-FindClusters(my.object, resolution = 1)
  }
  DefaultAssay(my.object) <- "RNA"
} else if (integration_method == "Harmony") {
  #my.object <- CreateSeuratObject(counts = cbind(health.obj, disease_matrix), project = "all", min.cells = 5, meta.data = this_meta)
  my.object <- NormalizeData(my.object, verbose = F)
  my.object <- FindVariableFeatures(my.object, selection.method = "vst", nfeatures = n_variable_feature) 
  my.object <- ScaleData(my.object, verbose = FALSE) 
  my.object <- RunPCA(my.object, npcs = as.numeric(n_pc), verbose = F)
  my.object <- RunHarmony(my.object, "sample", plot_convergence = F)
  my.object <- RunUMAP(my.object, reduction = "harmony", dims = 1:as.numeric(n_pc))
  my.object <- FindNeighbors(my.object, reduction = "harmony", dims = 1:as.numeric(n_pc))
  my.object <- FindClusters(my.object, resolution = as.numeric(resolution_seurat))
  DefaultAssay(my.object) <- "RNA"
}

DefaultAssay(my.object) <- "RNA"
exp_data <- GetAssayData(object = my.object,slot = "data")
write.table(data.frame("Gene"=rownames(exp_data),exp_data,check.names = F),paste(jobid,"_filtered_expression.txt",sep = ""), row.names = F,sep="\t",quote=FALSE)
rm(exp_data)
DefaultAssay(my.object) <- "integrated"
#DimPlot(my.object,reduction = "umap")
cell_names <- colnames(my.object)

levels(my.object$seurat_clusters) <- 1:length(levels(my.object$seurat_clusters))
cell_info <- my.object$seurat_clusters
cell_info <- as.factor(as.numeric(cell_info))
cell_label <- cbind(cell_names,cell_info)
colnames(cell_label) <- c("cell_name","label")
cell_label <- cell_label[order(cell_label[,1]),]
write.table(cell_label,paste(jobid,"_predict_label.txt",sep = ""),quote = F,row.names = F,sep = "\t")


#dist.matrix <- dist(x = Embeddings(object = my.object[['pca']])[,1:30])
umap_embeddings <- Embeddings(object = my.object[['umap']])

if (ncol(my.object) > 10000) {
  this_bin <- ncol(my.object) %/% 10000
  small_cell_idx <- seq(1,ncol(my.object),by=this_bin)
  dist.matrix <- dist(x = Embeddings(object = my.object[['pca']])[small_cell_idx,])
  sil <- silhouette(x = as.numeric(x = cell_info[small_cell_idx]), dist = dist.matrix)
} else {
  dist.matrix <- dist(x = Embeddings(object = my.object[['pca']]))
  sil <- silhouette(x = as.numeric(x = cell_info), dist = dist.matrix)
}


if (any(!is.na(sil))){
  silh_out <- cbind(cell_info,cell_names,sil[,3])
  silh_out <- silh_out[order(as.numeric(silh_out[,1])),]
} else {
  silh_out <- cbind(cell_info,cell_names,rep(0,length(cell_info)))
  silh_out <- silh_out[order(as.numeric(silh_out[,1])),]
} 
rm(dist.matrix)
# set max row,
if (ncol(my.object) > 500) {
  this_bin <- ncol(my.object) %/% 500
  small_cell_idx <- seq(1,ncol(my.object),by=this_bin)
  silh_out <- silh_out[small_cell_idx,]
} 
write.table(silh_out,paste(jobid,"_silh.txt",sep=""),sep = ",",quote = F,col.names = F,row.names = F)

#write.table(cell_label,paste(jobid,"_cell_label.txt",sep = ""),quote = F,row.names = F,sep = "\t")
#DimPlot(my.object,reduction = 'umap')
#saveRDS(my.object,"my.object.rds")
#my.object <- readRDS("my.object.rds")
if (label_use_predict =='2'){
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delimiter,stringsAsFactors = F)
  cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
  cell_info <- cell_info[order(cell_info[,1]),]
  ## when users did not provide header
  if(nrow(cell_info) == ncol(my.object) - 1) {
    cell_info <- read.table(label_file,check.names = FALSE, header=F,sep = delimiter)
    cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
    cell_info[,2] <- as.factor(cell_info[,2])
  }
  ## when users uploads label with #1,2,3 as rownames
  if(ncol(cell_info) > 2 && cell_info[1,1] == 1) {
    cell_info <- read.table(label_file,check.names = FALSE, header=T,sep = delimiter, row.names = 1)
    cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
    cell_info[,2] <- as.factor(cell_info[,2])
  }
  ## check if user's label has valid number of rows, if not just use predicted value
  if (nrow(cell_info) == nrow(cell_label)){
    original_cell_info <- as.factor(cell_info[,2])
    #cell_info[,2] <- as.character(original_cell_info)
    my.object <- AddMetaData(my.object, as.character(original_cell_info), col.name = "Provided.idents")
    cell_info[,2] <- as.numeric(as.factor(cell_info[,2]))
    rownames(cell_info) <- cell_info[,1]
    cell_info <- cell_info[,-1]
  } else {
    original_cell_name_in_object <- str_remove(colnames(my.object), "s[0-9]+_")
    filter_cell_info <- dplyr::filter(cell_info, cell_info[,1] %in% original_cell_name_in_object)
    cell_info <- filter_cell_info[match(original_cell_name_in_object, filter_cell_info[,1]),2]
    #filter_cell_info[1:10,1]
    #cell_info[1:10,]
    #colnames(my.object)[1:10]
    #original_cell_name_in_object[1:10]
    my.object <- AddMetaData(my.object, as.character(cell_info), col.name = "Provided.idents")
  }
} else {
  my.object <- AddMetaData(my.object, cell_label[,2], col.name = "Provided.idents")
}

my.object <-AddMetaData(my.object,cell_info,col.name = "Customized.idents")
my.object$Customized.idents <- as.factor(my.object$Customized.idents)

#Plot.cluster2D(reduction.method = "umap",customized = T,pt_size = pt_size)

#DimPlot(my.object,reduction = 'umap')
## get marker genes
my.cluster<-as.character(sort(unique(as.numeric(Idents(my.object)))))
my.marker<-FindAllMarkers(my.object,only.pos = T,min.pct = 0.25, logfc.threshold = 0.5)

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

dir.create("json",showWarnings = F)
## save marker genes to json format, used in result page
for(i in 1: length(my.cluster)){
  this_marker <- my.marker[which(my.marker[,6] == i),]
  my.marker_json <- list(NULL)
  names(my.marker_json) <- 'data'
  colnames(this_marker) <- NULL
  if(nrow(this_marker) > 0) {
    this_marker[,6] <- paste("CT",this_marker[,6],sep = "")
    this_marker <- this_marker[,c(6,7,1:5)]
    my.marker_json$data <- this_marker
    my.marker_json <- toJSON(my.marker_json,pretty = T, simplifyDataFrame =F)
    write(my.marker_json, paste("json/",jobid,"_CT_",i,"_dge.json",sep=""))
  } else {
    this_marker <- list(c(paste0("CT",i),"Not found",NA,NA,NA,NA,NA))
    my.marker_json$data <- this_marker
    my.marker_json <- toJSON(my.marker_json,pretty = T, simplifyDataFrame =F)
    write(my.marker_json, paste("json/",jobid,"_CT_",i,"_dge.json",sep=""))
  }
}



sort_column <- function(df) {
  tmp <- colnames(df)
  split <- strsplit(tmp, "CT") 
  split <- as.numeric(sapply(split, function(x) x <- sub("", "", x[2])))
  return(order(split))
}

dir.create("regulon_id",showWarnings = F)
my.top <- my.top[,sort_column(my.top)]
write.table(my.top,file = "cell_type_unique_diffrenetially_expressed_genes.txt",quote = F,row.names = F,sep = "\t")

scatter_result <- cbind.data.frame(Embeddings(my.object, reduction = 'umap'),cell_type_index = my.object$Customized.idents,cell_type = my.object$Provided.idents,cell_name=colnames(my.object))
color_list <- as.character(palette36.colors(36))[-2][1:length(unique(my.object$Customized.idents))]
new_scatter_result <- list()

for (i in 1:length(unique(my.object$Customized.idents))) {
  this_idx <- which(scatter_result$cell_type_index == i)
  this_cell_type <- as.character(scatter_result[this_idx,4][1])
  this_cell_name <- rownames(scatter_result[this_idx,])
  this_data <- scatter_result[,c(1,2,5)][this_idx,]
  colnames(this_data) <- NULL
  rownames(this_data) <- NULL
  this_row <- list(list(name=i,color=color_list[i],cell_type=this_cell_type,data=this_data))
  
  new_scatter_result <- append(new_scatter_result,this_row)
}

res1 <- jsonlite::toJSON(new_scatter_result,pretty = F)
umap_embeddings_table <- data.frame()
for(i in 1:length(new_scatter_result)){
  x <- new_scatter_result[[i]]
  this_df <- data.frame(x$data,x$cell_type,x$name)
  colnames(this_df) <- c("umap1","umap2","cell_name","cell_cluster","index")
  this_df <- this_df[c(5,3,4,1,2)]
  umap_embeddings_table <- rbind(umap_embeddings_table,this_df)
}

write.table(umap_embeddings_table,paste0(jobid,'_umap_embeddings.txt'),sep = '\t',quote = F,row.names = F)
write(res1, paste("json/",jobid,"_umap.json", sep = ""))

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
    scale_colour_manual(name  ="Cell cluster:(Cells)",values  = color_array[1:length(tmp.celltype)],
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
           cex=1.0,title="Cell cluster",bty='n')
  } else {legend("topright",legend = tmp.color.cat$CellName,
                 inset=c(-0.05,0), ncol=1,
                 col = as.character(tmp.color.cat$Color),pch = 19,
                 cex=1.0,title="Cell cluster",bty='n')}
  
  
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

if (label_use_predict =='1' | label_use_predict =='2'){
  cell_info <- read.table(label_file,check.names = FALSE, header=TRUE,sep = delimiter)
  cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
  cell_info <- cell_info[order(cell_info[,1]),]
  ## when users did not provide header
  if(nrow(cell_info) == ncol(my.object) - 1) {
    cell_info <- read.table(label_file,check.names = FALSE, header=F,sep = delimiter)
    cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
    cell_info[,2] <- as.factor(cell_info[,2])
  }
  ## when users uploads label with #1,2,3 as rownames
  if(ncol(cell_info) > 2 && cell_info[1,1] == 1) {
    cell_info <- read.table(label_file,check.names = FALSE, header=T,sep = delimiter, row.names = 1)
    cell_info[,1] <-  gsub('([[:punct:]])|\\s+','_',cell_info[,1])
    cell_info[,2] <- as.factor(cell_info[,2])
  }
  
  original_cell_name_in_object <- str_remove(colnames(my.object), "s[0-9]+_")
  filter_cell_info <- dplyr::filter(cell_info, cell_info[,1] %in% original_cell_name_in_object)
  cell_info <- filter_cell_info[match(original_cell_name_in_object, filter_cell_info[,1]),2]
  
  #levels(my.object$Customized.idents) <- levels(original_cell_info)[c(5,6,7,4,1,2,3)]
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
if(ncol(my.object) < 30000){
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
}

