#!/bin/bash
#SBATCH --job-name=ex90n50_v2
#SBATCH --partition=cpu
#SBATCH --nodelist=cpu[069-079]
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=2:00:00
#SBATCH --output=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.ex90n50_v2.out
#SBATCH --error=/home/kfloer_smith_edu/03_26_flut_rnaseq/job_logs/%j.ex90n50_v2.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

source /home/kfloer_smith_edu/03_26_flut_rnaseq/03_26_flut_rnaseq_unity_config.sh

module load uri/main
module load "$TRINITY_MODULE"

TRINITY_FASTA="/scratch3/workspace/kfloer_smith_edu-simple/trinity_v3_50bp_nogrid/trinity_out_dir.Trinity.fasta"
QUANT_SF="$TMP_DIR/salmon_quant_ex90_v2/quant.sf"
EX90_OUT="$TMP_DIR/ex90n50_v2"

mkdir -p "$EX90_OUT" "$LOG_DIR"

if [[ ! -f "$TRINITY_FASTA" ]]; then
    echo "ERROR: Trinity.fasta not found at $TRINITY_FASTA"
    exit 1
fi

if [[ ! -f "$QUANT_SF" ]]; then
    echo "ERROR: quant.sf not found at $QUANT_SF"
    exit 1
fi

echo "[ex90n50_v2] Assembly: $TRINITY_FASTA"
echo "[ex90n50_v2] Quant:    $QUANT_SF"
echo "[ex90n50_v2] Output:   $EX90_OUT"
echo "[ex90n50_v2] Calculating ExN50 stats..."

perl "$EBROOTTRINITY"/trinityrnaseq-v2.15.1/util/misc/contig_ExN50_statistic.pl \
    "$QUANT_SF" \
    "$TRINITY_FASTA" \
    | tee "$EX90_OUT/ExN50_stats.txt"

echo ""
echo "========================================"
echo "  Ex90N50 RESULT"
echo "========================================"
grep "^90" "$EX90_OUT/ExN50_stats.txt" || tail -5 "$EX90_OUT/ExN50_stats.txt"
echo "========================================"
echo "[ex90n50_v2] Complete. Full stats: $EX90_OUT/ExN50_stats.txt"
