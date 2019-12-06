library(monocle3)
library(Matrix)
options(stringsAsFactors = F)
setwd("/BigData/analysis_work/IRIS3/DataTest/scRNA-Seq/2.Yan/")
# cell * gene matrix, gene in row, cell in column
HSMM_expr_matrix <- read.table("Yan_expression.txt",row.names = 1,check.names = F,header = T)
# cell condition, cell in row, condition in column
HSMM_sample_sheet <- read.delim("Yan_cell_label.txt",row.names = 1)
HSMM_sample_sheet$CellLabel<-as.character(HSMM_sample_sheet$Cluster)
# gene attribution: such as which gene define which cell type. 
# HSMM_gene_annotation <- read.delim("gene_annotations.txt")

sparse<-Matrix(as.matrix(HSMM_expr_matrix),sparse=T)
gene_annotation<-data.frame(row.names = rownames(sparse),gene_short_name=rownames(sparse))
cds <- new_cell_data_set(sparse,cell_metadata = HSMM_sample_sheet,gene_metadata = gene_annotation)
cds<-preprocess_cds(cds,norm_method = "log",num_dim = 30)
plot_pc_variance_explained(cds)
cds=reduce_dimension(cds)
plot_cells(cds,reduction_method = "PCA",color_cells_by ="CellLabel",cell_size = 2)
cds<-cluster_cells(cds)
plot_cells(cds,color_cells_by = "CellLabel")
cds<-learn_graph(cds)
plot_cells(cds,label_groups_by_cluster = F,label_leaves = F,label_branch_points = F)
