#!/bin/bash

# Set input/output directories
data_dir=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/data
output_dir=/Users/mjaskir/ngg/rotations/satterthwaite/tracts/outputs

# Iterate over subjects with qsirecon outputs
for sub_dir in ${data_dir}/qsirecon/sub-*; do

	# Extract subject ID
	sub=$(basename ${sub_dir})

	# Check if tract (.tck) files exist
	if [ ! -f ${sub_dir}/ses-V1/dwi/*.tck ]; then
		echo "No tract (.tck) files for ${sub}"
		continue
	fi

	# Create output directory
    if [ ! -d ${output_dir}/sub ]; then
        mkdir -p ${output_dir}/${sub}/tracts
    fi

	# Iterate over streamline (.tck) files
	for tract in ${sub_dir}/ses-V1/dwi/*.tck; do

		# Extract file name (without extension)
		tract_fname=$(basename ${tract} | sed 's/.tck//g')

		# Voxelize tracts
		if [ ! -f ${output_dir}/${sub}/tracts/${tract_fname}.nii.gz ]; then

			# Voxelize tracts
			tckmap ${tract} -template ${data_dir}/qsiprep/${sub}/ses-V1/dwi/${sub}_ses-V1_space-T1w_dwiref.nii.gz ${output_dir}/${sub}/tracts/${tract_fname}.mgz 

		fi

	done

done
