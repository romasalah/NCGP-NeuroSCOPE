# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""

if __name__=="__main__":
    #User inputs:
    # Settings
    runmode='wsl'
    import os
    main_dir="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG/"
    runpreproc='scripts/03mvpa/bwsj/run_sl_bwsbj_fsaverage6_singularity.sh'
    script = main_dir + runpreproc
    hs_list=["L", "R"]
    errorreport=[]
    targetlist=['identity']
    tasklist=["faces"]
    modellist=["deconvolve", "remlfit"]
    permutelist=["0","100"]
    sessionlist=["pre", "post"]
    for currenttask in tasklist:
        for cur_hs in hs_list:
            for currenttgt in targetlist:
                for curmodel in modellist:
                    for cursess in sessionlist:
                        for curperm in permutelist:
                            wslcmd='wsl ' + script + ' ' + currenttgt + ' ' + currenttask + ' '\
                                   + cur_hs + ' ' + curmodel + ' ' + curperm + ' ' + cursess
                            print(wslcmd)
                            os.system(wslcmd)

