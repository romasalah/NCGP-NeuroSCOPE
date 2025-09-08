#!/bin/bash

SCRIPT="run-glm-nohpal-bonna-submit.slurm"

for SUBID in ../../data/sub-*; do
    SUBID=$(basename "$SUBID")
    SUBID="${SUBID##*\-}"
	echo "Submitting job for sub-"$SUBID""
    	sbatch "$SCRIPT" "$SUBID"
	echo ""
done
