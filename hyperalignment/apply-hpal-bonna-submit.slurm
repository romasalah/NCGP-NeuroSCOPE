#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --account=ag_cens_schultz
#SBATCH --cpus-per-task=32
#SBATCH --mem=32000
#SBATCH -vvv
BASEDIR="/home/jschultz/Castello_2021/scripts/01hyperalignment"
SCRIPT="run-hpal-singularity.sh"
CMD="$BASEDIR/$SCRIPT $1"
srun bash $CMD