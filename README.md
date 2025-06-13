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

### Pre-install steps - specific instructions for O2.hms.harvard.edu

This section will guide you through the creation of a Conda environment and installation of Nextflow. The Conda environment is used to isolate the required software installations from other potential software you might have associated with your account. Nextflow is used to orchestrate running the pipeline.

- SSH onto O2
- Start an interactive session: `srun --pty -p interactive --mem 16G -t 0-02:00 -c 2 /bin/bash`
- Import a couple modules: `module load miniconda3 java/jdk-21.0.2`
    - `miniconda3` is required for building the Conda environment
    - `java/jdk-21.0.2` is required for Nextflow
- Clone this repository: `git clone <REPO URL>`

**Create the conda environment**
- `cd phageIP/conda`
- `mamba env create -f env.yml` (this will take a while...)

Note that for all intents and purposes `mamba` and `conda` are interchangeable. However, `mamba` will often be *much* faster for locating the required packages and performing installations. After the process is complete, there will be a prompt to "activate" the environment. *You do not need to activate at this time.*


**Install nextflow**

You can perform these next steps anywhere, so it doesn't matter where you are located on the filesystem. However, it might be a good idea to just create a temporary directory in your home folder. When you're done, you can delete that temporary folder so you don't have unnecessary clutter.

- Download and install: `curl -s https://get.nextflow.io | bash`

Make Nextflow executable and move to local path

- `chmod +x nextflow`
- `mv nextflow $HOME/.local/bin/`

Now, `nextflow` will be available each time you log-on to O2 since it is located on your `PATH`.

**Configure nextflow**

Nextflow is a versatile pipeline tool capable of running jobs on local machines, HPCs (like O2), and even cloud environments such as AWS. To run on these different systems (without changing the nf scripts themselves), we simply have to provide nextflow with an appropriate configuration file. 

In the repository, we have a file named `code/nextflow/phage_ip.config.template` which is a "templated" (read: *incomplete*) configuration file. We will copy that and apply edits to make it complete.   

When running our jobs, we want to tell Nextflow to use the Conda environment we configured earlier. To do this, we need to specify the path to where the environment is saved. To find this out, simply run:

```
conda env list
```
which will print all the conda environments available. It will look something like:
```
# conda environments:
#
...                         ...
phageip-env                 /home/some-user/.conda/envs/phageip-env
...                         ...
```
Among those, you should see `phageip-env` (or another name if you happened to modify the `name` in `conda/env.yml` above). Note that `some-user` will be your user ID on O2. Copy that path on the right side and substitute into your config file, e.g.
```
...
    conda = '/home/some-user/.conda/envs/phageip-env'
...
```

**Other required configuration options**

Under the `params` section of the configuration file you will see some default parameters (e.g. for setting trim parameters on trimmomatic). We require the following to be added:

- `trimmomatic_adapter_fastq`: This is the path to a file that has the adapter sequences required by trimmomatic.

The other parameters (e.g. for trimming) can be adjusted as you wish.

**Configuring portions of the phipflow process**

Note that if you require changes to parameters in the downstream phipflow process, you can add them to this config file as an override.


# Run standard virscan
Once phageIP wrapper is installed, and the install is validated by running the install test, you can proceed to running your data.


### Transfer fastq from sequencer to O2

Direct from sequencer (in terminal)
```rsync -crvau /share/JuelgLabNextSeq/Data/<path_to_fastq.gz> <user>@transfer.rc.hms.harvard.edu:/n/data2/mgh/ragon/juelg/<user>```

Via Ragon Server
1. Move fastq files from `image/<run>/Analysis/<n>/fastq/*.fastq/gz` to ragon server `172.21.65.183` via GUI filesystem on the sequencer
2. Log into `172.21.65.183` using generic Ragon user (contact IT for password)
```rsync -crvau sshuser@172.21.65.183:/share/JuelgLabNextSeq/Data/<path_to_fastq.gz> <user>@transfer.rc.hms.harvard.edu:/n/data2/mgh/ragon/juelg/<user>/```

### Preparing your metadata file
 
To run the process, we need a properly formatted metadata file in CSV (comma-separated) format. This tells the process where to find FASTQ files, their sample identities, and potentially other metadata.

Your metadata/sample table must include (note the column names are case-sensitive! e.g. the `ID` at the end):
1. `fastq_filepath` - **absolute** path to sample files (minimum 2 replicates per sample). This is the full path to the files and makes no assumption about where they are located relative to your application code.
2. `technical_replicate_ID` - unique replicate id
3. `control_status` - sample type: "library" (library well, no pulldown), "beads_only" (pbs well, library pulldown without serum), "empirical" (sample)
4. `sample_ID` - unique sample identifier, repeated for sample replicates

The sample table may include additional metadata on samples. Including metadata and study design variables here will carry through to the pipeline output and allow users to perform group comparisons within phipflow using `sample_grouping_col`

**About lane merging:**
If individual samples (same sequencing index, same plate) are split across lanes, they will be merged into a single FASTQ file. This merging is accomplished by grouping on the `sample_ID` and `technical_replicate_ID` variables. If there are >1 FASTQ files associated with each unique combination of `sample_ID` and `technical_replicate_ID` they will be concatenated together.

**Running the process**

To run everything, we use the `submit.sh` script, which will be submitted via `sbatch`. We require the following arguments (in order!). Always use *absolute* paths so there will be no ambiguity about which files you are using.

1. Absolute path to the input metadata file you just prepared
2. Absolute path to the output directory
3. Absolute path to the peptide table
4. (Optional) Path to the Nextflow config you edited earlier. If this is not specified, it will attempt to use `nextflow/phage_ip.config` (assuming it exists). However, it's always a good idea to be explicit and supply the absolute path to this config file.

As an example:
```
cd <PATH TO THE CLONED PHAGEIP REPOSITORY>/code
sbatch submit.sh \
    <METADATA FILE> \
    <OUTPUT DIRECTORY> \
    <PEPTIDE FILE> \
    <NEXTFLOW CONFIG FILE>
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

### Within the output folder, you will find: 
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

### For analyzing the data consider
- reviewing the enriched in <group> in aggregate_data
- use the peptide annotation to filter for HPV related peptides and plot them along an axis representing position within proteins of interest (e.g. https://matsengrp.github.io/phippery/examples.html#example-results-wide-csv)
- aggregate/compare select hit peptides using MEME (https://meme-suite.org/meme/tools/xstreme)
