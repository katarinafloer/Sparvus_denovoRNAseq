#!/bin/bash
#SBATCH --job-name=detonate_v2
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.detonate_v2.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.detonate_v2.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

# ---- Activate conda environment ----
module purge
source $(conda info --base)/etc/profile.d/conda.sh
conda activate detonate_env

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

# ---- Directories ----
DETONATE_OUT="$TMP_DIR/detonate_v2"
mkdir -p "$DETONATE_OUT" "$LOG_DIR"

# ---- Input ----
TRINITY_FASTA="/scratch3/workspace/kfloer_smith_edu-simple/trinity_v3_50bp_nogrid/trinity_out_dir.Trinity.fasta"
ALL_LEFT="/scratch3/workspace/kfloer_smith_edu-simple/trinity_v2_50bp/reads.ALL.left.fastq.gz"
ALL_RIGHT="/scratch3/workspace/kfloer_smith_edu-simple/trinity_v2_50bp/reads.ALL.right.fastq.gz"

if [[ ! -f "$TRINITY_FASTA" ]]; then
    echo "ERROR: Trinity.fasta not found at $TRINITY_FASTA"
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

echo "[detonate_v2] Input assembly: $TRINITY_FASTA"
echo "[detonate_v2] Left reads:     $ALL_LEFT"
echo "[detonate_v2] Right reads:    $ALL_RIGHT"
echo "[detonate_v2] Output:         $DETONATE_OUT"
echo "[detonate_v2] CPUs:           $SLURM_CPUS_PER_TASK"
echo "[detonate_v2] Read length:    151bp"
echo "[detonate_v2] Starting DETONATE..."

# ---- Run DETONATE ----
rsem-eval-calculate-score \
    --paired-end \
    --strand-specific \
    --num-threads "$SLURM_CPUS_PER_TASK" \
    "$ALL_LEFT" \
    "$ALL_RIGHT" \
    "$TRINITY_FASTA" \
    "$DETONATE_OUT/detonate_v2" \
    151

# ---- Report result ----
echo ""
echo "========================================"
echo "  DETONATE RESULT"
echo "========================================"
cat "$DETONATE_OUT/detonate_v2.score"
echo "========================================"
echo "[detonate_v2] Complete. Results: $DETONATE_OUT"
