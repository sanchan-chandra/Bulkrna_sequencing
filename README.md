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
2️⃣ Quality Control (QC)

Check sequencing quality using FastQC and summarize with MultiQC:
```
# Run FastQC
mkdir -p fastqc_results
fastqc fastq/*.fastq.gz -o fastqc_results/ --threads 8

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
9️⃣ Differential Expression Analysis (DESeq2)
  Perfect 👍 — here’s your **final ready-to-go `README.md`** version of the DESeq2 bulk RNA-seq workflow, now with **automatic PNG plot saving** (for sample distance heatmap, PCA, and individual gene expression plots).
You can **copy-paste this directly** into your GitHub repository — everything is documented, runnable, and publication-ready.

---

# 🧬 Bulk RNA-seq Differential Expression Analysis (DESeq2)

This repository provides a complete workflow for **bulk RNA-seq differential gene expression analysis** using **DESeq2** in R.
It includes preprocessing, normalization, visualization, and statistical testing — plus automatic plot export for easy reproducibility.

---

## 📘 Overview

We use the **DESeq2** package to perform:

1. **Size factor normalization**
2. **Dispersion estimation**
3. **Negative Binomial GLM model fitting**
4. **Wald tests** for differential expression

Visual outputs include PCA plots, sample distance heatmaps, and expression plots for genes of interest.
Gene annotation is performed using **BioMart (GRCh38.p13)**.

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
data <- read.csv("raw_counts.csv", header = TRUE, row.names = "ensembl_id")
data <- data[, sort(colnames(data))]

# Define conditions
condition <- c(rep("LNCAP_Hypoxia", 2), rep("LNCAP_Normoxia", 2),
               rep("PC3_Hypoxia", 2), rep("PC3_Normoxia", 2))
my_colData <- as.data.frame(condition)
rownames(my_colData) <- colnames(data)
```

---

### 2️⃣ Create DESeq2 Object and Run Normalization

```r
dds <- DESeqDataSetFromMatrix(countData = data,
                              colData = my_colData,
                              design = ~ condition)
dds <- DESeq(dds)

# Export normalized counts
normalized_counts <- counts(dds, normalized = TRUE)
write.csv(normalized_counts, "normalized_counts.csv")
```

---

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

## 🎨 Visualization (Auto PNG Saving)

### 🔹 1. Variance Stabilizing Transformation

```r
vsd <- vst(dds, blind = TRUE)
```

---

### 🔹 2. Sample Distance Heatmap (Saved as PNG)

```r
plotDistsToFile <- function(vsd.obj, filename = "sample_distance_heatmap.png") {
  sampleDists <- dist(t(assay(vsd.obj)))
  sampleDistMatrix <- as.matrix(sampleDists)
  rownames(sampleDistMatrix) <- vsd.obj$condition
  colors <- colorRampPalette(rev(brewer.pal(9, "Blues")))(255)
  png(filename, width = 1200, height = 1000, res = 150)
  pheatmap(sampleDistMatrix,
           clustering_distance_rows = sampleDists,
           clustering_distance_cols = sampleDists,
           col = colors,
           main = "Sample-to-Sample Distance Heatmap",
           fontsize = 12)
  dev.off()
}
plotDistsToFile(vsd)
```

---

### 🔹 3. PCA Plot (Saved as PNG)

```r
plotPCAtoFile <- function(vsd.obj, filename = "PCA_plot.png") {
  pcaData <- plotPCA(vsd.obj, intgroup = "condition", returnData = TRUE)
  percentVar <- round(100 * attr(pcaData, "percentVar"))
  p <- ggplot(pcaData, aes(PC1, PC2, color = condition)) +
    geom_point(size = 4) +
    ggrepel::geom_text_repel(aes(label = name), size = 3, color = "black") +
    labs(title = "PCA Plot (by Condition)",
         x = paste0("PC1: ", percentVar[1], "% variance"),
         y = paste0("PC2: ", percentVar[2], "% variance")) +
    theme_bw(base_size = 14)
  ggsave(filename, plot = p, width = 8, height = 6, dpi = 300)
}
plotPCAtoFile(vsd)
```

---

### 🔹 4. Expression Plot for a Specific Gene (Saved as PNG)

```r
plot_counts_toFile <- function(dds.obj, gene_id, filename = paste0(gene_id, "_expression.png")) {
  p <- plotCounts(dds.obj, gene = gene_id, intgroup = "condition", returnData = TRUE)
  g <- ggplot(p, aes(x = condition, y = count, color = condition)) +
    geom_boxplot(outlier.shape = NA, alpha = 0.4) +
    geom_jitter(width = 0.2, size = 3) +
    scale_y_log10() +
    labs(title = paste("Normalized Expression:", gene_id),
         y = "log10(Count)",
         x = "") +
    theme_bw(base_size = 14)
  ggsave(filename, plot = g, width = 7, height = 5, dpi = 300)
}

# Example: Plot for IGFBP1
plot_counts_toFile(dds, "IGFBP1")
```

---

## 🧠 Differential Expression

You can easily generate DE results and filter by significance:

```r
res <- results(dds, contrast = c("condition", "LNCAP_Hypoxia", "LNCAP_Normoxia"))
res <- lfcShrink(dds, contrast = c("condition", "LNCAP_Hypoxia", "LNCAP_Normoxia"), type = "apeglm")

# Save results
write.csv(as.data.frame(res), "LNCAP_DESeq2_results.csv")
```

To apply cutoffs:

```r
sig_res <- subset(res, padj < 0.05 & abs(log2FoldChange) > 1)
write.csv(as.data.frame(sig_res), "LNCAP_significant_genes.csv")
```

---

## 📁 Output Files

| Output File                            | Description                       |
| -------------------------------------- | --------------------------------- |
| `normalized_counts.csv`                | Normalized count data             |
| `gene_annotated_normalized_counts.csv` | Annotated counts                  |
| `sample_distance_heatmap.png`          | Sample-to-sample distance heatmap |
| `PCA_plot.png`                         | PCA plot                          |
| `*_expression.png`                     | Gene expression plot              |
| `*_DESeq2_results.csv`                 | All DE results                    |
| `*_significant_genes.csv`              | Significant DE genes              |

---

## 🧪 Example Dataset

* **Cell lines:** LNCaP and PC3
* **Conditions:** Normoxia vs Hypoxia
* **Goal:** Identify hypoxia-responsive genes and pathway changes across cell types.

---

## 📚 References

* Love, M.I., Huber, W., & Anders, S. (2014). *Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2.* Genome Biology, 15(12), 550.
* Ensembl BioMart: [https://www.ensembl.org/biomart](https://www.ensembl.org/biomart)

---

Would you like me to also include a **Volcano plot** (with automatic PNG export) section in this same README? It’s often used for highlighting significant up- and downregulated genes visually.


