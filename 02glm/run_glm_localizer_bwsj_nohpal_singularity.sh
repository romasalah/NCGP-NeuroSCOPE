#!/bin/bash -ex

BASEDIR=/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG
BASEDIR_IN=/idata
IMG="/mnt/c/Users/CENs-Admin/Documents/Omar/Castello_2021/singularity/neurodocker.img"
WORKDIR=$BASEDIR_IN/_workdirs/glm
WORKDIR_out=$BASEDIR/_workdirs/glm
DATADIR=$BASEDIR_IN/data
FMRIPREPDIR=$BASEDIR_IN/derivatives103
PYTHON_WRAP=/opt/conda2/envs/neuro27/bin/python
NCORES=4


HEMI="$1"
MODELSFX='localizer-nohpal-bwsj5'
OUTDIR=$BASEDIR_IN/derivatives103/glm-"$MODELSFX"
WORKDIR="$WORKDIR"-locbw"$HEMI"ffa
OUTDIR_out=$BASEDIR/derivatives103/glm-"$MODELSFX"
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
       --run-files $FMRIPREPDIR/*/fmriprep/sub-*/*/*/*localizer*fsaverage6*$HEMI*.gii \
       --confound-files $FMRIPREPDIR/*/fmriprep/sub-*/*/*/*localizer*.tsv \
       --event-files $DATADIR/*/sub-*/*/*/*localizer*_events.tsv \
       -w $WORKDIR \
       -o $OUTDIR \
       --output-template bwsj_task-localizer_space-fsaverage6_hemi-"$HEMI"_  \
       -n $NCORES \
       $CMD"

singularity run --writable \
  -B $BASEDIR:/idata \
  -e \
  "$IMG" \
  $PYTHON_WRAP $CMD
