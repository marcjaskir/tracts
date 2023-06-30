#!/bin/bash

# Set data directory
data_dir=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/data

# Run qsiprep recon-all
qsiprep-docker \
    -i pennbbl/qsiprep:0.18.0alpha0 \
    ${data_dir}/qsiprep \
    ${data_dir} \
    participant \
    --recon-spec dsi_studio_autotrack \
    --recon-input ${data_dir}/qsiprep \
    --recon-only \
    --omp-nthreads 1 \
    --nthreads 2 \
    --fs-license-file /Users/mjaskir/ngg/software/freesurfer/license.txt \
    -w /Users/mjaskir/ngg/rotations/satterthwaite/tracts/code/logs
