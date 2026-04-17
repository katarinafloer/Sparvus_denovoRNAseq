#!/bin/bash
#SBATCH --job-name=busco_v2
#SBATCH --partition=cpu
#SBATCH --constraint=avx512
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.busco_v2.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.busco_v2.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

# ---- Purge modules and activate conda environment ----
module purge
source $(conda info --base)/etc/profile.d/conda.sh
conda activate busco_env

# ---- Directories ----
BUSCO_OUT="$TMP_DIR/busco_v2"
mkdir -p "$BUSCO_OUT" "$LOG_DIR"

# ---- Input ----
FASTA="/scratch3/workspace/kfloer_smith_edu-simple/trinity_v3_50bp_nogrid/trinity_out_dir.Trinity.fasta"

if [[ ! -f "$FASTA" ]]; then
    echo "ERROR: FASTA not found at $FASTA"
    exit 1
fi

echo "[busco_v2] Input: $FASTA"
echo "[busco_v2] Output: $BUSCO_OUT"
echo "[busco_v2] Lineage: vertebrata_odb10"
echo "[busco_v2] CPUs: $SLURM_CPUS_PER_TASK"
echo "[busco_v2] Starting BUSCO..."

# ---- Run BUSCO ----
busco \
    -i "$FASTA" \
    -o busco_v2_vertebrata \
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
cat "$BUSCO_OUT"/busco_v2_vertebrata/short_summary*.txt
echo "========================================"
echo "[busco_v2] Complete. Results: $BUSCO_OUT"
