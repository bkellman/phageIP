# install conda env
conda env create -f environment.yml

# link file to data
fastqLoc=NGS_Phage/BenK/20231004_virscan_demo/
ln -s /n/data2/mgh/ragon/alter/$fastqLoc ../data-raw/fastq

