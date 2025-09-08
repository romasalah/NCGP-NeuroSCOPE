#!/bin/bash -ex
# THIS SCRIPT RUNS BETWEEN SUBJECT DECODING
# ON DATA THAT HAS BEEN ONLY ANATOMICALLY ALIGNED
TARG=$1
TASK=$2
HEMI=$3
DECON=$4
PERMUTE=$5
SESS=$6
BASEDIR="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG"
IMG="/mnt/c/Users/CENs-Admin/Documents/Omar/Castello_2021/singularity/neurodocker.img"
FMRIPREPDIR=/idata/derivatives103/"$SESS"/fmriprep
FSDIR=/idata/derivatives103/"$SESS"/freesurfer
GLMDIR=/idata/derivatives103/"$SESS"/glm-blockrun-nosmooth
PYTHON_WRAP=/opt/conda2/envs/neuro27/bin/python
NCORES=22

programname=$0
function usage {
    echo "usage: $programname target task hemi [deconvolve|remlfit] [permute] [session]"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi


if [ $HEMI == L ]; then
  H=lh
else
  H=rh
fi

if [ -z "$DECON" ]; then
    DECON=deconvolve
fi

OUTDIR=/idata/derivatives103/"$SESS"/slclfbwsbj-blockrun-"$DECON"-fsaverage6-"$SESS"

INPUT="$GLMDIR"/sub-*/sub-*_task-"$TASK"_space-fsaverage6_hemi-"$HEMI"_"$DECON"-block.niml.dset
OUTPUT="$OUTDIR"/bwsbj_task-"$TASK"_space-fsaverage6_hemi-"$HEMI"_target-"$TARG"_sl

if [ ! -z $PERMUTE ]; then
    printf -v P "%03d" $PERMUTE
    OUTPUT="$OUTPUT"_"$P"ip
    CMD="--permute $PERMUTE"
fi
OUTPUT="$OUTPUT".niml.dset

CMD="/idata/scripts/03mvpa/bwsj/run_sl_bwsbj.py \
     -i $INPUT \
     -t $TARG \
     -o $OUTPUT \
     -n $NCORES \
     -f $FSDIR \
     $CMD"


singularity run --writable \
-B $BASEDIR:/idata \
-e \
"$IMG" \
"$PYTHONWRAP" "$CMD"
