#!/bin/bash -ex
set -eu

IMGNAME="neurodocker_2a.img"
BASEDIR=/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG
FS_LICENSE=$BASEDIR/scripts/00preproc/license.txt
IMG=$BASEDIR/singularity/$IMGNAME
WORKDIR_out=$BASEDIR/_workdirs/hpalpreproc
TMPDIR_out=$WORKDIR_out/tmp
OUTDIR_out=$BASEDIR/derivatives/hpal
PYTHONWRAP=/opt/conda2/envs/neuro27/bin/python
BASEDIR_INSIDE=/idata
NCORES=32
export FS_LICENSE

if [ ! -d "$WORKDIR_out" ]; then
   echo "Creating $WORKDIR_out"
   mkdir -p "$WORKDIR_out"
fi

if [ ! -d "$TMPDIR_out" ]; then
   echo "Creating $TMPDIR_out"
   mkdir -p "$TMPDIR_out"
fi

if [ ! -d "$OUTDIR_out" ]; then
   echo "Creating $OUTDIR_out"
   mkdir -p "$OUTDIR_out"
fi

CMD="$BASEDIR_INSIDE/scripts/01hyperalignment/run_hpal.py --input-dir $BASEDIR_INSIDE/derivatives/hpal-preproc --hemi $1  --fsdir  $BASEDIR_INSIDE/derivatives/freesurfer -n $NCORES  -o  $BASEDIR_INSIDE/derivatives/hpal"


singularity run --writable \
  -B $BASEDIR:/idata \
  -B "$TMPDIR_out":/tmp \
  -e \
  "$IMG" \
  $PYTHONWRAP $CMD
