#!/bin/bash
#SBATCH --job-name=busco_v1
#SBATCH --partition=cpu
#SBATCH --constraint=avx512
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.busco_v1.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.busco_v1.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

# ---- Purge modules and activate conda environment ----
module purge
source $(conda info --base)/etc/profile.d/conda.sh
conda activate busco_env

# ---- Directories ----
BUSCO_OUT="$TMP_DIR/busco_v1"
mkdir -p "$BUSCO_OUT" "$LOG_DIR"

# ---- Input ----
TRINITY_FASTA="$TRINITY_V1_FASTA"

if [[ ! -f "$TRINITY_FASTA" ]]; then
    echo "ERROR: Trinity.fasta not found at $TRINITY_FASTA"
    exit 1
fi

echo "[busco_v1] Input: $TRINITY_FASTA"
echo "[busco_v1] Output: $BUSCO_OUT"
echo "[busco_v1] Lineage: vertebrata_odb10"
echo "[busco_v1] CPUs: $SLURM_CPUS_PER_TASK"
echo "[busco_v1] Starting BUSCO..."

# ---- Run BUSCO ----
busco \
    -i "$TRINITY_FASTA" \
    -o busco_v1_vertebrata \
    --out_path "$BUSCO_OUT" \
    -l vertebrata_odb10 \
    -m transcriptome \
    -c "$SLURM_CPUS_PER_TASK" \
    --download_path "$TMP_DIR/busco_downloads"

# ---- Print summary ----
echo ""
echo "========================================"
echo "  BUSCO SUMMARY"
echo "========================================"
cat "$BUSCO_OUT"/busco_v1_vertebrata/short_summary*.txt
echo "========================================"
echo "[busco_v1] Complete. Results: $BUSCO_OUT"
