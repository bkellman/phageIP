# ONLY MERGE IF SAMPLES ARE SLIT ACROSS LANES
# merge lanes (example, do not run)
for FC in FC_07336 FC_07266 FC_07272 FC_07332
do
	echo $FC

	# get file location
	baseFC=/n/data2/mgh/ragon/juelg/<user>/BPF_Files/${FC}/Unaligned_1234_PF_mm1/
    # get directory containing fastq files
	filedir=${baseFC}/Data/Project_alterMember
	# get file manifest
	man=${baseFC}${FC}_1234_PF_mm1_alterMember_manifest.csv
	echo $(head -n 2 $man)

	# get unique files from manifest
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