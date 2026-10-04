#!/bin/bash

SCRIPT="apply-hpal-bonna-submit.slurm"

for SUBID in ../../data/sub-*; do
    SUBID=$(basename "$SUBID")
    SUBID="${SUBID##*\-}"
	echo "Submitting job for sub-"$SUBID""
    	sbatch "$SCRIPT" "$SUBID"
	echo ""
done
