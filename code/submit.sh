#!/bin/bash
#SBATCH -c 1                               # Request one core
#SBATCH -t 0-05:00                         # Runtime in D-HH:MM format
#SBATCH -p short                           # Partition to run in
#SBATCH --mem=8G                           # Memory total in MiB (for all cores)
#SBATCH -o opt_%j.out                      # File to which STDOUT will be written, including job ID (%j)
#SBATCH -e opt_%j.err                      # File to which STDERR will be written, including job ID (%j)
                                           # You can change the filenames given with -o and -e to any filenames you'd like

# Required for nextflow:
module load java/jdk-21.0.2


# Input parameters to the script. For further description, see README in the repository:

# The metadata file which includes sample IDs, replicate information, FASTQ path, etc.
INPUT_METADATA=$1

# The root directory where results will be stored. Inside this directory will be a timestamped
# subdirectory so that multiple runs will not overwrite earlier files.
OUTPUT_ROOT_DIRECTORY=$2

# The peptide table:
PEP=$3

# The nextflow config file. If not specified, then use a default
# in the nextflow directory
NF_CONFIG=$4
if [ -z "${NF_CONFIG}" ]; then
    NF_CONFIG="nextflow/phage_ip.config"
fi

# Create a timestamp to avoid overwriting
TIMESTAMP=$(date +%m-%d-%Y-%H-%M-%S)

# The phipflow process needs the final metadata file produced by
# the merge/trim/prep process, so we specify here for a single reference:
OUTPUT_METADATA_NAME="final_metadata.csv"


# Run the pre-pipeline steps, such as lane merging and adapter trimming
nextflow run main.nf -c $NF_CONFIG \
    -profile o2cluster \
    --input_metadata $INPUT_METADATA \
    --final_metadata $OUTPUT_METADATA_NAME \
    --output_dir $OUTPUT_ROOT_DIRECTORY/$TIMESTAMP \
    -resume

FINAL_METADATA_PATH=$OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/$OUTPUT_METADATA_NAME


# simple run, call hits
nextflow run matsengrp/phip-flow -r V1.12  \
        -c $NF_CONFIG \
        -profile o2cluster \
        --sample_table $FINAL_METADATA_PATH \
        --peptide_table $PEP \
        --read_length 50 --oligo_tile_length 168 \
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
        --read_length 50 --oligo_tile_length 168 \
        --run_zscore_fit_predict true \
        --run_cpm_enr_workflow true \
        --output_wide_csv true \
        --output_tall_csv false \
        --peptide_seq_col peptide \
        --peptide_org_col Organism \
        --sample_grouping_col sample_ID \
        --results $OUTPUT_ROOT_DIRECTORY/$TIMESTAMP/simple_run_agg

