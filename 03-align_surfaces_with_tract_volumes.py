import os
import json
import sys
from os.path import join as ospj
from smriprep.interfaces.surf import normalize_surfs

########################################
# Set directories
########################################
with open('config.json', "rb") as f:
    config = json.load(f)
outputs_root = config['outputs_root']

########################################
# Check for required files
########################################
sub = sys.argv[1]

########################################
# Check for required files
########################################

# Check for pial surface files
pial_files = [ospj(outputs_root, sub, 'surfaces', 'freesurfer', f) for f in os.listdir(ospj(outputs_root, sub, 'surfaces', 'freesurfer')) if f.endswith('pial.freesurfer.surf.gii')]
if len(pial_files) != 2:
    print('Missing pial surface files for %s' % sub)
    exit(1)

# Check for white surface files
white_files = [ospj(outputs_root, sub, 'surfaces', 'freesurfer', f) for f in os.listdir(ospj(outputs_root, sub, 'surfaces', 'freesurfer')) if f.endswith('white.freesurfer.surf.gii')]
if len(white_files) != 2:
    print('Missing white surface files for %s' % sub)
    exit(1)

# Check for .lta transformation file
lta_files = [ospj(outputs_root, sub, 'transforms', 'freesurfer-to-native_acpc', f) for f in os.listdir(ospj(outputs_root, sub, 'transforms', 'freesurfer-to-native_acpc')) if f.endswith('.lta')]
if len(lta_files) != 1:
    print('Missing .lta transformation file for %s' % sub)
    exit(1)

########################################
# Create output directories
########################################

# Create directory for transformed surfaces (into QSIPrep space)
if not os.path.exists(ospj(outputs_root, sub, 'surfaces', 'native_acpc')):
    os.makedirs(ospj(outputs_root, sub, 'surfaces', 'native_acpc'))
outputs_dir = ospj(outputs_root, sub, 'surfaces', 'native_acpc')

########################################
# Apply Freesurfer to native AC-PC volume transformation to surfaces
########################################

print('Transforming pial surfaces...')

# Apply transformation to pial surfaces
for pial_file in pial_files:

    # Get hemisphere
    hemi = pial_file.split('/')[-1].split('.')[0]

    # Apply transformation
    converted_surf = normalize_surfs(pial_file, lta_files[0], pial_file)

    # Move the converted surface to the same directory as the original surface
    os.rename(converted_surf, ospj(outputs_dir, '%s.pial.native_acpc.surf.gii' % hemi))

print('Transforming white surfaces...')

# Apply transformation to white surfaces
for white_file in white_files:

    # Get hemisphere
    hemi = white_file.split('/')[-1].split('.')[0]

    # Apply transformation
    converted_surf = normalize_surfs(white_file, lta_files[0], white_file)

    # Move the converted surface to the same directory as the original surface
    os.rename(converted_surf, ospj(outputs_dir, '%s.white.native_acpc.surf.gii' % hemi))
