#!/bin/bash

# Go to the folder with BAM files
cd /home/sanchan_chandrasheka/bulkrnaseq_analysis/scripts || exit

# Path to annotation file (GTF)
GTF=/home/sanchan_chandrasheka/bulkrnaseq_analysis/reference/Homo_sapiens.GRCh38.114.gtf

# Path to output folder (already exists)
OUTDIR=/home/sanchan_chandrasheka/bulkrnaseq_analysis/quants

# Loop over all BAM files and run featureCounts
for bam in *.bam; do
    start=$(date +%s)

    echo "Processing $bam ..."
    featureCounts -s 0 -t exon -g gene_id \
        -a "$GTF" \
        -o "$OUTDIR/${bam%.bam}_featurecounts.txt" \
        "$bam"

    end=$(date +%s)
    runtime=$(( (end - start) / 60 ))
    echo "✅ Completed $bam in $runtime minutes."
    echo "------------------------------------"
done

