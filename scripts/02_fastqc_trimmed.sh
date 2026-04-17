#!/bin/bash
#SBATCH --job-name=fastqc_trimmed
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=23:00:00
#SBATCH --array=1-24%10
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.fastqc_trimmed.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.fastqc_trimmed.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load "$FASTQC_MODULE"

# ---- Directories ----
FASTQC_OUTPUT_DIR="$BASE_DIR/qc/fastqc_trimmed"

mkdir -p \
  "$BASE_DIR" \
  "$LOG_DIR" \
  "$TMP_DIR" \
  "$BASE_DIR/qc" \
  "$FASTQC_OUTPUT_DIR"

# ---- Input list ----
# NOTE: This list file must be generated AFTER trimming completes.
# See TRIMMING_README.md for the find command to create it.
R1_LIST="$BASE_DIR/03_26_flut_trimmed_r1_list.txt"

if [[ ! -f "$R1_LIST" ]]; then
    echo "ERROR: R1 list file not found: $R1_LIST"
    echo "Generate it after trimming with:"
    echo "  find $BASE_DIR/trimmed -name '*_R1_trimmed_*' | sort > $R1_LIST"
    exit 1
fi

R1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$R1_LIST")

if [[ -z "${R1:-}" ]]; then
    echo "ERROR: No R1 file found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

R2="${R1/_R1_trimmed_/_R2_trimmed_}"

if [[ ! -f "$R1" ]]; then
    echo "ERROR: R1 file not found: $R1"
    exit 1
fi

if [[ ! -f "$R2" ]]; then
    echo "ERROR: R2 file not found: $R2"
    exit 1
fi

SAMPLE=$(basename "$R1" | cut -d_ -f1)

echo "[$SAMPLE] R1: $R1"
echo "[$SAMPLE] R2: $R2"
echo "[$SAMPLE] Output dir: $FASTQC_OUTPUT_DIR"

fastqc \
    -t "$SLURM_CPUS_PER_TASK" \
    --outdir "$FASTQC_OUTPUT_DIR" \
    "$R1" "$R2"

echo "[$SAMPLE] FastQC (trimmed) complete"
