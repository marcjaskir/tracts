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

    # Check for a QSIPrep preprocessed T1w image
    if [ ! -f ${data_dir}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz ]; then
        echo "No QSIPrep-preprocessed T1w image for ${sub}"
        continue
    else
        cp ${data_dir}/qsiprep/${sub}/anat/${sub}_desc-preproc_T1w.nii.gz ${output_dir}/${sub}
    fi

    # Check if a Freesurfer-derived nu.mgz image exists
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

    # Compute transformation from Freesurfer-derived nu.mgz image to QSIPrep preprocessed T1w image
    # tkregister2 --mov ${output_dir}/${sub}/nu.mgz \
    #            --targ ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
    #            --reg ${output_dir}/${sub}/nu_in_desc-preproc_T1w.dat \
    #            --s ${sub}
    mri_robust_register --mov ${output_dir}/${sub}/nu.mgz \
                        --dst ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
                        --lta ${output_dir}/${sub}/nu_in_desc-preproc_T1w.lta \
                        --mapmov ${output_dir}/${sub}/nu_in_desc-preproc_T1w.mgz \
                        --satit \
                        --maxit 20 \
                        --iscale

    lta_convert --inlta ${output_dir}/${sub}/nu_in_desc-preproc_T1w.lta \
                --outreg ${output_dir}/${sub}/nu_in_desc-preproc_T1w.dat

    # As a sanity check, transform nu.mgz to QSIPrep preprocessed T1w image
    mri_vol2vol --mov ${output_dir}/${sub}/nu.mgz \
                --targ ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
                --reg ${output_dir}/${sub}/nu_in_desc-preproc_T1w.dat \
                --o ${output_dir}/${sub}/nu_in_desc-preproc_T1w.mgz
                

    # Transform the subject's pial surface to be aligned with the QSIPrep preprocessed T1w image
    mri_surf2surf --hemi lh \
                --sval-xyz pial \
                --tval-xyz ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
                --tval ${output_dir}/${sub}/lh_pial_in_desc_preproc_T1w \
                --reg ${output_dir}/${sub}/nu_in_desc-preproc_T1w.dat ${output_dir}/${sub}/${sub}_desc-preproc_T1w.mgz \
                --s ${sub}

    # Map the bundle volumes to Freesurfer surfaces in native space by appling transformation
    # test_bundle_name=ArcuateFasciculusL
    # test_bundle_file=${data_dir}/qsirecon/${sub}/ses-V1/dwi/sub-0857566_ses-V1_space-T1w_desc-preproc_bundle-${test_bundle_name}_AutoTrackGQI.mgz
    # mri_vol2surf --src ${test_bundle_file} \
    #             --reg ${output_dir}/${sub}/desc-preproc_T1w-in-nu.dat \
    #             --regheader ${sub} \
    #             --hemi lh \
    #             --o ${output_dir}/${sub}/${test_bundle_name}_surf.mgz

done