#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)

########################################
# Read in subject ID
########################################
sub=${1}

########################################
# Check for required files
########################################

# Check if qsirecon tract (.tck) files exist
if ! find "${data_root}/qsirecon/${sub}/ses-V1/dwi" -name "*.tck" -print -quit | grep -q .; then
    echo "No tract (.tck) files for ${sub}"
    exit 1
fi

########################################
# Create output directories
########################################

# Create output directories for voxelized tracts
if [ ! -d ${outputs_root}/${sub}/tracts ]; then
    mkdir -p ${outputs_root}/${sub}/tracts/mgz
    mkdir -p ${outputs_root}/${sub}/tracts/nifti/native_orientation-LPS
    mkdir -p ${outputs_root}/${sub}/tracts/nifti/native_orientation-LAS
fi
outputs_dir_mgz=${outputs_root}/${sub}/tracts/mgz
outputs_dir_nifti_LPS=${outputs_root}/${sub}/tracts/nifti/native_orientation-LPS
outputs_dir_nifti_LAS=${outputs_root}/${sub}/tracts/nifti/native_orientation-LAS

########################################
# Voxelize tracts
########################################

# Iterate over tract (.tck) files
for tract in ${data_root}/qsirecon/${sub}/ses-V1/dwi/*.tck; do

    # Extract file name (without .tck extension)
    tract_fname=$(basename ${tract} | sed 's/.tck//g')
    tract_label=$(echo ${tract_fname} | cut -d'-' -f6 | cut -d'_' -f1)

    # Voxelize tracts
    if [ ! -f ${outputs_dir_mgz}/${tract_fname}.mgz ]; then
        tckmap ${tract} -template ${data_root}/qsiprep/${sub}/ses-V1/dwi/${sub}_ses-V1_space-T1w_dwiref.nii.gz ${outputs_dir_mgz}/${tract_label}.mgz
    fi

    # Convert voxelized tracts to NIFTIs
    mri_convert --in_type mgz \
        --out_type nii \
        ${outputs_dir_mgz}/${tract_label}.mgz \
        ${outputs_dir_nifti_LPS}/${tract_label}_LPS.nii.gz

    # Change orientation of NIFTIs to LAS+ (for compatibility with Connectome Workbench commands)
    mri_convert --in_type nii \
                --out_type nii \
                --out_orientation LAS+ \
                ${outputs_dir_nifti_LPS}/${tract_label}_LPS.nii.gz \
                ${outputs_dir_nifti_LAS}/${tract_label}_LAS.nii.gz

done
