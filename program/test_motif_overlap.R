
########## Test DMINDA and MEME overlap ##################
# used files:
# regulon_motif
library(tidyverse)

library(dabestr)
###test
#wd <- "d:/Users/flyku/Documents/IRIS3-data/20190816170235"
setwd("/var/www/html/iris3/data/20190906120624")
jobid <-20190906120624 
wd <- getwd()
setwd(wd)

quiet <- function(x) { 
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 



sort_dir <- function(dir) {
  tmp <- sort(dir)
  split <- strsplit(tmp, "_CT_") 
  split <- as.numeric(sapply(split, function(x) x <- sub("_bic.*", "", x[2])))
  return(tmp[order(split)])
  
}

alldir <- list.dirs(path = wd)
alldir <- grep("*_bic$",alldir,value=T)
alldir <- sort_dir(alldir)

#i=10
total_motif_list <- list()
total_rank_list <- list()
total_gene_module <- tibble()
for (i in 1:length(alldir)) {
  regulon_motif_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_motif.txt",sep = ""),"r")
  regulon_motif <- readLines(regulon_motif_handle)
  close(regulon_motif_handle)
  motif_list <- lapply(strsplit(regulon_motif,"\\t"), function(x){x})
  
  regulon_rank_handle <- file(paste(jobid,"_CT_",i,"_bic.regulon_rank.txt",sep = ""),"r")
  regulon_rank <- readLines(regulon_rank_handle)
  close(regulon_rank_handle)
  
  gene_module <- read_delim(paste(jobid,"_CT_",i,"_bic.txt",sep = ""),delim="\t")
  colnames(gene_module) <- paste("ct",i,colnames(gene_module),sep = "")
  total_gene_module <- append(gene_module,total_gene_module)

  rank_list <- lapply(strsplit(regulon_rank,"\\t"), function(x){x})
  total_motif_list <- append(total_motif_list,motif_list)
  total_rank_list <- append(total_rank_list,rank_list)
}


multiple_motif <- unlist(lapply(total_motif_list, function(x){
  length(x) >= 3
})
)
total_regulon <- length(total_motif_list)
total_multiple_regulon <- length(which(multiple_motif == T))
multiple_motif <- total_motif_list[which(multiple_motif == T)]
length(multiple_motif)




total_both_meme_dminda_regulon <- length(unlist(lapply(total_motif_list, function(x){
  if (length(x) > 2) {
    for (i in 2:length(x)) {
      if(as.numeric(strsplit(x,",")[[2]][2])>100 && as.numeric(strsplit(x,",")[[i]][2])<100){
        return(strsplit(x,",")[[2]][2])
      } else if(as.numeric(strsplit(x,",")[[2]][2])<100 && as.numeric(strsplit(x,",")[[i]][2])>100){
        return(strsplit(x,",")[[2]][2])
      }
    }
  }
})))
x <- total_motif_list[[1]]
both_meme_dminda_regulon_id <- unlist(lapply(total_motif_list, function(x){
  if (length(x) > 2) {
    for (i in 2:length(x)) {
      if(as.numeric(strsplit(x,",")[[2]][2])>100 && as.numeric(strsplit(x,",")[[i]][2])<100){
        return(x[[1]])
      } else if(as.numeric(strsplit(x,",")[[2]][2])<100 && as.numeric(strsplit(x,",")[[i]][2])>100){
        return(x[[1]])
      }
    }
  }
}))

x <- total_rank_list[[1]]
both_meme_dminda_regulon_rss <- unlist(lapply(total_rank_list, function(x){
  if (x[[1]] %in% both_meme_dminda_regulon_id){
    return (x[[5]])
  }
}))




meme_total_motif <- length(unlist(lapply(total_motif_list, function(x){
  if(as.numeric(strsplit(x,",")[[2]][2])>100){
    return(strsplit(x,",")[[2]][2])
  }
})))

meme_regulon_id <- unlist(lapply(total_motif_list, function(x){
      if(as.numeric(strsplit(x,",")[[2]][2])>100){
        return(x[[1]])
      } 
}))
meme_regulon_rss <-  unlist(lapply(total_rank_list, function(x){
  if (x[[1]] %in% meme_regulon_id){
    return (x[[5]])
  }
}))


x <- total_rank_list[[1]]
both_meme_dminda_regulon_rss <- unlist(lapply(total_rank_list, function(x){
  if (x[[1]] %in% both_meme_dminda_regulon_id){
    return (x[[5]])
  }
}))

dminda_total_motif <- length(unlist(lapply(total_motif_list, function(x){
  if(as.numeric(strsplit(x,",")[[2]][2])<100){
    return(strsplit(x,",")[[2]][2])
  }
})))


dminda_regulon_id <- unlist(lapply(total_motif_list, function(x){
  if(as.numeric(strsplit(x,",")[[2]][2])<100){
    return(x[[1]])
  } 
}))
dminda_regulon_rss <-  unlist(lapply(total_rank_list, function(x){
  if (x[[1]] %in% dminda_regulon_id){
    return (x[[5]])
  }
}))
df1 <- data.frame(value=as.numeric(both_meme_dminda_regulon_rss),group="dminda_and_meme")
df2 <- data.frame(value=as.numeric(meme_regulon_rss),group="meme_only")
df3 <- data.frame(value=as.numeric(dminda_regulon_rss),group="dminda_only")
df <- rbind(df1,df2,df3)

#colnames(df) <- c("dminda_and_meme","meme_only","dminda_only")

#unpaired_mean_diff <- dabest(df,group, value,
#                             idx =  c("dminda_and_meme","meme_only","dminda_only"),
#                             paired = FALSE)

#plot(unpaired_mean_diff)
total_regulon
total_multiple_regulon







############test marker gene in gene module

total_gene_module <- lapply(total_gene_module, na.omit)
gene1 <- which(unlist(lapply(total_gene_module, function(x){
  return("CD99" %in% x)
}))==T)

gene1 <- which(unlist(lapply(total_gene_module, function(x){
  return("CAV1" %in% x)
}))==T)

gene1 <- which(unlist(lapply(total_gene_module, function(x){
  return("FOLR1" %in% x)
}))==T)

exp_data<- read_delim(paste(jobid,"_filtered_expression.txt",sep = ""),delim = "\t")
barplot(as.numeric(exp_data[which(exp_data[,1]=="CD99"),]))

mean(as.matrix(exp_data[,-1]))


############parse MEME xml output
# wd <- "D:/Users/flyku/Documents/IRIS3-data/20190818121919"
# jobid <-20190818121919 
setwd(wd)
require(xml2)
require(XML)
xdata <- "tomtom/ct4bic187m2/tomtom.xml"
xml_data <- xmlToList(xdata)

Fun2 <-function(xdata){
  dumFun <- function(x){
    xname <- xmlName(x)
    xattrs <- xmlAttrs(x)
    c(sapply(xmlChildren(x), xmlValue), name = xname, xattrs)
  }
  dum <- xmlParse(xdata)
  as.data.frame(t(xpathSApply(dum, "//*/POR", dumFun)), stringsAsFactors = FALSE)
}

a <- Fun2(fn)
a
doc <- xmlTreeParse(xdata)
xpathApply(doc,"//param[@id=*]",xmlValue)

xmlinfile <- paste(readLines(xdata), collapse="\n")

xpathApply(xmlParse(xmlinfile), "/params/param[@id='3']", xmlValue)  

rootNode <- xmlRoot(xdata)
for (i in 1:xmlSize(rootNode)) {                
  
  id = xmlGetAttr(node = rootNode[[i]],    
                  name = "id")                 
  
  sapply(X = rootNode[[i]]["prix"],          
         fun = addAttributes,                   
         id = id)                                
}


xml_data <- read_xml(xdata)
#nodes <- xml_find_all(xml_data, ".//motif")
#nodes<-xml_attr(nodes, "id")[motif_index]
motif_name <- xml_find_all(xml_data, ".//motif")
motif_name <- xml_attr(motif_name, "alt")
motif_index <- xml_find_all(xml_data, ".//matches")
motif_index <- xml_find_all(xml_data, ".//query")
motif_index <- xml_find_all(xml_data, ".//target")
motif_index<-as.numeric(xml_attr(motif_index, "idx")[1]) + 2
motif_name[motif_index]

#xml_text(motif_name)
#i=101
allfiles <- list.files(path = "tomtom",pattern = "tomtom.xml",recursive = T,full.names = T)
total_motif_name <- data.frame()
for (i in 1:length(allfiles)) {
  motif_id <- strsplit(allfiles[i],"/")[[1]][2]
  if (strsplit(allfiles[i],"/")[[1]][3] == "JASPAR"){
    xml_data <- read_xml(allfiles[i])
    motif_name <- xml_find_all(xml_data, ".//motif")
    motif_name <- xml_attr(motif_name, "alt")
    motif_index <- xml_find_all(xml_data, ".//matches")
    motif_index <- xml_find_all(xml_data, ".//query")
    motif_index <- xml_find_all(xml_data, ".//target")
    motif_index<-as.numeric(xml_attr(motif_index, "idx")[1]) + 2
    total_motif_name <- rbind(total_motif_name,data.frame(motif_id,motif_name[motif_index]))
  }
}
colnames(total_motif_name) <- c("motif_id","TF_name")
tst <- total_motif_name

total_regulon_list <- list()
for (i in 1:length(unique(total_motif_name[,2]))) {
  this_tf_index <- total_motif_name[,2] %in% unique(total_motif_name[,2])[i]
  tmp_list <- c(as.character(unique(total_motif_name[,2])[i]),as.character(total_motif_name[this_tf_index,1]))
  total_regulon_list <- append(list(tmp_list),total_regulon_list)
}


