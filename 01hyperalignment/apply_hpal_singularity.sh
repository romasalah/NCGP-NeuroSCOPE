#!/bin/bash -ex

# Parameter 1 = Basedir in wsl (example /mnt/e/NCGP)
# Parameter 2 = hemisphere (L or R)
# Parameter 2 = number of batches (default 0)
# Parameter 3 = batch index (default 1)

IMGNAME="neurodockerV5a.img"
BASEDIR=$1
IMG=$BASEDIR/singularity/$IMGNAME
WORKDIR=$BASEDIR/_workdirs/hpalfunc
TMPDIR=$WORKDIR/tmp
DATADIR=$BASEDIR/derivatives/fmriprep
HOME_DIR_INSIDE=/idata
FSDIR=$HOME_DIR_INSIDE/derivatives/freesurfer
OUTDIR=$BASEDIR/derivatives/hpal-func
OUTDIR_IN=$HOME_DIR_INSIDE/derivatives/hpal-func
MAPPERDIR=$HOME_DIR_INSIDE/derivatives/hpal
FS_LICENSE=$BASEDIR/scripts/00preproc/license.txt
FMRIPREPDIR=$HOME_DIR_INSIDE/derivatives/fmriprep
PYTHONWRAP=/opt/conda2/envs/neuro27/bin/python

NCORES=4

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

SUBJ=sub-"$2"
HEMI="$3"

if [ $HEMI == L ]; then
    HEMIFS=lh
else
    HEMIFS=rh
fi

CMD="$HOME_DIR_INSIDE/scripts/01hyperalignment/apply_hpal.py \
    --inputs $FMRIPREPDIR/$SUBJ/ses-*/func/*"$HEMI"*.func.gii \
    --mask $FSDIR/fsaverage6/SUMA/"$HEMIFS".maskmedial.niml.dset \
    --mapper $MAPPERDIR/$SUBJ/"$SUBJ"_task-movie_space-fsaverage6_hemi-"$HEMI"_target-hpal_mapper.h5 \
    --reverse $MAPPERDIR/$SUBJ/"$SUBJ"_task-movie_space-fsaverage6_hemi-"$HEMI"_target-hpal_mapper.h5 \
    --output-dir $OUTDIR_IN \
    --nproc $NCORES"

singularity run --writable \
  -B $BASEDIR:/idata \
  -e \
  "$IMG" \
  $PYTHONWRAP $CMD
