" example
replicate_id,control_status,sample_ID,sample_name,fastq_filepath
097,library,S1,c1,../data-raw/fastq//IDX097-c1-1_S1_R1_001.fastq.gz
098,beads_only,S2,c2,../data-raw/fastq//IDX098-c2-1_S2_R1_001.fastq.gz
100,beads_only,S4,c4,../data-raw/fastq//IDX100-c4-1_S4_R1_001.fastq.gz
101,beads_only,S5,c5,../data-raw/fastq//IDX101-c5-1_S5_R1_001.fastq.gz
102,beads_only,S6,c6,../data-raw/fastq//IDX102-c6-1_S6_R1_001.fastq.gz
103,empirical,S7,v1,../data-raw/fastq//IDX103-v1-1_S7_R1_001.fastq.gz
104,empirical,S8,v2,../data-raw/fastq//IDX104-v2-1_S8_R1_001.fastq.gz
105,library,S9,c1,../data-raw/fastq//IDX105-c1-2_S9_R1_001.fastq.gz
107,beads_only,S11,c3,../data-raw/fastq//IDX107-c3-2_S11_R1_001.fastq.gz
108,beads_only,S12,c4,../data-raw/fastq//IDX108-c4-2_S12_R1_001.fastq.gz

"


### toy examples: https://github.com/matsengrp/phip-flow/tree/main/data/pan-cov-example


################
### minimum definition for sample table: 
# technical_replicate_id  (unique; 1 per measurement)
# control_status          ("library" [library control], "beads_only" [PBS control], or "emperical" [samples])
# sample_ID               (non-unique; duplicated for each replicate of a sample)
# fastq_filepath          (relative or absolute path to the fastq files)
# optional: other annotations can be used if desired

# read files
f=list.files('data-raw/phipflow_demo_pan-cov-example/NGS')

# technical_replicate_id  (unique; 1 per measurement)
technical_replicate_id = c(273, 572, 247, 725,  90, 382, 269,242)

# control_status          ("library" [library control], "beads_only" [PBS control], or "emperical" [samples])
control_status = c('library','beads_only','library','beads_only','empirical','empirical','empirical','empirical')

# sample_ID               (non-unique; duplicated for each replicate of a sample)
sample_ID = c('NA','NA','NA','NA','80','80','45','45')

# fastq_filepath          (relative or absolute path to the fastq files)
fastq_filepath = paste0('../data-raw/phipflow_demo_pan-cov-example/NGS/',gsub('.fastq.gz','.trim.fastq.gz',f))

# save
sample_table = data.frame(technical_replicate_id,control_status,sample_ID,fastq_filepath)
write.csv(sample_table,'data-raw/phipflow_demo_pan-cov-example/sample_table_with_beads_and_lib.DEMO.csv')


#####
## final table should resemble:
ex = read.csv('data-raw/phipflow_demo_pan-cov-example/sample_table_with_beads_and_lib.csv')
head(ex)
