#!/bin/bash
#SBATCH --job-name=transdecoder_v1
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.transdecoder_v1.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.transdecoder_v1.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

# ---- Activate conda / mamba environment ----
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate annot_env

# ---- Input / output ----
FASTA="/scratch3/workspace/kfloer_smith_edu-simple/trinity/trinity_out_dir.Trinity.fasta"
OUT_DIR="/home/kfloer_smith_edu/03_26_flut_rnaseq/annot/transdecoder_out_v1"

mkdir -p "$OUT_DIR"

if [[ ! -f "$FASTA" ]]; then
    echo "ERROR: FASTA not found at $FASTA"
    exit 1
fi

echo "[transdecoder_v1] Input:  $FASTA"
echo "[transdecoder_v1] Output: $OUT_DIR"
echo "[transdecoder_v1] CPUs:   $SLURM_CPUS_PER_TASK"
echo "[transdecoder_v1] Starting TransDecoder..."

"$CONDA_PREFIX/opt/transdecoder/TransDecoder" \
    -t "$FASTA" \
    -O "$OUT_DIR" \
    --single_best_only

echo "[transdecoder_v1] Complete. Results: $OUT_DIR"
