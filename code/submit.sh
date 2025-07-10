#!/bin/bash
#SBATCH -c 1                               # Request one core
#SBATCH -t 0-05:00                         # Runtime in D-HH:MM format
#SBATCH -p short                           # Partition to run in
#SBATCH --mem=8G                           # Memory total in MiB (for all cores)
#SBATCH -o opt_%j.out                      # File to which STDOUT will be written, including job ID (%j)
#SBATCH -e opt_%j.err                      # File to which STDERR will be written, including job ID (%j)
                                           # You can change the filenames given with -o and -e to any filenames you'd like

# Required for nextflow:
module load java/jdk-23.0.1

# Required so that spawned jobs will be able to activate conda envs:
module load conda/miniforge3/24.11.3-0


usage() {
    echo "Usage: $0 [-s] [-g] [-b] -f filename -o dir -p peptide_table [-c nextflow_config] [-h]"
    echo "  -s         Run simple"
    echo "  -g         Run group comparison"
    echo "  -b         Run both simple and group comparisons"
    echo "  -c FILE    The Nextflow config file (optional)"
    echo "  -f FILE    The metadata file"
    echo "  -o DIR     The output directory"
    echo "  -p FILE    The peptide table"
    echo "  -h         Show this help message"
    exit 1
}

# No arguments: print usage
if [[ $# -eq 0 ]]; then
    usage
fi

DEFAULT_NF_CONFIG="nextflow/phage_ip.config"

# TODO: handle this:
PUBLIC_EPITOPES=""

RUN_SIMPLE=0
RUN_GROUP=0
RUN_BOTH=0
PERMISSIVE=0
INPUT_METADATA=""
OUTPUT_ROOT_DIRECTORY=""
NF_CONFIG=""
PEP=""

echo $NF_CONFIG
while getopts "sgbxf:o:c:p:h" opt; do
    case $opt in
        s) RUN_SIMPLE=1 ;;
        g) RUN_GROUP=1 ;;
        b) RUN_BOTH=1 ;;
        x) PERMISSIVE=1 ;;
        f) INPUT_METADATA="$OPTARG" ;;
        o) OUTPUT_ROOT_DIRECTORY="$OPTARG" ;;
        c) NF_CONFIG="$OPTARG" ;;
        p) PEP="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done


if [[ $RUN_SIMPLE -eq 0 && $RUN_GROUP -eq 0 && $RUN_BOTH -eq 0 ]]; then
    echo "You must specify -s, -g, or -b for simple, group, or both"
    exit 1
fi


if [[ -n "$OUTPUT_ROOT_DIRECTORY" ]]; then
    echo "Creating output directory: $OUTPUT_ROOT_DIRECTORY"
    mkdir -p "$OUTPUT_ROOT_DIRECTORY" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create output directory '$OUTPUT_ROOT_DIRECTORY'"
        exit 1
    fi
else
    echo "Error: the output directory location must be specified."
    exit 1
fi


if [[ -n "$INPUT_METADATA" ]]; then
    if [[ -f "$INPUT_METADATA" ]]; then
        echo "Using metadata file: $INPUT_METADATA"
    else
        echo "Error: File '$INPUT_METADATA' not found."
        exit 1
    fi
fi

if [[ -n "$PEP" ]]; then
    if [[ -f "$PEP" ]]; then
        echo "Using peptide table: $PEP"
    else
        echo "Error: File '$PEP' not found."
        exit 1
    fi
fi


if [[ -z "$NF_CONFIG" ]]; then
    NF_CONFIG="$DEFAULT_NF_CONFIG"
fi

if [[ -n "$NF_CONFIG" ]]; then
    if [[ -f "$NF_CONFIG" ]]; then
        echo "Using Nextflow config: $NF_CONFIG"
    else
        echo "Error: File '$NF_CONFIG' not found. If you did not override this using the -c argument, then something is amiss."
        exit 1
    fi
fi

# Create a timestamp to avoid overwriting
TIMESTAMP=$(date +%m-%d-%Y-%H-%M-%S)

# The phipflow process needs the final metadata file produced by
# the merge/trim/prep process, so we specify here for a single reference:
OUTPUT_METADATA_NAME="final_metadata.csv"

# Perform some checks to ensure that no one has modified the files
# and we are running with different parameters, etc.

# Print the current commit hash
commit_hash=$(git rev-parse HEAD)
echo "Current git commit hash: $commit_hash"

# Find previously committed files that have changes (modified/deleted, not untracked)
changed=$(git status --porcelain | grep -v '^??')
if [[ -z "$changed" ]]; then
    echo "Previously committed files are clean (no changes detected)."
else
    if [[ $PERMISSIVE -eq 0 ]]; then
        echo "ERROR: There were previously committed files with changes:"
        echo "$changed"
        echo "To prevent corruption of the results due to temporary changes, exiting."
        echo "If you would like to run WITH these changes, try again using the -x flag"
        exit 1
    else
        echo "WARNING: There are uncommitted changes in your pipeline code, but permissive mode was enabled."
        echo "$changed"
    fi
fi

# Run the pre-pipeline steps, such as lane merging and adapter trimming
nextflow run nextflow/main.nf -c $NF_CONFIG \
    -profile o2cluster \
    --input_metadata $INPUT_METADATA \
    --final_metadata $OUTPUT_METADATA_NAME \
    --output_dir $OUTPUT_ROOT_DIRECTORY/$TIMESTAMP \
    -resume

# now that the run directory was created, write the git commit there
# so that it's completely unambiguous:
echo $commit_hash > $OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/git_commit.txt
FINAL_METADATA_PATH=$OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/$OUTPUT_METADATA_NAME

if [[ $RUN_SIMPLE -eq 1 || $RUN_BOTH -eq 1 ]]; then

    nextflow run matsengrp/phip-flow -r V1.12  \
        -c $NF_CONFIG \
        -profile o2cluster \
        --sample_table $FINAL_METADATA_PATH \
        --peptide_table $PEP \
        --read_length 50 \
        --oligo_tile_length 168 \
        --run_zscore_fit_predict true \
        --run_cpm_enr_workflow true \
        --output_wide_csv true \
        --output_tall_csv false \
        --peptide_seq_col peptide \
        --results $OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/simple_run \
        -resume

    # simple run, call hits, aggregate organism-specific hits by sample
    nextflow run matsengrp/phip-flow -r V1.12  \
        -c $NF_CONFIG \
        -profile o2cluster \
        --sample_table $FINAL_METADATA_PATH \
        --peptide_table $PEP \
        --read_length 50 \
        --oligo_tile_length 168 \
        --run_zscore_fit_predict true \
        --run_cpm_enr_workflow true \
        --output_wide_csv true \
        --output_tall_csv false \
        --peptide_seq_col peptide \
        --peptide_org_col Organism \
        --sample_grouping_col sample_ID \
        --results $OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/simple_run_agg

fi

if [[ $RUN_GROUP -eq 1  || $RUN_BOTH -eq 1 ]]; then

    OUTDIR=$OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/group_run
    declare -a GROUPS=("sample_ID" "group1" "group2")
    declare -a TAXA=("Organism" "Species")

    for taxon in "${TAXA[@]}"
    do
        for group in "${GROUPS[@]}"
        do
    
            nextflow run matsengrp/phip-flow -r V1.12  \
                -c $NF_CONFIG \
                -profile o2cluster \
                --sample_table $FINAL_METADATA_PATH \
                --peptide_table $PEP \
                --read_length 50 \
                --oligo_tile_length 168 \
                --public_epitopes_csv $PUBLIC_EPITOPES \
                --run_zscore_fit_predict true \
                --run_cpm_enr_workflow true \
                --summarize_by_organism true \
                --output_wide_csv true \
                --output_tall_csv false \
                --run_BEER false \
                --peptide_seq_col peptide \
                --peptide_org_col ${taxon} \
                --sample_grouping_col ${group} \
                --results $OUTDIR \
                -resume

            mv $OUTDIR/aggregated_data/organism.summary.csv.gz $OUTDIR/aggregated_data/organism.summary.${group}__${taxon}.csv.gz
            mv $OUTDIR/aggregated_data/peptide.ebs.csv.gz $OUTDIR/aggregated_data/peptide.ebs.${group}__${taxon}.csv.gz

        done
    done
fi
