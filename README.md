# phageIP

Welcome to phageIP. This is a wrapper for phipflow, a nextflow pipeline for running virscan/phipseq alignment, quantification, hit-calling (phippery), and sample/group aggregation over organism/sample/species.

![image](https://github.com/user-attachments/assets/68e21e82-816d-4e46-815b-2d1ec9153ea9)


__TOC__
- [phageIP](#phageip)
- [Install](#install)
    + [pre-install steps - specific instructions for O2.hms.harvard.edu](#pre-install-steps---specific-instructions-for-o2hmsharvardedu)
    + [install conda env](#install-conda-env)
    + [install beer](#install-beer)
    + [Test install](#test-install)
- [Run standard virscan](#run-standard-virscan)
    + [Download phageIP repo](#download-phageip-repo)
    + [Transfer fastq from sequencer to O2](#transfer-fastq-from-sequencer-to-o2)
    + [0_Merge_Lanes.sh - Merge Lanes (if needed) and Move samples to data-raw/fastq/](#0-merge-lanessh---merge-lanes--if-needed--and-move-samples-to-data-raw-fastq-)
    + [1_prep_sample_table.r - Prepare sample tables](#1-prep-sample-tabler---prepare-sample-tables)
    + [2_trim.sh - Trim fastq using trimmomatic to improve alignment](#2-trimsh---trim-fastq-using-trimmomatic-to-improve-alignment)
    + [3_run.simple.sh & 3_run.group_compare.sh](#3-runsimplesh---3-rungroup-comparesh)
    + [4_QC_sample.R & 4_QC.all.ipynb](#4-qc-sampler---4-qcallipynb)
- [Inputs](#inputs)
    + [Input formatting notes](#input-formatting-notes)
- [Outputs and analysis](#outputs-and-analysis)
    + [Within the output folder, you fill find:](#within-the-output-folder--you-fill-find-)
    + [For anylizing the data consider](#for-anylizing-the-data-consider)


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
# exit O2 and restart as instructed
exit

# login to o2 again
ssh <username>@o2.hms.harvard.edu
# start a screen (optional but nice, allows you to disconnect without ending job)
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

# Run standard virscan
Once phageIP wrapper is installed, and the install is validated by running the install test, you can proceed to running your data.

### Download phageIP repo
The simplest way to anylize virscan data is to download the phageIP repo everytime you want to run new data

### Transfer fastq from sequencer to O2

Direct from sequencer (in terminal)
```rsync -crvau /share/JuelgLabNextSeq/Data/<path_to_fastq.gz> <user>@transfer.rc.hms.harvard.edu:/n/data2/mgh/ragon/juelg/<user>```

Via Ragon Server
1. Move fastq files from image/<run>/Analysis/<n>/fastq/*.fastq/gz to ragon server 172.21.65.183 via GUI filesystem on the sequencer
2. Log into 172.21.65.183 using generic Ragon user (contact IT for password)
```rsync -crvau sshuser@172.21.65.183:/share/JuelgLabNextSeq/Data/<path_to_fastq.gz> <user>@transfer.rc.hms.harvard.edu:/n/data2/mgh/ragon/juelg/<user>/```

### 0_Merge_Lanes.sh - Merge Lanes (if needed) and Move samples to data-raw/fastq/
If individual samples (same sequencing index, same plate) are split across lanes, they need to be merged into a single sample. See example of lane merging in ```code/0_Merge_Lanes.sh```

Copy merged ```fastq.gz``` to ```data-raw/fastq/``` for easy access during run. 

### 1_prep_sample_table.r - Prepare sample tables 
Sample table must include:
1. fastq_filepath - relative path to sample files (minimum 2 replicates per sample)
2. technical_replicate_id - unique replicate id
3. control_status - sample type: "library" (library well, no pulldown), "beads_only" (pbs well, library pulldown without serum), "empirical" (sample)
4. sample_ID - unique sample identifier, repeated for sample replicates

Sample table may include metadata on samples. Including metadata and study design variables here will carry through to the pipeline output and allow users to perform group comparisons within phipflow using ```sample_grouping_col```

### 2_trim.sh - Trim fastq using trimmomatic to improve alignment
Trimming samples (cutting reads to a fixed length and removing continuous low-quality bases) improves read alignment

First, edit 2_trim.sh file to direct phipflow to your sample table:
```
### parameters
basedir=/n/scratch/users/<u>/<user>/phageIP/
cr=50
hd=25
SAMPLES=../data-raw/<YOUR SAMPLE TABLE>.csv
PEP=../data-raw/peptide_table/VIR3_clean_CMVFixed_n_Betacoronavirus1.csv
adapt=/n/scratch/users/b/bek321/phageIP_PASC/data-raw/peptide_table/VIR3_clean.adapt.fa
```

Next run 2_trim.sh either in interactive mode or as a batch job.

Interactive mode (will allow you to watch and adjust run in real time)
```
screen -S trim
srun --pty -p interactive --mem 40G -t 0-08:00 -c 20 /bin/bash
./2_trim.sh
```

Batch job (see opt_<job_id>.log/.out for output. Check status with squeue -u <user>)
```
sbatch 2_trim.sh
```

### 3_run.simple.sh & 3_run.group_compare.sh
Run phipflow to align, quantify and call hits

First, edit 3_run.simple.sh or 3_run.group_compare.sh file to direct phipflow to your sample table (SAMPLES) and specify taxa (TAXA) and sample group (GROUPS) categories for hit aggregation:

```
### parameters
basedir=/n/scratch/users/<u>/<user>/phageIP/
cr=50
hd=25
SAMPLES=../data-raw/<SAMPLE SHEET>.csv

PEP=../data-raw/peptide_table/VIR3_clean_CMVFixed_n_Betacoronavirus1.csv
adapt=/n/scratch/users/b/bek321/phageIP_PASC/data-raw/peptide_table/VIR3_clean.adapt.fa
PUBLIC=../data-raw/peptide_tables/public_epitopes_Table_S1_bms.cleanup.csv

outdir=virscan_<project>_<date>

declare -a GROUPS=("sample_ID" "<group1>" "<group2>")
declare -a TAXA=("Organism" "Species")
```

Run 3_run.simple.sh to produce hits and sample_ID hit aggregation or run 3_run.group_compare.sh to run aggregation across multiple taxa or groups

Interactive mode (will allow you to watch and adjust run in real time)
```
screen -S trim
srun --pty -p interactive --mem 40G -t 0-08:00 -c 20 /bin/bash
./3_run.simple.sh
```

Batch job (see opt_<job_id>.log/.out for output. Check status with squeue -u <user>)
```
sbatch  3_run.simple.sh
```

### 4_QC_sample.R & 4_QC.all.ipynb

Simple QC (read counts > 1e6 and mapped percent > 85%) can be run in R with 4_QC_sample.R
In depth QC can be run with 4_QC.all.ipynb in an R.4.4 kernal


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

### Input formatting notes

peptide table:
- peptide start and end positions (of the peptide coordinates relative to the whole protein) should be integers and named "pos_start" and "pos_end" respectively
- the peptide amino acid sequence should be under a column named "seq"
- incomplete information in the "seq" "pos_start" or "pos_end" columns can result in premature termination
- the "oligo" column must be formatted with flanking sequences as lowercase and insert as uppercase. Given the whole sequence (in excel): `=upper(LEFT(<x>,16))&=MID(<x>,17,LEN(D204454)-2*16)&lower(right(<x>,16))`

sample table:
- aggregation term cannot include NAs or blank values, instead use "no-value"

# Outputs and analysis

Note unzip .gz files in bash or mac using ```gunzip```, or in Windows using 7zip

### Within the output folder, you fill find: 
- python and R objects containing all hit calls and stats
    + pickle_data/ - all data in ```wide_data/``` formatted for python
    + rds_data/ - all data in  ```wide_data/``` formatted for R
- wide_data/ - all data formatted as cvs
    + Annotation
        - data_peptide_annotation_table.csv - detailed annotation for each peptide (rows are dimension matched to peptides)
        - data_sample_annotation_table.csv - detailed annotation for each sample including meta data and QC (rows are dimension matched to samples)
    + Sequencing Data
        - data_counts.csv - read counts peptides x samples
        - data_cpm.csv - read counts per million (normalization) peptides x samples
    + Analysis - Elledge method
        - data_zscore.csv - enrichment of each peptide measured in z-score divergence from the mockIP/pbs-only
        - data_enrichment.csv - (I think) foldchange compared to background (mockIP/pbs-only) peptides x samples
        - data_size_factors.csv - normalization factors used by edgeR, you can ignore this
    + Analysis - EdgeR method
        - data_edgeR_logfc.csv - edgeR foldchange compared to background (mockIP/pbs-only) peptides x samples
        - data_edgeR_logpval.csv - p-value corresponding to edgeR foldchange compared to background (mockIP/pbs-only) peptides x samples
        - data_edgeR_hits.csv - edgeR called hits peptides x samples
- aggregate_data/ - hits aggregated by species or organism over cancer and 10 random variables you can use to estimate the background
    + ```peptide.ebs.<subject group>_<taxa>.csv.gz ``` - peptides (rows) with peptide specific statistics, used to calculate aggregate statistics
        - peptide - peptide id (defined in ```wide_data/data_peptide_annotation_table.csv```)
        - n_replicates - (integer) replicates aggregated within sample or aggregation group
        - EBS - (continuous, z-score sum) Epitope Binding Score defined in Mina 2019 (10.1126/science.aay6485). Sum of z-score enrichment relative to background mockIP. Aggregate enrichment for an epitope
        - hit -  (boolian-ish, True/False/Discordant) Hit calls using the original z-score comparison of each peptide to the mock IP background. True/False if hits are concordant across replicates, otherwise discordant
        - edgeR_hit - (boolian-ish, True/False/Discordant) Hit calls using the more current edgeR comparison (10.1186/s12864-022-08869-y) of each peptide to the mock IP background. True/False if hits are concordant across replicates, otherwise discordant
        - sample - sample id or aggregation group
        - public - (boolian, True/False) indicates if peptide is a public epitope, i.e., commonly positive in human serum (10.1126/science.aaa0698)
    + ```Organism.summary.<subject group>_<taxa>.csv.gz``` - taxa-level aggregation of peptide.ebs...csv file
        - sample - sample id or aggregation group
        - organism - taxa level e.g. species, organism, genus...
        - n_hits_all - (integer, peptide.ebs$hit==True) number of hits called using the original z-score comparison of each peptide to the mock IP background
        - n_discordant_all - (integer, peptide.ebs$hit==discordant) number of hits called discordant between replicates using z-score
        - n_edgeR_hits_all - (integer, peptide.ebs$edgeR_hit==True) number of hits called using the more current edgeR comparison (10.1186/s12864-022-08869-y) of each peptide to the mock IP background.
        - n_edgeR_discordant_all - (integer, peptide.ebs$edgeR_hit==discordant) number of hits called discordant between replicates using edgeR
        - max_ebs_all - (continuous, z-score sum) max EBS over all peptides within a taxa and sample aggregation group
        - mean_ebs_all - (continuous, z-score sum) mean EBS over all peptides within a taxa and sample aggregation group
        - n_edgeR_hits_hits - (integer, peptide.ebs$hit==True & peptide.ebs$edgeR_hit==True) number of hits called using both z-score and edgeR methods
        - n_edgeR_discordant_hits - (integer, peptide.ebs$hit==discordant & peptide.ebs$edgeR_hit==discordant) number of hits called discordant using both z-score and edgeR methods
        - max_ebs_hits - (continuous, z-score sum) max EBS over only z-score hit peptides within a taxa and sample aggregation group
        - mean_ebs_hits - (continuous, z-score sum) mean EBS over only z-score hit peptides within a taxa and sample aggregation group

### For anylizing the data consider
- reviewing the enriched in <group> in aggregate_data
- use the peptide annotation to filter for HPV related peptides and plot them along an axis representing position within proteins of interest (e.g. https://matsengrp.github.io/phippery/examples.html#example-results-wide-csv)
- aggregate/compare select hit peptides using MEME (https://meme-suite.org/meme/tools/xstreme)
