#!/bin/bash
#SBATCH -c 20                               # Request one core
#SBATCH -t 03-00:05                         # Runtime in D-HH:MM format
#SBATCH -p medium                           # Partition to run in
#SBATCH --mem=40G                         # Memory total in MiB (for all cores)
#SBATCH -o opt_%j.out                 # File to which STDOUT will be written, including job ID (%j)
#SBATCH -e opt_%j.err                 # File to which STDERR will be written, including job ID (%j)
                                           # You can change the filenames given with -o and -e to any filenames you'd like

#srun --pty -p interactive --mem 40G -t 0-08:00 -c 20 /bin/bash

# squeue -u bek321

### parameters
basedir=/n/scratch/users/<u>/<user>/phageIP/
cr=50
hd=25
SAMPLES=../data-raw/phipflow_demo_pan-cov-example/sample_table_with_beads_and_lib.DEMO.csv
PEP=../data-raw/peptide_table/VIR3_clean_CMVFixed_n_Betacoronavirus1.csv
adapt=/n/scratch/users/b/bek321/phageIP_PASC/data-raw/peptide_table/VIR3_clean.adapt.fa

source /home/${USER}/.bashrc
source activate phipflow2 
#conda activate phipflow2 (if running interactive)

############################

wait
cd ${basedir}data-raw/fastq/

COUNTER=1

for infile in *.fastq.gz
do
        base=$(basename ${infile} .fastq.gz)
        trimmomatic SE -threads 2 ${infile} ${base}.trim.fastq.gz CROP:${cr} HEADCROP:${hd} SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:${adapt}:2:30:10 &

        COUNTER=$[$COUNTER +1]
       if (( $COUNTER % 10 == 0 ))           # no need for brackets
        then
            wait
        fi
done

