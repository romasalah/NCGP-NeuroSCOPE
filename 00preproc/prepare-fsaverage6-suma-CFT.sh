#!/bin/bash -ex

IMGNAME="neurodocker_2.img"
BASEDIR=/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG
IMG=$BASEDIR/singularity/$IMGNAME
FS_LICENSE=$BASEDIR/scripts/00preproc/license.txt
FSPATH=/idata/derivatives103/pre/freesurfer/fsaverage6
export FS_LICENSE

singularity exec \
  -B $BASEDIR:/idata
  -c \
  "$IMG" \
  xvfb-run @SUMA_Make_Spec_FS -NIFTI -no_ld \
    -inflate 10 -inflate 20 -inflate 30 -inflate 40 -inflate 50 -inflate 60 -inflate 70 \
    -inflate 80 -inflate 90 -inflate 100 -inflate 120 -inflate 150 \
    -inflate 200 \
    -sid $SUBJ -fspath $FSPATH
