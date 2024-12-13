# Install

### pre-install steps - specific instructions for O2.hms.harvard.edu
```
# login to o2
ssh <username>@o2.hms.harvard.edu
# load conda and git
module load git
module load miniconda3
# initialize conda
conda init
# exit and restart as instructed
exit

# login to o2 again
ssh <username>@o2.hms.harvard.edu
# start a screen (optional but nice)
screen -S install
# inside screen start interactive job (5hr, 20G, 2 cores)
srun --pty -p interactive --mem 20G -t 0-05:00 -c 2 /bin/bash
# load conda and git
module load git
# clone github into home directory
cd ~
git clone https://github.com/bkellman/phageIP.git
```

### install conda env
```
cd ~/phageIP/code
conda env create -f environment.yml
```

### install beer 
For Bayesian MCMC modeling, beer relies on [rjags]([url](https://cran.r-project.org/web/packages/rjags/index.html)) to interface Just Another Gibbs Sampler ([JAGS]([url](https://mcmc-jags.sourceforge.io/))).
beer install is manditory, JAGS is not manditory
```
# in R
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("beer")
```

### Test install
```
# start a screen (optional but nice)
screen -S demo
# navigate to code repo and run nextflow demo 
cd ~/phageIP/code
conda activate phipflow
nextflow run matsengrp/phip-flow -r V1.12 \
    --peptide_table ../data-raw/phipflow_demo_pan-cov-example/peptide_table.csv \
    --sample_table ../data-raw/phipflow_demo_pan-cov-example/sample_table_with_beads_and_lib.csv
```

# New run Setup

peptide table:
- peptide start and end positions (of the peptide coordinates relative to the whole protein) should be integers and named "pos_start" and "pos_end" respectively
- the peptide amino acid sequence should be under a column named "seq"
- incomplete information in the "seq" "pos_start" or "pos_end" columns can result in premature termination
- the "oligo" column must be formatted with flanking sequences as lowercase and insert as uppercase. Given the whole sequence (in excel): `=upper(LEFT(<x>,16))&=MID(<x>,17,LEN(D204454)-2*16)&lower(right(<x>,16))`
sample table
- aggregation term cannot include NAs or blank values, instead use "no-value"

# Inputs

Information about origin and properties of peptide:
![image](https://github.com/user-attachments/assets/41384320-ebed-4b21-ae9e-3573f1a35d94)
- Organism/species: virus of origin
- Sequence: amino acid sequence of protein from which peptide is derived 
- Gene ontology: important properties
Nucleotide sequence information:
![image](https://github.com/user-attachments/assets/8ada65d2-2ce0-40ba-a7c9-08ad59e62ebe)
- id: peptide ID within library
- divisions of nucleotide sequence: old_oligo, left, right, insert, oligo
- start & end: first and last amino acid position of the peptide within the protein
- peptide: AA sequence of peptide within protein sequence
