import argparse
import os
from pathlib import Path
import sys

import pandas as pd

# the output FASTQ pattern after merging by lane:
MERGED_TRIM_FASTQ_PATTERN = '{sample_id}.replicate_{n}.lane_merged.trim.fastq.gz'
TRIM_ONLY_FASTQ_PATTERN = '{sample_id}.replicate_{n}.trim.fastq.gz'

REQUIRED_COLS = [
    'sample_ID',
    'technical_replicate_ID',
    'fastq_filepath',
    'control_status'
]


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--input_metadata', 
                        required=True, type=Path)
    parser.add_argument('-o', '--output_metadata', 
                        required=True, type=Path)
    parser.add_argument('-d', '--output_dir', 
                        required=True, type=Path)
    parser.add_argument('-p', '--project_dir',
                        required=True, type=Path)
    return parser.parse_args()


def main():
    args = parse_args()

    # this is where the nextflow script (which calls this script)
    # is launched from. We need this due to a quirk of phip-flow
    # and relative paths. See notes below.
    project_dir = args.project_dir
    
    metadata = pd.read_csv(args.input_metadata)

    # ensure we have the minimal requirements met for columns.
    # If not, exit immediately.
    if len(set(REQUIRED_COLS).difference(metadata.columns)) > 0:
        sys.stderr.write('Note that we require the following columns:')
        sys.stderr.write(f'{"\n".join(REQUIRED_COLS)}')
        sys.exit(1)

    # get the other metadata column names which we will collapse
    # at the sample level.
    remaining_columns = [x for x in metadata.columns if not x in REQUIRED_COLS]

    updated_metadata = pd.DataFrame()
    for (sample_id, replicate), subdf in metadata.groupby(['sample_ID','technical_replicate_ID']):
        df = subdf.copy()
        if df.shape[0] > 1:
            fastq = MERGED_TRIM_FASTQ_PATTERN.format(sample_id=sample_id, n=replicate)
        else:
            fastq = TRIM_ONLY_FASTQ_PATTERN.format(sample_id=sample_id, n=replicate)

        df['sample_ID'] = sample_id
        df['technical_replicate_ID'] = replicate

        # Note that phip-flow has a parameter called `params.read_prefix` which
        # is set to the `launchDir` if the metadata file is not their default/testing
        # file. In Nextflow, that `launchDir`` is the directory where you start your
        # nextflow run from. Phip-flow assumes that the paths in your metadata
        # file are RELATIVE to that `launchDir` and ultimately prepends that path to the
        # `fastq_filepath` entries. To get around that, we construct relative paths
        
        # This is where the fastq will live:
        relpath = os.path.relpath(f'{args.output_dir}/{fastq}', project_dir)
        df['fastq_filepath'] = relpath
        updated_metadata = pd.concat([updated_metadata, df.drop_duplicates()])

    updated_metadata.to_csv(args.output_metadata, index=False)


if __name__ == '__main__':
    main()
