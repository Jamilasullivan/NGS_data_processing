#!/bin/bash
#SBATCH --job-name=alignment_pipeline
#SBATCH --output=logs/sample_%j.out
#SBATCH --error=logs/sample_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=standard
#SBATCH -d singleton
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=your_email@example.com
#SBATCH --account=my_lab_account

## DIRECTORIES ##########################################################################################################
WORKDIR=$(pwd)
TRIMDIR=${WORKDIR}/data/trimmed
REFDIR=${WORKDIR}/data/reference
ALIGNDIR=${WORKDIR}/results/alignment
LOGDIR=${WORKDIR}/logs
THREADS=8

mkdir -p "${ALIGNDIR}" "${LOGDIR}"

## CHECK FOR FASTA REFERENCE FILES #####################################################################################
shopt -s nullglob
ref_files=("${REFDIR}"/*.fa "${REFDIR}"/*.fna)
if [ ${#ref_files[@]} -eq 0 ]; then
    echo "ERROR: No reference FASTA files found in ${REFDIR}" >&2
    exit 1
fi
shopt -u nullglob

## REFERENCE PREPARATION ###############################################################################################
for REF in "${ref_files[@]}"; do
    fname=$(basename "$REF")
    base="${fname%.fna}"
    base="${base%.fa}"

    if [ ! -f "${REF}.bwt" ]; then
        echo "Indexing $REF with BWA..."
        bwa index "$REF"
    fi

    if [ ! -f "${REF}.fai" ]; then
        echo "Creating faidx for $REF..."
        samtools faidx "$REF"
    fi

    dict="${REF%.*}.dict"
    if [ ! -f "$dict" ]; then
        echo "Creating Picard dictionary for $REF..."
        picard CreateSequenceDictionary R="$REF" O="$dict"
    fi
done

REFGENOME="${ref_files[0]}"

## ALIGNMENT ###########################################################################################################
for R1 in "${TRIMDIR}"/*_trim_R1.fastq.gz; do
    SAMPLE=$(basename "$R1" _trim_R1.fastq.gz)
    R2="${TRIMDIR}/${SAMPLE}_trim_R2.fastq.gz"

    echo "Aligning ${SAMPLE} at $(date)..."

    bwa mem -t $THREADS "$REFGENOME" "$R1" "$R2" \
        | samtools view -bS - > "${ALIGNDIR}/${SAMPLE}.unsorted.bam"

    samtools sort -@ $THREADS -o "${ALIGNDIR}/${SAMPLE}.sorted.bam" "${ALIGNDIR}/${SAMPLE}.unsorted.bam"
    samtools index "${ALIGNDIR}/${SAMPLE}.sorted.bam"
    rm "${ALIGNDIR}/${SAMPLE}.unsorted.bam"

    picard MarkDuplicates \
        I="${ALIGNDIR}/${SAMPLE}.sorted.bam" \
        O="${ALIGNDIR}/${SAMPLE}.dedup.bam" \
        M="${ALIGNDIR}/${SAMPLE}.metrics.txt" \
        CREATE_INDEX=true

    samtools flagstat "${ALIGNDIR}/${SAMPLE}.dedup.bam" > "${ALIGNDIR}/${SAMPLE}.flagstat.txt"
    samtools idxstats "${ALIGNDIR}/${SAMPLE}.dedup.bam" > "${ALIGNDIR}/${SAMPLE}.idxstats.txt"
done

echo "All samples aligned successfully!"
