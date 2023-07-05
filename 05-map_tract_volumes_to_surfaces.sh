#!/bin/bash

#### NOTE: In progress - resolving commisural fibers

########################################
# Set directories
########################################
data_root=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/data
outputs_root=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/outputs

for sub_dir in ${outputs_root}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    ########################################
    # Map tract volumes to surfaces
    ########################################

    for tract_file in ${outputs_root}/${sub}/tracts/nifti/*.nii.gz; do

        # Extract tract name
        tract_fname=$(basename ${tract_file})

        # Extract hemisphere and grab last character of string
        hemi=$(echo ${tract_fname} | cut -d'_' -f1 | rev | cut -c1 | rev)

        # Check if hemi is not equal to 'L' or 'R'
        if [ "${hemi}" != "L" ] && [ "${hemi}" != "R" ]; then
            echo ${tract_fname}
        fi

        # Map tract to surface
        #wb_command -volume-to-surface-mapping ${tract_file} ${outputs_root}/${sub}/surfaces/lh.pial.qsiprep.surf.gii ${outputs_root}/${sub}/surfaces/${tract}_LAS.shape.gii -trilinear

    done

    # wb_command -volume-to-surface-mapping ${outputs_root}/${sub}/ArcuateFasciculusL_LAS.nii.gz ${output_dir}/${sub}/lh.pial.warped.surf.gii ${output_dir}/${sub}/ArcuateFasciculusL_LAS.shape.gii -trilinear

done