#!/bin/bash
#SBATCH --job-name=salmon_quant_v1
#SBATCH --partition=cpu
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --array=1-24%10
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.salmon_quant_v1.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.salmon_quant_v1.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$SALMON_MODULE"

# ---- Directories ----
INDEX_DIR="$TMP_DIR/salmon_index_v1"
QUANT_DIR="$TMP_DIR/salmon_quant_v1"

mkdir -p "$QUANT_DIR" "$LOG_DIR"

# ---- Input list ----
R1_LIST="$BASE_DIR/03_26_flut_trimmed_r1_list.txt"

if [[ ! -f "$R1_LIST" ]]; then
    echo "ERROR: Trimmed R1 list not found: $R1_LIST"
    exit 1
fi

# ---- Get sample for this array task ----
R1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$R1_LIST")

if [[ -z "${R1:-}" ]]; then
    echo "ERROR: No R1 file found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

R2="${R1/_R1_trimmed_/_R2_trimmed_}"
SAMPLE=$(basename "$R1" | cut -d_ -f1)

if [[ ! -f "$R1" ]]; then
    echo "ERROR: R1 file not found: $R1"
    exit 1
fi

if [[ ! -f "$R2" ]]; then
    echo "ERROR: R2 file not found: $R2"
    exit 1
fi

if [[ ! -f "$INDEX_DIR/seq.bin" ]]; then
    echo "ERROR: Salmon index not found at $INDEX_DIR"
    echo "Run 10_salmon_index_v1.sh first"
    exit 1
fi

echo "[$SAMPLE] R1: $R1"
echo "[$SAMPLE] R2: $R2"
echo "[$SAMPLE] Index: $INDEX_DIR"
echo "[$SAMPLE] Output: $QUANT_DIR/$SAMPLE"

# ---- Run Salmon ----
salmon quant \
    -i "$INDEX_DIR" \
    -l ISR \
    -1 "$R1" \
    -2 "$R2" \
    -p "$SLURM_CPUS_PER_TASK" \
    --validateMappings \
    --gcBias \
    --seqBias \
    -o "$QUANT_DIR/$SAMPLE"

echo "[$SAMPLE] Salmon quantification complete"
echo "[$SAMPLE] quant.sf: $QUANT_DIR/$SAMPLE/quant.sf"
