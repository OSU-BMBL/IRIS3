#######  get DoRothEA overlaped for all regulons for job_list[i] ##########

library(tibble)
library(readr)
#args <- commandArgs(TRUE)

# job_list[i] <- '2019102482720'
# species <- 'Human'

job <- read.table("/var/www/html/CeRIS/data/20191101133117/job",sep="\t")
job <- job[c(-5,-6,-14,-16),]

job_list <- as.character(job$V1)

for (i in 1:length(job_list)) {
wd <- paste("/var/www/html/CeRIS/data/",job_list[i],sep="")
setwd(wd)
species <- as.character(read.table("species_main.txt"))
if (species == "Human") {
  tf_db <- read_tsv(paste("/var/www/html/CeRIS/program/db/human_tfregulons_database_v01_20180216__limit.tsv"))
} else if (species == "Mouse"){
  tf_db <- read_tsv(paste("/var/www/html/CeRIS/program/db/mouse_tfregulons_database_v01_20180216__limit.tsv"))
}
combine_result <-read.table(paste(job_list[i],"_combine_regulon.txt",sep = ""), sep="\t",header = T)
this_tf <- combine_result$tf_name
#regulon_gene_list <- c("ABCC12","ABCG5","ABCG8","ABO","ACAD11","ACTRT1","ADAM11","ADAM19","ADAMTS14","ADAMTS15","ADAMTS17","ADAMTS9","ADCY7","AGBL1","AGPAT4","AGR2","AIG1","ALDH1A2","ALOXE3","ALPK2","ALX3","ANKRD44","ANO2","AOC2","ARHGAP30","ARHGAP33","ARHGAP6","ARHGEF9","ARMC2","B3GNT4","B4GALT6","BCL11B","BDH2","BLK","BMP6","BMPER","BOC","BTBD9","BTG4","C12orf77","C20orf96","C6orf201","CABP5","CACNB4","CADPS2","CALHM1","CALML4","CALN1","CASS4","CCDC102B","CCDC114","CCDC60","CCDC88C","CCNJ","CD163L1","CD99L2","CDH5","CDK15","CDK18","CDKL5","CEND1","CEP120","CGA","CHRNA6","CHRNB4","CKMT2","CLEC10A","CLEC4G","CNGB3","CNPY1","COL15A1","COL5A1","COX7A1","CPA6","CPNE4","CPNE9","CR1L","CRMP1","CRYAB","CSDC2","CSPG4","CTNNBIP1","CTNND2","CUX1","CXCL11","CYP2J2","CYP46A1","DAB1","DAZL","DBH","DCST1","DCX","DEFA5","DGKI","DISP1","DKFZp451B082","DMBT1","DMD","DMGDH","DMKN","DNAH17","DOK5","DOK6","DPP6","DSCAM","DYNC2H1","EDAR","ELFN2","ENHO","ENTPD5","EPHB1","ERC2","EVC2","EVI5L","EXTL1","F13A1","FAM124A","FAM135B","FAM171B","FAM174B","FAM180A","FAM180B","FBN3","FBXW12","FCER1G","FCRLB","FGF8","FHIT","FIBCD1","FOXF2","FRMPD4","FRS3","FSTL5","GAB1","GAD2","GBX1","GGN","GGT6","GHRHR","GLYATL3","GNAI1","GNB3","GNG2","GOLGA2P2Y","GOLGA6B","GOLGA6C","GP1BA","GPR119","GPR137B","GPR137C","GPR22","GRIK4","GRK7","GRM3","GXYLT2","HAPLN3","HBQ1","HCN4","HLF","HOXA7","HRH3","HS3ST2","HSFX2","HSPA12A","ICOS","IGSF22","IHH","IKBKE","IL17C","INPP5E","INSC","IQCF1","IQUB","IRAK1BP1","IRF5","IZUMO4","JAG1","JAKMIP1","KATNAL1","KCNC3","KCNE1","KCNG4","KCNK16","KCNK18","KCNN2","KCNQ3","KCTD13","KIF19","KIF2B","KIRREL2","KIRREL3","KLHDC7A","KRT16","KRT36","KRTAP10-1","KRTAP10-5","LGALS12","LGI3","LIPE","LIPM","LMBRD2","LMO1","LMO3","LMO7","LMOD3","LOC340357","LRRC3B","LRRC8B","LRRC8E","LSM14B","LYPD4","MAB21L2","MAGEB16","MAGEC2","MAP3K15","MAP6D1","MAPK10","MAPK4","MBL2","MGAT5B","MGRN1","MLKL","MLLT3","MLPH","MRVI1","MT3","MX2","MXD1","MYF6","MYO7B","MYRIP","NALCN","NCALD","NCAM1","NEURL1B","NFATC1","NMUR2","NOD1","NPHP4","NR3C2","NT5M","NUDT10","NXPH1","NXPH4","OAS2","OLFM2","OLIG1","ONECUT1","OPN1LW","OPN1MW","OPN1MW2","OR1N1","OR2AG1","OR2AG2","OR2M2","OR2M3","OR3A3","OR52E6","OR6A2","OR7D4","OSR1","PACS1","PAG1","PAIP2B","PARVG","PCYT1B","PDE10A","PDK1","PDZK1","PEBP4","PGPEP1","PKIA","PLAT","PLCB1","PLEKHA7","PLIN1","PNPLA2","PRDM10","PRDM16","PRKG2","PRR15","PSEN2","PSTPIP1","PTGDR","PTK2B","PTPN3","PTPRE","PXDNL","PXK","RAB39B","RAC2","RAD9B","RALYL","RASA3","RASGRP1","RASGRP3","RAX2","RELN","RESP18","RGS11","RGS22","RGS7","RIMKLA","RLN1","ROPN1L","ROR2","ROS1","RPS4Y1","RS1","RTN1","RUNDC3A","RUNDC3B","SAA4","SAMD3","SCEL","SDS","SEC16B","SEMA3C","SEMA3D","SERPINB8","SH2D4B","SHD","SIAH2","SIGLEC7","SLC22A15","SLC22A2","SLC35D1","SLC43A3","SLC45A3","SLC5A9","SLC6A11","SLC6A12","SMAD3","SMARCC2","SNORA16B","SORBS3","SPATA20","SPEF1","SPHKAP","SPINK8","SPOCK3","STOML3","STON1-GTF2A1L","SV2B","SVOPL","SYT9","TACR3","TCEA2","TDRD10","TGM7","THBS1","THSD7B","TLR5","TMC2","TMCC1","TMCC2","TMEM132D","TMEM136","TMEM198","TMEM200A","TMEM82","TMEM8B","TMOD2","TNFSF12-TNFSF13","TNFSF13","TNIK","TOX","TPH2","TPRXL","TRAF3IP2","TRANK1","TRPM3","TRPM5","TRPV4","TSNAXIP1","TTYH3","TWIST1","UGT2A2","UNC5A","USP35","USP44","UTS2","VCAM1","VTCN1","VWA5A","WFDC10A","WNT5A","WNT8B","WWOX","ZCCHC12","ZDHHC1","ZHX2","ZNF155","ZNF181","ZNF280C","ZNF462","ZNF540","ZNF563","ZNF570","ZNF629","ZNF710","ZSWIM3")

result <- t(apply(combine_result, 1, function(x){
  this_tf <- as.character(x[2])
  this_tf_db <- tf_db[which(tf_db[,1] == this_tf),]
  this_regulon_genes <- strsplit(as.character(x[5]),",")[[1]]
  this_gene_mapping <- this_tf_db[this_tf_db$target %in% this_regulon_genes,]
  return(c(as.character(x[1]),length(this_regulon_genes),nrow(this_tf_db),nrow(this_gene_mapping)))
}))

colnames(result) <- c('index','total_genes_in_regulon','total_query','total_match')

result <- as.data.frame(result)
result[,2] <- as.numeric(result[,2])
result[,3] <- as.numeric(result[,3])
result[,4] <- as.numeric(result[,4])

res <- rbind(append("colSums",colSums(result[,-1])),result)
write.table(res,paste(job_list[i],"_dorothea_overlap.txt",sep=""),sep="\t",quote=F,col.names = T,row.names = F)

}


out <- list(NA)
for (i in 1:length(job_list)) {
  setwd(paste("/var/www/html/CeRIS/data/",job_list[i],sep=""))
  out[[i]] <-  list(read.table(paste(job_list[i],"_dorothea_overlap.txt",sep=""),sep = "\t",header = T)[1,])
  names(out[[i]]) <- as.character(job[i,2])
}

df <- melt(out)[,-1]

df2 <- df %>% 
       spread(variable,value) %>% 
       arrange(L1)
        
