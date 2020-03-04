setwd("D:/Users/flyku/Documents/IRIS3-R/data")
file = read.table("scenic_regulon.csv",sep = ",",header = T)
colnames(file)[1] = "TF"

out_file <- "result.txt"
all_tf <- as.character(unique(file[,1]))
total_tf <-length(all_tf)

cat("",file=out_file)
for (i in 1:total_tf) {
  this_genes <- as.character(file[which(file[,1] == all_tf[i]),2])
  this_mean_weight <- mean(file[which(file[,1] == all_tf[i]),7])
  cat(paste(this_mean_weight,"\t",sep = ""),file=out_file,sep = "\t",append = T)
  cat(this_genes,file=out_file,sep = "\t",append = T)
  cat("\n",file=out_file,append = T)
}
