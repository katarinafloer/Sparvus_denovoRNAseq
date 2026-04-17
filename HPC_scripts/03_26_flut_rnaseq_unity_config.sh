#!/bin/bash

#####################################
#  UNITY HPC MASTER CONFIG FILE
#####################################

# ---- Directories ----
export BASE_DIR="/home/kfloer_smith_edu/03_26_flut_rnaseq"

export LOG_DIR="$BASE_DIR/job_logs"
export RAW_DIR="/work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq"

export TMP_DIR="/scratch3/workspace/kfloer_smith_edu-simple"
export ADAPTERS_FILE="/home/kfloer_smith_edu/adapters_truseq.fa"

# ---- Tools / Modules ----
#module avail STAR
export STAR_MODULE="STAR/2.7.10b-GCC-11.3.0"
export STAR_PARENT_MODULE="uri/main"
export SAMTOOLS_MODULE="samtools/1.19.2"
export FASTQC_MODULE="fastqc/0.12.1"
export MULTIQC_PARENT_MODULE="uri/main"
export MULTIQC_MODULE="MultiQC/1.12-foss-2021b"
export TRIMMOMATIC_MODULE="trimmomatic/0.39"
export BBDUK_MODULE="bbmap/39.01"
export BBDUK_CMD="bbduk.sh"

export TRINITY_MODULE="Trinity/2.15.1-foss-2022a"
export TRINITY_PARENT_MODULE="uri/main"

export SALMON_MODULE="Salmon/1.9.0-GCC-11.3.0"
export SALMON_PARENT_MODULE="uri/main"
export TRINITY_V1_FASTA="/scratch3/workspace/kfloer_smith_edu-simple/trinity/trinity_out_dir.Trinity.fasta"
export R_BIOCONDUCTOR_MODULE="R-bundle-Bioconductor/3.15-foss-2022a-R-4.2.1"
