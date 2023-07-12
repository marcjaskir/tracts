#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)

# Iterate over subjects with qsirecon outputs
for sub_dir in ${data_root}/qsirecon/sub-*; do

    # Extract subject ID
    sub=$(basename ${sub_dir})

    if [ ${sub} != 'sub-0857566' ]; then
        continue
    fi

    ########################################
    # Check for required files
    ########################################

    # Check if qsirecon tract (.tck) files exist
    if ! find "${data_root}/qsirecon/${sub}/ses-V1/dwi" -name "*.tck" -print -quit | grep -q .; then
        echo "No tract (.tck) files for ${sub}"
        continue
    fi

    ########################################
    # Voxelize tracts
    ########################################

    # Create output directory for tracts
    if [ ! -d ${outputs_root}/${sub}/tracts/freesurfer ]; then
        mkdir -p ${outputs_root}/${sub}/tracts/freesurfer
    fi
    outputs_dir_fs=${outputs_root}/${sub}/tracts/freesurfer

    # Iterate over tract (.tck) files
    for tract in ${data_root}/qsirecon/${sub}/ses-V1/dwi/*.tck; do

        # Extract file name (without .tck extension)
        tract_fname=$(basename ${tract} | sed 's/.tck//g')

        # Voxelize tracts
        if [ ! -f ${outputs_dir_fs}/${tract_fname}.mgz ]; then
            tckmap ${tract} -template ${data_root}/qsiprep/${sub}/ses-V1/dwi/${sub}_ses-V1_space-T1w_dwiref.nii.gz ${outputs_dir_fs}/${tract_fname}.mgz 
        fi

    done
    
    ########################################
    # Convert voxelized tracts to NIFTIs and change orientation to LAS+ (for compatibility with Connectome Workbench)
    ########################################

    # Create directory for NIFTI tracts
    if [ ! -d ${outputs_root}/${sub}/tracts/nifti ]; then
        mkdir -p ${outputs_root}/${sub}/tracts/nifti
    fi
    outputs_dir_nifti=${outputs_root}/${sub}/tracts/nifti

    # Iterate over voxelized tracts
    for tract_file in ${outputs_root}/${sub}/tracts/freesurfer/*.mgz; do

        # Extract tract filename and label
        tract_fname=$(basename ${tract_file})
        tract_label=$(echo ${tract_fname} | cut -d'-' -f6 | cut -d'_' -f1)

        # Convert tract files to NIFTIs
        mri_convert --in_type mgz \
            --out_type nii \
            ${tract_file} \
            ${outputs_dir_nifti}/${tract_label}_LPS.nii.gz

        # Change orientation to LAS+
        mri_convert --in_type nii \
                    --out_type nii \
                    --out_orientation LAS+ \
                    ${outputs_dir_nifti}/${tract_label}_LPS.nii.gz \
                    ${outputs_dir_nifti}/${tract_label}_LAS.nii.gz

    done

done
