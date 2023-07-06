#!/bin/bash

########################################
# Set directories
########################################
data_root=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/data
outputs_root=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/outputs

for sub_dir in ${outputs_root}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    # Start with sub-0857566 for now
    if [ ${sub} != "sub-0857566" ]; then
        continue
    fi

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

            # # Apply T1w -> MNI152NLin2009cAsym transform to tract
            # antsApplyTransforms \
            #     -i ${tract_file} \
            #     -r ${data_root}/qsiprep/${sub}/anat/sub-0857566_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz \
            #     -t ${data_root}/qsiprep/${sub}/anat/sub-0857566_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 \
            #     -o ${outputs_dir}/${tract_label}_MNI152NLin2009cAsym.nii.gz \
            #     -n NearestNeighbor

            # # Change orientation to RAS+
            # mri_convert --in_type nii \
            #             --out_type nii \
            #             --out_orientation RAS+ \
            #             ${outputs_dir}/${tract_label}_MNI152NLin2009cAsym.nii.gz \
            #             ${outputs_dir}/${tract_label}_MNI152NLin2009cAsym_RAS.nii.gz

            # # Apply MNI152NLin2009cAsym -> MNI152NLin6Asym transform to tract
            # antsApplyTransforms \
            #     -i ${outputs_dir}/${tract_label}_MNI152NLin2009cAsym_RAS.nii.gz \
            #     -r ${data_root}/templates/tpl-MNI152NLin6Asym_res-02_T1w.nii \
            #     -t ${data_root}/templates/tpl-MNI152NLin6Asym_from-MNI152NLin2009cAsym_mode-image_xfm.h5 \
            #     -o ${outputs_dir}/${tract_label}_MNI152NLin6Asym_RAS.nii.gz \
            #     -n NearestNeighbor

            # # Change orientation to LAS+
            # mri_convert --in_type nii \
            #             --out_type nii \
            #             --out_orientation LAS+ \
            #             ${outputs_dir}/${tract_label}_MNI152NLin6Asym_RAS.nii.gz \
            #             ${outputs_dir}/${tract_label}_MNI152NLin6Asym_LAS.nii.gz

            # # Copy geometry from MNI152NLin6Asym template
            # fslcpgeom ${outputs_dir}/${tract_label}_MNI152NLin6Asym_LAS.nii.gz ${data_root}/templates/Atlas_ROIs.2.nii.gz

            antsApplyTransforms -d 3 \
                -i ${tract_file} \
                -o ${outputs_dir}/${tract_label}.test.cifti.vol.nii.gz \
                -r ${data_root}/templates/Atlas_ROIs.2.nii.gz \
                -t ${data_root}/templates/tpl-MNI152NLin6Asym_from-MNI152NLin2009cAsym_mode-image_xfm.h5 \
                -t ${data_root}/qsiprep/${sub}/anat/sub-0857566_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 \
                -n nearestneighbor

            # Convert MNI152NLin6Asym tract to CIFTI
            wb_command -cifti-create-dense-scalar \
                ${outputs_dir}/${tract_label}_MNI152NLin6Asym.dscalar.nii \
                -volume ${outputs_dir}/${tract_label}.test.cifti.vol.nii.gz \
                ${data_root}/templates/Atlas_ROIs.2.nii.gz



        fi

    done

done