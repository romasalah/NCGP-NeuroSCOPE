# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""

if __name__=="__main__":
    import os
    main_dir="/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG/"
    script0='scripts/02glm/run_glm_blockrun_singularity.sh'
    script = main_dir + script0
    Participants_list=["001"]
    tasklist=["faces"]
    session="pre"
    sesslist=["pre","post"]
    for currenttask in tasklist:
        for participant_dash_label in Participants_list:
            for cursess in sesslist:
                wslcmd='wsl ' + script + ' ' + participant_dash_label + '  fsaverage6 ' + currenttask + ' ' + cursess
                print(wslcmd)
                os.system(wslcmd)

