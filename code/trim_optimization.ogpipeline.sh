module load gcc/6.2.0
module load bowtie/1.2.2
module load samtools/1.3.1

# build index
bowtie-build vir3.fasta vir3

# cp unzip files
for i in raw.data/*.gz; do gzip -d $i; done

# align
for fq in raw.data/*.gz; do
    bowtie -3 25 -n 3 -l 30 -e 1000 --tryhard --nomaqround --norc --best --sam --quiet vir3/vir3 $fq | samtools view -u - | samtools sort -T ${fq%.fastq}.2.temp.bam -o ${fq%.fastq}.bam    
done

# index
for i in raw.data/*.bam; do samtools index $i; done 

# count
for i in raw.data/*.bam; do samtools idxstats $i | cut -f 1,3 | sed -e '/^\*\t/d' -e '1 i id\tSAMPLE_ID' | tr "\\t" "," >${i%.bam}.count.csv; done