#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --account=ag_cens_schultz
#SBATCH --cpus-per-task=32
#SBATCH --mem=32000
#SBATCH -vvv
BASEDIR="/home/jschultz/NCPG/scripts/00preproc"
SCRIPT="make-maskmedial-fsaverage6.sh"
CMD="$BASEDIR/$SCRIPT"
srun bash $CMD