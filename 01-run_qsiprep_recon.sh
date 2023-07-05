#!/bin/bash

########################################
# Set directories
########################################
data_root=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/data
fs_license=/Users/mjaskir/ngg/software/freesurfer/license.txt
work_dir=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/code/logs

########################################
# Run qsiprep recon-all
########################################
qsiprep-docker \
    -i pennbbl/qsiprep:0.18.0alpha0 \
    ${data_root}/qsiprep \
    ${data_root} \
    participant \
    --recon-spec dsi_studio_autotrack \
    --recon-input ${data_root}/qsiprep \
    --recon-only \
    --omp-nthreads 1 \
    --nthreads 2 \
    --fs-license-file ${fs_license} \
    -w ${work_dir}
