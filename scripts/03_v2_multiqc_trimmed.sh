#!/bin/bash
#SBATCH --job-name=multiqc_trimmed
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=23:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.multiqc_trimmed.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.multiqc_trimmed.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

#####################################
#  Load config + modules
#####################################

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load "$MULTIQC_PARENT_MODULE"
module --show_hidden load "$MULTIQC_MODULE"

#####################################
#  Directories & settings
#####################################


FASTQC_OUTPUT_DIR="$BASE_DIR/qc/fastqc_trimmedv2_50bp"
MULTIQC_OUTPUT_DIR="$BASE_DIR/qc/multiqc_trimmedv2_50bp"

mkdir -p "$LOG_DIR" "$FASTQC_OUTPUT_DIR" "$MULTIQC_OUTPUT_DIR"

echo "Running MultiQC on trimmed FastQC results in: $FASTQC_OUTPUT_DIR"

multiqc -o "$MULTIQC_OUTPUT_DIR" "$FASTQC_OUTPUT_DIR" \
  >"${LOG_DIR}/multiqc_trimmed.out.log" 2>"${LOG_DIR}/multiqc_trimmed.err.log"

echo "MultiQC (trimmed) completed!"
echo "FastQC reports:  $FASTQC_OUTPUT_DIR"
echo "MultiQC report:  $MULTIQC_OUTPUT_DIR"
echo "Logs are in      $LOG_DIR"
