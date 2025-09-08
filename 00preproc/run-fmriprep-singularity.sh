#!/bin/bash -ex
IMGNAME="fmriprep-22.1.1.simg"
BASEDIR=/home/jschultz/NCPGS1
IMG=/home/jschultz/Castello_2021/scripts/$IMGNAME
WORKDIR=$(readlink -f $BASEDIR/workdir)
TMPDIR=$WORKDIR/tmp
DATADIR=$BASEDIR/data
OUTDIR=$BASEDIR/derivatives2211
FS_LICENSE=$BASEDIR/scripts/00preproc/license.txt

NCORES=32

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

singularity run  \
  -B "$WORKDIR":/work \
  -B "$DATADIR":/data:ro \
  -B "$OUTDIR":/out \
  -e \
  "$IMG" \
  /data /out participant \
  --bold2t1w-dof 6 \
  --output-space fsaverage6 T1w \
  --nthreads "$NCORES" \
  --omp-nthreads 32 \
  --fs-license-file "$FS_LICENSE" \
  --participant-label "$1" \
  -w /work
