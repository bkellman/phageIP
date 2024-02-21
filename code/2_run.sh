srun --pty -p interactive --mem 50G -t 0-10:00 -c 20 /bin/bash
srun --pty -p interactive --mem 100G -t 0-10:00 -c 20 /bin/bash

# squeue -u bek321

### parameters
basedir=/n/scratch/users/b/bek321/phageIP/
cr=50
hd=25
SAMPLES=../data-raw/20231219_PASC_samples.trim.csv
PEP=../data-raw/peptide_table/VIR3_clean.csv

############################

wait
cd ${basedir}data-raw/fastq/

COUNTER=1

for infile in *.fastq.gz
do
        base=$(basename ${infile} .fastq.gz)
        trimmomatic SE -threads 2 ${infile} ${base}_1.trim.fastq.gz CROP:${cr} HEADCROP:${hd} SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:/n/scratch/users/b/bek321/phageIP_PASC/data-raw/peptide_table/VIR3_clean.adapt.fa:2:30:10 &

        COUNTER=$[$COUNTER +1]
       if (( $COUNTER % 10 == 0 ))           # no need for brackets
        then
            wait
        fi
done


conda activate phipflow2
cd ${basedir}data-final

nextflow run matsengrp/phip-flow -r V1.12  \
        --sample_table $SAMPLES \
        --peptide_table $PEP \
        --read_length 50 --oligo_tile_length 168 \
        --run_zscore_fit_predict \
        --run_cpm_enr_workflow \
        --summarize_by_organism true \
        --output_wide_csv \
        --output_tall_csv \
        --peptide_org_col Organism \
        --sample_grouping_col sample_name \
        --results 20231219_PASC_phipflow_"$(date -I)" \
        -resume

# # bowtie_opt_args= "–tryhard –nomaqround –norc –best –sam –quiet -5 17 -3 25 -n 3 -l 30 -e 1000"
#         # --bowtie_optional_args "--trim5 17" \
# #         --n_mismatches 2 \


# # adaptors lowercase, inserts uppercase -> increased alignment from 15% to 50%
# # trim adaptors --read_length 60 --peptide_tile_length 50  -> avg alignment length is 73nt; trailing 25nt remain; ~50% align
# # trim to 50 readlength and adaptors --read_length 50 --peptide_tile_length 50 -> alignment length 50nt; 50-64% align (inconsistent between phipflow reporting and samtools reporting)

#         --public_epitopes_csv ../code/phip-flow/templates/public_epitope_template.csv \


# #### no trim
# nextflow run matsengrp/phip-flow -r V1.10  \
#         --sample_table ../data-raw/20231219_PASC_samples.DEBUG.csv \
#         --peptide_table ../data-raw/peptide_table/VIR3_clean.csv \
#         --read_length 50 --oligo_tile_length 168 \
#         --peptide_seq_col Prot \
#         --output_wide_csv \
#         --sample_grouping_col sample_name \
#         --results 20231219_PASC_phipflow_debug_"$(date -I)" \
#         -resume

# ### trim
# nextflow run matsengrp/phip-flow -r V1.12  \
#         --sample_table ../data-raw/20231219_PASC_samples.DEBUG.trim \
#         --peptide_table ../data-raw/peptide_table/VIR3_clean.csv \
#         --read_length 50 --oligo_tile_length 50 \
#         --peptide_seq_col Prot \
#         --output_wide_csv \
#         --sample_grouping_col sample_name \
#         --results test_"$(date -I)" \
#         -resume


# #(phipflow) [bek321@compute-e-16-230 220b26f2462bffce469fa0deb0d90e]$ zcat FC_07332_GEN00227896.fastq.gz | bowtie   -5 17 -3 50 -l 30 -e 1000   --threads 2   -n 2   --tryhard --nomaqround --norc --best --sam --quiet   -x peptide_index/peptide - > test.sam
# # reads processed: 24337
# # reads with at least one alignment: 24337 (100.00%)
# # reads that failed to align: 0 (0.00%)


# nextflow run matsengrp/phip-flow -r V1.12  \
#         --sample_table ../data-raw/20231219_PASC_samples.DEBUG.trim \
#         --peptide_table ../data-raw/peptide_table/VIR3_clean.csv \
#         --read_length 50 --oligo_tile_length 50 \
#         --bowtie_optional_args "--trim5 17" \
#         --peptide_seq_col Prot \
#         --output_wide_csv \
#         --sample_grouping_col sample_name \
#         --results 20231219_PASC_phipflow_debug_5trim17_"$(date -I)" \
#         -resume





#         # --run_zscore_fit_predict \
#         # --run_cpm_enr_workflow \
#         # --summarize_by_organism true \
#         # --peptide_org_col Organism \


# nextflow clean -f -k

# #         --run_BEER \
#         # --sample_grouping_col sample_name,experiment_group \