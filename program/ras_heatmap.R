job <- read.table("/var/www/html/CeRIS/data/20191101133117/job",sep="\t")
job <- job[c(-5,-6,-14,-16),]

job_list <- as.character(job$V1)

#for (i in 1:length(job_list)) {
#  setwd(paste("/var/www/html/CeRIS/data/",job_list[i],sep=""))
#  system(paste("Rscript /var/www/html/CeRIS/program/generate_rss_scatter.R ",job_list[i],sep=""))
#}

out <- list(NA)
for (i in 1:length(job_list)) {
  setwd(paste("/var/www/html/CeRIS/data/",job_list[i],sep=""))
  out[[i]] <-  list(as.numeric(read.table(paste(job_list[i],"_combine_regulon.txt",sep=""),sep = "\t")[-1,3]))
  names(out[[i]]) <- as.character(job[i,2])
}


df <- melt(out)
df$L2 <- as.factor(df$L2)

ggplot(df, aes(x=L2, y=value,fill=as.character(L2))) + 
  geom_violin(trim=T,width=1.0) + 
  scale_color_brewer(palette="Set1") +
  geom_boxplot(width=0.13,fill="white",col="black") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size=9,color="#666666"),legend.position = "none")


setwd(paste("/var/www/html/CeRIS/data/",job_list[i],sep=""))
total_ct <- max(na.omit(as.numeric(stringr::str_match(list.files(path = getwd()), "_CT_(.*?)_bic")[,2])))
label_data <- read.table(paste(job_list[i],"_cell_label.txt",sep = ""),sep="\t",header = T)

label <- as.data.frame(as.factor(label_data[,-1]))
rownames(label) <- label_data[,1]




total_ras_list <- list()
for (j in 1:total_ct) {
  ras <- read.table(paste(job_list[i],"_CT_",j,"_bic.regulon_activity_score.txt",sep = ""),sep = "\t",header = T,check.names = F)
  if(nrow(ras) > 10) {
    total_ras_list <- rbind(total_ras_list,ras[1:10,])
  } else {
    total_ras_list <- rbind(total_ras_list,ras)
  }
} 
rownames(total_ras_list) <- total_ras_list[,1]
total_ras_list <- total_ras_list[,-1]
total_ras_list <- (total_ras_list - rowMeans(total_ras_list))/rowSds(as.matrix(total_ras_list), na.rm=TRUE)
total_ras_list <- total_ras_list[,label_data[,1]]
pheatmap(total_ras_list,cluster_rows = F,cluster_cols = F,show_colnames = F, annotation_col = label)
