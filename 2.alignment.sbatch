#!/bin/bash

#SBATCH --job-name=[for all related scripts]            # Give your job a name
#SBATCH --output=logs/sample_%j.out                     # Where to save stdout
#SBATCH --error=                                        # Where to save stderr
#SBATCH --time=                                         # Max wall-clock runtime
#SBATCH --cpus-per-task=8                               # Number of CPU cores to allocate
#SBATCH --mem=16G                                       # Total memory (RAM) requested
#SBATCH --partition=                                    # Which queue/partition to run on
#SBATCH --nodes=                                        # Number of compute nodes
#SBATCH --ntasks=                                       # Number of tasks (MPI jobs)
#SBATCH --mail-type=                                    # When to send email notifications
#SBATCH --mail-user=                                    # Your email address
#SBATCH --dependency=                                   # Run only after another job finishes
#SBATCH --account or --qos                              # Billing/project code
#SBATCH --job-name + -d singleton                       # Only one job with this name at a time

## DIRECTORIES #################################################################################################################################################

WORKDIR="${HOME}/NGS_analysis"
TRIMDIR="${WORKDIR}/data/trimmed"
REFDIR="${WORKDIR}/data/reference"
ALIGNDIR="${WORKDIR}/results/alignment"
LOGDIR="${WORKDIR}/logs"
REF="${REFDIR}/genome.fa"
DICT="${REFDIR}/genome.dict"

mkdir -p "${ALIGNDIR}" "${LOGDIR}"

THREADS=8

## ESTIMATION OF GENOME SIMILARITY USING MASH ##################################################################################################################

# breaks sequence into k-mers, randomly subsets to statistically represent the sequence, measures overlap, Jaccard index, distance estimate.

## REFERENCE PREPARATION #######################################################################################################################################

# Build lookup tables for aligner
bwa index "${REF}"
samtools faidx "${REF}"
picard CreateSequenceDictionary R="${REF}" O="${DICT}"

# Checking that refrence genome exists
if [ ! -f "${REF}" ]; then                                                                # if it is tested and found to not be true that a file with the name ${REF} exists, then...
  echo "ERROR: Reference fasta not found at ${REF}" >&2                                   # tell me that this file was not found and have this message also show up in the error log (stderr)
  exit 1                                                                                  # if this is the case then stop the script running here
fi                                                                                        # the end of an if command

# Index reference for bwa (only if index files don't exist)
if [ ! -f "${REF}.bwt" ]; then                                                            # if the .bwt file for my reference genome does not exist, then...
  echo "Indexing reference for bwa: $(date)"                                              # run the indexing step
  bwa index "${REF}"
fi

# Also ensure samtools faidx and sequence dictionary exist
if [ ! -f "${REF}.fai" ]; then                                                            # if the FASTA index (.fai) doesn’t exist, create it.
  echo "Creating samtools faidx for ${REF}"
  samtools faidx "${REF}"
fi

if [ ! -f "${DICT}" ]; then                                                               # if the sequence dictionary doesn't already exist , then...
  echo "Creating sequence dictionary for ${REF}"
  picard CreateSequenceDictionary R="${REF}" O="${DICT}"                                  # take the reference genome FASTA file and create it
fi

## ALIGNMENT ###################################################################################################################################################

for R1 in ${TRIMDIR}/*_R1.trim.fastq.gz; do
    SAMPLE=$(basename "${R1}" _R1.trim.fastq.gz)
    R2="${TRIMDIR}/${SAMPLE}_R2.trim.fastq.gz"                                                                   # define R1 and R2

    echo "Starting alignment for sample: ${SAMPLE} at $(date)"

    # Align with BWA MEM
    bwa mem -t "${THREADS}" "${REF}" "${R1}" "${R2}" \                                                           # alignment of R1 and R2 to $REF
        | samtools view -bS - > "${ALIGNDIR}/${SAMPLE}.unsorted.bam"                                             # converts SAM to unsorted BAM

    # Sort BAM
    samtools sort -@ "${THREADS}" -o "${ALIGNDIR}/${SAMPLE}.sorted.bam" "${ALIGNDIR}/${SAMPLE}.unsorted.bam"     # take the unsorted BAM files from ALIGNDIR, sort them and save them as sorted
    samtools index "${ALIGNDIR}/${SAMPLE}.sorted.bam"                                                            # create an index file of the sorted BAM files
    rm "${ALIGNDIR}/${SAMPLE}.unsorted.bam"                                                                      # remove unsorted files to save space

    # Mark duplicates
    picard MarkDuplicates \                                                                                      # use Picard to identify and flag PCR duplicates
        I="${ALIGNDIR}/${SAMPLE}.sorted.bam" \                                                                   # use sorted BAM files as the input
        O="${ALIGNDIR}/${SAMPLE}.dedup.bam" \                                                                    # create deduplicated BAM files as an output. The duplicates are not removed, only marked.
        M="${ALIGNDIR}/${SAMPLE}.metrics.txt" \                                                                  # create a metrics report
        CREATE_INDEX=true                                                                                        # create an index

    # QC summary
    samtools flagstat "${ALIGNDIR}/${SAMPLE}.dedup.bam" > "${ALIGNDIR}/${SAMPLE}.flagstat.txt"                   # give alignment stats summary
    samtools idxstats "${ALIGNDIR}/${SAMPLE}.dedup.bam" > "${ALIGNDIR}/${SAMPLE}.idxstats.txt"                   # give per-reference sequence statistics

    echo "Finished alignment for sample: ${SAMPLE} at $(date)"
done

echo "All samples aligned successfully!"
