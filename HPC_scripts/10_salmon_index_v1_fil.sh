#!/bin/bash
#SBATCH --job-name=salmon_index_v1_fil
#SBATCH --partition=cpu
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.salmon_index_v1.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.salmon_index_v1.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$SALMON_MODULE"

# ---- Directories ----
INDEX_DIR="$TMP_DIR/salmon_index_v1_fil"
mkdir -p "$INDEX_DIR" "$LOG_DIR"

# ---- Input ----
TRINITY_FASTA="$TMP_DIR/filtered_assembly_v1/Trinity.TPM1.fasta"

if [[ ! -f "$TRINITY_FASTA" ]]; then
    echo "ERROR: Trinity.fasta not found at $TRINITY_FASTA"
    exit 1
fi

echo "[salmon_index_v1_fil] Input: $TRINITY_FASTA"
echo "[salmon_index_v1_fil] Output: $INDEX_DIR"
echo "[salmon_index_v1_fil] Building Salmon index..."

salmon index \
    -t "$TRINITY_FASTA" \
    -i "$INDEX_DIR" \
    -p "$SLURM_CPUS_PER_TASK" \
    --keepDuplicates

echo "[salmon_index_v1_fil] Index complete: $INDEX_DIR"
