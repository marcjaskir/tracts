import os
from os.path import join as ospj
from smriprep.interfaces.surf import normalize_surfs

########################################
# Set directories
########################################
outputs_root = '/Users/mjaskir/ngg/rotations/satterthwaite/tracts/outputs'

# Iterate over subject directories with outputs
for sub_dir in [ospj(outputs_root, d) for d in os.listdir(outputs_root) if d.startswith('sub-')]:

    ########################################
    # Check for required files
    ########################################

    # Check for pial surface files
    pial_files = [ospj(sub_dir, 'surfaces', f) for f in os.listdir(ospj(sub_dir, 'surfaces')) if f.endswith('pial.gii')]
    if len(pial_files) != 2:
        print('Missing pial surface files for %s' % sub_dir)
        continue

    # Check for .lta transformation file
    lta_files = [ospj(sub_dir, 'freesurfer-to-qsiprep_volume_xfm', f) for f in os.listdir(ospj(sub_dir, 'freesurfer-to-qsiprep_volume_xfm')) if f.endswith('.lta')]
    if len(lta_files) != 1:
        print('Missing .lta transformation file for %s' % sub_dir)
        continue

    ########################################
    # Apply Freesurfer to QSIPrep volume transformation to pial surfaces
    ########################################

    # Apply transformation
    for pial_file in pial_files:

        # Get hemisphere
        hemi = pial_file.split('/')[-1].split('.')[0]

        # Apply transformation
        converted_surf = normalize_surfs(pial_file, lta_files[0], pial_file)

        # Move the converted surface to the same directory as the original surface
        os.rename(converted_surf, ospj(sub_dir, 'surfaces', '%s.pial.qsiprep.surf.gii' % hemi))