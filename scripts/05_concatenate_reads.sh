#!/bin/bash
#SBATCH --job-name=concatenate_reads
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=4:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.concatenate.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.concatenate.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

# ---- Directories ----
TRINITY_DIR="$TMP_DIR/trinity"
mkdir -p "$TRINITY_DIR" "$LOG_DIR"

# ---- Input list ----
R1_LIST="$BASE_DIR/03_26_flut_trimmed_r1_list.txt"

if [[ ! -f "$R1_LIST" ]]; then
    echo "ERROR: Trimmed R1 list not found: $R1_LIST"
    exit 1
fi

# ---- Output files ----
ALL_LEFT="$TRINITY_DIR/reads.ALL.left.fastq.gz"
ALL_RIGHT="$TRINITY_DIR/reads.ALL.right.fastq.gz"

echo "[concat] Excluding C45-2H, concatenating 23 samples..."
echo "[concat] Output left:  $ALL_LEFT"
echo "[concat] Output right: $ALL_RIGHT"

# ---- Concatenate R1 (left) ----
echo "[concat] Concatenating R1 reads..."
while IFS= read -r R1; do
    # Skip C45-2H
    if [[ "$R1" == *"C45-2H"* ]]; then
        echo "[concat] Skipping: $R1"
        continue
    fi
    if [[ ! -f "$R1" ]]; then
        echo "ERROR: R1 file not found: $R1"
        exit 1
    fi
    echo "[concat] Adding: $(basename $R1)"
    cat "$R1" >> "$ALL_LEFT"
done < "$R1_LIST"

# ---- Concatenate R2 (right) ----
echo "[concat] Concatenating R2 reads..."
while IFS= read -r R1; do
    # Skip C45-2H
    if [[ "$R1" == *"C45-2H"* ]]; then
        continue
    fi
    R2="${R1/_R1_trimmed_/_R2_trimmed_}"
    if [[ ! -f "$R2" ]]; then
        echo "ERROR: R2 file not found: $R2"
        exit 1
    fi
    echo "[concat] Adding: $(basename $R2)"
    cat "$R2" >> "$ALL_RIGHT"
done < "$R1_LIST"

# ---- Verify output ----
echo ""
echo "[concat] Verifying output files..."
echo "[concat] Left file size:  $(du -sh $ALL_LEFT | cut -f1)"
echo "[concat] Right file size: $(du -sh $ALL_RIGHT | cut -f1)"
echo "[concat] Concatenation complete."
echo "[concat] Left:  $ALL_LEFT"
echo "[concat] Right: $ALL_RIGHT"
