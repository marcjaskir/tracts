#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)
SUBJECTS_DIR=${data_root}/freesurfer

# Iterate over subjects with voxellized tracts
for sub_dir in ${outputs_root}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    # Skip subjects while debugging
    if [ ${sub} != "sub-0857566" ]; then
        continue
    fi

    ########################################
    # Check for required files
    ########################################

    # Check for a Freesurfer nu.mgz image
    if [ ! -f ${SUBJECTS_DIR}/${sub}/mri/nu.mgz ]; then
        echo "No Freesurfer nu.mgz image for ${sub}"
        continue
    fi

    # Check for a QSIPrep T1w image
    if [ ! -f ${data_root}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz ]; then
        echo "No QSIPrep T1w image for ${sub}"
        continue
    fi

    ########################################
    # Harmonize filetypes and orientations of Freesurfer and QSIPrep images with voxelized tracts
    ########################################

    # Create freesurfer-to-qsiprep_volume_xfm directory
    if [ ! -d ${outputs_root}/${sub}/freesurfer-to-qsiprep_volume_xfm ]; then
        mkdir -p ${outputs_root}/${sub}/freesurfer-to-qsiprep_volume_xfm
    fi
    outputs_dir_xfm=${outputs_root}/${sub}/freesurfer-to-qsiprep_volume_xfm

    # Create surfaces directory
    if [ ! -d ${outputs_root}/${sub}/surfaces ]; then
        mkdir -p ${outputs_root}/${sub}/surfaces
    fi
    outputs_dir_surf=${outputs_root}/${sub}/surfaces

    ###############
    # Freesurfer
    ###############

    # Convert Freesurfer nu.mgz files to NIFTIs
    mri_convert --in_type mgz \
                --out_type nii \
                ${SUBJECTS_DIR}/${sub}/mri/nu.mgz \
                ${outputs_dir_xfm}/nu.nii.gz

    # Change orientation to LAS+
    mri_convert --in_type nii \
                --out_type nii \
                --out_orientation LAS+ \
                ${outputs_dir_xfm}/nu.nii.gz \
                ${outputs_dir_xfm}/nu_LAS.nii.gz
    rm ${outputs_dir_xfm}/nu.nii.gz

    # Convert Freesurfer surfaces to GIFTIs
    mris_convert --to-scanner \
        ${SUBJECTS_DIR}/${sub}/surf/lh.pial \
        ${outputs_dir_surf}/lh.pial.fs.surf.gii

    mris_convert --to-scanner \
        ${SUBJECTS_DIR}/${sub}/surf/rh.pial \
        ${outputs_dir_surf}/rh.pial.fs.surf.gii

    mris_convert \
        ${SUBJECTS_DIR}/${sub}/surf/lh.sphere.reg \
        ${outputs_dir_surf}/lh.sphere.fs.surf.gii

    mris_convert \
        ${SUBJECTS_DIR}/${sub}/surf/rh.sphere.reg \
        ${outputs_dir_surf}/rh.sphere.fs.surf.gii

    ###############
    # QSIPrep
    ###############

    # Change orientation of QSIPrep T1w files to LAS+
    mri_convert --in_type nii \
                --out_type nii \
                --out_orientation LAS+ \
                ${data_root}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz \
                ${outputs_dir_xfm}/desc-preproc_T1w_LAS.nii.gz
    
    ########################################
    # Warp Freesurfer volume to QSIPrep volume
    ########################################

    # Compute affine
    flirt -in ${outputs_dir_xfm}/nu_LAS.nii.gz \
        -ref ${outputs_dir_xfm}/desc-preproc_T1w_LAS.nii.gz \
        -out ${outputs_dir_xfm}/nu_in_desc-preproc_T1w_LAS.nii.gz \
        -omat ${outputs_dir_xfm}/nu_in_desc-preproc_T1w_LAS.mat

    # Convert affine to lta format
    lta_convert --infsl ${outputs_dir_xfm}/nu_in_desc-preproc_T1w_LAS.mat \
                --src ${outputs_dir_xfm}/nu_LAS.nii.gz \
                --trg ${outputs_dir_xfm}/desc-preproc_T1w_LAS.nii.gz \
                --outlta ${outputs_dir_xfm}/nu_in_desc-preproc_T1w_LAS.lta
    rm ${outputs_dir_xfm}/nu_in_desc-preproc_T1w_LAS.mat

done
