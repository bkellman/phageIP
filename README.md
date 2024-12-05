# Install

### pre-install steps

### install conda env
```
$conda env create -f environment.yml
$conda activate phip-flow
```

### install beer (optional)
For Bayesian MCMC modeling, beer relies on [rjags]([url](https://cran.r-project.org/web/packages/rjags/index.html)) to interface Just Another Gibbs Sampler ([JAGS]([url](https://mcmc-jags.sourceforge.io/))).
```
# in R
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("beer")
```

# Setup

peptide table:
- peptide start and end positions (of the peptide coordinates relative to the whole protein) should be integers and named "pos_start" and "pos_end" respectively
- the peptide amino acid sequence should be under a column named "seq"
- incomplete information in the "seq" "pos_start" or "pos_end" columns can result in premature termination
- the "oligo" column must be formatted with flanking sequences as lowercase and insert as uppercase. Given the whole sequence (in excel): `=upper(LEFT(<x>,16))&=MID(<x>,17,LEN(D204454)-2*16)&lower(right(<x>,16))`
sample table
- aggregation term cannot include NAs or blank values, instead use "no-value"
