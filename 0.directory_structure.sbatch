#!/bin/bash

## CREATING DIRECTORIES ####################################################################################################>

WORKDIR=$(pwd) # current path
mkdir -p ${WORKDIR}/{data/{raw,trimmed,reference,metadata},\
results/{rawqc,trimmedqc,trimmed_multiqc,raw_multiqc,alignment,variants,coverage,annotation},\
logs,\
config,\
docs}

echo "Directory structure created."
