#!/bin/bash

# Set data and output directories
data_dir=/Users/mjaskir/ngg/rotations/satterthwaite/data/jaskir_tracts
output_dir=/Users/mjaskir/ngg/rotations/satterthwaite/outputs/vol2surf_xfm

# Update SUBJECTS_DIR environmental variable
SUBJECTS_DIR=${data_dir}/freesurfer

for sub_dir in ${SUBJECTS_DIR}/sub-*; do

    # Extract subject label
    sub=$(basename ${sub_dir})

    # Only run sub-0857566 while debugging
    if [ ${sub} != "sub-0857566" ]; then
        continue
    fi

    # Create output directory for each subject if it doesn't exist
    if [ ! -d ${output_dir}/sub ]; then
        mkdir -p ${output_dir}/${sub}
    fi

    # Check for QSIPrep preprocessed T1w image
    if [ ! -f ${data_dir}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz ]; then
        echo "No QSIPrep-preprocessed T1w image for ${sub}"
        continue
    else
        cp ${data_dir}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz ${output_dir}/${sub}
    fi

    # Check if Freesurfer-derived nu.mgz image exists
    if [ ! -f ${sub_dir}/mri/nu.mgz ]; then
        echo "No Freesurfer-preprocessed nu.mgz image for ${sub}"
        continue
    else
        cp ${sub_dir}/mri/nu.mgz ${output_dir}/${sub}
    fi

    # Convert QSIPrep preprocessed T1w image from nii.gz to mgz format
    mri_convert --in_type nii \
                --out_type mgz \
                ${output_dir}/${sub}/${sub}_desc-preproc_T1w.nii.gz \
                ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz

    # Compute transformation from QSIPrep preprocessed T1w image to Freesurfer-derived nu.mgz image
    tkregister2 --mov ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
               --targ ${output_dir}/${sub}/nu.mgz \
               --reg ${output_dir}/${sub}/desc-preproc_T1w-in-nu.dat \
               --s ${sub} \
               --regheader

    # Use bbregister to apply transformation to QSIPrep preprocessed T1w image
    bbregister --s ${sub} \
               --mov ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
               --reg ${output_dir}/${sub}/desc-preproc_T1w-in-nu.dat \
               --t1 \
               --o ${output_dir}/${sub}/desc-preproc_T1w-in-nu.mgz

    # Map the bundle volumes to Freesurfer surfaces in native space by appling transformation
    test_bundle_name=ArcuateFasciculusL
    test_bundle_file=${data_dir}/qsirecon/${sub}/ses-V1/dwi/sub-0857566_ses-V1_space-T1w_desc-preproc_bundle-${test_bundle_name}_AutoTrackGQI.mgz
    mri_vol2surf --src ${test_bundle_file} \
                --reg ${output_dir}/${sub}/desc-preproc_T1w-in-nu.dat \
                --regheader ${sub} \
                --hemi lh \
                --o ${output_dir}/${sub}/${test_bundle_name}_surf.mgz

done