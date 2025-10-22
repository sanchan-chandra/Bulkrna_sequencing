# Bulk RNA-Seq Analysis

🎯 Project Overview  
This project demonstrates a complete Bulk RNA-Seq workflow, from raw sequencing data up to differential expression analysis using DESeq2.
We analyzed the effect of **hypoxia** on gene expression in two prostate cancer cell lines:

* **LNCaP** – derived from a lymph node metastasis
* **PC3** – derived from a bone metastasis

For each cell line, we compared **Normoxia vs Hypoxia** to identify genes that respond to low oxygen levels.

📂 **Dataset Information**

* **GEO Accession:** GSE106305
* **Citation:** Guo H, Ci X, Ahmed M, Hua JT et al. ONECUT2 is a driver of neuroendocrine prostate cancer. Nat Commun 2019 Jan 17;10(1):278. PMID: 30655535
* **Description:** RNA-Seq and ChIP-Seq experiments in LNCaP and PC3 cells under normoxia and hypoxia conditions.
* **Note:** Each biological sample is split across multiple technical runs (SRR IDs). In this analysis, 20 SRR files were merged into 8 final FASTQ files.


# 🧬💻 Step-by-step Workflow
### 1️⃣ Data Acquisition  
1.Download .sra files using SRA Toolkit   
2.Convert .sra → .fastq.gz using fastq-dump 
(Optional) Automate multiple downloads with a Python script
```
# Download SRA
prefetch SRR7179504

# Convert to FASTQ
fastq-dump --outdir fastq --gzip --skip-technical --readids \
--read-filter pass --dumpbase --split-3 --clip SRR7179504/SRR7179504.sra
```
Output: FASTQ files (raw sequencing reads)  
<img width="600" height="120" alt="Screenshot 2025-10-22 171653" src="https://github.com/user-attachments/assets/b57e5476-e08a-4490-bd7d-37efc96a7e4f" />

### 2️⃣ Quality Control (QC)

Check sequencing quality using FastQC and summarize with MultiQC:
```
# Run FastQC
mkdir -p fastqc_results
fastqc fastq/*.fastq.gz -o fastqc_results/ --threads 8
```
Output: HTML reports showing sequencing quality    
<img width="600" height="200" alt="Screenshot 2025-10-22 172214" src="https://github.com/user-attachments/assets/7e18d07c-7630-441f-9b1e-082062eef1f0" />

```
# Aggregate with MultiQC
multiqc fastqc_results/ -o multiqc_report/
```
### 3️⃣ (Optional) Read Trimming

Remove low-quality bases or adapters with Trimmomatic:
```
trimmomatic SE -threads 4 -phred33 \
  fastq/SRR7179504_pass.fastq.gz \
  fastq/SRR7179504_trimmed.fastq.gz \
  TRAILING:10
```
### 4️⃣ Merge Technical Runs

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
Output: 8 final FASTQ files (one per replicate)  
<img width="685" height="42" alt="Screenshot 2025-10-22 172504" src="https://github.com/user-attachments/assets/3f8bef29-f125-425d-8c67-70c329de2d0d" />

### 5️⃣ Reference Genome & Annotation

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
### 6️⃣ Alignment (HISAT2 → Samtools)

Align reads and convert to sorted & indexed BAM:
```
hisat2 -q -x grch38/genome -U fastq/LNCAP_Hypoxia_S1.fastq.gz | \
  samtools sort -o alignedreads/LNCAP_Hypoxia_S1.bam

samtools index alignedreads/LNCAP_Hypoxia_S1.bam
```
Output: Aligned, sorted, and indexed BAM files  
<img width="600" height="108" alt="Screenshot 2025-10-22 172623" src="https://github.com/user-attachments/assets/9371ba06-9adc-4359-a108-e1ad8fbc3edd" />

### 7️⃣ Quantification (featureCounts)

Generate gene × sample count matrix:
```
featureCounts -S 2 -a Homo_sapiens.GRCh38.114.gtf \
  -o quants/featurecounts.txt alignedreads/*.bam
```

### 8️⃣ Post-alignment QC (Qualimap)
```
qualimap rnaseq -bam alignedreads/LNCAP_Hypoxia_S1.bam \
  -gtf Homo_sapiens.GRCh38.114.gtf \
  -outdir rnaseq_qc_results --java-mem-size=8G
```
Output: QC reports for aligned reads  
<img width="1200" height="85" alt="Screenshot 2025-10-22 172818" src="https://github.com/user-attachments/assets/7a3c4c4e-de55-4e43-a339-fd8a49ffa670" />

### 9️⃣ Differential Expression Analysis (DESeq2)  
 Complete step by step guide is provided below 
 

# 🧬 Bulk RNA-seq Differential Expression Analysis (DESeq2)

### 1.⚙️ Installation , Load Data and Packages

Install all dependencies via Bioconductor and CRAN:

```r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("DESeq2", "apeglm", "EnhancedVolcano", "pheatmap", "RColorBrewer"))
install.packages(c("tidyverse", "ggrepel"))
```
Load Data and Packages
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
<img width="398" height="55" alt="Screenshot 2025-10-22 174924" src="https://github.com/user-attachments/assets/d95580cc-4fbd-449c-b9b7-dd06923283e0" />

---


### 2.Create DESeq2 Object and Run Normalization

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

<img width="294.5" height="145" alt="Screenshot 2025-10-22 175345" src="https://github.com/user-attachments/assets/b2288ff1-cc8c-41a3-92dc-c573232a98ce" />

---

Create DESeq2 object

```r
library(DESeq2)

dds <- DESeqDataSetFromMatrix(countData = data,
                              colData = my_colData,
                              design = ~ condition)
```

---

Run differential expression analysis

```r
dds <- DESeq(dds)
```

The function performs:

* Estimation of size factors
* Estimation of dispersion
* Negative binomial GLM fitting and Wald statistics

---
Inspect the DESeq2 object

```r
ddS
```

Expected output includes:

<img width="393.5" height="120" alt="Screenshot 2025-10-22 175640" src="https://github.com/user-attachments/assets/d03c38d6-426a-422d-991b-d6efc6a3be67" />


---

Extract raw and normalized counts

```r
# Raw counts
head(dds@assays@data$counts)

# Normalized counts
normalized_counts <- counts(dds, normalized = TRUE)
head(normalized_counts)
```

---

Save normalized counts (optional)

```r
write.csv(normalized_counts, "normalized_counts.csv", row.names = TRUE)
```

This CSV can be used for downstream analysis, visualization, or sharing with collaborators.



### 3.🧩 Gene Annotation
  🔧 Download Gene Annotations from Ensembl BioMart  
1. Go to [Ensembl BioMart](http://uswest.ensembl.org/biomart/martview/).  
2. Select **Database:** Ensembl Genes 99, **Dataset:** Human genes (GRCh38.p13).  
3. Under **Attributes → Gene**, select:  
   * Gene stable ID  
   * Gene name  
   * Gene type  
     Deselect: Gene stable ID version, Transcript stable ID, Transcript stable ID version.  
4. Click **Results → Export as CSV → Go**.  
5. Rename the file to `GRCh38.p13_annotation.csv` and load in R:  

```r
annotation <- read.csv("GRCh38.p13_annotation.csv")
```

Then:

```r
# Read gene annotation file
annotation <- read.csv("GRCh38.p13_annotation.csv", header = TRUE)  # Contains Ensembl IDs, gene names, gene types
# Convert rownames to a column if needed (skip if 'ensembl_id' already exists)
# normalized_counts <- rownames_to_column(as.data.frame(normalized_counts), var = "ensembl_id")
# Join annotation with normalized counts
annotated_data <- right_join(annotation, normalized_counts, by = c("ensembl_gene_id" = "ensembl_id"))  # Match Ensembl IDs
# Write the annotated data to CSV
write.csv(annotated_data, "gene_annotated_normalized_counts.csv", row.names = FALSE)  # Save output

```

---

### 4.**Visualizing Sample Variability** 📊

We assess sample-to-sample variability to identify outliers and check experiment quality.

 **Variance Stabilizing Transformation**

```r
library(DESeq2)
vsd <- vst(dds, blind = TRUE)
```

> Stabilizes variance across mean expression levels.

---

**Distance Plot**  
```
library(pheatmap)
library(RColorBrewer)

plotDists <- function(vsd.obj, output_file){
  sampleDists <- dist(t(assay(vsd.obj)))
  sampleDistMatrix <- as.matrix(sampleDists)
  rownames(sampleDistMatrix) <- colnames(vsd.obj)
  colors <- colorRampPalette(rev(brewer.pal(9, "Blues")))(255)
  png(filename = output_file, width = 1500, height = 1500, res = 300)
  pheatmap(sampleDistMatrix,
           clustering_distance_rows = sampleDists,
           clustering_distance_cols = sampleDists,
           col = colors)
  dev.off()
}

plotDists(vsd, "/home/sanchan_chandrasheka/bulkrnaseq_analysis/deseq2_results/Distance_plot_samples.png")

```
> Euclidean distance between samples; similar samples cluster together.



**Variable Genes Heatmap**  

```r
library(pheatmap)
library(matrixStats)
library(RColorBrewer)

top_genes <- 40
counts <- assay(vsd)
row_variances <- rowVars(counts)
top_counts <- counts[order(row_variances, decreasing=TRUE)[1:top_genes], ]
top_counts <- top_counts - rowMeans(top_counts)
rownames(top_counts) <- normalized_counts$hgnc_symbol[match(rownames(top_counts),
                                                           normalized_counts$ensembl_gene_id)]
coldata <- as.data.frame(vsd@colData)
coldata$sizeFactor <- NULL

png("/home/sanchan_chandrasheka/bulkrnaseq_analysis/deseq2_results/Variable_genes_heatmap.png",
    width = 1500, height = 1500, res = 300)
pheatmap(top_counts,
         color = colorRampPalette(brewer.pal(11, "RdBu"))(256)[256:1],
         annotation_col = coldata,
         border_color = NA)
dev.off()

```

> Shows top variable genes driving sample clustering.

---

**PCA Plot**  

```r
library(ggplot2)
library(ggrepel)

plot_PCA <- function(vsd.obj, output_file="PCA_plot.png") {
  pcaData <- plotPCA(vsd.obj, intgroup = c("condition"), returnData = TRUE)
  percentVar <- round(100 * attr(pcaData, "percentVar"))
  p <- ggplot(pcaData, aes(PC1, PC2, color=condition)) +
    geom_point(size=3) +
    labs(x = paste0("PC1: ",percentVar[1],"% variance"),
         y = paste0("PC2: ",percentVar[2],"% variance"),
         title = "PCA Plot colored by condition") +
    ggrepel::geom_text_repel(aes(label = name), color = "black") +
    theme_bw(base_size = 14)
  ggsave(output_file, plot = p, width = 6, height = 5, dpi = 300)
  return(p)
}

plot_PCA(vsd, output_file="/home/sanchan_chandrasheka/bulkrnaseq_analysis/deseq2_results/PCA_plot.png")

```


> Visualizes sample similarity in 2D; replicates cluster together.


### 5. Extract DE results  
To extract the differentially expressed genes from the DESeq2 object, we will use the results() function:
```
res <- results(dds, contrast = c("condition", "LNCAP_Hypoxia", "LNCAP_Normoxia"))

# Load annotation
annotation <- read.csv("GRCh38.p13_annotation.csv", header = TRUE, stringsAsFactors = FALSE)

# Calculate average CPM
raw_counts <- counts(dds, normalized = FALSE)
cpms <- rowMeans(edgeR::cpm(raw_counts))
cpms <- tibble(ensembl_id = rownames(dds), avg_cpm = cpms)

# Merge results, annotation, and CPM
res_tib <- as_tibble(res, rownames = "ensembl_id") %>%
           left_join(annotation, by = c("ensembl_id" = "ensembl_gene_id")) %>%
           left_join(cpms, by = "ensembl_id")
#Filter DE genes
de_genes_padj <- res_tib %>% filter(padj < 0.001)
de_genes_log2f <- res_tib %>% filter(padj < 0.001 & abs(log2FoldChange) > 0.5)
de_genes_cpm <- res_tib %>% filter(padj < 0.001 & avg_cpm > 2)
#Prepare ranked list for GSEA
res_prot <- res_tib %>% filter(gene_biotype == "protein_coding") %>%
            select(hgnc_symbol, log2FoldChange) %>%
            drop_na() %>%
            mutate(hgnc_symbol = toupper(hgnc_symbol)) %>%
            arrange(desc(log2FoldChange))
write.table(res_prot, file = "LNCAP_Hypoxia_vs_Normoxia_rank.rnk",
            sep = "\t", row.names = FALSE, quote = FALSE)
#Save filtered CSV files
write.csv(de_genes_padj, file = paste0(comparisons[1], "_vs_", comparisons[2], "_padj_cutoff.csv"), row.names = FALSE)
  write.csv(de_genes_log2f, file = paste0(comparisons[1], "_vs_", comparisons[2], "_log2fc_cutoff.csv"), row.names = FALSE)
  write.csv(de_genes_cpm, file = paste0(comparisons[1], "_vs_", comparisons[2], "_cpm_cutoff.csv"), row.names = FALSE)
  write.csv(combined_data, file = paste0(comparisons[1], "_vs_", comparisons[2], "_allgenes.csv"), row.names = FALSE)
  write.table(res_prot_ranked, file = paste0(comparisons[1], "_vs_", comparisons[2], "_rank.rnk"), sep = "\t", row.names = FALSE, quote = FALSE)

```
---

**1️⃣ Volcano Plot**

```r
# Load packages
library(ggplot2)
library(dplyr)
library(ggrepel)

# Load DE results CSV
res <- read.csv("LNCAP_Hypoxia_vs_LNCAP_Normoxia_allgenes.csv", header = TRUE)

# Volcano plot function
plot_volcano <- function(res, padj_cutoff = 0.0005, nlabel = 10, label.by = "padj") {
  # assign significance
  res <- res %>%
    mutate(significance = ifelse(padj < padj_cutoff,
                                 paste0("padj < ", padj_cutoff),
                                 paste0("padj > ", padj_cutoff))) %>%
    filter(!is.na(significance))
  
  significant_genes <- res %>% filter(significance == paste0("padj < ", padj_cutoff))
  
  # Get top and bottom genes
  if(label.by == "padj") {
    top_genes <- significant_genes %>% arrange(padj) %>% head(nlabel)
    bottom_genes <- significant_genes %>% filter(log2FoldChange < 0) %>% arrange(padj) %>% head(nlabel)
  } else if(label.by == "log2FoldChange") {
    top_genes <- significant_genes %>% arrange(desc(log2FoldChange)) %>% head(nlabel)
    bottom_genes <- significant_genes %>% arrange(log2FoldChange) %>% head(nlabel)
  } else stop("Invalid label.by argument. Choose either padj or log2FoldChange.")
  
  ggplot(res, aes(x = log2FoldChange, y = -log10(padj))) +
    geom_point(aes(color = significance)) +
    scale_color_manual(values = c("red", "black")) +
    ggrepel::geom_text_repel(data = top_genes, aes(label = hgnc_symbol), size = 3) +
    ggrepel::geom_text_repel(data = bottom_genes, aes(label = hgnc_symbol), color = "#619CFF", size = 3) +
    geom_vline(xintercept = 0, linetype = "dotted") +
    labs(x = "Log2FoldChange", y = "-log10(padj)") +
    theme_minimal()
}

# Example usage
plot_volcano(res, padj_cutoff = 0.0005, nlabel = 15, label.by = "padj")
````

> Genes downregulated are labeled in blue, upregulated in red. This allows quick identification of highly significant DE genes.

---

**2️⃣ Log2 Fold Change Comparison Between Two Cell Lines**

```r
# Load DE results for two comparisons
res1 <- read.csv("LNCAP_Hypoxia_vs_LNCAP_Normoxia_allgenes.csv", header = TRUE)
res2 <- read.csv("PC3_Hypoxia_vs_PC3_Normoxia_allgenes.csv", header = TRUE)

compare_significant_genes <- function(res1, res2, padj_cutoff = 0.0001, ngenes = 250, nlabel = 10,
                                      samplenames = c("comparison1", "comparison2"), title = "") {
  # Top up/down regulated genes
  genes1 <- rbind(head(res1[res1$padj < padj_cutoff,], ngenes),
                  tail(res1[res1$padj < padj_cutoff,], ngenes))
  genes2 <- rbind(head(res2[res2$padj < padj_cutoff,], ngenes),
                  tail(res2[res2$padj < padj_cutoff,], ngenes))
  
  # Union of genes
  de_union <- union(genes1$ensembl_id, genes2$ensembl_id)
  res1_union <- res1[match(de_union, res1$ensembl_id), c("ensembl_id", "log2FoldChange", "hgnc_symbol")]
  res2_union <- res2[match(de_union, res2$ensembl_id), c("ensembl_id", "log2FoldChange", "hgnc_symbol")]
  combined <- dplyr::left_join(res1_union, res2_union, by = "ensembl_id", suffix = samplenames)
  
  # Identify overlapping and unique DE genes
  combined$de_condition <- "None"
  combined$de_condition[combined$ensembl_id %in% intersect(genes1$ensembl_id, genes2$ensembl_id)] <- "Significant in Both"
  combined$de_condition[combined$ensembl_id %in% setdiff(genes1$ensembl_id, genes2$ensembl_id)] <- paste0("Significant in ", samplenames[1])
  combined$de_condition[combined$ensembl_id %in% setdiff(genes2$ensembl_id, genes1$ensembl_id)] <- paste0("Significant in ", samplenames[2])
  combined[is.na(combined)] <- 0
  
  # Labels
  label1 <- rbind(head(combined[combined$de_condition==paste0("Significant in ", samplenames[1]),], nlabel),
                  tail(combined[combined$de_condition==paste0("Significant in ", samplenames[1]),], nlabel))
  label2 <- rbind(head(combined[combined$de_condition==paste0("Significant in ", samplenames[2]),], nlabel),
                  tail(combined[combined$de_condition==paste0("Significant in ", samplenames[2]),], nlabel))
  label3 <- rbind(head(combined[combined$de_condition=="Significant in Both",], nlabel),
                  tail(combined[combined$de_condition=="Significant in Both",], nlabel))
  combined_labels <- rbind(label1, label2, label3)
  
  # Scatter plot of log2FC
  ggplot(combined, aes_string(x = paste0("log2FoldChange", samplenames[1]),
                              y = paste0("log2FoldChange", samplenames[2]))) +
    geom_point(aes(color = de_condition), size = 0.7) +
    scale_color_manual(values = c("#00BA38", "#619CFF", "#F8766D")) +
    ggrepel::geom_text_repel(data = combined_labels,
                             aes_string(label = paste0("hgnc_symbol", samplenames[1]), color = "de_condition"),
                             show.legend = FALSE, size = 3) +
    geom_vline(xintercept = 0, linetype = 2, size = 0.3) +
    geom_hline(yintercept = 0, linetype = 2, size = 0.3) +
    labs(title = title,
         x = paste0("log2FoldChange in ", samplenames[1]),
         y = paste0("log2FoldChange in ", samplenames[2])) +
    theme_minimal() +
    theme(legend.title = element_blank())
}

```


---


## 6. **Gene Set Enrichment Analysis (GSEA) of LNCaP Hypoxia RNA-seq**

---
 **1. Load HALLMARK Pathways**

Option 1: **Download GMT file manually** (`h.all.v7.0.symbols.gmt.txt`) from [MSigDB](https://www.gsea-msigdb.org/gsea/msigdb/collections.jsp)

```r
hallmark_pathway <- gmtPathways("h.all.v7.0.symbols.gmt.txt")
head(names(hallmark_pathway))
```

Option 2: **Use `msigdbr`** (requires stable internet)

```r
hallmark_genesets <- msigdbr(species = "Homo sapiens", collection = "H")
```

---

**2. Load and Prepare Ranked List**

```r
lncap_ranked_list <- read.table("LNCAP_Hypoxia_vs_LNCAP_Normoxia_rank.rnk",
                                header = TRUE, stringsAsFactors = FALSE)

prepare_ranked_list <- function(ranked_list) { 
  if (sum(duplicated(ranked_list$Gene.name)) > 0) {
    ranked_list <- aggregate(. ~ Gene.name, FUN = mean, data = ranked_list)
    ranked_list <- ranked_list[order(ranked_list$log2FoldChange, decreasing = TRUE), ]
  }
  ranked_list <- na.omit(ranked_list)
  tibble::deframe(ranked_list)
}

lncap_ranked_list <- prepare_ranked_list(lncap_ranked_list)
head(lncap_ranked_list)
```

---

**3. Run GSEA**

```r
fgsea_results <- fgsea(pathways = hallmark_pathway,
                       stats = lncap_ranked_list,
                       minSize = 15,
                       maxSize = 500,
                       nperm = 1000)

fgsea_results %>% 
  arrange(desc(NES)) %>% 
  select(pathway, padj, NES) %>% 
  head()
```

* **NES** = Normalized Enrichment Score
* **padj** = adjusted p-value

---

**4. Visualize Pathway Enrichment**

**Waterfall Plot**

```r
waterfall_plot <- function(fgsea_results, graph_title) {
  fgsea_results %>% 
    mutate(short_name = str_split_fixed(pathway, "_", 2)[,2]) %>%
    ggplot(aes(reorder(short_name, NES), NES)) +
    geom_bar(stat = "identity", aes(fill = padj < 0.05)) +
    coord_flip() +
    labs(x = "Hallmark Pathway", y = "Normalized Enrichment Score", title = graph_title) +
    theme(axis.text.y = element_text(size = 7),
          plot.title = element_text(hjust = 0.5))
}

waterfall_plot(fgsea_results, "Hallmark pathways altered by hypoxia in LNCaP cells")
```

---

**Enrichment Curves (Individual Pathways)**

```r
# Positively enriched (up in hypoxia)
png("HALLMARK_GLYCOLYSIS_enrichment.png", width = 800, height = 600, res = 150)
plotEnrichment(hallmark_pathway[["HALLMARK_GLYCOLYSIS"]], lncap_ranked_list) +
  labs(title = "HALLMARK_GLYCOLYSIS enrichment in LNCaP hypoxia") +
  theme_minimal()
dev.off()

# Hypoxia pathway
png("HALLMARK_HYPOXIA_enrichment.png", width = 800, height = 600, res = 150)
plotEnrichment(hallmark_pathway[["HALLMARK_HYPOXIA"]], lncap_ranked_list) +
  labs(title = "HALLMARK_HYPOXIA enrichment in LNCaP hypoxia") +
  theme_minimal()
dev.off()

# Negatively enriched (down in hypoxia)
png("HALLMARK_OXIDATIVE_PHOSPHORYLATION_enrichment.png", width = 800, height = 600, res = 150)
plotEnrichment(hallmark_pathway[["HALLMARK_OXIDATIVE_PHOSPHORYLATION"]], lncap_ranked_list) +
  labs(title = "HALLMARK_OXIDATIVE_PHOSPHORYLATION enrichment in LNCaP hypoxia") +
  theme_minimal()
dev.off()
```

---
 

Overall, this pipeline provides a robust framework for confidently exploring, visualizing, and interpreting bulk RNA-sequencing data.

### 📚 Learning Outcomes
Learned how to process raw RNA-Seq data step by step
Understood the importance of QC at every stage
Experienced handling large datasets and merging technical replicates
Performed differential expression analysis using DESeq2
Gained insights into how hypoxia impacts prostate cancer cell lines  

### 👩‍🏫 Mentor  
This work was carried out under the guidance of "Smriti Arora"   
reference for the analysis: https://github.com/erilu/bulk-rnaseq-analysis  

### 📬 Contact
Author: Sanchan Chandrashekar
Email: sanchan4000@gmail.com


