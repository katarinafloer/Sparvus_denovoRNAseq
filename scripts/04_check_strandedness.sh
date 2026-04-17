#!/bin/bash
#SBATCH --job-name=check_strandedness
#SBATCH --partition=cpu
#SBATCH --constraint=avx512
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=2:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.strandedness.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.strandedness.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$SALMON_MODULE"

# ---- Directories ----
STRAND_DIR="$TMP_DIR/strandedness_check"
DECOY_DIR="$STRAND_DIR/xenopus_ref"
INDEX_DIR="$STRAND_DIR/salmon_index"
QUANT_DIR="$STRAND_DIR/quant_out"

mkdir -p "$INDEX_DIR" "$QUANT_DIR"

# ---- Reference ----
XLAEVIS_REF="$DECOY_DIR/xlaevis_cdna.fa.gz"

if [[ ! -f "$XLAEVIS_REF" ]]; then
    echo "ERROR: Xenopus reference not found at $XLAEVIS_REF"
    exit 1
fi

# ---- Build Salmon index (skip if already exists) ----
if [[ ! -f "$INDEX_DIR/pos.bin" ]]; then
    echo "[strandedness] Building Salmon index..."
    salmon index \
        -t "$XLAEVIS_REF" \
        -i "$INDEX_DIR" \
        -p "$SLURM_CPUS_PER_TASK"
else
    echo "[strandedness] Salmon index already exists, skipping..."
fi

# ---- Pick one test sample ----
R1_LIST="$BASE_DIR/03_26_flut_trimmed_r1_list.txt"

if [[ ! -f "$R1_LIST" ]]; then
    echo "ERROR: Trimmed R1 list not found: $R1_LIST"
    exit 1
fi

TEST_R1=$(grep -v "C45-2H" "$R1_LIST" | head -1)
TEST_R2="${TEST_R1/_R1_trimmed_/_R2_trimmed_}"
SAMPLE=$(basename "$TEST_R1" | cut -d_ -f1)

echo "[strandedness] Test sample: $SAMPLE"
echo "[strandedness] R1: $TEST_R1"
echo "[strandedness] R2: $TEST_R2"

# ---- Subsample 1M read pairs ----
echo "[strandedness] Subsampling 1M read pairs..."
set +o pipefail
zcat "$TEST_R1" | head -4000000 | gzip > "$STRAND_DIR/test_R1.fastq.gz"
zcat "$TEST_R2" | head -4000000 | gzip > "$STRAND_DIR/test_R2.fastq.gz"
set -o pipefail

# ---- Run Salmon with auto-detect ----
echo "[strandedness] Running Salmon with --libType A..."
salmon quant \
    -i "$INDEX_DIR" \
    -l A \
    -1 "$STRAND_DIR/test_R1.fastq.gz" \
    -2 "$STRAND_DIR/test_R2.fastq.gz" \
    -p "$SLURM_CPUS_PER_TASK" \
    --validateMappings \
    -o "$QUANT_DIR"

# ---- Report result ----
echo ""
echo "========================================"
echo "  STRANDEDNESS RESULT FOR: $SAMPLE"
echo "========================================"
cat "$QUANT_DIR/lib_format_counts.json"
echo "========================================"
echo "  ISR = RF stranded  -->  --SS_lib_type RF for Trinity"
echo "  ISF = FR stranded  -->  --SS_lib_type FR for Trinity"
echo "  IU  = unstranded   -->  no --SS_lib_type flag"
echo "========================================"
echo "[strandedness] Complete. Output: $STRAND_DIR"
