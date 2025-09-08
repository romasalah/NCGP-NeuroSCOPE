# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""
if __name__=="__main__":
    import os
    main_dir="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG/"
    runpreproc='scripts/02glm/run_glm_localizer_bwsj_singularity.sh'
    script = main_dir + runpreproc
    container="singularity"
    Participants_list=["001"]
    hs_list=["R"]
    for cur_hemisphere in hs_list:
        wslcmd='wsl ' + script + ' ' + cur_hemisphere
        print(wslcmd)
        os.system(wslcmd)


