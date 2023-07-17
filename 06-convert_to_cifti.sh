#!/bin/bash

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)

# Change orientation of subcortical segmentation
# 3dresample -orient RPI \
#     -inset ${data_root}/templates/MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-02_atlas-HCP_dseg.nii \
#     -prefix ${data_root}/templates/MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-02_atlas-HCP_orientation-LAS_dseg.nii

for sub_dir in ${outputs_root}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    # Create cifti outputs directory
    if [ ! -d ${outputs_root}/${sub}/tracts/cifti ]; then
        mkdir -p ${outputs_root}/${sub}/tracts/cifti
    fi
    outputs_dir=${outputs_root}/${sub}/tracts/cifti

    # Iterate over bundles
    for tract_file in ${outputs_root}/${sub}/tracts/nifti/*.nii.gz; do

        # Extract tract label
        tract_fname=$(basename ${tract_file})
        tract_label=$(echo ${tract_fname} | sed 's/_LPS.nii.gz//g')

        # Start with 1 bundle as a test case
        if [ "${tract_fname}" == "ArcuateFasciculusL_LPS.nii.gz" ]; then

            antsApplyTransforms -d 3 \
                -i ${tract_file} \
                -o ${outputs_dir}/${tract_label}.nii.gz \
                -r ${data_root}/templates/MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-02_atlas-HCP_dseg.nii \
                -t ${data_root}/templates/transforms/tpl-MNI152NLin6Asym_from-MNI152NLin2009cAsym_mode-image_xfm.h5 \
                -t ${data_root}/qsiprep/${sub}/anat/sub-0857566_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 \
                -n nearestneighbor

            # Convert MNI152NLin6Asym tract to CIFTI
            wb_command -cifti-create-dense-scalar \
                ${outputs_dir}/${tract_label}_MNI152NLin6Asym.dscalar.nii \
                -volume ${outputs_dir}/${tract_label}.nii.gz \
                ${data_root}/templates/MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-02_atlas-HCP_dseg.nii \
                -left-metric ${data_root}/templates/fslr/tpl-fsLR_hemi-L_den-164k_desc-vaavg_midthickness.shape.gii \
                -right-metric ${data_root}/templates/fslr/tpl-fsLR_hemi-R_den-164k_desc-vaavg_midthickness.shape.gii
            # rm ${outputs_dir}/${tract_label}.test.cifti.vol.nii.gz

        fi

    done

done