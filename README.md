# Bulk RNA-Seq Analysis – Hypoxia Response in LNCaP and PC3 Cell Lines
🎯 Project Overview
This project demonstrates an end-to-end Bulk RNA-Seq analysis workflow from raw SRA files to differentially expressed genes (DEGs).
We investigated how hypoxia alters gene expression in two prostate cancer cell lines:
| Cell Line | Origin                                                                |
| --------- | --------------------------------------------------------------------- |
| LNCaP     | Derived from a lymph node metastasis of human prostate adenocarcinoma |
| PC3       | Derived from a bone metastasis of a grade IV prostate adenocarcinoma  |
We compared Normoxia vs Hypoxia conditions in each cell line.

⚙️ Workflow Overview

-The workflow consists of the following major steps:
-Download raw data from NCBI SRA
-Convert SRA → FASTQ 
-Quality control with FastQC
-Read trimming/filtering (optional)
-Align reads to reference genome (using HISAT2)
-Quantify gene expression (featureCounts)
-Merge counts into a counts matrix
-Differential expression analysis using DESeq2
-Visualization and interpretation (PCA, heatmaps, volcano plots)

📂 Dataset Information

GEO Accession: GSE106305
Citation: Guo H, Ci X, Ahmed M, Hua JT et al. ONECUT2 is a driver of neuroendocrine prostate cancer. Nat Commun 2019 Jan 17;10(1):278. PMID: 30655535  
Description: RNA-Seq and ChIP-Seq experiments in LNCaP and PC3 cells under normoxia and hypoxia conditions.  
Note: Each biological sample is split into multiple technical runs (SRR IDs). We merged 20 SRR files into 8 final FASTQ files for analysis.  

🧬💻 Step-by-step guide with code
1️⃣ Data Acquisition
1.Download .sra files using SRA Toolkit
2.Convert .sra → .fastq.gz using fastq-dump
```
# Download SRA
prefetch SRR7179504

# Convert to FASTQ
fastq-dump --outdir fastq --gzip --skip-technical --readids \
--read-filter pass --dumpbase --split-3 --clip SRR7179504/SRR7179504.sra
```
<img width="600" height="120" alt="Screenshot 2025-10-22 171653" src="https://github.com/user-attachments/assets/b57e5476-e08a-4490-bd7d-37efc96a7e4f" />

2️⃣ Quality Control (QC)

Check sequencing quality using FastQC and summarize with MultiQC:
```
# Run FastQC
mkdir -p fastqc_results
fastqc fastq/*.fastq.gz -o fastqc_results/ --threads 8
```
<img width="600" height="200" alt="Screenshot 2025-10-22 172214" src="https://github.com/user-attachments/assets/7e18d07c-7630-441f-9b1e-082062eef1f0" />

```
# Aggregate with MultiQC
multiqc fastqc_results/ -o multiqc_report/
```
3️⃣ (Optional) Read Trimming

Remove low-quality bases or adapters with Trimmomatic:
```
trimmomatic SE -threads 4 -phred33 \
  fastq/SRR7179504_pass.fastq.gz \
  fastq/SRR7179504_trimmed.fastq.gz \
  TRAILING:10
```
4️⃣ Merge Technical Runs

Concatenate multiple SRR files per biological replicate:
```
cat SRR7179504_pass.fastq.gz SRR7179505_pass.fastq.gz SRR7179506_pass.fastq.gz SRR7179507_pass.fastq.gz  > LNCAP_Normoxia_S1.fastq.gz
cat SRR7179508_pass.fastq.gz SRR7179509_pass.fastq.gz SRR7179510_pass.fastq.gz SRR7179511_pass.fastq.gz  > LNCAP_Normoxia_S2.fastq.gz
cat SRR7179520_pass.fastq.gz SRR7179521_pass.fastq.gz SRR7179522_pass.fastq.gz SRR7179523_pass.fastq.gz  > LNCAP_Hypoxia_S1.fastq.gz
cat SRR7179524_pass.fastq.gz SRR7179525_pass.fastq.gz SRR7179526_pass.fastq.gz SRR7179527_pass.fastq.gz  > LNCAP_Hypoxia_S2.fastq.gz

mv SRR7179536_pass.fastq.gz PC3_Normoxia_S1.fastq.gz
mv SRR7179537_pass.fastq.gz PC3_Normoxia_S2.fastq.gz
mv SRR7179540_pass.fastq.gz PC3_Hypoxia_S1.fastq.gz
mv SRR7179541_pass.fastq.gz PC3_Hypoxia_S2.fastq.gz
```
<img width="1370" height="84" alt="Screenshot 2025-10-22 172504" src="https://github.com/user-attachments/assets/3f8bef29-f125-425d-8c67-70c329de2d0d" />

5️⃣ Reference Genome & Annotation

Download HISAT2 prebuilt GRCh38 genome index:
```
wget https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz
tar -xvzf grch38_genome.tar.gz

```
Download Ensembl GTF annotation:
```
wget https://ftp.ensembl.org/pub/release-114/gtf/homo_sapiens/Homo_sapiens.GRCh38.114.gtf.gz
gunzip Homo_sapiens.GRCh38.114.gtf.gz
```
6️⃣ Alignment (HISAT2 → Samtools)

Align reads and convert to sorted & indexed BAM:
```
hisat2 -q -x grch38/genome -U fastq/LNCAP_Hypoxia_S1.fastq.gz | \
  samtools sort -o alignedreads/LNCAP_Hypoxia_S1.bam

samtools index alignedreads/LNCAP_Hypoxia_S1.bam
```
<img width="1321" height="133" alt="Screenshot 2025-10-22 172623" src="https://github.com/user-attachments/assets/9371ba06-9adc-4359-a108-e1ad8fbc3edd" />

7️⃣ Quantification (featureCounts)

Generate gene × sample count matrix:
```
featureCounts -S 2 -a Homo_sapiens.GRCh38.114.gtf \
  -o quants/featurecounts.txt alignedreads/*.bam
```

8️⃣ Post-alignment QC (Qualimap)
```
qualimap rnaseq -bam alignedreads/LNCAP_Hypoxia_S1.bam \
  -gtf Homo_sapiens.GRCh38.114.gtf \
  -outdir rnaseq_qc_results --java-mem-size=8G
```
<img width="1466" height="85" alt="Screenshot 2025-10-22 172818" src="https://github.com/user-attachments/assets/7a3c4c4e-de55-4e43-a339-fd8a49ffa670" />

9️⃣ Differential Expression Analysis (DESeq2)
  Perfect 👍 — here’s your **final ready-to-go `README.md`** version of the DESeq2 bulk RNA-seq workflow, now with **automatic PNG plot saving** (for sample distance heatmap, PCA, and individual gene expression plots).
You can **copy-paste this directly** into your GitHub repository — everything is documented, runnable, and publication-ready.

---

# 🧬 Bulk RNA-seq Differential Expression Analysis (DESeq2)

This repository provides a complete workflow for **bulk RNA-seq differential gene expression analysis** using **DESeq2** in R.
It includes preprocessing, normalization, visualization, and statistical testing — plus automatic plot export for easy reproducibility.

---

## ⚙️ Installation

Install all dependencies via Bioconductor and CRAN:

```r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("DESeq2", "apeglm", "EnhancedVolcano", "pheatmap", "RColorBrewer"))
install.packages(c("tidyverse", "ggrepel"))
```

---

## 📂 Input Files

| File                    | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| `raw_counts.csv`        | Raw integer count matrix (rows = genes, columns = samples) |
| `GRCh38_annotation.csv` | Annotation file from Ensembl BioMart                       |
| *(optional)*            | Metadata (can be created inside the script)                |

---

## 🧮 Workflow

### 1️⃣ Load Data and Packages

```r
library(DESeq2)
library(tidyverse)
library(pheatmap)
library(RColorBrewer)
library(ggrepel)

# Read count matrix
data <- read.csv("/home/sanchan_chandrasheka/bulkrnaseq_analysis/countsmatrix/merged_counts_matrix.csv",
                 header = TRUE, row.names = "Geneid")
data <- data[, sort(colnames(data))]
# View the first few rows
head(data)

# Define conditions
condition <- c(rep("LNCAP_Hypoxia", 2), rep("LNCAP_Normoxia", 2),
               rep("PC3_Hypoxia", 2), rep("PC3_Normoxia", 2))
my_colData <- as.data.frame(condition)
rownames(my_colData) <- colnames(data)
```
<img width="797" height="110" alt="Screenshot 2025-10-22 174924" src="https://github.com/user-attachments/assets/d95580cc-4fbd-449c-b9b7-dd06923283e0" />

---
We observe that each sample has been sequenced at a different “depth”, in which there are varying numbers of total reads for each sample. For example, PC3_Hypoxia_S2 has only 12 million reads, which is less than 1/3rd of the reads for PC3_Hypoxia_S1. This means that we cannot directly compare the count values between samples without normalizing each column based on its total read count. After the data have been processed using DESeq2, we will have normalized data that we can use to make comparisons.

### 2️⃣ Create DESeq2 Object and Run Normalization

---

##  Create colData for DESeq2

Define the biological replicates for each condition:

```r
# Biological replicates
condition <- c(rep("LNCAP_Hypoxia", 2), rep("LNCAP_Normoxia", 2),
               rep("PC3_Hypoxia", 2), rep("PC3_Normoxia", 2))

# Assign sample names (columns of your count matrix)
my_colData <- data.frame(condition)
rownames(my_colData) <- colnames(data)
my_colData
```

Expected output:

<img width="589" height="290" alt="Screenshot 2025-10-22 175345" src="https://github.com/user-attachments/assets/b2288ff1-cc8c-41a3-92dc-c573232a98ce" />

---

##  Create DESeq2 object

```r
library(DESeq2)

dds <- DESeqDataSetFromMatrix(countData = data,
                              colData = my_colData,
                              design = ~ condition)
```

---

##  Run differential expression analysis

```r
dds <- DESeq(dds)
```

The function performs:

* Estimation of size factors
* Estimation of dispersion
* Negative binomial GLM fitting and Wald statistics

---

##  Inspect the DESeq2 object

```r
dds
```

Expected output includes:

<img width="787" height="240" alt="Screenshot 2025-10-22 175640" src="https://github.com/user-attachments/assets/d03c38d6-426a-422d-991b-d6efc6a3be67" />


---

## Extract raw and normalized counts

```r
# Raw counts
head(dds@assays@data$counts)

# Normalized counts
normalized_counts <- counts(dds, normalized = TRUE)
head(normalized_counts)
```

---

## Step 10: Save normalized counts (optional)

```r
write.csv(normalized_counts, "normalized_counts.csv", row.names = TRUE)
```

This CSV can be used for downstream analysis, visualization, or sharing with collaborators.



## 🧩 Gene Annotation

To annotate genes:

* Use **BioMart → Ensembl Genes (GRCh38.p13)**
* Select:

  * ✅ Gene stable ID
  * ✅ Gene name
  * ✅ Gene type

Then:

```r
annotation <- read.csv("GRCh38_annotation.csv", header = TRUE)
normalized_counts <- rownames_to_column(as.data.frame(normalized_counts), var = "ensembl_id")
annotated_data <- right_join(annotation, normalized_counts, by = c("Gene.stable.ID" = "ensembl_id"))
write.csv(annotated_data, "gene_annotated_normalized_counts.csv")
```

---
Here’s a **concise version** of your visualization section for GitHub, with short explanations and code blocks:

---

## **Visualizing Sample Variability** 📊

We assess sample-to-sample variability to identify outliers and check experiment quality.

### **1. Variance Stabilizing Transformation**

```r
library(DESeq2)
vsd <- vst(dds, blind = TRUE)
```

> Stabilizes variance across mean expression levels.

---

### **2. Distance Plot**

```r
library(pheatmap)
plotDists <- function(vsd.obj){
  sampleDists <- dist(t(assay(vsd.obj)))
  sampleDistMatrix <- as.matrix(sampleDists)
  rownames(sampleDistMatrix) <- vsd.obj$condition
  colors <- colorRampPalette(rev(RColorBrewer::brewer.pal(9, "Blues")))(255)
  pheatmap(sampleDistMatrix, clustering_distance_rows=sampleDists,
           clustering_distance_cols=sampleDists, col=colors)
}
plotDists(vsd)
```

> Euclidean distance between samples; similar samples cluster together.

---

### **3. Variable Genes Heatmap**

```r
library(matrixStats)
variable_gene_heatmap <- function(vsd.obj, num_genes=500, annotation){
  counts <- assay(vsd.obj)
  row_variances <- rowVars(counts)
  top_genes <- counts[order(row_variances, decreasing=TRUE)[1:num_genes],]
  top_genes <- top_genes - rowMeans(top_genes)
  rownames(top_genes) <- annotation$Gene.name[match(rownames(top_genes), annotation$Gene.stable.ID)]
  coldata <- as.data.frame(vsd.obj@colData)
  coldata$sizeFactor <- NULL
  pheatmap(top_genes, color=colorRampPalette(RColorBrewer::brewer.pal(11,"RdBu"))(256)[256:1],
           annotation_col=coldata, fontsize_row=250/num_genes, fontsize_col=8, border_color=NA)
}
variable_gene_heatmap(vsd, num_genes=40, annotation=annotation)
```

> Shows top variable genes driving sample clustering.

---

### **4. PCA Plot**

```r
library(ggplot2); library(ggrepel)
plot_PCA <- function(vsd.obj){
  pcaData <- plotPCA(vsd.obj, intgroup="condition", returnData=TRUE)
  percentVar <- round(100*attr(pcaData,"percentVar"))
  ggplot(pcaData, aes(PC1, PC2, color=condition)) +
    geom_point(size=3) +
    labs(x=paste0("PC1: ",percentVar[1],"% variance"),
         y=paste0("PC2: ",percentVar[2],"% variance"),
         title="PCA Plot by condition") +
    ggrepel::geom_text_repel(aes(label=name))
}
plot_PCA(vsd)
```

> Visualizes sample similarity in 2D; replicates cluster together.

---

This is **compact, readable, and ready to paste** into your GitHub README.

If you want, I can also make a **version with emojis for each step** to make it visually appealing on GitHub. Do you want me to do that?


## 📚 References

* Love, M.I., Huber, W., & Anders, S. (2014). *Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2.* Genome Biology, 15(12), 550.
* Ensembl BioMart: [https://www.ensembl.org/biomart](https://www.ensembl.org/biomart)

---

Would you like me to also include a **Volcano plot** (with automatic PNG export) section in this same README? It’s often used for highlighting significant up- and downregulated genes visually.


