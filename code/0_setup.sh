# set working directory
cd /n/scratch/users/b/bek321/phageIP_PASC/code

# install
conda create -n phipflow -c conda-forge -c bioconda python scipy click numpy pandas scipy xarray statsmodels POT biopython nextflow bioconductor-edger
conda activate phipflow
conda install -c bioconda samtools=1.3.1
pip install git+https://github.com/matsengrp/phippery@1.2.0
conda install -c conda-forge jags
# in R
install.packages('rjags')
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("beer")

curl -fksSL https://sourceforge.net/projects/bowtie-bio/files/bowtie/1.3.1/bowtie-1.3.1-linux-x86_64.zip \
    --output bowtie-1.3.1-linux-x86_64.zip \
    && unzip bowtie-1.3.1-linux-x86_64.zip \
    && (cd ~/lib/bin/ && ln -s ~/lib/bowtie-1.3.1-linux-x86_64/* ./)

curl -fksSL https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 | tar xj && \
    cd samtools-1.3.1 && \
    make all all-htslib && make install install-htslib

conda activate phipflow


# link file to data
fastqLoc=NGS_Phage/BenK/20231004_virscan_demo/
ln -s /n/data2/mgh/ragon/alter/$fastqLoc ../data-raw/fastq

# run O2 interactive job
# srun --pty -p interactive --mem 30G -t 0-10:00 -c 2 /bin/bash

# merge lanes
#for FC in FC_07336 FC_07266 FC_07272 FC_07332
for FC in FC_07266 FC_07336
#for FC in FC_07272 FC_07332
do
echo $FC
baseFC=/n/data2/mgh/ragon/alter/NGS_Phage/JonH/BPF_Files/${FC}/Unaligned_1234_PF_mm1/
filedir=${baseFC}/Data/Project_alterMember
man=${baseFC}${FC}_1234_PF_mm1_alterMember_manifest.csv
echo $(head -n 2 $man)

# get unique files
filesFC=$(tail $man -n +2 | awk -F "," '{print $6}' | sort | uniq) # get sample IDs w/o first line

#	tail $man -n +2 | awk -F "," '{print $6}' | sort | uniq | xargs -P 2 -I {x} \
#		find $filedir/ -name "*${x}*" -type f -exec zcat {} \; | gzip > ${FC}_${x}.fastq.gz

for x in ${filesFC} ; 
do 
	echo $x
	echo $(ls -lhat $filedir/*${x}* | awk '{print $5}') # get input file size
	find $filedir/ -name "*${x}*" -type f -exec zcat {} \; | gzip > ../data-raw/fastq/${FC}_${x}.fastq.gz # merge
	echo $(ls -lhat ../data-raw/fastq/${FC}_${x}.fastq.gz) # get output file size
	echo "next sample"
done
echo "next FC"
done