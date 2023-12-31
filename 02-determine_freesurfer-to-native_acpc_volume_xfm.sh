#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)
SUBJECTS_DIR=${data_root}/freesurfer

########################################
# Read in subject ID
########################################
sub=${1}

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
# Create output directories
########################################   

# Create output directories for transforms (including reference volumes) and surfaces converted to GIFTIs
if [ ! -d ${outputs_root}/${sub}/transforms ]; then
    mkdir -p ${outputs_root}/${sub}/transforms/freesurfer-to-native_acpc
    mkdir -p ${outputs_root}/${sub}/surfaces/freesurfer
fi
outputs_dir_xfm=${outputs_root}/${sub}/transforms/freesurfer-to-native_acpc
outputs_dir_surf=${outputs_root}/${sub}/surfaces/freesurfer

########################################
# Harmonize filetypes and orientations of Freesurfer and QSIPrep images with voxelized tracts
########################################

###############
# Freesurfer
###############

# Convert Freesurfer reference volumes (nu.mgz) to NIFTIs
mri_convert --in_type mgz \
            --out_type nii \
            ${SUBJECTS_DIR}/${sub}/mri/nu.mgz \
            ${outputs_dir_xfm}/${sub}.freesurfer.nu.LIA.nii.gz

# Change orientation of Freesurfer reference volumes to LAS+
mri_convert --in_type nii \
            --out_type nii \
            --out_orientation LAS+ \
            ${outputs_dir_xfm}/${sub}.freesurfer.nu.LIA.nii.gz \
            ${outputs_dir_xfm}/${sub}.freesurfer.nu.nii.gz
rm ${outputs_dir_xfm}/${sub}.freesurfer.nu.LIA.nii.gz

# Convert Freesurfer surfaces to GIFTIs
mris_convert --to-scanner \
    ${SUBJECTS_DIR}/${sub}/surf/lh.pial \
    ${outputs_dir_surf}/${sub}.lh.pial.freesurfer.surf.gii

mris_convert --to-scanner \
    ${SUBJECTS_DIR}/${sub}/surf/rh.pial \
    ${outputs_dir_surf}/${sub}.rh.pial.freesurfer.surf.gii

mris_convert --to-scanner \
    ${SUBJECTS_DIR}/${sub}/surf/lh.white \
    ${outputs_dir_surf}/${sub}.lh.white.freesurfer.surf.gii

mris_convert --to-scanner \
    ${SUBJECTS_DIR}/${sub}/surf/rh.white \
    ${outputs_dir_surf}/${sub}.rh.white.freesurfer.surf.gii

mris_convert \
    ${SUBJECTS_DIR}/${sub}/surf/lh.sphere.reg \
    ${outputs_dir_surf}/${sub}.lh.sphere.freesurfer.surf.gii

mris_convert \
    ${SUBJECTS_DIR}/${sub}/surf/rh.sphere.reg \
    ${outputs_dir_surf}/${sub}.rh.sphere.freesurfer.surf.gii

###############
# QSIPrep
###############

# Change orientation of QSIPrep T1w files to LAS+
mri_convert --in_type nii \
            --out_type nii \
            --out_orientation LAS+ \
            ${data_root}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz \
            ${outputs_dir_xfm}/${sub}.native_acpc.desc-preproc_T1w.nii.gz

########################################
# Warp Freesurfer volume to QSIPrep volume
########################################

# Compute affine
flirt -in ${outputs_dir_xfm}/${sub}.freesurfer.nu.nii.gz \
    -ref ${outputs_dir_xfm}/${sub}.native_acpc.desc-preproc_T1w.nii.gz \
    -out ${outputs_dir_xfm}/${sub}.native_acpc.nu.nii.gz \
    -omat ${outputs_dir_xfm}/${sub}.freesurfer-to-native_acpc.xfm.mat

# Convert affine to lta format
lta_convert --infsl ${outputs_dir_xfm}/${sub}.freesurfer-to-native_acpc.xfm.mat \
            --src ${outputs_dir_xfm}/${sub}.freesurfer.nu.nii.gz \
            --trg ${outputs_dir_xfm}/${sub}.native_acpc.desc-preproc_T1w.nii.gz \
            --outlta ${outputs_dir_xfm}/${sub}.freesurfer-to-native_acpc.xfm.lta
rm ${outputs_dir_xfm}/${sub}.freesurfer-to-native_acpc.xfm.mat
