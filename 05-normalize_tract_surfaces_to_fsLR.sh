#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)

for sub_dir in ${outputs_root}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    # Create output directory for normalized surface mappings
    if [ ! -d ${outputs_root}/${sub}/surface_mappings/fslr_32k ]; then
        mkdir -p ${outputs_root}/${sub}/surface_mappings/fslr_32k
    fi
    outputs_dir=${outputs_root}/${sub}/surface_mappings/fslr_32k

    ########################################
    # Normalize tract surfaces to fsLR
    ########################################

    for tract_file in ${outputs_root}/${sub}/surface_mappings/native/*; do

        # Extract tract label
        tract_fname=$(basename ${tract_file})
        tract_label="${tract_fname%%.*}"

        # Start with 1 bundle as a test case
        if [ "${tract_fname}" == "ArcuateFasciculusL.lh.shape.gii" ]; then

            # Resample tract surface to fsLR
            wb_command -metric-resample \
                ${tract_file} \
                ${outputs_root}/${sub}/surfaces/lh.sphere.fs.surf.gii \
                ${data_root}/templates/L.sphere.32k_fs_LR.surf.gii \
                BARYCENTRIC \
                ${outputs_dir}/${tract_label}.lh.32k_fs_LR.shape.gii

        fi

    done

done