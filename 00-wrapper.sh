#!/bin/bash

# Start time
start=$(date +%s)

########################################
# Set directories
########################################
data_root=$(jq -r '.data_root' config.json)
outputs_root=$(jq -r '.outputs_root' config.json)
environment=$(jq -r '.environment' config.json)

########################################
# Activate conda environment
########################################
eval "$(conda shell.bash hook)"
conda activate ${environment}

########################################
# Specify subject ID
########################################
#sub=${1}
sub='sub-0857566'

########################################
# Create log directory
######################################## 
if [ ! -f ${outputs_root}/${sub}/logs ]; then
    mkdir -p ${outputs_root}/${sub}/logs
fi
outputs_dir_logs=${outputs_root}/${sub}/logs

echo "Running tract-to-surface mapping for ${sub}..."

echo "-- Voxelizing tracts..."
./01-voxelize_tracts.sh ${sub} >> ${outputs_dir_logs}/01-voxelize_tracts.log 2>&1

echo "-- Determining Freesurfer to Native AC-PC volume transformation..."
./02-determine_freesurfer-to-native_acpc_volume_xfm.sh ${sub} >> ${outputs_dir_logs}/02-determine_freesurfer-to-native_acpc_volume_xfm.log 2>&1

echo "-- Aligning surfaces with tract volumes..."
python 03-align_surfaces_with_tract_volumes.py ${sub} >> ${outputs_dir_logs}/03-align_surfaces_with_tract_volumes.log 2>&1

echo "-- Mapping tract volumes to surfaces..."
./04-map_tract_volumes_to_surfaces.sh ${sub} >> ${outputs_dir_logs}/04-map_tract_volumes_to_surfaces.log 2>&1

echo "-- Converting tract volume/surface data to CIFTI..."
./05-convert_to_cifti.sh ${sub} >> ${outputs_dir_logs}/05-convert_to_cifti.log 2>&1

# Calculate elapsed time
end=$(date +%s)
elapsed=$((end - start))
minutes=$((elapsed / 60))
seconds=$((elapsed % 60))

echo "Done! - Elapsed time: ${minutes} minutes ${seconds} seconds"
