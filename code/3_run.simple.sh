#!/bin/bash
#SBATCH -c 20                               # Request one core
#SBATCH -t 03-00:05                         # Runtime in D-HH:MM format
#SBATCH -p medium                           # Partition to run in
#SBATCH --mem=100G                         # Memory total in MiB (for all cores)
#SBATCH -o opt_%j.out                 # File to which STDOUT will be written, including job ID (%j)
#SBATCH -e opt_%j.err                 # File to which STDERR will be written, including job ID (%j)
                                           # You can change the filenames given with -o and -e to any filenames you'd like

#srun --pty -p interactive --mem 20G -t 0-2:00 -c 10 /bin/bash

# squeue -u bek321

### parameters
basedir=/n/scratch/users/<u>/<user>/phageIP/
cr=50
hd=25
SAMPLES=../data-raw/<SAMPLE_TABLE>.csv
PEP=../data-raw/peptide_table/VIR3_clean_CMVFixed_n_Betacoronavirus1.csv
adapt=/n/scratch/users/b/bek321/phageIP_PASC/data-raw/peptide_table/VIR3_clean.adapt.fa

source /home/${USER}/.bashrc
source activate phipflow2 
#conda activate phipflow2 (if running interactive)

############################

# simple run, call hits
nextflow run matsengrp/phip-flow -r V1.12  \
        --sample_table $SAMPLES \
        --peptide_table $PEP \
        --read_length 50 --oligo_tile_length 168 \
        --run_zscore_fit_predict true \
        --run_cpm_enr_workflow true \
        --output_wide_csv true \
        --output_tall_csv false \
        --peptide_seq_col peptide \
        --results simple_run_"$(date -I)" \
        -resume

# simple run, call hits, aggregate organism-specific hits by sample
nextflow run matsengrp/phip-flow -r V1.12  \
        --sample_table $SAMPLES \
        --peptide_table $PEP \
        --read_length 50 --oligo_tile_length 168 \
        --run_zscore_fit_predict true \
        --run_cpm_enr_workflow true \
        --output_wide_csv true \
        --output_tall_csv false \
        --peptide_seq_col peptide \
        --peptide_org_col Organism \
        --sample_grouping_col sample_ID \
        --results simple_run_agg_"$(date -I)" \
        -resume
