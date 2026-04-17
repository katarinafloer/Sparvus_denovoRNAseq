#!/bin/bash
#SBATCH --job-name=check_strandedness_multi
#SBATCH --partition=cpu
#SBATCH --constraint=avx512
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.strandedness_multi.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.strandedness_multi.err
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

mkdir -p "$STRAND_DIR"

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

# ---- Input list ----
R1_LIST="$BASE_DIR/03_26_flut_trimmed_r1_list.txt"

if [[ ! -f "$R1_LIST" ]]; then
    echo "ERROR: Trimmed R1 list not found: $R1_LIST"
    exit 1
fi

# ---- Test 5 samples: one from each major group ----
# C45 body, C45 head, C103 body, F103 body, F103 head
# Excludes C45-2H (low depth)
SAMPLES_TO_TEST=(
    $(grep "C45-" "$R1_LIST" | grep "_B_\|B_S" | grep -v "C45-2H" | head -1)
    $(grep "C45-" "$R1_LIST" | grep "_H_\|H_S" | grep -v "C45-2H" | head -1)
    $(grep "C103-" "$R1_LIST" | grep "_B_\|B_S" | head -1)
    $(grep "F103-" "$R1_LIST" | grep "_B_\|B_S" | head -1)
    $(grep "F103-" "$R1_LIST" | grep "_H_\|H_S" | head -1)
)

# ---- Summary file ----
SUMMARY="$STRAND_DIR/strandedness_summary.txt"
echo "Sample  Expected_Format  Compatible_Ratio  ISR  ISF  IU" > "$SUMMARY"

# ---- Run Salmon on each test sample ----
for TEST_R1 in "${SAMPLES_TO_TEST[@]}"; do

    if [[ -z "$TEST_R1" ]]; then
        echo "[strandedness] WARNING: could not find a sample for one group, skipping..."
        continue
    fi

    TEST_R2="${TEST_R1/_R1_trimmed_/_R2_trimmed_}"
    SAMPLE=$(basename "$TEST_R1" | cut -d_ -f1)
    QUANT_DIR="$STRAND_DIR/quant_${SAMPLE}"

    mkdir -p "$QUANT_DIR"

    echo ""
    echo "[strandedness] Processing sample: $SAMPLE"
    echo "[strandedness] R1: $TEST_R1"
    echo "[strandedness] R2: $TEST_R2"

    # Subsample 1M read pairs
    set +o pipefail
    zcat "$TEST_R1" | head -4000000 | gzip > "$STRAND_DIR/test_${SAMPLE}_R1.fastq.gz"
    zcat "$TEST_R2" | head -4000000 | gzip > "$STRAND_DIR/test_${SAMPLE}_R2.fastq.gz"
    set -o pipefail

    # Run Salmon with auto-detect
    salmon quant \
        -i "$INDEX_DIR" \
        -l A \
        -1 "$STRAND_DIR/test_${SAMPLE}_R1.fastq.gz" \
        -2 "$STRAND_DIR/test_${SAMPLE}_R2.fastq.gz" \
        -p "$SLURM_CPUS_PER_TASK" \
        --validateMappings \
        -o "$QUANT_DIR"

    # Extract key values from json
    EXPECTED=$(grep "expected_format" "$QUANT_DIR/lib_format_counts.json" | awk -F'"' '{print $4}')
    RATIO=$(grep "compatible_fragment_ratio" "$QUANT_DIR/lib_format_counts.json" | awk -F': ' '{print $2}' | tr -d ',')
    ISR=$(grep '"ISR"' "$QUANT_DIR/lib_format_counts.json" | awk -F': ' '{print $2}' | tr -d ',')
    ISF=$(grep '"ISF"' "$QUANT_DIR/lib_format_counts.json" | awk -F': ' '{print $2}' | tr -d ',')
    IU=$(grep '"IU"' "$QUANT_DIR/lib_format_counts.json" | awk -F': ' '{print $2}' | tr -d ',')

    echo "$SAMPLE  $EXPECTED  $RATIO  $ISR  $ISF  $IU" >> "$SUMMARY"

    echo "[strandedness] $SAMPLE result: $EXPECTED (compatible ratio: $RATIO)"

done

# ---- Print summary ----
echo ""
echo "========================================"
echo "  STRANDEDNESS SUMMARY — ALL SAMPLES"
echo "========================================"
cat "$SUMMARY"
echo "========================================"
echo "  ISR = RF stranded  -->  --SS_lib_type RF for Trinity"
echo "  ISF = FR stranded  -->  --SS_lib_type FR for Trinity"
echo "  IU  = unstranded   -->  no --SS_lib_type flag"
echo "========================================"
echo "[strandedness] Complete. Full output: $STRAND_DIR"
echo "[strandedness] Summary table: $SUMMARY"
