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

current
FC_ID,Run Folder, Lane, Library Pool ID, Library Pool Name, Library Id, Library Name, Index, Index Name
FC_07336,220405_NB501673_0868_AHLJF7BGXL,1,LIB054808,JnM_PASC_Vir1,GEN00228285,JnM_Vir1_A1,CCATGAG,IDX097
FC_07336,220405_NB501673_0868_AHLJF7BGXL,1,LIB054808,JnM_PASC_Vir1,GEN00228286,JnM_Vir1_A2,CCGAAGC,IDX098
FC_07336,220405_NB501673_0868_AHLJF7BGXL,1,LIB054808,JnM_PASC_Vir1,GEN00228287,JnM_Vir1_A3,CCGATTG,IDX099
FC_07336,220405_NB501673_0868_AHLJF7BGXL,1,LIB054808,JnM_PASC_Vir1,GEN00228288,JnM_Vir1_A4,CCGCCAT,IDX100
FC_07336,220405_NB501673_0868_AHLJF7BGXL,1,LIB054808,JnM_PASC_Vir1,GEN00228289,JnM_Vir1_A5,CCGGATA,IDX101
FC_07336,220405_NB501673_0868_AHLJF7BGXL,1,LIB054808,JnM_PASC_Vir1,GEN00228290,JnM_Vir1_A6,CCGGTAC,IDX102

"

library(dplyr)

# /n/data2/mgh/ragon/alter/NGS_Phage/JonH/BPF_Files/FC_07336/Unaligned_1234_PF_mm1/
platesL=list(
  Vir1='data-raw/filename2sample/FC_07336_1234_PF_mm1_alterMember_manifest.csv',
  Vir2='data-raw/filename2sample/FC_07266_1234_PF_mm1_alterMember_manifest.csv',
  Vir3='data-raw/filename2sample/FC_07272_1234_PF_mm1_alterMember_manifest.csv',
  Vir4='data-raw/filename2sample/FC_07332_1234_PF_mm1_alterMember_manifest.csv'
)


# read larman indexes
idx = read.csv('data-raw/96_Well_Plate_Barcode_Primers.csv') %>%
  rename(Index.Name=Name,Index=X)
head(idx)

# read platemap
plates = openxlsx::read.xlsx('data-raw/platemap_VirScan_PhipSeq_PASC_Master_Table.xlsx',sheet = 5) %>%
  reshape2::melt(id.vars=c('row','plate')) %>%
  mutate(Well.Position = paste0(row,gsub('c','',variable)))
head(plates)

### merge idx and platemap
samples = merge( plates[,c('Well.Position','value','plate')],idx[,c('Well.Position','Index.Name','Index')]) %>%
  mutate(
    replicate = gsub('.*[-|_]D-','',value),
    experiment = gsub('\\*.*','',value),
    sample_ID = gsub('[-|_]D-.*','', gsub('.*\\*','',value))
  )

samples$value=gsub(' |\\/','-',gsub('\\*','.',samples$value))

head(samples)

# load filemap
filemap=do.call(rbind,lapply(platesL,read.csv)) %>% 
  mutate(
    experiment=unlist(lapply(strsplit(Library.Pool.Name,'_'),function(x) x[2])),
    Well.Position=unlist(lapply(strsplit(Library.Name,'_'),function(x) x[3])),#  strsplit(Library.Name,'_')[[1]][3],
    plate=unlist(lapply(strsplit(Library.Pool.Name,'_'),function(x) x[3]))
  ) 
table(table( filemap$Well.Position ))

dim(filemap)
filemap = filemap[,-3] %>% unique()
dim(filemap)

samples2 = merge(samples %>% mutate(Index = trimws(toupper(Index))),
                 filemap %>% mutate(Index_rc = trimws(toupper(Index))) %>% select(-Index),
                 by=c('plate','Index.Name'),suffixes = c('_s','_f')) 
dim(samples2)

# load metadata
#meta = openxlsx::read.xlsx('data-raw/neuropasc_metadata/MASTER METADATA RheumCARD - PASC_And_AutoImmune Controls .xlsx')


df2=data.frame(
  replicate_id = samples2$Library.Id, # unique replicate id
  control_status= ifelse(samples2$sample_ID=='PBS','beads_only',  
                    ifelse(grepl('Library',samples2$sample_ID),'library','empirical')), 
  sample_ID = samples2$value,  # unique id
  sample_name = gsub('[-|_]D-[1-9]','',samples2$value) ,
  experiment_group = samples2$experiment_s,
  fastq_filepath= paste0('../data-raw/fastq/',samples2$FC_ID,'_',samples2$Library.Id,'.fastq.gz')
)

write.csv(df2,quote=F,row.names=F,file='data-raw/20231219_PASC_samples.csv')

