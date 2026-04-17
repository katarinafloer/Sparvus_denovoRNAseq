#!/bin/bash
#SBATCH --job-name=ex90n50_v1_filter
#SBATCH --partition=cpu
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=2:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.ex90n50_v1.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.ex90n50_v1.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$TRINITY_MODULE"

# ---- Input ----
TRINITY_FASTA="$TMP_DIR/filtered_assembly_v1/Trinity.TPM1.fasta"
FULL_MATRIX="$TMP_DIR/filtered_assembly_v1/salmon.isoform.TPM.not_cross_norm"
EX90_OUT="$TMP_DIR/ex90n50_v1_filtered"

FILTERED_IDS="$EX90_OUT/filtered_ids.txt"
FILTERED_MATRIX="$EX90_OUT/salmon.isoform.TPM.filtered"

mkdir -p "$EX90_OUT" "$LOG_DIR"

if [[ ! -f "$TRINITY_FASTA" ]]; then
    echo "ERROR: Trinity.fasta not found at $TRINITY_FASTA"
    exit 1
fi

if [[ ! -f "$FULL_MATRIX" ]]; then
    echo "ERROR: Full expression matrix not found at $FULL_MATRIX"
    exit 1
fi

echo "[ex90n50_v1_filtered] Assembly:      $TRINITY_FASTA"
echo "[ex90n50_v1_filtered] Full matrix:   $FULL_MATRIX"
echo "[ex90n50_v1_filtered] Filtered mat:  $FILTERED_MATRIX"
echo "[ex90n50_v1_filtered] Output:        $EX90_OUT"

# ---- Build filtered matrix matching filtered fasta ----
grep '^>' "$TRINITY_FASTA" | sed 's/^>//' > "$FILTERED_IDS"

awk 'NR==FNR {ids[$1]=1; next} FNR==1 || ($1 in ids)' \
    "$FILTERED_IDS" \
    "$FULL_MATRIX" \
    > "$FILTERED_MATRIX"

if [[ ! -s "$FILTERED_MATRIX" ]]; then
    echo "ERROR: Filtered matrix was not created properly"
    exit 1
fi

echo "[ex90n50_v1_filtered] Calculating ExN50 stats..."

perl "$EBROOTTRINITY"/trinityrnaseq-v2.15.1/util/misc/contig_ExN50_statistic.pl \
    "$FILTERED_MATRIX" \
    "$TRINITY_FASTA" \
    | tee "$EX90_OUT/ExN50_stats.txt"

echo ""
echo "========================================"
echo "  Ex90N50 RESULT"
echo "========================================"
grep "^90" "$EX90_OUT/ExN50_stats.txt" || tail -5 "$EX90_OUT/ExN50_stats.txt"
echo "========================================"
echo "[ex90n50_v1_filtered] Complete. Full stats: $EX90_OUT/ExN50_stats.txt"
