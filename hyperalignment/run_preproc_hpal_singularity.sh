#!/bin/bash -ex
IMGNAME="neurodockerV5a.img"
BASEDIR=/mnt/f/NCGP/data
IMG=$BASEDIR/singularity/$IMGNAME
WORKDIR=_workdirs/hpalpreproc
TMPDIR=$WORKDIR/tmp
OUTDIR=/hpal-preproc
FS_LICENSE=/scripts/00preproc/license.txt
PYTHONWRAP=/opt/conda2/envs/neuro27/bin/python
HOME_DIR_INSIDE=/idata
NCORES=8

if [ ! -d "$BASEDIR/$WORKDIR" ]; then
   echo "Creating $WORKDIR"
   mkdir -p "$BASEDIR/$WORKDIR"
fi

if [ ! -d "$BASEDIR/$TMPDIR" ]; then
   echo "Creating $TMPDIR"
   mkdir -p "$BASEDIR/$TMPDIR"
fi

if [ ! -d "$BASEDIR/$OUTDIR" ]; then
   echo "Creating $OUTDIR"
   mkdir -p "$BASEDIR/$OUTDIR"
fi

CMD="$HOME_DIR_INSIDE/scripts/hyperalignment/run_preproc_hpal.py \
    -s $1 --task movie \
    --fmriprep-dir $HOME_DIR_INSIDE/derivatives/fmriprep \
    --work-dir $HOME_DIR_INSIDE/$WORKDIR \
    --output-dir $HOME_DIR_INSIDE/$OUTDIR \
    --njobs $NCORES"
echo $CMD
if [ ! -z "$2" ]; then
    CMD="$CMD --space $2"
fi

sudo -u censfmriteam -p 123456 singularity run -w  \
  -B $BASEDIR:/idata \
  -e \
  "$IMG" \
  $PYTHONWRAP $CMD