if(!params.output_dir){
    error('You must specify an output directory. Try again.')
}

params.trimmed_fastq_dir = "trimmed_fastq"
params.merged_fastq_dir = "merged_fastq"


process prep_metadata {
    // This process looks at the metadata CSV
    // and creates an output metadata that is 
    // compatible with the downstream phipflow process
    // (Namely, phipflow expects FASTQ file paths to be
    // relative to the launch directory and this script
    // takes care of that)

    memory "2 GB"
    cpus 1
    time "10m"

    publishDir "${params.output_dir}", mode:"copy"

    input:
        path input_meta

    output:
        path "${output_metadata}"

    script:
        output_metadata = "${params.final_metadata}"
        """
        python3 ${projectDir}/scripts/prep_metadata.py \
            -f ${input_meta} \
            -o ${output_metadata} \
            -d ${params.output_dir}/${params.trimmed_fastq_dir} \
            -p ${projectDir}
        """
}


process merge_fastq {

    memory "4 GB"
    cpus 1
    time "15m"

    publishDir "${params.output_dir}/${params.merged_fastq_dir}", mode: "copy"

    input:
        // Note that `meta` is itself a list of the 
        // sample ID and replicate ID
        tuple val(meta), path(in_fastq)

    output:
        tuple val(meta), path("${out_fastq}")

    script:
        sample_id = meta[0]
        rep_id = meta[1]
        out_fastq = "${sample_id}.${rep_id}.merged.fastq.gz"
        """
        zcat ${in_fastq} | gzip > ${out_fastq}
        """
}


process trim_fastq {

    memory "16 GB"
    cpus 2
    time "30m"


    publishDir "${params.output_dir}/${params.trimmed_fastq_dir}", mode: "copy"

    input:
        tuple val(meta), path(merged_fastq), val(trimmed_fastq)

    output:
        path "${bn}"

    script:
        bn = trimmed_fastq.split('/')[-1]
        """
        trimmomatic SE \
            -threads 2 \
            ${merged_fastq} \
            ${bn} \
            CROP:${params.trimmomatic_crop} \
            HEADCROP:${params.trimmomatic_head_crop} \
            SLIDINGWINDOW:4:20 \
            MINLEN:25 \
            ILLUMINACLIP:${params.trimmomatic_adapter_fasta}:2:30:10

        """
}


workflow  {
    
    // look at and prep the metadata. This will prepare a new
    // metadata CSV which will be used for the downstream processes
    final_metadata = prep_metadata(params.input_metadata)

    // Using the original metadata file, group by the sample + replicate ID. This will
    // ultimately give us the FASTQ files which will be merged
    orig_meta_ch = Channel.fromPath(params.input_metadata)
             .splitCsv(header:true)
             .map{
                row -> tuple([row.sample_ID, row.technical_replicate_ID], file(row.fastq_filepath))
             }
             .groupTuple()

    // actually merge the FASTQ files.
    merge_ch = orig_meta_ch | merge_fastq 

    // Using the final metadata file, we can grab the desired name of the merged + trimmed FASTQ
    final_meta_ch = final_metadata
             .splitCsv(header:true)
             .map{
               row -> tuple([row.sample_ID, row.technical_replicate_ID], row.fastq_filepath)
             }

    // This join lets us bring in the path to the final trimmed FASTQ.
    info_ch = merge_ch.join(final_meta_ch)

    // Finally, trim the merged FASTQ
    info_ch | trim_fastq

}