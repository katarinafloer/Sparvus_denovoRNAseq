#!/bin/bash
#SBATCH --job-name=salmon_quant_ex90_v2
#SBATCH --partition=cpu
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=8:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.salmon_quant_ex90_v2.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.salmon_quant_ex90_v2.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$SALMON_MODULE"

# ---- Directories ----
INDEX_DIR="$TMP_DIR/salmon_index_v3_50bp"
QUANT_DIR="$TMP_DIR/salmon_quant_ex90_v2"
mkdir -p "$QUANT_DIR" "$LOG_DIR"

# ---- Input ----
ALL_LEFT="$TMP_DIR/trinity_v2_50bp/reads.ALL.left.fastq.gz"
ALL_RIGHT="$TMP_DIR/trinity_v2_50bp/reads.ALL.right.fastq.gz"

if [[ ! -f "$INDEX_DIR/seq.bin" ]]; then
    echo "ERROR: Salmon index not found at $INDEX_DIR"
    echo "Run the 50bp Salmon index job first"
    exit 1
fi

if [[ ! -f "$ALL_LEFT" ]]; then
    echo "ERROR: Left reads not found at $ALL_LEFT"
    exit 1
fi

if [[ ! -f "$ALL_RIGHT" ]]; then
    echo "ERROR: Right reads not found at $ALL_RIGHT"
    exit 1
fi

echo "[salmon_quant_ex90_v2] Index:       $INDEX_DIR"
echo "[salmon_quant_ex90_v2] Left reads:  $ALL_LEFT"
echo "[salmon_quant_ex90_v2] Right reads: $ALL_RIGHT"
echo "[salmon_quant_ex90_v2] Output:      $QUANT_DIR"
echo "[salmon_quant_ex90_v2] Running Salmon quantification..."

salmon quant \
    -i "$INDEX_DIR" \
    -l ISR \
    -1 "$ALL_LEFT" \
    -2 "$ALL_RIGHT" \
    -p "$SLURM_CPUS_PER_TASK" \
    --validateMappings \
    --gcBias \
    --seqBias \
    -o "$QUANT_DIR"

echo "[salmon_quant_ex90_v2] Quantification complete: $QUANT_DIR"
echo "[salmon_quant_ex90_v2] quant.sf: $QUANT_DIR/quant.sf"
