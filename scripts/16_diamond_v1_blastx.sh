#!/bin/bash
#SBATCH --job-name=diamond_v1_x
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.diamond_v1_x.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.diamond_v1_x.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

# ---- activate env ----
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate annot_env

# ---- paths ----
PEP="/scratch3/workspace/kfloer_smith_edu-simple/trinity/trinity_out_dir.Trinity.fasta"
DB="/home/kfloer_smith_edu/03_26_flut_rnaseq/annot/swissprot"
OUT_DIR="/home/kfloer_smith_edu/03_26_flut_rnaseq/annot/annot_v1_blastx"
OUT="$OUT_DIR/diamond_swissprot.tsv"

mkdir -p "$OUT_DIR"

# ---- sanity checks ----
if [[ ! -f "$PEP" ]]; then
  echo "ERROR: peptide file not found: $PEP"
  exit 1
fi

if [[ ! -f "${DB}.dmnd" ]]; then
  echo "ERROR: DIAMOND DB not found: ${DB}.dmnd"
  exit 1
fi

echo "[diamond_v1] Starting DIAMOND"
echo "[diamond_v1] Query: $PEP"
echo "[diamond_v1] DB: ${DB}.dmnd"
echo "[diamond_v1] Threads: $SLURM_CPUS_PER_TASK"

# ---- run ----
diamond blastx \
  --query "$PEP" \
  --db "$DB" \
  --out "$OUT" \
  --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle \
  --max-target-seqs 1 \
  --evalue 1e-5 \
  --threads "$SLURM_CPUS_PER_TASK" \
  --more-sensitive

echo "[diamond_v1] Done → $OUT"
