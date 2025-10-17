#!/bin/bash

# Paths
BAMDIR=/home/sanchan_chandrasheka/bulkrnaseq_analysis/scripts
GTF=/home/sanchan_chandrasheka/bulkrnaseq_analysis/reference/Homo_sapiens.GRCh38.114.gtf
OUTDIR=/home/sanchan_chandrasheka/bulkrnaseq_analysis/qualimap_qc

# Make output folder if not exists
mkdir -p "$OUTDIR"

# Loop through BAM files
for bamfile in "$BAMDIR"/*.bam; do
    sample=$(basename "$bamfile" .bam)

    echo "🔎 Running Qualimap for $sample ..."
    qualimap rnaseq \
        -bam "$bamfile" \
        -gtf "$GTF" \
        -outdir "$OUTDIR/rnaseq_qc_${sample}" \
        --java-mem-size=8G

    echo "✅ Completed $sample"
    echo "------------------------------------"
done
