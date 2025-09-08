#!/bin/bash -ex
TARG=$1
HEMI=$2
SESS=$3
DECON=$4
BASEDIR="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG"
IMG="/mnt/c/Users/CENs-Admin/Documents/Omar/Castello_2021/singularity/neurodocker.img"
FMRIPREPDIR=/idata/derivatives103/$SESS/fmriprep
FSDIR=/idata/derivatives103/$SESS/freesurfer
PYTHON_WRAP=/opt/conda2/envs/neuro27/bin/python
NCORES=1

TASK="faces"

OUTDIR=/idata/derivatives103/$SESS/slclfbwsbj-blockrun-"$DECON"-fsaverage6-"$SESS"
INPUT="$OUTDIR"/bwsbj_task-"$TASK"_space-fsaverage6_hemi-"$HEMI"_target-"$TARG"_sl_000ip.niml.dset
PERMUTED="$OUTDIR"/bwsbj_task-"$TASK"_space-fsaverage6_hemi-"$HEMI"_target-"$TARG"_sl_100ip.niml.dset
OUTPUT="$OUTDIR"/bwsbj_task-"$TASK"_space-fsaverage6_hemi-"$HEMI"_target-"$TARG"_sl


CMD="/idata/scripts/04stat/run_permtest_bootstrap.py \
     -i $INPUT \
     -p $PERMUTED \
     --prefix $OUTPUT \
     -n $NCORES \
     --nbootstraps 100000 \
     $CMD"


singularity run  \
-B $BASEDIR:/idata \
-e \
"$IMG" \
"$PYTHONWRAP" "$CMD"
