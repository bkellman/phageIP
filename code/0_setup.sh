# get files
# rsync -crvau /share/JuelgLabNextSeq/Data/ bek321@transfer.rc.hms.harvard.edu:/n/data2/mgh/ragon/alter/NGS_Phage/BenK/
# rsync -crvau sshuser@172.21.65.183:/share/JuelgLabNextSeq/Data/ /n/data2/mgh/ragon/alter/NGS_Phage/BenK/

# run HMO-O2 interactive job
# srun --pty -p interactive --mem 10G -t 0-10:00 -c 2 /bin/bash

# set working directory
cd /n/scratch/users/b/bek321/phageIP/code

# install conda env
conda env create -f environment.yml

# link file to data
#fastqLoc=NGS_Phage/BenK/20231004_virscan_demo/
#ln -s /n/data2/mgh/ragon/alter/$fastqLoc ../data-raw/fastq

cd /n/scratch/users/b/bek321/phageIP/data-final


# merge lanes (example, do not run)
for FC in FC_07336 FC_07266 FC_07272 FC_07332
do
	echo $FC

	# get file location
	baseFC=/n/data2/mgh/ragon/alter/NGS_Phage/JonH/BPF_Files/${FC}/Unaligned_1234_PF_mm1/
	filedir=${baseFC}/Data/Project_alterMember
	# get file manifest
	man=${baseFC}${FC}_1234_PF_mm1_alterMember_manifest.csv
	echo $(head -n 2 $man)

	# get unique files
	filesFC=$(tail $man -n +2 | awk -F "," '{print $6}' | sort | uniq) # get sample IDs w/o first line

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