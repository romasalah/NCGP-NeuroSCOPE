#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --account=ag_cens_schultz
#SBATCH --cpus-per-task=32
#SBATCH --mem=32000
#SBATCH -vvv
#SBATCH --time=10:00:00
BASEDIR="/home/jschultz/NCPGS1/scripts/00preproc"
SCRIPT="run-fmriprep-singularity.sh"
CMD="$BASEDIR/$SCRIPT $1"
srun bash $CMD
