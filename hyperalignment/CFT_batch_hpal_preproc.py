# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""

if __name__=="__main__":
    import os
    # from bids import BIDSLayout
    import shutil
    # #User inputs:
    # #Initialize BIDSLayout
    BIDSdir_win=r"D:\Omar\NCGP\data"
    # layout = BIDSLayout(BIDSdir_win , derivatives=True)
    # # Get list of all relevant files
    # files_to_rename = layout.get(suffix='timeseries', task='faces', extension='tsv', return_type='file')
    # # Iterate through the list and rename
    # for old_file_path in files_to_rename:
    #     # Extracting the components of the old filename
    #     original_file_name = os.path.basename(old_file_path)
    #     original_file_path = os.path.dirname(old_file_path)
    #     fullfname=os.path.join(original_file_path, original_file_name)
    #     # Duplicate the file with "hemi-R_confounds" suffix
    #     hemi_r_file_name = original_file_name.replace("desc-confounds_timeseries", "hemi-R_confounds")
    #     hemi_r_file_path = os.path.join(original_file_path, hemi_r_file_name)
    #     shutil.copy2(fullfname, hemi_r_file_path)
    #
    #     # Duplicate the file with "hemi-L_confounds" suffix
    #     hemi_l_file_name = original_file_name.replace("desc-confounds_timeseries", "hemi-L_confounds")
    #     hemi_l_file_path = os.path.join(original_file_path, hemi_l_file_name)
    #     shutil.copy2(fullfname, hemi_l_file_path)
    # Settings
    runmode='wsl'
    main_dir="/mnt/f/NCGP/data/"
    runpreproc='scripts/hyperalignment/run_preproc_hpal_singularity.sh'
    preprocscript = main_dir + runpreproc
    container="singularity"
    output_dash_spaces= "fsaverage6"
    Participants_list=["004", "005", "006", "007", "008","010", "011",
                       "012", "013", "015", "016", "019", "020", "021",
                       "023","024"]
    errorreport=[]
    for participant_dash_label in Participants_list:
        try:
            if runmode=='wsl':
                wslcmd='wsl ' + preprocscript + ' ' + participant_dash_label + ' ' + output_dash_spaces
                print(wslcmd)
                os.system(wslcmd)
            elif runmode=='singularity':
                singcmd="/opt/conda2/envs/neuro27/bin/python /idata/scripts/01hyperalignment/run_preproc_hpal.py --subject " +  participant_dash_label + " --task movie --fmriprep-dir /idata/fmriprep --work-dir /idata/_workdirs/hpalpreproc-budapest --output-dir /idata/derivatives/hpal-preproc --njobs 16 --space fsaverage6"
                os.system(singcmd)
            curstatus='passed'
        except Exception as curstatus:
            errorreport.append([participant_dash_label, str(curstatus)])
    print(errorreport)
    for pt in Participants_list:
        cursub= "sub-" + pt
        src_dir=os.path.join(BIDSdir_win, 'hpal-preproc', cursub)
        dest_dir=os.path.join(BIDSdir_win, 'derivatives', 'fmriprep', cursub, 'ses-01','func')
        # List all files in the source directory
        files = [f for f in os.listdir(src_dir) if os.path.isfile(os.path.join(src_dir, f))]
        # Copy each file to the destination directory
        for file_name in files:
            shutil.copy(os.path.join(src_dir, file_name), os.path.join(dest_dir, file_name))
