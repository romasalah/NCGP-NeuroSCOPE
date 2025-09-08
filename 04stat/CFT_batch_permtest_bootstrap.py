# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""

if __name__=="__main__":
    #User inputs:
    # Settings
    import os
    main_dir="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG/"
    runpreproc='scripts/04stat/run_permtest_bwsbj_bootstrap_singularity.sh'
    script = main_dir + runpreproc
    hs_list=["L", "R"]
    targetlist=['identity']
    sessionlist=["pre", "post"]
    modellist=["deconvolve","remlfit"]
    for cur_hs in hs_list:
        for currenttgt in targetlist:
            for cursess in sessionlist:
                for curmodel in modellist:
                    wslcmd='wsl ' + script + ' ' + currenttgt + ' ' + cur_hs + ' ' + cursess + ' ' + curmodel
                    print(wslcmd)
                    os.system(wslcmd)

