### size-based P-value

setwd('/path/to/.blocks')

LINES <-readLines('NameOfblocksFile')

BC <-read.table(text=grep('Enrichment',LINES,value=TRUE))
temp <-BC[,6:7]   


matrix.please<-function(x) {
    m<-as.matrix(x[,-1])
    rownames(m)<-x[,1]
    m
}

ecoli <-read.table('/path/to/the/discretized/matrix/',,header=T,sep='\t')   # we need the discretized matrix consisting of 0 and 1

matrix.please<-function(x) {
    m<-as.matrix(x[,-1])
    rownames(m)<-x[,1]
    m
}

M <-matrix.please(ecoli)
n0 <-ncol(M)
alpha0 <-nrow(M)/ncol(M)
p <-mean(M)


p_BC_all_matrix_input_LG_continuous<-function(m0,n0,m1,n1,p){
	alpha0<-m0/n0
	beta0<-m1/n1
	b<-1/p
	s_nab<-(1+beta0)/beta0*log(n0)/log(b)-
	(1+beta0)/beta0*log((1+beta0)/beta0*log(n0)/log(b))/log(b)+log(alpha0)/log(b)+
	(1+beta0)/beta0/log(b)-log(beta0)/log(b)
	gamma0<-(n1-s_nab)
	logpp<-(beta0+1)*log((log(n0)/log(b)))-((beta0+1)*gamma0)*log(n0)
	return(logpp)
}


F <-temp
names(F) <-c('Core_Row','Core_Col')
m0 <-nrow(M)
n0 <-ncol(M)
m1 <-as.numeric(substr(as.character(F$Core_Row),10,13))
n1 <-as.numeric(substr(as.character(F$Core_Col),10,13))
F$ID <-BC$V1
F$Pvalue <-p_BC_all_matrix_input_LG_continuous(m0,n0,m1,n1,p)

head(F)



