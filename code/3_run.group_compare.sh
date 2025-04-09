#!/bin/bash
#SBATCH -c 20                               # Request one core
#SBATCH -t 3-00:05                         # Runtime in D-HH:MM format
#SBATCH -p medium                           # Partition to run in
#SBATCH --mem=100G                         # Memory total in MiB (for all cores)
#SBATCH -o opt_%j.out                 # File to which STDOUT will be written, including job ID (%j)
#SBATCH -e opt_%j.err                 # File to which STDERR will be written, including job ID (%j)
                                           # You can change the filenames given with -o and -e to any filenames you'd like

# You can change hostname to any command you would like to run


### parameters
basedir=/n/scratch/users/<u>/<user>/phageIP/
cr=50
hd=25
SAMPLES=../data-raw/phipflow_demo_pan-cov-example/sample_table_with_beads_and_lib.DEMO.csv
PEP=../data-raw/peptide_table/VIR3_clean_CMVFixed_n_Betacoronavirus1.csv
adapt=/n/scratch/users/b/bek321/phageIP_PASC/data-raw/peptide_table/VIR3_clean.adapt.fa
PUBLIC=../data-raw/peptide_tables/public_epitopes_Table_S1_bms.cleanup.csv

outdir=virscan_momi_all_2024-10-31

declare -a GROUPS=("sample_ID" "group1" "group2")
declare -a TAXA=("Organism" "Species")

source /home/${USER}/.bashrc
source activate phipflow2 
#conda activate phipflow2 (if running interactive)

###########################

cd ${basedir}data-final

for taxon in "${TAXA[@]}"
do
    for group in "${GROUPS[@]}"
    do
    
                nextflow run matsengrp/phip-flow -r V1.12  \
                        --sample_table $SAMPi \
                        --peptide_table $PEP \
                        --read_length 50 --oligo_tile_length 168 \
                        --public_epitopes_csv ${PUBLIC} \
                        --run_zscore_fit_predict true \
                        --run_cpm_enr_workflow true \
                        --summarize_by_organism true \
                        --output_wide_csv true \
                        --output_tall_csv false \
                        --run_BEER false \
                        --peptide_seq_col peptide \
                        --peptide_org_col ${taxon} \
                        --sample_grouping_col ${group} \
                        --results ${outdir} \
                        -resume

                mv ${outdir}/aggregated_data/organism.summary.csv.gz ${outdir}/aggregated_data/organism.summary.${group}__${taxon}.csv.gz
                mv ${outdir}/aggregated_data/peptide.ebs.csv.gz ${outdir}/aggregated_data/peptide.ebs.${group}__${taxon}.csv.gz

    done
done