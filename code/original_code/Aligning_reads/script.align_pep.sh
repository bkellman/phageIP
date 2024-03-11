#!/bin/bash

#SBATCH -p short
#SBATCH -t 01:00:00
#SBATCH --mem=4G

for fq in $1; do

    bowtie -3 35 -n 3 -l 30 -e 1000 --tryhard --nomaqround --norc --best --sam --quiet /home/jdh19/PhageWork/pep2_ref50 $fq | samtools view -u - | samtools sort -T ${fq%.fastq}.2.temp.bam -o ${fq%.fastq}.bam   
 
done

