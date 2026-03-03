# NGS_data_processing

## Overview
This repository gives a general outline of a script to manage the analysis of NGS data. 
## General Requirements
There are some requirements from the user, in order to ensure the successful function of the scrips.
* The *0.directory_structure.sbatch* script should be run before any other steps in order to create the correct directories for all results to be saved into.
* The raw Fastq files should be stored within the *data/raw* directory created by the *0.directory_structure.sbatch* script.
## 1. QC and Trimming
The first script deals with the QC and trimming from the start point of Fastq files.
The *1.QC_and_trimming.sbatch* script completes the tasks (in order) of:
1. FastQC for quality control of raw fastq files
2. MultiQC to summarise the FastQC for the raw fastq files
3. Fastp for trimming and filtering of raw data
4. FastQC for quality control of trimmed and filtered reads
5. MultiQC to summarise the FastQC for the trimmed and filtered reads
## 2. Alignment
The second script deals with the alignment of reads to the reference genome. 
