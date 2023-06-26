#!/bin/bash

data_dir=/Users/mjaskir/ngg/rotations/satterthwaite/data/jaskir_tracts

for sub_dir in ${data_dir}/qsirecon/sub-*; do

	sub=$(basename ${sub_dir})

	# Check if streamline (.tck) files exist
	if [ ! -f ${sub_dir}/ses-V1/dwi/*.tck ]; then
		echo "No streamline files for ${sub}"
		continue
	fi

	# Iterate over streamline (.tck) files
	for track in ${sub_dir}/ses-V1/dwi/*.tck; do

		# Extract file names (without extension)
		track_fname=$(basename ${track} | sed 's/.tck//g')

		# Convert the streamline to a voxelwise map
		if [ ! -f ${sub_dir}/ses-V1/dwi/${track_fname}.nii.gz ]; then
			tckmap ${track} -template ${data_dir}/qsiprep/${sub}/ses-V1/dwi/${sub}_ses-V1_space-T1w_dwiref.nii.gz ${sub_dir}/ses-V1/dwi/${track_fname}.mgz 
		fi

	done

done
