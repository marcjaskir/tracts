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
# Create output directories
########################################

# Create output directory for surface mappings
if [ ! -d ${outputs_root}/${sub}/surface_mappings ]; then
    mkdir -p ${outputs_root}/${sub}/surface_mappings/native_acpc
    mkdir -p ${outputs_root}/${sub}/surface_mappings/fslr_32k
    mkdir -p ${outputs_root}/${sub}/surface_mappings/fslr_164k
fi
outputs_dir_native_acpc=${outputs_root}/${sub}/surface_mappings/native_acpc
outputs_dir_fslr_32k=${outputs_root}/${sub}/surface_mappings/fslr_32k
outputs_dir_fslr_164k=${outputs_root}/${sub}/surface_mappings/fslr_164k

########################################
# Create midthickness surfaces from Freesurfer data (used for resampling to fsLR)
########################################

###############
# fsLR 32k
###############

# Left hemisphere
wb_shortcuts -freesurfer-resample-prep \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.lh.white.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.lh.pial.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.lh.sphere.freesurfer.surf.gii \
    ${data_root}/templates/fslr_32k/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
    ${outputs_dir_fslr_32k}/lh.midthickness.surf.gii \
    ${outputs_dir_fslr_32k}/lh.midthickness.fslr_32k.surf.gii \
    ${outputs_dir_fslr_32k}/lh.sphere.reg.surf.gii

# Right hemisphere
wb_shortcuts -freesurfer-resample-prep \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.rh.white.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.rh.pial.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.rh.sphere.freesurfer.surf.gii \
    ${data_root}/templates/fslr_32k/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii \
    ${outputs_dir_fslr_32k}/rh.midthickness.surf.gii \
    ${outputs_dir_fslr_32k}/rh.midthickness.fslr_32k.surf.gii \
    ${outputs_dir_fslr_32k}/rh.sphere.reg.surf.gii

###############
# fsLR 164k
###############

# Left hemisphere
wb_shortcuts -freesurfer-resample-prep \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.lh.white.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.lh.pial.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.lh.sphere.freesurfer.surf.gii \
    ${data_root}/templates/fslr_164k/fs_LR-deformed_to-fsaverage.L.sphere.164k_fs_LR.surf.gii \
    ${outputs_dir_fslr_164k}/lh.midthickness.surf.gii \
    ${outputs_dir_fslr_164k}/lh.midthickness.fslr_164k.surf.gii \
    ${outputs_dir_fslr_164k}/lh.sphere.reg.surf.gii

# Right hemisphere
wb_shortcuts -freesurfer-resample-prep \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.rh.white.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.rh.pial.native_acpc.surf.gii \
    ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.rh.sphere.freesurfer.surf.gii \
    ${data_root}/templates/fslr_164k/fs_LR-deformed_to-fsaverage.R.sphere.164k_fs_LR.surf.gii \
    ${outputs_dir_fslr_164k}/rh.midthickness.surf.gii \
    ${outputs_dir_fslr_164k}/rh.midthickness.fslr_164k.surf.gii \
    ${outputs_dir_fslr_164k}/rh.sphere.reg.surf.gii

########################################
# Map tract volumes to native surfaces
########################################

for tract_file in ${outputs_root}/${sub}/tracts/nifti/native_acpc_orientation-LAS/*; do

    # Extract tract label
    tract_fname=$(basename ${tract_file})
    tract_label=$(echo ${tract_fname} | cut -d'.' -f2)
        
    # Map tract to native surfaces
    wb_command -volume-to-surface-mapping \
        ${tract_file} \
        ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.lh.pial.native_acpc.surf.gii \
        ${outputs_dir_native_acpc}/${sub}.${tract_label}.lh.shape.gii \
        -trilinear
    wb_command -volume-to-surface-mapping \
        ${tract_file} \
        ${outputs_root}/${sub}/surfaces/native_acpc/${sub}.rh.pial.native_acpc.surf.gii \
        ${outputs_dir_native_acpc}/${sub}.${tract_label}.rh.shape.gii \
        -trilinear

done

########################################
# Warp tract surfaces to fsLR
########################################

for tract_file in ${outputs_dir_native_acpc}/*.shape.gii; do

    # Extract tract label
    tract_fname=$(basename ${tract_file})
    tract_label=$(echo ${tract_fname} | cut -d '.' -f2-3)

    echo "Warping ${tract_label} to fsLR"

    # Extract last 2 characters of tract label
    hemi=$(echo ${tract_label} | rev | cut -c1-2 | rev)

    ###############
    # fsLR 32k
    ###############

        # Left hemisphere
    if [ ${hemi} == 'lh' ]; then

        wb_command -metric-resample \
            ${tract_file} \
            ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.lh.sphere.freesurfer.surf.gii \
            ${data_root}/templates/fslr_32k/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
            ADAP_BARY_AREA \
            ${outputs_dir_fslr_32k}/${sub}.${tract_label}.shape.gii \
            -area-surfs ${outputs_dir_fslr_32k}/lh.midthickness.surf.gii ${outputs_dir_fslr_32k}/lh.midthickness.fslr_32k.surf.gii

    # Right hemisphere
    elif [ ${hemi} == 'rh' ]; then

        wb_command -metric-resample \
            ${tract_file} \
            ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.rh.sphere.freesurfer.surf.gii \
            ${data_root}/templates/fslr_32k/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii \
            ADAP_BARY_AREA \
            ${outputs_dir_fslr_32k}/${sub}.${tract_label}.shape.gii \
            -area-surfs ${outputs_dir_fslr_32k}/rh.midthickness.surf.gii ${outputs_dir_fslr_32k}/rh.midthickness.fslr_32k.surf.gii

    fi       

    ###############
    # fsLR 164k
    ###############

    # Left hemisphere
    if [ ${hemi} == 'lh' ]; then

        wb_command -metric-resample \
            ${tract_file} \
            ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.lh.sphere.freesurfer.surf.gii \
            ${data_root}/templates/fslr_164k/fs_LR-deformed_to-fsaverage.L.sphere.164k_fs_LR.surf.gii \
            ADAP_BARY_AREA \
            ${outputs_dir_fslr_164k}/${sub}.${tract_label}.shape.gii \
            -area-surfs ${outputs_dir_fslr_164k}/lh.midthickness.surf.gii ${outputs_dir_fslr_164k}/lh.midthickness.fslr_164k.surf.gii

    # Right hemisphere
    elif [ ${hemi} == 'rh' ]; then

        wb_command -metric-resample \
            ${tract_file} \
            ${outputs_root}/${sub}/surfaces/freesurfer/${sub}.rh.sphere.freesurfer.surf.gii \
            ${data_root}/templates/fslr_164k/fs_LR-deformed_to-fsaverage.R.sphere.164k_fs_LR.surf.gii \
            ADAP_BARY_AREA \
            ${outputs_dir_fslr_164k}/${sub}.${tract_label}.shape.gii \
            -area-surfs ${outputs_dir_fslr_164k}/rh.midthickness.surf.gii ${outputs_dir_fslr_164k}/rh.midthickness.fslr_164k.surf.gii

    fi

done

# Clean up intermediary files
rm ${outputs_dir_fslr_32k}/lh.midthickness.surf.gii
rm ${outputs_dir_fslr_32k}/rh.midthickness.surf.gii
rm ${outputs_dir_fslr_32k}/lh.sphere.reg.surf.gii
rm ${outputs_dir_fslr_32k}/rh.sphere.reg.surf.gii
rm ${outputs_dir_fslr_32k}/lh.midthickness.fslr_32k.surf.gii
rm ${outputs_dir_fslr_32k}/rh.midthickness.fslr_32k.surf.gii
rm ${outputs_dir_fslr_164k}/lh.midthickness.surf.gii
rm ${outputs_dir_fslr_164k}/rh.midthickness.surf.gii
rm ${outputs_dir_fslr_164k}/lh.sphere.reg.surf.gii
rm ${outputs_dir_fslr_164k}/rh.sphere.reg.surf.gii
rm ${outputs_dir_fslr_164k}/lh.midthickness.fslr_164k.surf.gii
rm ${outputs_dir_fslr_164k}/rh.midthickness.fslr_164k.surf.gii
