#!/bin/bash
#SBATCH --job-name=filter_transcripts_v1
#SBATCH --partition=cpu
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.filter_transcripts_v1.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.filter_transcripts_v1.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$TRINITY_MODULE"
module load "$R_BIOCONDUCTOR_MODULE"

# ---- Directories ----
FILTER_DIR="$TMP_DIR/filtered_assembly_v1"
QUANT_DIR="$TMP_DIR/salmon_quant_v1"
mkdir -p "$FILTER_DIR" "$LOG_DIR"

# ---- Input ----
TRINITY_FASTA="$TRINITY_V1_FASTA"
GENE_TRANS_MAP="$TRINITY_V1_GENE_MAP"

# ---- Step 1: Generate TPM matrix from all 24 samples ----
echo "[filter_v1] Step 1: Generating TPM matrix..."

cd "$FILTER_DIR"

# List all quant.sf files
QUANT_FILES=$(ls "$QUANT_DIR"/*/quant.sf | tr '\n' ' ')

$EBROOTTRINITY/trinityrnaseq-v2.15.1/util/abundance_estimates_to_matrix.pl \
    --est_method salmon \
    --gene_trans_map "$GENE_TRANS_MAP" \
    --name_sample_by_basedir \
    --out_prefix salmon \
    $QUANT_FILES

echo "[filter_v1] TPM matrix generated"
ls -lh "$FILTER_DIR"/salmon*

# ---- Step 2: Filter low expression transcripts ----
echo "[filter_v1] Step 2: Filtering transcripts with min TPM < 1..."

perl "$EBROOTTRINITY"/trinityrnaseq-v2.15.1/util/filter_low_expr_transcripts.pl \
  --matrix "$FILTER_DIR/salmon.isoform.TPM.not_cross_norm" \
  --transcripts "$TRINITY_FASTA" \
  --gene_to_trans_map "$GENE_TRANS_MAP" \
  --min_expr_any 1 \
  > "$FILTER_DIR/Trinity.TPM1.fasta"

echo "[filter_v1] Filtering complete"

# ---- Step 3: Run TrinityStats on filtered assembly ----
echo "[filter_v1] Step 3: TrinityStats on filtered assembly..."
perl $EBROOTTRINITY/trinityrnaseq-v2.15.1/util/TrinityStats.pl \
    "$FILTER_DIR/Trinity.TPM1.fasta"

# ---- Summary ----
echo ""
echo "========================================"
echo "  FILTERING SUMMARY"
echo "========================================"
echo "Original transcripts: $(grep -c '^>' $TRINITY_FASTA)"
echo "Filtered transcripts: $(grep -c '^>' $FILTER_DIR/Trinity.TPM1.fasta)"
echo "Output: $FILTER_DIR/Trinity.TPM1.fasta"
echo "========================================"
