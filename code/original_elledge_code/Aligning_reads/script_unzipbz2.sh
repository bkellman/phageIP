#!/bin/bash

for file in raw.data/*fastq.bz2; do
 
    #put the file into batch
    batch="$batch $file"
    counter=$[counter +1]
 
    # when counter is multiple of 48, such as 48, 96, and so on, submit the batch of files as a new job
    if (( $counter % 48 == 0 )); then
        echo submitting: $counter files: $batch
        sbatch -p short -t 0-0:30:0 --mem=1G --wrap "for bz2 in $batch; do bzip2 -d \${bz2}; done" 
         
        # get ready for the next batch
        batch=""
     fi
done

