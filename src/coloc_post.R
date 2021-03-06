# Post-coloc analyses

#How many BANs within 1 Mbp of lead snps?
hom_morris = read.table("./results/flat/homologs_within1mbp_morris_REV.txt")
hom_estrada = read.table("./results/flat/homologs_within1_estrada_REV.txt")

homologs = c(hom_estrada$V1, hom_morris$V1)
homologs = unique(homologs)

length(homologs)#738 genes

##How many lead snps?
estrada_lead_snps = read.table("./data/GEFOS/lead_snps_pos", header=F, stringsAsFactors = F)
morris_lead_snps = read.csv("./data/Morrisetal2018.NatGen.SumStats/Morris_eBMD_conditionally_ind_snps.csv", header=T, stringsAsFactors = F)

lead = c(estrada_lead_snps$V6, morris_lead_snps$RSID)
lead = unique(lead)
length(lead)#1161 unique lead snps


#Of the 544 homologs within 1 mbp of a lead snp, how many have colocalizing eQTL?
fn = read.table("~/Documents/projects/DO_project/results/flat/coloc/coloc_v7_FNBMD_over75_REV.txt")
ls = read.table("~/Documents/projects/DO_project/results/flat/coloc/coloc_v7_LSBMD_over75_REV.txt")
morris_coloc = read.table("~/Documents/projects/DO_project/results/flat/coloc/coloc_morris_v7_all_results_over75_REV.txt")

coloc_genes = c(fn$gene, ls$gene, morris_coloc$gene)
coloc_genes = unique(coloc_genes)
length(coloc_genes)#72


#How many are known regulators of bone biology?
superset = read.table("./results/flat/superset_in_networks.txt")
superset = superset$V1
#MYPOP,PLEKHM1,ZNF609,GPR133,PTRF
length(which(tolower(coloc_genes) %in% tolower(superset)))
#37 in superset. however, PTRF and GPR133 amd ZNF609 are also in superset as Cavin1 and Adgrd1 and Zfp609, respectively. So 40 in superset, 13 from literature search, for 53 total.


#based on overlap with bone list, are the colocalizing genes enriched in bone genes? Can do this relative to enrichment in genome or enrichment in BANs that were colocalized 

#This analysis considers the BAN genes as the global set
new_set = superset
new_set[which(tolower(new_set) == "cavin1")] = "ptrf"
new_set[which(tolower(new_set) == "adgrd1")] = "gpr133"
new_set[which(tolower(new_set) == "zfp609")] = "znf609"

allgenes = homologs

a = length(which(tolower(coloc_genes) %in% tolower(new_set))) # number of coloc genes that are also bone genes (40)
b = length(which(tolower(coloc_genes) %in% tolower(new_set) == F)) # number of coloc genes that are not bone genes (32, 72-a)
c = length(which((tolower(allgenes) %in% tolower(new_set)) & (tolower(allgenes) %in% tolower(coloc_genes) == FALSE)))#not coloc and bone genes (220)
d = length(which((tolower(allgenes) %in% tolower(new_set)==FALSE) & (tolower(allgenes) %in% tolower(coloc_genes) == FALSE)))#not coloc and not bone genes (446)

#make contingency table
mat = matrix(nrow=2,ncol=2)
mat[1,] = c(a,c)
mat[2,] = c(b,d)
fisher.test(mat) #two sided (enrichment or depletion)
fisher.test(mat,alternative = "g") #enrichment

###same but with hypergeometric 

q=40
k=72
m=260
n=478
#m+n = 738
phyper(q-1,m,n,k,lower.tail = F) #prob 33 or more bone genes drawn



#This analysis considers all genes in genome as the global set
#23648 genes

new_set = superset
new_set[which(tolower(new_set) == "cavin1")] = "ptrf"
new_set[which(tolower(new_set) == "adgrd1")] = "gpr133"
new_set[which(tolower(new_set) == "zfp609")] = "znf609"


allgenes = homologs

a = length(which(tolower(coloc_genes) %in% tolower(new_set))) # number of coloc genes that are also bone genes (40)
b = length(which(tolower(coloc_genes) %in% tolower(new_set) == F)) # number of coloc genes that are not bone genes (32, 72-a)
c = length(which(tolower(new_set) %in% tolower(coloc_genes) == FALSE))#not coloc and bone genes. For the genome it would equal number of bone genes that dont colocalize (1251)
d = 23645 - (a+b+c)#not coloc and not bone genes (22087)

#make contingency table
mat = matrix(nrow=2,ncol=2)
mat[1,] = c(a,c)
mat[2,] = c(b,d)
fisher.test(mat) #two sided
fisher.test(mat,alternative = "g") #enrichment




q=?
k=?
m=length(new_set)
n=?-m

phyper(q-1,m,n,k,lower.tail = F) #prob 33 or more bone genes drawn, genome-wide

