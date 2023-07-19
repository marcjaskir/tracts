import os
import json
from os.path import join as ospj
from smriprep.interfaces.surf import normalize_surfs

########################################
# Set directories
########################################
with open('config.json', "rb") as f:
    config = json.load(f)
outputs_root = config['outputs_root']

# Iterate over subject directories with outputs
for sub_dir in [ospj(outputs_root, d) for d in os.listdir(outputs_root) if d.startswith('sub-')]:

    # Extract subject ID
    sub = sub_dir.split('/')[-1]

    ########################################
    # Check for required files
    ########################################

    # Check for pial surface files
    pial_files = [ospj(sub_dir, 'surfaces', 'freesurfer', f) for f in os.listdir(ospj(sub_dir, 'surfaces', 'freesurfer')) if f.endswith('pial.freesurfer.surf.gii')]
    if len(pial_files) != 2:
        print('Missing pial surface files for %s' % sub_dir)
        continue

    # Check for white surface files
    white_files = [ospj(sub_dir, 'surfaces', 'freesurfer', f) for f in os.listdir(ospj(sub_dir, 'surfaces', 'freesurfer')) if f.endswith('white.freesurfer.surf.gii')]
    if len(white_files) != 2:
        print('Missing white surface files for %s' % sub_dir)
        continue

    # Check for .lta transformation file
    lta_files = [ospj(sub_dir, 'transforms', 'freesurfer-to-qsiprep', f) for f in os.listdir(ospj(sub_dir, 'transforms', 'freesurfer-to-qsiprep')) if f.endswith('.lta')]
    if len(lta_files) != 1:
        print('Missing .lta transformation file for %s' % sub_dir)
        continue

    ########################################
    # Create output directories
    ########################################

    # Create directory for transformed surfaces (into QSIPrep space)
    if not os.path.exists(ospj(sub_dir, 'surfaces', 'qsiprep')):
        os.makedirs(ospj(sub_dir, 'surfaces', 'qsiprep'))
    outputs_dir = ospj(sub_dir, 'surfaces', 'qsiprep')

    ########################################
    # Apply Freesurfer to QSIPrep volume transformation to surfaces
    ########################################

    # Apply transformation to pial surfaces
    for pial_file in pial_files:

        # Get hemisphere
        hemi = pial_file.split('/')[-1].split('.')[0]

        # Apply transformation
        converted_surf = normalize_surfs(pial_file, lta_files[0], pial_file)

        # Move the converted surface to the same directory as the original surface
        os.rename(converted_surf, ospj(outputs_dir, '%s.pial.qsiprep.surf.gii' % hemi))

    # Apply transformation to white surfaces
    for white_file in white_files:

        # Get hemisphere
        hemi = white_file.split('/')[-1].split('.')[0]

        # Apply transformation
        converted_surf = normalize_surfs(white_file, lta_files[0], white_file)

        # Move the converted surface to the same directory as the original surface
        os.rename(converted_surf, ospj(outputs_dir, '%s.white.qsiprep.surf.gii' % hemi))