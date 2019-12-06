









setwd("/fs/project/PAS1475/Yuzhou_Chang/IRIS3/test_data/20190906114155/")
my.raw.data<-read_data(x = "20190906114155_raw_expression.txt",sep="\t",read.method = "CellGene")
my.object<-CreateSeuratObject(my.raw.data)
my.count.data<-GetAssayData(object = my.object[['RNA']],slot="counts")
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

my.imputated.data <- DrImpute(as.matrix(my.normalized.data))
colnames(my.imputated.data)<-colnames(my.count.data)
rownames(my.imputated.data)<-rownames(my.count.data)
my.imputated.data<- as.sparse(my.imputated.data)
my.imputatedLog.data<-log1p(my.imputated.data)
my.object<-SetAssayData(object = my.object,slot = "data",new.data = my.imputatedLog.data,assay="RNA")
my.export.for_LFMG<-my.imputated.data
my.export.rownames<-c(rownames(my.imputated.data))
my.export.for_LFMG<-data.frame(Gene=my.export.rownames,my.imputated.data,check.names = F)
save(my.export.for_LFMG,file = "my.export.for_LFMG.RDS")
write.table(my.export.for_LFMG,"Imputated.expressionMatirx.txt",quote = F,row.names=F,sep="\t")
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
my.object<-FindVariableFeatures(my.object,selection.method = "vst",nfeatures = 2000)
all.gene<-my.object@assays$RNA@var.features
my.object<-ScaleData(my.object,features = all.gene)
my.object<-RunPCA(my.object,rev.pca = F,features = VariableFeatures(object = my.object))
my.object<-RunUMAP(object = my.object,dims = 1:30,umap.method="uwot")
# silhouette score calculation
#dist.matrix <- dist(x = Embeddings(object = my.object[['pca']])[,1:30])
dist.matrix <- dist(x = Embeddings(object = my.object[['umap']]))
sil <- silhouette(x = as.numeric(x = cell_info), dist = dist.matrix)
silh_out <- cbind(cell_info,cell_names,sil[,3])
silh_out <- silh_out[order(silh_out[,1]),]
write.table(silh_out,paste(jobid,"_silh.txt",sep=""),sep = ",",quote = F,col.names = F,row.names = F)

# ElbowPlot(object = my.object)
my.object<-RunTSNE(my.object,dims = 1:10,perplexity=10,dim.embed = 3)
my.object<-RunUMAP(my.object,dims=1:10)
# my.object<-FindNeighbors(my.object,k.param = 20,dims = 1:30)
# my.object<-FindClusters(my.object,resolution = 0.5)
# plot
activity_score <- read.table(paste(jobid,"_CT_",4,"_bic.regulon_activity_score.txt",sep = ""),row.names = 1,header = T,check.names = F)
Plot.cluster2D(customized = T,pt_size = pt_size)
Plot.regulon2D(reduction.method = "umap",regulon = 1,customized = T,cell.type=4,pt_size = pt_size)
#####
my.RAS.filelist<-list.files(pattern = "_activity_score.txt")
my.order<- sapply(strsplit(my.RAS.filelist,"_"),"[",3)
my.regulon.cell.Matrix<-c()
for(i in 1:length(my.RAS.filelist)){
  tmp.file.index<-grep(my.order[i],paste0("_CT",my.order[i],"_bic.regulon_activity_score.txt$"))
  tmp.x<-read.delim(my.RAS.filelist[tmp.file.index])
  rownames(tmp.x)<-paste0("CT_",my.order[i],"_Regulon","_",1:nrow(tmp.x))
  my.regulon.cell.Matrix<-rbind.data.frame(my.regulon.cell.Matrix,tmp.x)
}
my.count.data<-my.object@assays$RNA@data
my.trajectory<-SingleCellExperiment(assays=List(counts=my.count.data))
reducedDims(my.trajectory)<-Dim.Calculate(Matrix.type="GEM")

Plot.Cluster.Trajectory(customized= T,start.cluster=NULL,add.line = T,end.cluster=NULL,show.constraints=T)

