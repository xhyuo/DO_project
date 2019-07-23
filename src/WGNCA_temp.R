############
library(sva)
library(Mus.musculus)#seems to use mm10
library(WGCNA)
library(topGO)
library(DESeq2)
############
options(stringsAsFactors = FALSE)
#

#read in VST transformed, quantile-normalized data (produced in ./src/normalize_RNAseq.R)
#load("./results/Rdata/counts_vst_qnorm.Rdata")
#For now try non-quantile normalized data, compare with q-normed

# read in the RNA-seq processed counts file
counts = read.csv("./results/flat/genes_over_6reads_in_morethan_38samps_tpm_over0.1_38samps_COUNTS.csv", stringsAsFactors = FALSE,row.names = 1,check.names = FALSE)

#read in an annotation file. This is output from the RNA-seq pipeline
annot_file = read.delim("./data/314-FarberDO2_S6.gene_abund.tab",header = TRUE)

#find and remove features that have fewer than 10 reads in more than 90% (173) of samples 
x=c()
for(i in 1:nrow(counts)){
  if(sum(counts[i,]<10)>=173){
    print(i)
    x = append(x,i)
  }
}

#253 genes removed
counts = counts[-x,]

#vst from deseq2
vst = varianceStabilizingTransformation(as.matrix(counts))

#get batch. What I did here is I got batch from the file names of the alignment output for RNA-seq
f = list.files("./results/flat/RNA-seq/sums/")
p1 = f[grep(pattern = "Pool1",f)]
p2 = f[grep(pattern = "Pool2",f)]
p3 = f[grep(pattern = "FarberDO2",f)]

b1 = c()
b2 = c()
b3 = c()
for(i in 1:length(p1)){
  b1 = c(b1,strsplit(strsplit(p1[i],"Pool1_")[[1]][2],"-")[[1]][1])
  b1 = unique(b1)
}

for(i in 1:length(p2)){
  b2 = c(b2,strsplit(strsplit(p2[i],"Pool2_")[[1]][2],"-")[[1]][1])
  b2 = unique(b2)
}

for(i in 1:length(p3)){
  b3 = c(b3,strsplit(strsplit(p3[i],"fastq_")[[1]][2],"-")[[1]][1])
  b3 = unique(b3)
}


#read in the raw phenotypes file
x = read.csv("./results/flat/full_pheno_table.csv", stringsAsFactors = FALSE)

#get covs by matching colnames of vst with mouse ID in raw pheno file
covs = x[match(colnames(vst),x$Mouse.ID),]

#sac.date,sex, age at sac, generation
covs = covs[,c(2,5,7,22)]

covs$male = NA
covs$female = NA
covs$batch1=NA
covs$batch2=NA
covs$batch3=NA


#covs$male = as.numeric(covs$sex=="M")
#covs$female = as.numeric(covs$sex=="F")
#define batches
covs$batch1[match(b1,rownames(covs))] = 1
covs[which(rownames(covs)%in% b1==FALSE),"batch1"] = 0

covs$batch2[match(b2,rownames(covs))] = 1
covs[which(rownames(covs)%in% b2==FALSE),"batch2"] = 0

covs$batch3[match(b3,rownames(covs))] = 1
covs[which(rownames(covs)%in% b3==FALSE),"batch3"] = 0


#cc = as.matrix(covs[,c(3,5:8)])
#rownames(cc) = rownames(covs)

#convert to integers
#covs[,1] = as.factor(covs[,1])

#cc[,c(1:5)] = as.integer(cc[,])

covs = as.data.frame(covs[,2:9])

covs$batch = NA
covs[which(covs$batch1 == 1),"batch"] = 1
covs[which(covs$batch2 == 1),"batch"] = 2
covs[which(covs$batch3 == 1),"batch"] = 3


batch = covs$batch

#generation is confounded with batch so it is not added
modcombat = model.matrix(~as.factor(sex) + as.factor(age_at_sac_days), data=covs)

#batch removal
edata = ComBat(dat=vst, batch=batch, mod=modcombat, par.prior=TRUE, prior.plots=FALSE)

#transpose the matrix
edata = t(edata)
########################


#pick the soft thresholding power
powers = c(c(1:10), seq(from = 12, to=20, by=2))
# Call the network topology analysis function
sft = pickSoftThreshold(edata, powerVector = powers, verbose = 5,networkType = "signed")
# Plot the results:
sizeGrWindow(9, 5)
par(mfrow = c(1,2));
cex1 = 0.9;
# Scale-free topology fit index as a function of the soft-thresholding power
plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
     main = paste("Scale independence"));
text(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     labels=powers,cex=cex1,col="red");
# this line corresponds to using an R^2 cut-off of h
abline(h=0.90,col="red")
# Mean connectivity as a function of the soft-thresholding power
plot(sft$fitIndices[,1], sft$fitIndices[,5],
     xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
     main = paste("Mean connectivity"))
text(sft$fitIndices[,1], sft$fitIndices[,5], labels=powers, cex=cex1,col="red")
###

net = blockwiseModules(edata, power = 9,
                       TOMType = "signed", minModuleSize = 30,
                       reassignThreshold = 0, mergeCutHeight = 0.25,
                       numericLabels = TRUE, pamRespectsDendro = FALSE,
                       saveTOMs = TRUE,
                       saveTOMFileBase = "net_combat_sex_age_p9",
                       verbose = 3)

##


full_pheno_table_ordered = read.delim("~/Desktop/DO_proj/pheno_data/full_pheno_table_ordered",stringsAsFactors = FALSE,as.is = TRUE)

datTraits = full_pheno_table_ordered[which(full_pheno_table_ordered$Mouse.ID %in% rownames(edata)),]
datTraits = datTraits[match(rownames(edata),datTraits$Mouse.ID),]

#datTraits[,135] = as.numeric(gsub(x = datTraits[,135],pattern = "~ ",replacement = ""))
datTraits = datTraits[,-c(1:7,16,22)]
for(i in 1:ncol(datTraits)){datTraits[,i] = as.numeric(datTraits[,i])}
#datTraits = log2(datTraits + 0.0001)
datTraits = datTraits[,-c(27:44)]

# Define numbers of genes and samples



sizeGrWindow(12, 9)
# Convert labels to colors for plotting
mergedColors = labels2colors(net$colors)
# Plot the dendrogram and the module colors underneath
plotDendroAndColors(net$dendrograms[[1]], mergedColors[net$blockGenes[[1]]],
                    "Module colors",
                    dendroLabels = FALSE, hang = 0.03,
                    addGuide = TRUE, guideHang = 0.05)

# Construct numerical labels corresponding to the colors
moduleLabels = net$colors
moduleColors = labels2colors(net$colors)
MEs = net$MEs;
geneTree = net$dendrograms[[1]]
nGenes = ncol(edata);
nSamples = nrow(edata);
# Recalculate MEs with color labels
MEs0 = moduleEigengenes(edata, moduleColors)$eigengenes
MEs = orderMEs(MEs0)
moduleTraitCor = cor(MEs, datTraits, use = "p",method = "p");
moduleTraitPvalue = corPvalueStudent(moduleTraitCor, 192)# is this correct? what about nSamples for traits?
sizeGrWindow(10,6)
# Will display correlations and their p-values
textMatrix = paste(signif(moduleTraitCor, 2), "\n(",
                   signif(moduleTraitPvalue, 1), ")", sep = "");
dim(textMatrix) = dim(moduleTraitCor)
par(mar = c(6, 8.5, 3, 3));
# Display the correlation values within a heatmap plot
labeledHeatmap(Matrix = moduleTraitCor,
               xLabels = names(datTraits),
               yLabels = names(MEs),
               ySymbols = names(MEs),
               colorLabels = FALSE,
               colors = greenWhiteRed(50),
               textMatrix = textMatrix,
               setStdMargins = FALSE,
               cex.text = 0.35,
               zlim = c(-1,1),
               cex.lab.x = 0.7,
               cex.lab.y = 0.8,
               verticalSeparator.x = c(1:length(names(datTraits))),
               horizontalSeparator.y = c(1:length(names(MEs))),
               main = paste("Module-trait relationships"))
###
###
which(moduleTraitCor == sort((moduleTraitCor),decreasing =TRUE)[2], arr.ind = T)
colnames(moduleTraitCor)[31]
########################
annot_file = read.delim("314-FarberDO2_S6.gene_abund.tab",header = TRUE)
colnames(edata) = annot_file[match(colnames(edata),annot_file$Gene.ID),"Gene.Name"]


combat_annot = as.data.frame(colnames(edata))

combat_annot$module = net$colors
combat_annot$color = moduleColors

combat_annot[,c(4:8)] = annot_file[match(combat_annot$`colnames(edata)`,annot_file$Gene.Name),c(1,3,4,5,6)]


modNames = substring(names(MEs), 3)
geneModuleMembership = as.data.frame(cor(edata, MEs, use = "p"))
MMPvalue = as.data.frame(corPvalueStudent(as.matrix(geneModuleMembership), nSamples))
geneModuleMembership$gene = colnames(edata)
#names(geneModuleMembership) = paste("MM", modNames, sep="");
#names(MMPvalue) = paste("p.MM", modNames, sep="");

combat_annot[9:35] = geneModuleMembership[match(geneModuleMembership$gene,combat_annot$`colnames(edata)`),c(1:27)]



#reached here
uct_bend_traits = datTraits[,c(1,2,11:13,15:27,46:63)]

x = cor.test(signed_net$MEs[,"ME12"],uct_bend_traits$Conn.D)

cor_table = as.data.frame(matrix(ncol=ncol(uct_bend_traits),nrow = 26))
for(module in 1:length(signed_net$MEs)){
  for(trait in 1:ncol(uct_bend_traits)){
    x = cor.test(signed_net$MEs[,module],uct_bend_traits[,trait])
    cor_table[module,trait] = x$p.value
    print(x$p.value)
  }
}
rownames(cor_table) = colnames(signed_net$MEs)
colnames(cor_table) = colnames(uct_bend_traits)
#
allGenes = colnames(resid)
interesting.genes = combat_annot[which(combat_annot$color == "green"),1]#darkred

geneList<-factor(as.integer(allGenes %in% interesting.genes)) #If TRUE returns 1 as factor, otherwise 0
names(geneList)<-allGenes
###MF###
GOdata <- new("topGOdata", ontology = "MF", allGenes =geneList,
              annot = annFUN.org, mapping='org.Mm.eg.db', ID='symbol')
test.stat<-new("classicCount", testStatistic = GOFisherTest, name='Fisher test')
result<-getSigGroups(GOdata,test.stat)
t1<-GenTable(GOdata, classic=result, topNodes=length(result@score))
head(t1)
###CC###
GOdata <- new("topGOdata", ontology = "CC", allGenes = geneList,
              annot = annFUN.org, mapping='org.Mm.eg.db', ID='symbol')
test.stat<-new("classicCount", testStatistic = GOFisherTest, name='Fisher test')
result<-getSigGroups(GOdata,test.stat)
t2<-GenTable(GOdata, classic=result, topNodes=length(result@score))
head(t2)
###BP###
GOdata <- new("topGOdata", ontology = "BP", allGenes = geneList,
              annot = annFUN.org, mapping='org.Mm.eg.db', ID='symbol')
test.stat<-new("classicCount", testStatistic = GOFisherTest, name='Fisher test')
result<-getSigGroups(GOdata,test.stat)
t3<-GenTable(GOdata, classic=result, topNodes=length(result@score))
head(t3)
####
t.all = NULL
t.all<-rbind(t1,t2,t3)
t.all$classic<-as.numeric(as.character(t.all$classic))
t.all<-subset(t.all,t.all$classic<=0.01)
t.all<-t.all[order(t.all$classic,decreasing=FALSE),]
dim(t.all[t.all$classic<=1e-5,])
######

