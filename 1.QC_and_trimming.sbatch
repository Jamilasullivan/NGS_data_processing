#!/bin/bash

#SBATCH --job-name=[job_name]
#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=1      #
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out        # redirect stdout to this file

## CREATING DIRECTORIES ########################################################################################################################################

mkdir -p ~/NGS_analysis/{data/{raw,trimmed,reference,metadata},\
results/{rawqc,trimmedqc,alignment,variants,coverage,annotation},\
scripts,\
logs,\
config,\
docs}

echo "Directory structure created!"

## PRESET VARIABLES ############################################################################################################################################

WORKDIR = $(pwd)                              # current path
RAWDIR = ${WORKDIR}/data/raw                  # location of FASTA/Q files
RAWQCDIR = ${WORKDIR}/results/rawqc           # storage of fastqc results for raw data
TRIMDIR = ${WORKDIR}/data/trimmed             # storage of the trimmed data
TRIMQCDIR = ${WORKDIR}/results/trimmedqc      # storage of fastqc results for trimmed data
MULTIQCDIR = ${WORKDIR}/

BASEQUAL = -q                                 # Base quality threshold: trim bases from the ends of reads if their Phred score < this value.
MAXUNQUAL = -u                                # Maximum percentage of unqualified bases per read: if more than this % of bases are below the quality threshold (-q), the whole read is discarded. Read-level filetering.
THREADS = -t                                  # -t2 indicates 2 threads (2 CPU cores to process the file in parallel.)

FASTQC = "fastqc/0.12.1"
FASTP = "fastp/0.23.2"
MULTIQC = "multiqc/1.33"

## FASTQC - RAW DATA QUALITY CONTROL ##############################################################################################################################

#loading the module
module load ${FASTQC}

#creating base names for files - list of sample names without suffices
for file in ${RAWDIR}/*_1.fast*                                                   # names all the samples to analyse
do

R1=$(basename $file | cut -file1 -d.)                                             # takes the file name, splits by the first '.' and keeps the first part
base=$(echo $R1 | sed 's/_1//')                                                   # removes the read number, leaving only the raw sample name

fastqc -q ${THREADS} ${RAWDIR}/${base}_1.fastq* \                  # running the fastqc command. -q supresses console messages. -t2 indicates 2 threads (2 CPU cores to process the file in parallel.
                     ${RAWDIR}/${base}_2.fastq* \
                  -o ${RAWQCDIR}

done

#unloading the module
module unload ${FASTQC}

## FASTP - TRIMMING AND FILTERING RAW DATA ########################################################################################################################

#loading the module
module load ${FASTP}

#creating base names for files - list of sample names without suffices
for file in ${RAWDIR}/*_1.fast*                                                   # names all the samples to analyse
do

R1=$(basename $file | cut -file1 -d.)                                             # takes the file name, splits by the first '.' and keeps the first part
base=$(echo $R1 | sed 's/_1//')                                                   # removes the read number, leaving only the raw sample name

fastp ${BASEQUAL} ${MAXUNQUAL} --cut_right\                                       # Trim low-quality bases from the 3’ end (right side) of reads. Use --trim_left to do the 5' end.
        		-i ${RAWDIR}/${base}_1.fastq*\                            # Input R1 FASTQ files
        		-I ${RAWDIR}/${base}_2.fastq*\                            # Input R2 FASTQ files (paired-end)
        		-o ${TRIMDIR}/${base}_trim_R1.fastq.gz\                   # Output R1 trimmed file
        		-O ${TRIMDIR}/${base}_trim_R2.fastq.gz\                   # Output R2 trimmed file
        		-h ${TRIMDIR}/fastp_report.html \                         # Generates HTML QC report per sample
        		-j ${TRIMDIR}/fastp_report.json                           # Generates JSON report (good for MultiQC)
done

#unloading module
module unload ${FASTP}

## FASTQC - TRIMMED AND FILTERED DATA QUALITY CONTROL #############################################################################################################

#loading the module
module load ${FASTQC}

#creating base names for files - list of sample names without suffices
for file in ${RAWDIR}/*_1.fast*                                                   # names all the samples to analyse
do

R1=$(basename $file | cut -file1 -d.)                                             # takes the file name, splits by the first '.' and keeps the first part
base=$(echo $R1 | sed 's/_1//')                                                   # removes the read number, leaving only the raw sample name

fastqc -q ${THREADS} ${TRIMDIR}/${base}_trim_R1.fastq.gz \
                     ${TRIMDIR}/${base}_trim_R2.fastq.gz \
                  -o ${TRIMQCDIR}

done

#unload module
module unload ${FASTQC}

## MULTIQC #####################################################################################################################################################

#loading module
module load 



