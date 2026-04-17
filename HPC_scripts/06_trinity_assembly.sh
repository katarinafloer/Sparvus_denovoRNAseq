#!/bin/bash
#SBATCH --job-name=trinity_assembly
#SBATCH --partition=cpu
#SBATCH --constraint=avx512
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=48:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.trinity.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.trinity.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$TRINITY_MODULE"

# ---- Directories ----
TRINITY_DIR="$TMP_DIR/trinity"
TRINITY_OUT="$TRINITY_DIR/trinity_out_dir"

mkdir -p "$TRINITY_DIR" "$LOG_DIR" "$TMP_DIR/trinity_tmp"

# ---- Input files (from 04_concatenate_reads.sh) ----
ALL_LEFT="$TRINITY_DIR/reads.ALL.left.fastq.gz"
ALL_RIGHT="$TRINITY_DIR/reads.ALL.right.fastq.gz"

if [[ ! -f "$ALL_LEFT" ]]; then
    echo "ERROR: Concatenated left reads not found: $ALL_LEFT"
    echo "Run 04_concatenate_reads.sh first"
    exit 1
fi

if [[ ! -f "$ALL_RIGHT" ]]; then
    echo "ERROR: Concatenated right reads not found: $ALL_RIGHT"
    echo "Run 04_concatenate_reads.sh first"
    exit 1
fi

echo "[trinity] Left reads:  $ALL_LEFT ($(du -sh $ALL_LEFT | cut -f1))"
echo "[trinity] Right reads: $ALL_RIGHT ($(du -sh $ALL_RIGHT | cut -f1))"
echo "[trinity] Output dir:  $TRINITY_OUT"
echo "[trinity] CPUs: $SLURM_CPUS_PER_TASK"
echo "[trinity] Memory: 180G"
echo "[trinity] Strandedness: RF (confirmed ISR)"
echo "[trinity] Starting Trinity assembly..."

# ---- Run Trinity ----
Trinity \
    --seqType fq \
    --left "$ALL_LEFT" \
    --right "$ALL_RIGHT" \
    --SS_lib_type RF \
    --normalize_reads \
    --min_kmer_cov 2 \
    --max_memory 180G \
    --CPU "$SLURM_CPUS_PER_TASK" \
    --output "$TRINITY_OUT" 

# ---- Verify output ----
echo ""
echo "[trinity] Assembly complete."
echo "[trinity] Output FASTA: $TRINITY_OUT/Trinity.fasta"

if [[ -f "$TRINITY_OUT/Trinity.fasta" ]]; then
    echo "[trinity] Trinity.fasta size:  $(du -sh $TRINITY_OUT/Trinity.fasta | cut -f1)"
    echo "[trinity] Transcript count:    $(grep -c '^>' $TRINITY_OUT/Trinity.fasta)"
else
    echo "ERROR: Trinity.fasta not found — assembly may have failed"
    exit 1
fi

echo "[trinity] Done. Next steps:"
echo "  1. Run TrinityStats on Trinity.fasta"
echo "  2. Run BUSCO against vertebrata_odb10"
echo "  3. Build Salmon index from Trinity.fasta"
echo "  4. Run Salmon quantification for all 24 samples"
