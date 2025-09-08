#!/bin/bash -ex

# This script runs the GLM using BLOCK function with betas estimated within
# each run.
# $1 is subject
# $2 is space
# $3 is task
# $4 is session
# $5 is smoothing, if any
sessid=$4
BASEDIR="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG"
IMG="/mnt/c/Users/CENs-Admin/Documents/Omar/Castello_2021/singularity/neurodocker.img"
WORKDIR=$BASEDIR/derivatives103/"$sessid"/_workdirs/glm
TMPDIR=$WORKDIR/tmp
HOME_DIR_INSIDE=/idata
PYTHON_WRAP=/opt/conda2/envs/neuro27/bin/python
FMRIPREPDIR=$BASEDIR/derivatives103/"$sessid"/fmriprep
NCORES=3


if [ ! -z "$5" ]; then
  CMD="--smooth $5"
  SFX="$5"mm
else
  SFX="nosmooth"
fi
MODEL="'BLOCK(1.6,1)'"
MODELSFX='blockrun'
OUTDIR=$BASEDIR/derivatives103/"$sessid"/glm-"$MODELSFX"
OUTDIRIN=$HOME_DIR_INSIDE/derivatives103/"$sessid"/glm-"$MODELSFX"
WORKDIR="$WORKDIR"-"$MODELSFX"-"$2"-"$SFX"
OUTDIR="$OUTDIR"-"$SFX"
WORKDIRIN=$HOME_DIR_INSIDE/derivatives103/"$sessid"/_workdirs/glm-"$sessid"
WORKDIRIN="$WORKDIRIN"-"$MODELSFX"-"$2"-"$SFX"
OUTDIRIN="$OUTDIRIN"-"$SFX"
TMPDIR=$WORKDIR/tmp

if [ ! -d "$WORKDIR" ]; then
   echo "Creating $WORKDIR"
   mkdir -p "$WORKDIR"
fi

if [ ! -d "$TMPDIR" ]; then
   echo "Creating $TMPDIR"
   mkdir -p "$TMPDIR"
fi

if [ ! -d "$OUTDIR" ]; then
   echo "Creating $OUTDIR"
   mkdir -p "$OUTDIR"
fi

MASK=$BASEDIR/derivatives103/glm-localizer-nohpal-bwsj5/sub-"$1"/sub-"$1"_space-"$2"_unionbrainmask.nii.gz

if [ -f "$MASK" ] && [ "$2" != "fsaverage6" ] ; then
  echo "Using mask $MASK"
  CMD="$CMD --mask $MASK"
fi

CMD="$HOME_DIR_INSIDE/scripts/02glm/run_glm_model.py \
       -d /idata/data/$sessid \
       -f /idata/derivatives103/$sessid/fmriprep \
       -w $WORKDIRIN \
       -o $OUTDIRIN \
       -s $1 \
       -p $2 \
       --task $3 \
       --estimate-within-run \
       -n $NCORES \
       --model $MODEL \
       $CMD"

singularity run --writable \
  -B $BASEDIR:/idata \
  -e \
  "$IMG" \
  "$PYTHON_WRAP $CMD"
