setwd("d:/Users/flyku/Documents/IRIS3-data/Puram")
library(plyr)
library(tidyverse)
label <- read.table("Puram_cell_label1.csv",header = T,stringsAsFactors = T,sep = ",")
label[,2] <- as.factor(label[,2])
levels(label[,2])[levels(label[,2])=="1"] <- "no"
levels(label[,2])[levels(label[,2])=="2"] <- "yes"
levels(label[,2])[levels(label[,2])=="0"] <- "unresolved"
colnames(label) <- c("cell_name","label")
write.table(label,"label1.csv",quote = F,sep = ",",row.names = F)

label <- read.table("Puram_cell_label2.csv",header = T,stringsAsFactors = T,sep = ",")
label[,2] <- as.factor(label[,2])
levels(label[,2])[levels(label[,2])=="1"] <- "T"
levels(label[,2])[levels(label[,2])=="2"] <- "B"
levels(label[,2])[levels(label[,2])=="3"] <- "Macro"
levels(label[,2])[levels(label[,2])=="4"] <- "Endo"
levels(label[,2])[levels(label[,2])=="5"] <- "CAF"
levels(label[,2])[levels(label[,2])=="6"] <- "NK"
colnames(label) <- c("cell_name","label")

write.table(label,"label2.csv",quote = F,sep = ",",row.names = F)

exp <- read_tsv("GSE72056_melanoma_single_cell_revised_v2.txt")
exp[3,1]


setwd("d:/Users/flyku/Documents/IRIS3-data/Puram")
library(plyr)
library(tidyverse)
label <- read.table("Puram_cell_label1.csv",header = T,stringsAsFactors = T,sep = ",")
label[,2] <- as.factor(label[,2])
levels(label[,2])[levels(label[,2])=="1"] <- "no"
levels(label[,2])[levels(label[,2])=="2"] <- "yes"
levels(label[,2])[levels(label[,2])=="0"] <- "unresolved"
colnames(label) <- c("cell_name","label")
write.table(label,"label1.csv",quote = F,sep = ",",row.names = F)

label <- read.table("Puram_cell_label2.csv",header = T,stringsAsFactors = T,sep = ",")
label[,2] <- as.factor(label[,2])
levels(label[,2])[levels(label[,2])=="1"] <- "T"
levels(label[,2])[levels(label[,2])=="2"] <- "B"
levels(label[,2])[levels(label[,2])=="3"] <- "Macro"
levels(label[,2])[levels(label[,2])=="4"] <- "Endo"
levels(label[,2])[levels(label[,2])=="5"] <- "CAF"
levels(label[,2])[levels(label[,2])=="6"] <- "NK"
colnames(label) <- c("cell_name","label")

write.table(label,"label2.csv",quote = F,sep = ",",row.names = F)

exp <- read_tsv("GSE72056_melanoma_single_cell_revised_v2.txt")
tumor_label <- paste("Mel",as.character(exp[1,]),sep = "")
label_result <- cbind(colnames(exp),(tumor_label))
write.table(label_result,"tumor_label.csv",quote = F,sep = ",",row.names = F)
exp[3,1]
exp_result <- exp[c(-1,-2,-3),]
write.table(exp_result,"Puram_expression.csv",quote = F,col.names = T,row.names = F)

