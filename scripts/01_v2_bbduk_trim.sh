#!/bin/bash
#SBATCH --job-name=v2_bbduk_trim
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=23:00:00
#SBATCH --array=1-24%10
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.bbduk.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%A_%a.bbduk.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load "$BBDUK_MODULE"

# ---- Directories ----
TRIMMED_DIR="$TMP_DIR/trimmedv2_50bp"

mkdir -p \
  "$BASE_DIR" \
  "$LOG_DIR" \
  "$TMP_DIR" \
  "$TRIMMED_DIR"

# ---- Input list ----
R1_LIST="$BASE_DIR/03_26_flut_raw_r1_list.txt"

if [[ ! -f "$R1_LIST" ]]; then
    echo "ERROR: R1 list file not found: $R1_LIST"
    exit 1
fi

R1=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$R1_LIST")

if [[ -z "${R1:-}" ]]; then
    echo "ERROR: No R1 file found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

R2="${R1/_R1_/_R2_}"

if [[ ! -f "$R1" ]]; then
    echo "ERROR: R1 file not found: $R1"
    exit 1
fi

if [[ ! -f "$R2" ]]; then
    echo "ERROR: R2 file not found: $R2"
    exit 1
fi

SAMPLE=$(basename "$R1" | cut -d_ -f1)

# NOTE: QC report flags --
#   C45-2H  : only 5.6M read pairs (marginal depth); monitor post-trim counts
#   F103-3H : highest duplication (90.6%) and most failed FastQC modules (54.5%);
#             monitor post-alignment mapping rate and gene body coverage

# ---- Output file names ----
R1_BASENAME=$(basename "$R1")
R2_BASENAME=$(basename "$R2")
R1_TRIMMED="$TRIMMED_DIR/${R1_BASENAME/_R1_/_R1_trimmed_}"
R2_TRIMMED="$TRIMMED_DIR/${R2_BASENAME/_R2_/_R2_trimmed_}"

echo "[$SAMPLE] R1: $R1"
echo "[$SAMPLE] R2: $R2"
echo "[$SAMPLE] R1 trimmed: $R1_TRIMMED"
echo "[$SAMPLE] R2 trimmed: $R2_TRIMMED"
echo "[$SAMPLE] Adapters: $ADAPTERS_FILE"

# ---- Run BBDuk ----
# Parameters:
#   ktrim=r   - trim adapters from right end
#   k=23      - kmer length for adapter matching
#   mink=11   - minimum kmer length at read ends
#   hdist=1   - allow 1 mismatch in kmer matching
#   qtrim=rl  - quality-trim both ends
#   trimq=20  - quality threshold Q20
#   minlen=50 - discard reads shorter than 50 bp after trimming
#   tpe=t     - trim paired reads to same length
#   tbo=t     - trim by overlap (detect adapter via read overlap)

$BBDUK_CMD \
    in1="$R1" \
    in2="$R2" \
    out1="$R1_TRIMMED" \
    out2="$R2_TRIMMED" \
    ref="$ADAPTERS_FILE" \
    ktrim=r \
    k=23 \
    mink=11 \
    hdist=1 \
    qtrim=rl \
    trimq=20 \
    minlen=50 \
    tpe=t \
    tbo=t \
    threads="$SLURM_CPUS_PER_TASK" \
    -Xmx14g \
    tmpdir="$TMP_DIR"

echo "[$SAMPLE] BBDuk trimming complete"
