#remove NAs and merge all coloc_all results

coloc_results_files =list.files(path= "../coloc_results/", pattern = "coloc_results*")
coloc_7_all_results = data.frame()
for (i in coloc_results_files){
  result = read.delim(paste("../coloc_results/",i,sep = ""),as.is = TRUE,stringsAsFactors = FALSE,header = FALSE,sep=" ")
  result = result[-1,]
  result = result[which(is.na(result$V2)==FALSE),]
  coloc_7_all_results=rbind(coloc_7_all_results,result)
}
coloc_7_all_results = coloc_7_all_results[,-c(1)]
gene_list = read.table("estrada_lead_BAN_overlaps.txt")
gene_list = gene_list[,c(6,7)]
gene_list = unique(gene_list)


coloc_7_all_results$gene = apply(coloc_7_all_results,1,function(x) gene_list[which(gene_list[,1] == x[3]),2])                                     
                                     
colnames(coloc_7_all_results) = c("pheno","tissue","ensembl","nSNPs","H0","H1","H2","H3","H4","gene")
coloc_7_all_results$nSNPs = as.numeric(coloc_7_all_results$nSNPs)

coloc_7_all_results$gene = as.character(coloc_7_all_results$gene)
write.table(coloc_7_all_results,"coloc_v7_all_results.txt",sep = "\t",quote = FALSE)

coloc_7_all_results_over75 = coloc_7_all_results[which(coloc_7_all_results$H4 >=0.75),] 

fn = coloc_7_all_results_over75[which(coloc_7_all_results_over75$pheno=="FNBMD"),]
ls = coloc_7_all_results_over75[which(coloc_7_all_results_over75$pheno=="LSBMD"),]

write.table(fn,"coloc_v7_FNBMD_over75.txt",sep = "\t",quote = FALSE)
write.table(ls,"coloc_v7_LSBMD_over75.txt",sep = "\t",quote = FALSE)