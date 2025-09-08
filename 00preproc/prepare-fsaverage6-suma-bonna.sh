#!/bin/bash -ex

BASEDIR=/home/jschultz/NCPG
IMG=/home/jschultz/Castello_2021/scripts/fmriprep-1.0.3.simg
FS_LICENSE=/idata/scripts/00preproc/license.txt
FSrelpath=derivatives103/freesurfer/fsaverage6
export FS_LICENSE

singularity exec   -B $BASEDIR:/idata "$IMG"   xvfb-run @SUMA_Make_Spec_FS -NIFTI -no_ld     -inflate 10 -inflate 20     -inflate 30 -inflate 40 -inflate 50 -inflate 60 -inflate 70     -inflate 80 -inflate 90 -inflate 100 -inflate 120 -inflate 150     -inflate 200     -sid fsaverage6 -fspath /idata/$FSrelpath
singularity exec   -B $BASEDIR:/idata /home/jschultz/Castello_2021/scripts/fmriprep-1.0.3.simg  xvfb-run  /idata/scripts/00preproc/make-maskmedial-fsaverage6.sh
