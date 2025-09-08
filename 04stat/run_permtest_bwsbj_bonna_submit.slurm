#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --account=ag_cens_schultz
#SBATCH --cpus-per-task=32
#SBATCH --mem=32000
#SBATCH --time=2-00:00:00
srun bash run_permtest_bwsbj_bonna.sh $1 $2 $3 $4 $5 $6
