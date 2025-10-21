# Bulkrna_sequencing
This project demonstrates step-by-step analysis of Bulk RNA-Seq data, starting from raw SRA files to obtaining differentially expressed genes (DEGs).
```
variable_gene_heatmap(vsd, num_genes = 40, annotation = annotation)
```bash
# Align FASTQ file to the genome
hisat2 -q -x grch38/genome -U fastq/LNCAP_Hypoxia_S1.fastq.gz | samtools sort -o alignedreads/LNCAP_Hypoxia_S1.bam
samtools index alignedreads/LNCAP_Hypoxia_S1.bam
