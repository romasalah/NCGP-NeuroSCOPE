# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023
Refactored on Aug 27 2025
Python 2.7 compatible
@author: Omar S. Ahmed
"""
import os
import argparse

def main(curhemi):
    print("Inside")
    preprocscript = '/idata/scripts/01hyperalignment/apply_hpal_singularity.sh'
    participants = [
        "004", "005", "006", "007", "008", "010", "011",
        "012", "013", "015", "016", "017",
        "019", "020", "021", "022", "023", "024"
    ]
    for participant_label in participants:
        wslcmd = 'python {preproc} {pid} {hemi}'.format(
            preproc=preprocscript,
            pid=participant_label,
            hemi=curhemi
        )
        print(wslcmd)
        os.system(wslcmd)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Run hyperalignment preprocessing for specified hemisphere."
    )
    parser.add_argument(
        "--curhemi",
        type=str,
        choices=["L", "R"],
        default="R",
        help="Hemisphere to process (L or R)."
    )
    args = parser.parse_args()
    main(args.curhemi)
