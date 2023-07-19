#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)

for sub_dir in ${outputs_root}/sub-1*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    ########################################
    # Create output directories
    ########################################

    # Create output directory for normalized tract volumes (MNI152NLin6Asym)
    if [ ! -d ${outputs_root}/${sub}/tracts/nifti/MNI152NLin6Asym ]; then
        mkdir -p ${outputs_root}/${sub}/tracts/nifti/MNI152NLin6Asym
    fi
    outputs_dir_mni=${outputs_root}/${sub}/tracts/nifti/MNI152NLin6Asym

    # Create output directory for CIFTIs
    if [ ! -d ${outputs_root}/${sub}/tracts/cifti ]; then
        mkdir -p ${outputs_root}/${sub}/tracts/cifti
    fi
    outputs_dir_cifti=${outputs_root}/${sub}/tracts/cifti

    # Iterate over tract volumes
    for tract_file in ${outputs_root}/${sub}/tracts/nifti/native_orientation-LPS/*; do

        # Extract tract label
        tract_fname=$(basename ${tract_file})
        tract_label=$(echo ${tract_fname} | sed 's/_LPS.nii.gz//g')

        echo "Converting ${tract_label} volume/surface data to CIFTI"

        ########################################
        # Warp tract volumes to MNI152NLin6Asym
        ########################################

        antsApplyTransforms -d 3 \
            -i ${tract_file} \
            -o ${outputs_dir_mni}/${tract_label}.nii.gz \
            -r ${data_root}/templates/MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-02_atlas-HCP_dseg.nii \
            -t ${data_root}/templates/transforms/tpl-MNI152NLin6Asym_from-MNI152NLin2009cAsym_mode-image_xfm.h5 \
            -t ${data_root}/qsiprep/${sub}/anat/${sub}_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 \
            -n nearestneighbor

        ########################################
        # Convert surface and volume components to CIFTI
        ########################################

        wb_command -cifti-create-dense-scalar \
            ${outputs_dir_cifti}/${tract_label}.dscalar.nii \
            -volume ${outputs_dir_mni}/${tract_label}.nii.gz \
            ${data_root}/templates/MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-02_atlas-HCP_dseg.nii \
            -left-metric ${outputs_root}/${sub}/surface_mappings/fslr_164k/${tract_label}.lh.shape.gii \
            -right-metric ${outputs_root}/${sub}/surface_mappings/fslr_164k/${tract_label}.rh.shape.gii

    done

done