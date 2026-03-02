#!/bin/bash

#SBATCH --job-name=[job_name]
#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=1      #
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out        # redirect stdout to this file

## PRESET VARIABLES ############################################################################################################################################

WORKDIR=$(pwd)                                          # current path
RAWDIR=${WORKDIR}/data/raw                              # location of FASTA/Q files
RAWQCDIR=${WORKDIR}/results/rawqc                       # storage of fastqc results for raw data
TRIMDIR=${WORKDIR}/data/trimmed                         # storage of the trimmed data
TRIMQCDIR=${WORKDIR}/results/trimmedqc                  # storage of fastqc results for trimmed data
TRIMMULTIQCDIR=${WORKDIR}/results/trimmed_multiqc       # storage of trimmed multiqc results
RAWMULTIQCDIR=${WORKDIR}/results/raw_multiqc            # storage of raw multiqc results

#FASTQC="fastqc/0.12.1"
#FASTP="fastp/0.23.2"
#MULTIQC="multiqc/1.33"

echo "Variables created."

## FASTQC - RAW DATA QUALITY CONTROL ##############################################################################################################################

#loading the module
#module load fastqc/0.12.1

for file in "${RAWDIR}"/*_1.fastq*; do
    # Get the base filename without directory and without _1.fastq or _1.fastq.gz
    base=$(basename "$file" | sed -E 's/_1\.fastq(.gz)?//')

    R1="${RAWDIR}/${base}_1.fastq.gz"
    R2="${RAWDIR}/${base}_2.fastq.gz"

    # Check if files exist before running FastQC
    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "Running FastQC on $base"
        fastqc -q -t 2 "$R1" "$R2" -o "${RAWQCDIR}"
    else
        echo "Skipping $base: files not found"
    fi
done

#unloading the module
#module unload ${FASTQC}

echo "FastQC on raw data complete."

## MULTIQC FOR RAW READS ##################################################################################################################

#loading module
#module load ${MULTIQC}


multiqc ${RAWQCDIR}\
       -o ${RAWMULTIQCDIR}

echo "MultiQC complete."
echo "Ensure reference genome is ready for alignment."

#module purge

## FASTP - TRIMMING AND FILTERING RAW DATA ########################################################################################################################

#loading the module
#module load ${FASTP}

# creating base names for files - list of sample names without suffices
for file in ${RAWDIR}/*_1.fast*   # names all the samples to analyse
do
    # takes the file name, strips directory, splits by first '.' to get main name
    R1=$(basename "$file" | cut -d. -f1)

    # removes the read number (_1), leaving only the base sample name
    base=$(echo "$R1" | sed 's/_1//')

    # define paired file paths
    R1="${RAWDIR}/${base}_1.fastq.gz"
    R2="${RAWDIR}/${base}_2.fastq.gz"

    # run fastp on paired-end files
    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "${TRIMDIR}/${base}_trim_R1.fastq.gz" \
        -O "${TRIMDIR}/${base}_trim_R2.fastq.gz" \
        -h "${TRIMDIR}/${base}_fastp_report.html" \
        -j "${TRIMDIR}/${base}_fastp_report.json" \
        --qualified_quality_phred 33 \
        --unqualified_percent_limit 40 \
        --thread 2 \

    echo "Finished fastp for sample: ${base}"

done

#unload module ${FASTP}

## FASTQC - TRIMMED AND FILTERED DATA QUALITY CONTROL #############################################################################################################

#loading the module
#module load ${FASTQC}

#creating base names for files - list of sample names without suffices
for file in ${RAWDIR}/*_1.fast*                                                   # names all the samples to analyse
do

R1=$(basename $file | cut -d. -f1)                                             # takes the file name, splits by the first '.' and keeps the first part
base=$(echo $R1 | sed 's/_1//')                                                   # removes the read number, leaving only the raw sample name

fastqc -q -t 2 ${TRIMDIR}/${base}_trim_R1.fastq.gz \
               ${TRIMDIR}/${base}_trim_R2.fastq.gz \
               -o ${TRIMQCDIR}

done

#unload module
#module unload ${FASTQC}

echo "FastQC on trimmed data complete."

## MULTIQC #####################################################################################################################################################

#loading module
#module load ${MULTIQC}


multiqc ${TRIMQCDIR}\
       -o ${TRIMMULTIQCDIR}

echo "MultiQC complete."
echo "Ensure reference genome is ready for alignment."

#module purge
