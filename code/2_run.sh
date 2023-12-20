conda activate phipflow
cd /n/scratch3/users/b/bek321/virscan_hipc/data-final

nextflow run matsengrp/phip-flow -r V1.10  \
        --sample_table ../data-raw/20230919_virscan_demo.samples.debug.csv \
        --peptide_table ../data-raw/VIR3_clean.csv \
        --read_length 100 --peptide_tile_length 200 \
        --run_zscore_fit_predict \
        --run_cpm_enr_workflow \
        --summarize_by_organism true \
        --peptide_org_col Organism \
        --sample_grouping_col sample_name \
        --results 20230919_virscan_demo_phipflow_"$(date -I)" \
        -resume