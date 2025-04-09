library(ggplot2)
library(dplyr)

#output from latest virscan run with mariana's data and after trimming
r=data.table::fread('<outdir>/wide_data/data_sample_annotation_table.csv.gz')

#change column if the dataframe has a column named "variable"
r <- r %>% rename(variable1 = variable)

##QC
reshape2::melt(r,id.vars=colnames(r)[1:30]) %>% 
    #filter( grepl('percent',variable)) %>%
  ggplot(aes(x=sample_ID,y=value))+ #geom_hline(yintercept = 85)+
    geom_point()+geom_line(aes(group=sample_ID))+
    facet_grid(variable~.,scales = 'free')+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

stats=r%>%group_by(sample_ID)%>%
  summarise(
    read_pass = sum(reads_mapped>1e6)>=2,
    align_pass = sum(percent_mapped>85)>=2,
    sample_pass = sum( reads_mapped>1e6 & percent_mapped>85)>=2
  ) 
table(stats$read_pass) # number of samples passing read count
table(stats$align_pass) # number of samples passing alignemet
table(stats$sample_pass) # number of samples where both replicates pass both tests

#save a better plot with (mostly) legible variables
ggsave("<date>_<project>_virscan_QC_metrics.pdf",width=10,height=10)

