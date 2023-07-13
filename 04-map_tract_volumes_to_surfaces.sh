#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)

for sub_dir in ${outputs_root}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    # Create output directory for surface mappings
    if [ ! -d ${outputs_root}/${sub}/surface_mappings ]; then
        mkdir -p ${outputs_root}/${sub}/surface_mappings/native
    fi
    outputs_dir=${outputs_root}/${sub}/surface_mappings/native

    ########################################
    # Map tract volumes to surfaces
    ########################################

    for tract_file in ${outputs_root}/${sub}/tracts/nifti/*_LAS.nii.gz; do

        # Extract tract label
        tract_fname=$(basename ${tract_file})
        tract_label=$(echo ${tract_fname} | sed 's/_LAS.nii.gz//g')

        # Extract last character of tract label
        hemi=$(echo ${tract_label} | rev | cut -c1 | rev)

        # Check if its a commisural tract
        if [ "${hemi}" != "L" ] && [ "${hemi}" != "R" ]; then
            
            # Map tract to surfaces
            wb_command -volume-to-surface-mapping ${tract_file} ${outputs_root}/${sub}/surfaces/lh.pial.qsiprep.surf.gii ${outputs_dir}/${tract_label}.lh.shape.gii -trilinear
            wb_command -volume-to-surface-mapping ${tract_file} ${outputs_root}/${sub}/surfaces/rh.pial.qsiprep.surf.gii ${outputs_dir}/${tract_label}.rh.shape.gii -trilinear

        else

            # Map tract to the corresponding hemisphere's surface
            if [ "${hemi}" == "L" ]; then
                
                wb_command -volume-to-surface-mapping ${tract_file} ${outputs_root}/${sub}/surfaces/lh.pial.qsiprep.surf.gii ${outputs_dir}/${tract_label}.lh.shape.gii -trilinear

            elif [ "${hemi}" == "R" ]; then

                wb_command -volume-to-surface-mapping ${tract_file} ${outputs_root}/${sub}/surfaces/rh.pial.qsiprep.surf.gii ${outputs_dir}/${tract_label}.rh.shape.gii -trilinear

            fi

        fi

    done

done