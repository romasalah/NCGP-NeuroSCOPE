#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --account=ag_cens_schultz
#SBATCH --cpus-per-task=32
#SBATCH --mem=32000
#SBATCH -vvv
BASEDIR="/home/jschultz/Castello_2021/scripts/00preproc"
SCRIPT="prepare-fsaverage6-suma-bonna.sh"
CMD="$BASEDIR/$SCRIPT"
srun bash $CMD