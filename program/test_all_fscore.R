#install.packages("enrichR")
library(enrichR)
library(data.table)
# check all enrichr databases
dbs <- listEnrichrDbs()

# read regulon-gene file


#job <- read.table("/var/www/html/CeRIS/job1",sep="\t",header=F)
#job <- job[c(-6,-19,-22),]

job <- read.delim("/var/www/html/CeRIS/job2",sep="\t",header=F)
job <- job[c(-22),]

job_list <- as.character(job$V1)

options(stringsAsFactors=FALSE)
count_regulon_result <- data.frame()
for (i in 1:length(job_list)) {
  wd <- paste("/var/www/html/CeRIS/data/",job_list[i],sep="")
  setwd(wd)
  combine_result <-read.table(paste(job_list[i],"_combine_regulon.txt",sep = ""), sep="\t",header = T,stringsAsFactors = F)
  total_regulon <- nrow(combine_result)
  active_regulon <- length(which(combine_result$rss_pval < 0.05))
  count_regulon_result <- rbind(count_regulon_result,c(job$V2[i],total_regulon,active_regulon))
}


output <- data.frame()

for (i in 1:length(job_list)) {
  #system(paste("chmod 777 ",job_list[i],"_combine_regulon.txt",sep = "")) 
  
  wd <- paste("/var/www/html/CeRIS/data/",job_list[i],sep="")
  setwd(wd)
  combine_result <-read.table(paste(job_list[i],"_combine_regulon.txt",sep = ""), sep="\t",header = T,stringsAsFactors = F)

  species <- as.character(read.table("species_main.txt")[,1])
  if (species == "Human") {
    #test.terms <- c("ENCODE_TF_ChIP-seq_2015","WikiPathways_2015", 
    #                "KEGG_2019_Human", "Enrichr_Submissions_TF-Gene_Coocurrence")
    
    test.terms <- c("KEGG_2019_Human")
  } else if (species == "Mouse"){
    test.terms <- c("KEGG_2019_Mouse")
  }
  


  ct_info <- combine_result$index
  ct_info <-gsub( "-.*$", "", ct_info)
  ct_info <- as.numeric(gsub("[[:alpha:]]","",ct_info))
  total_ct <- max(as.numeric(ct_info))
  
  KEGG_F_list <- KEGG_pre_list <- KEGG_recall_list<- list()
  #this_ct = 1
  for (this_ct in 1: total_ct) {
    KEGG_reg_num <- 0
    #Wiki_reg_num <- 0
    #ENCODE_reg_num <-0
    
    KEGG <- data.frame()
    #Wiki <- data.frame()
    #ENCODE <- data.frame()
    
    regulon_in_this_ct <- which(ct_info == this_ct)
    this_active_regulon <- combine_result[regulon_in_this_ct,]
    this_CTSR <- this_active_regulon$gene_symbol[which(this_active_regulon$rss_pval < 10)]
    #this_pre <- length(this_CTSR)/length(this_active_regulon)
    
    regulon <- this_CTSR
    
    #j=regulon[[1]]
    if (length(regulon) > 0 ){
      for (j in regulon){
        enriched <- enrichr(strsplit(j,",")[[1]], test.terms)
        # subset enrichment results: terms, number of genes, adj.p-value
        KEGG_reg <- enriched[[1]][,c(1:2,4)]
        #Wiki_reg <- enriched$WikiPathways_2015[,c(1:2,4)]
        #ENCODE_reg <- enriched$`ENCODE_TF_ChIP-seq_2015`[,c(1:2,4)]
        #Coocurrence_reg <- enriched$`Enrichr_Submissions_TF-Gene_Coocurrence`[,c(1:2,4)]
        # find significantly enriched terms
        KEGG_reg <- KEGG_reg[which(KEGG_reg[,3]<=0.05),]
        #Wiki_reg <- Wiki_reg[which(Wiki_reg[,3]<=0.05),]
        #ENCODE_reg <- ENCODE_reg[which(ENCODE_reg[,3]<=0.05),]
        #Coocurrence_reg <- Coocurrence_reg[which(Coocurrence_reg[,3]<=0.05),]
        # combine term lists
        KEGG <- rbind(KEGG,KEGG_reg)
        #Wiki <- rbind(Wiki,Wiki_reg)
        #ENCODE <- rbind(ENCODE,ENCODE_reg)
        #Coocurrence <- rbind(Coocurrence,Coocurrence_reg)
        # count # of CTSRs significantly enriched at least one term
        if(nrow(KEGG_reg)>0){
          KEGG_reg_num <- KEGG_reg_num+1
        }  
      }
    } else {
      KEGG <- rbind(KEGG,KEGG_reg)
    }

    # calculate precision (change length to nrow for real regulon list)
    KEGG_pre <- KEGG_reg_num/length(regulon)
    #Wiki_pre <- Wiki_reg_num/length(regulon)
    #ENCODE_pre <- ENCODE_reg_num/length(regulon)
    
    # calculate recall
    # ENCODE_TF_ChIP-seq_2015, 20382, 1811, 816
    # WikiPathways_2015, 5963, 51, 404
    # KEGG_2019_Human, 7802, 92, 308 
    # KEGG_2019_Mouse, 8551, 98, 303
    #Wiki_recall <- length(unique(Wiki[,1]))/404
    #ENCODE_recall <- length(unique(ENCODE[,1]))/816
    if (species == "Human") {
      KEGG_recall <- length(unique(KEGG[,1]))/308
    } else if (species == "Mouse"){
      KEGG_recall <- length(unique(KEGG[,1]))/303
    }
    
    # calculate F-score
    KEGG_F <- 2/(1/KEGG_pre+1/KEGG_recall)
    KEGG_pre_list[this_ct] <- KEGG_pre
    KEGG_recall_list[this_ct] <- KEGG_recall
    KEGG_F_list[this_ct] <- KEGG_F
  }
  
  KEGG_F_average <- mean(na.omit(unlist(KEGG_F_list)))
  #KEGG_recall_average <- mean(na.omit(unlist(KEGG_recall_list)))
  #KEGG_pre_average <- mean(na.omit(unlist(KEGG_pre_list)))
  
  #Wiki_F <- 2/(1/Wiki_pre+1/Wiki_recall)
  #ENCODE_F <- 2/(1/ENCODE_pre+1/ENCODE_recall)
  #this_output <- c(as.character(job[i,2]),KEGG_pre,KEGG_recall,KEGG_F,Wiki_pre,Wiki_recall, Wiki_F,ENCODE_pre, ENCODE_recall, ENCODE_F)
  this_output <- c(as.character(job[i,2]),KEGG_F_average)
  
  output <- rbind(output,this_output)
}
#2/(1/as.numeric(output[2,2])+1/as.numeric(output[2,3]))

colnames(output) <- c("data","KEGG_F_average")

#colnames(output) <- c("data","KEGG_pre","KEGG_recall","KEGG_F","Wiki_pre","Wiki_recall", "Wiki_F","ENCODE_pre", "ENCODE_recall", "ENCODE_F")
write.table(output,"~/enrichment_result.txt")

# export file
#KEGG <- rbind(KEGG_F, KEGG)
#Wiki <- rbind(KEGG_F, Wiki)
#ENCODE <- rbind(KEGG_F, ENCODE)
#write.table(KEGG,"KEGG_enrichment_result.txt")
#write.table(Wiki,"Wiki_enrichment_result.txt")
#write.table(ENCODE,"ENCODE_enrichment_result.txt")




