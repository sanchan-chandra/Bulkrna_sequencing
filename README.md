# Bulk RNA-Seq Analysis – Hypoxia Response in LNCaP and PC3 Cell Lines
🎯 Project Overview

This project demonstrates an end-to-end Bulk RNA-Seq analysis workflow from raw SRA files to differentially expressed genes (DEGs).

We investigated how hypoxia alters gene expression in two prostate cancer cell lines:
| Cell Line | Origin                                                                |
| --------- | --------------------------------------------------------------------- |
| LNCaP     | Derived from a lymph node metastasis of human prostate adenocarcinoma |
| PC3       | Derived from a bone metastasis of a grade IV prostate adenocarcinoma  |
We compared Normoxia vs Hypoxia conditions in each cell line.
📌 Objectives

Learn a basic workflow of bulk RNA-Seq analysis

Perform quality control, alignment, quantification, and differential expression analysis

Visualize results using PCA, heatmaps, volcano plots, and perform pathway enrichment

Document a reproducible workflow for beginners

📂 Dataset Information

GEO Accession: GSE106305

Citation: Guo H, Ci X, Ahmed M, Hua JT et al. ONECUT2 is a driver of neuroendocrine prostate cancer. Nat Commun 2019 Jan 17;10(1):278. PMID: 30655535

Description: RNA-Seq and ChIP-Seq experiments in LNCaP and PC3 cells under normoxia and hypoxia conditions.

Note: Each biological sample is split into multiple technical runs (SRR IDs). We merged 20 SRR files into 8 final FASTQ files for analysis.

⚙️ Workflow Overview
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
