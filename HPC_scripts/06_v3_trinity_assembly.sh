#!/bin/bash
#SBATCH --job-name=trinity_assembly_v3
#SBATCH --partition=cpu
#SBATCH --constraint=avx512
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=48:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.trinity_v2.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.trinity_v2.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$TRINITY_MODULE"

# ---- GridRunner path ----
GRID_RUNNER="/home/kfloer_smith_edu/HpcGridRunner/hpc_cmds_GridRunner.pl"
GRID_CONF="/home/kfloer_smith_edu/03_26_flut_rnaseq/hpc_grid_runner.conf"

if [[ ! -f "$GRID_RUNNER" ]]; then
    echo "ERROR: HPC GridRunner not found at $GRID_RUNNER"
    echo "Clone it with: git clone https://github.com/HpcGridRunner/HpcGridRunner.git ~/HpcGridRunner"
    exit 1
fi

if [[ ! -f "$GRID_CONF" ]]; then
    echo "ERROR: Grid config not found at $GRID_CONF"
    exit 1
fi

# ---- Directories ----
TRINITY_DIR="$TMP_DIR/trinity_v2_50bp"
TRINITY_OUT="$TRINITY_DIR/trinity_out_dir"

mkdir -p "$TRINITY_DIR" "$LOG_DIR"

# ---- Input files ----
ALL_LEFT="$TRINITY_DIR/reads.ALL.left.fastq.gz"
ALL_RIGHT="$TRINITY_DIR/reads.ALL.right.fastq.gz"

if [[ ! -f "$ALL_LEFT" ]]; then
    echo "ERROR: Concatenated left reads not found: $ALL_LEFT"
    echo "Run 04b_concatenate_reads_v2.sh first"
    exit 1
fi

if [[ ! -f "$ALL_RIGHT" ]]; then
    echo "ERROR: Concatenated right reads not found: $ALL_RIGHT"
    echo "Run 04b_concatenate_reads_v2.sh first"
    exit 1
fi

echo "[trinity_v2] Left reads:  $ALL_LEFT ($(du -sh $ALL_LEFT | cut -f1))"
echo "[trinity_v2] Right reads: $ALL_RIGHT ($(du -sh $ALL_RIGHT | cut -f1))"
echo "[trinity_v2] Output dir:  $TRINITY_OUT"
echo "[trinity_v2] CPUs: $SLURM_CPUS_PER_TASK"
echo "[trinity_v2] Memory: 180G"
echo "[trinity_v2] Strandedness: RF (confirmed ISR)"
echo "[trinity_v2] minlen: 50bp trimming"
echo "[trinity_v2] GridRunner: enabled"
echo "[trinity_v2] Starting Trinity assembly..."

# ---- Run Trinity with GridRunner ----
Trinity \
    --seqType fq \
    --left "$ALL_LEFT" \
    --right "$ALL_RIGHT" \
    --SS_lib_type RF \
    --normalize_reads \
    --min_kmer_cov 2 \
    --max_memory 180G \
    --CPU "$SLURM_CPUS_PER_TASK" \
    --output "$TRINITY_OUT" \
    --grid_exec "$GRID_RUNNER --grid_conf $GRID_CONF -c" \
    --grid_node_CPU 2 \
    --grid_node_max_memory 4G

# ---- Verify output ----
echo ""
echo "[trinity_v2] Assembly complete."

if [[ -f "$TRINITY_OUT/Trinity.fasta" ]]; then
    echo "[trinity_v2] Trinity.fasta size:  $(du -sh $TRINITY_OUT/Trinity.fasta | cut -f1)"
    echo "[trinity_v2] Transcript count:    $(grep -c '^>' $TRINITY_OUT/Trinity.fasta)"
else
    echo "ERROR: Trinity.fasta not found — assembly may have failed"
    exit 1
fi

echo "[trinity_v2] Done. Next steps:"
echo "  1. Run TrinityStats on Trinity.fasta"
echo "  2. Run BUSCO against vertebrata_odb10"
echo "  3. Build Salmon index from Trinity.fasta"
echo "  4. Run Salmon quantification for all 24 samples"
