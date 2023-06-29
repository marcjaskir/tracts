#!/bin/bash

# Set input/output directories
data_dir=/Users/mjaskir/ngg/rotations/satterthwaite/data/jaskir_tracts
output_dir=/Users/mjaskir/ngg/rotations/satterthwaite/outputs/vol2surf_xfm

# Update Freesurfer subjects directory
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

    # Convert Freesurfer-derived nu.mgz image from mgz to nii.gz format
    mri_convert --in_type mgz \
                --out_type nii \
                ${output_dir}/${sub}/nu.mgz \
                ${output_dir}/${sub}/nu.nii.gz

    # Compute affine for warping Freesurfer-derived nu.mgz image to QSIPrep preprocessed T1w image
    # flirt -in ${output_dir}/${sub}/nu.nii.gz \
    #       -ref ${output_dir}/${sub}/${sub}_desc-preproc_T1w.nii.gz \
    #       -out ${output_dir}/${sub}/nu_in_desc-preproc_T1w.nii.gz \
    #       -omat ${output_dir}/${sub}/nu_in_desc-preproc_T1w.mat

    antsRegistration \
    --collapse-output-transforms 1 \
    --dimensionality 3 \
    --initial-moving-transform [ ${output_dir}/${sub}/${sub}_desc-preproc_T1w.nii.gz, ${output_dir}/${sub}/nu.nii.gz, 0 ] \
    --initialize-transforms-per-stage 0 \
    --interpolation HammingWindowedSinc \
    --output [ ${output_dir}/${sub}/nu_in_desc-preproc_T1w_, ${output_dir}/${sub}/nu_in_desc-preproc_T1w_Warped.nii.gz ] \
    --transform Rigid[ 0.2 ] \
    --metric Mattes[ ${output_dir}/${sub}/${sub}_desc-preproc_T1w.nii.gz, ${output_dir}/${sub}/nu.nii.gz, 1, 32, Random, 0.25 ] \
    --convergence [ 10000x1000x10000x10000, 1e-06, 10 ] \
    --smoothing-sigmas 7.0x3.0x1.0x0.0vox \
    --shrink-factors 8x4x2x1 \
    --write-composite-transform 0

    # Convert affine
    ConvertTransformFile 3 ${output_dir}/${sub}/nu_in_desc-preproc_T1w_0GenericAffine.mat ${output_dir}/${sub}/nu_in_desc-preproc_T1w_0GenericAffine.txt

    # Edit affine header to be acceptable for wb_command -convert-affine
    sed -i '' -e 's|Transform: AffineTransform_double_3_3|Transform: MatrixOffsetTransformBase_double_3_3|' ${output_dir}/${sub}/nu_in_desc-preproc_T1w_0GenericAffine.txt

    # Convert affine to nifti 'world' affine
    wb_command -convert-affine \
                -from-itk ${output_dir}/${sub}/nu_in_desc-preproc_T1w_0GenericAffine.txt \
                -to-world ${output_dir}/${sub}/nu_in_desc-preproc_T1w_0GenericAffine.affine

    # Convert pial surface file to a gifti
    mris_convert ${output_dir}/${sub}/lh.pial ${output_dir}/${sub}/lh.pial.gii

    # Apply the affine transformation matrix to the pial surface file
    wb_command -surface-apply-affine ${output_dir}/${sub}/lh.pial.gii ${output_dir}/${sub}/nu_in_desc-preproc_T1w_0GenericAffine.affine ${output_dir}/${sub}/lh.pial.native.surf.gii

done