#!/bin/bash
#SBATCH -c 20                               # Request one core
#SBATCH -t 3-00:05                         # Runtime in D-HH:MM format
#SBATCH -p medium                           # Partition to run in
#SBATCH --mem=100G                         # Memory total in MiB (for all cores)
#SBATCH -o hostname_opt_%j.out                 # File to which STDOUT will be written, including job ID (%j)
#SBATCH -e hostname_opt_%j.err                 # File to which STDERR will be written, including job ID (%j)
                                           # You can change the filenames given with -o and -e to any filenames you'd like

# You can change hostname to any command you would like to run

source /home/${USER}/.bashrc
source activate phipflow2 

#conda activate phipflow2

for cr in 50 75
do
        for hd in 25 20 17 15 10 5 0 30 40
        do
                cd /n/scratch/users/b/bek321/phageIP/data-raw/fastq/

                for infile in FC_07336_GEN00228373.fastq.gz FC_07336_GEN00228374.fastq.gz FC_07266_GEN00227705.fastq.gz FC_07266_GEN00227706.fastq.gz FC_07266_GEN00227707.fastq.gz FC_07272_GEN00227735.fastq.gz FC_07332_GEN00227897.fastq.gz FC_07332_GEN00227898.fastq.gz
                do
                        base=$(basename ${infile} .fastq.gz)
                        trimmomatic SE -threads 2 ${infile} ${base}_1.trim.fastq.gz CROP:${cr} HEADCROP:${hd} SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:/n/scratch/users/b/bek321/phageIP/data-raw/peptide_table/VIR3_clean.adapt.fa:2:30:10 &
                done

                wait
                wait

                cd /n/scratch/users/b/bek321/phageIP/data-final

                for n in 2 3
                do
                        for readlen in 0 50
                        do
                                for olen in 50 168
                                do
                                        nextflow run matsengrp/phip-flow -r V1.12  \
                                                --sample_table ../data-raw/20231219_PASC_samples.DEBUG.trim \
                                                --peptide_table ../data-raw/peptide_table/VIR3_clean.csv \
                                                --read_length $readlen --oligo_tile_length $olen \
                                                --n_mismatches $n \
                                                --peptide_seq_col Prot \
                                                --output_wide_csv \
                                                --sample_grouping_col sample_name \
                                                --results 20231219_PASC_phipflow_SEARCH2_debug_trim${cr}.${hd}_n${n}_rd${readlen}_pep${olen} \
                                                -resume
                                done
                        done
                        
                done
        done
done
