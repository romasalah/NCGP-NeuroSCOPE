#!/bin/bash -ex

IMGNAME="neurodockerV4c.img"
BASEDIR=/mnt/e/Omar/Omar/NCPG
BASEDIR_IN=/idata
IMG=$BASEDIR/singularity/$IMGNAME
WORKDIR=$BASEDIR_IN/_workdirs/glm
WORKDIR_out=$BASEDIR/_workdirs/glm
DATADIR=$BASEDIR_IN/data
FMRIPREPDIR=$BASEDIR_IN/fmriprep
HPALDIR=$BASEDIR_IN/fmriprep
PYTHON_WRAP=/opt/conda2/envs/neuro27/bin/python
EVENTDIR=$BASEDIR_IN/data
NCORES=1


HEMI="$1"
MODELSFX='localizer-bwsj5'
OUTDIR=$BASEDIR_IN/glm-"$MODELSFX"
WORKDIR="$WORKDIR"-locbw"$HEMI"ffa
OUTDIR_out=$BASEDIR/glm-"$MODELSFX"
TMPDIR=$WORKDIR/tmp
TMPDIR_out=$WORKDIR_out/tmp

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

CMD="/idata/scripts/02glm/run_glm_localizer_bwsj.py \
       --run-files $HPALDIR/sub-0*/ses-*/func/*localizer*$HEMI.func.niml.dset \
       --confound-files $HPALDIR/sub-0*/ses-*/func/*localizer*_confounds.tsv \
       --event-files $HPALDIR/sub-0*/ses-*/func/*localizer*_events.tsv \
       -w $WORKDIR \
       -o $OUTDIR \
       --output-template bwsj_task-localizer_space-hpalsid000005fsaverage_hemi-"$HEMI"_ \
       -n $NCORES \
       $CMD"

singularity run --writable \
  -B $BASEDIR:/idata \
  -e \
  "$IMG" \
  $PYTHON_WRAP $CMD
