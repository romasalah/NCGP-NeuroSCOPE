# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""

if __name__=="__main__":
    import os
    main_dir="/mnt/e/Omar/NCPG/"
    runpreproc='scripts/01hyperalignment/apply_hpal_singularity.sh'
    preprocscript = main_dir + runpreproc
    Participants_list=[ "004", "005","006","007","008", "010","011",
                        "012","013", "015","016", "017",
                        "019", "021", "022", "023", "024"]
    Participants_list=[ "020"]
    hemilist=["R"]
    for participant_dash_label in Participants_list:
        for curhemi in hemilist:
            wslcmd='wsl ' + preprocscript + ' ' + participant_dash_label + ' ' + curhemi
            print(wslcmd)
            os.system(wslcmd)

