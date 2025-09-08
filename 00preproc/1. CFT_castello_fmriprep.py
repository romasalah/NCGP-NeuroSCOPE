# -*- coding: utf-8 -*-
"""
Created on Sat Jan 21 23:41:40 2023

@author: CENs-Admin
"""

def parse_input(mem, nthreads, participant_dash_label, output_dash_spaces,bold2t1w_dash_dof,w, omp_dash_nthreads, TEMPLATEFLOW_HOME, FS_LICENSE):
    # Parsing Input
    mem_mb=(mem*1000)-5000 #reduce some memory for buffer space during pre-processing
    a_dict=dict()
    for variable in ["nthreads", "mem_mb", "participant_dash_label", "output_dash_spaces", "bold2t1w_dash_dof", "w", "omp_dash_nthreads"]:
        a_dict[variable] = eval(variable)   
    export_vars=dict()
    for variable in ["TEMPLATEFLOW_HOME", "FS_LICENSE"]:
        export_vars[variable] = eval(variable)
    if  container=="docker":
        containercmd="fmriprep-docker"
    elif container =="singularity":
        containercmd=" unset PYTHONPATH; singularity run"
           
    #Join the final command string
    export_str= join_keyval(export_vars, True, "", True)
    export_cont_str=export_str + " & " + containercmd + " " + bids_dir + " " + output_dir + " "\
        + analysis_level +" "
    export_cont_params_str= join_keyval(a_dict, False, export_cont_str, False, True)
    finalcmdstr=export_cont_params_str + added_params
    return finalcmdstr
    
def join_keyval(vardict, exportvar=False, keyvalstr="", sepcommands= False, isparam=False, omitkey=False):
    sepstr=" "
    expstr=""
    equalsstr=" "
    isparamstr=""
    if isparam==True:
        isparamstr="--"
    if sepcommands==True:
        sepstr= "& "
    if exportvar == True:
        expstr= "set "
        equalsstr="="
    for curkey in vardict:
        curval=vardict[curkey]
        valtype=type(curval)
        if valtype==int:
            curvalstr=str(curval) + " "
        elif valtype==str:
            curvalstr= curval + " "
        curkeystr= curkey.replace("_dash_","-")
        if omitkey==True:
            curkeystr= ""
        keyvalstr=keyvalstr + expstr + isparamstr + curkeystr + equalsstr + curvalstr + sepstr
    keyvalstr=keyvalstr[:-2]
    return keyvalstr


if __name__=="__main__":
    #User inputs:
    # Settings
    import os
    bids_dir="C:\\Users\\CENs-Admin\\Documents\\Omar\\Castello_2021\\data"
    output_dir="C:\\Users\\CENs-Admin\\Documents\\Omar\\Castello_2021\\derivatives103"
    w="C:\\Users\\CENs-Admin\\Documents\\Omar\\Castello_2021\\workdir"
    analysis_level="participant"
    container="docker" #docker or singularity
    nthreads=4 #number of processors
    mem= 20 #gb

    TEMPLATEFLOW_HOME="HOME/.cache/templateflow"
    FS_LICENSE="C:\\Users\\CENs-Admin\\Documents\\Omar\\Castello_2021\\scripts\\00preproc\\license.txt"
    output_dash_spaces= "T1w fsaverage"
    bold2t1w_dash_dof=9
    omp_dash_nthreads=2
    added_params = " --no-tty --error-on-aroma-warnings --low-mem --resource-monitor"
    Participaants_list=["sid000005","sid000007","sid000009","sid000013","sid000024","sid000025","sid000030",
                        "sid000034","sid000050","sid000055","sid000114","sid000134","sid000278"]
    Participaants_list = ["sid000050"]
    errorreport=[]
    for participant_dash_label in Participaants_list:
        try:
            #parse input
            finalcmdstr= parse_input(mem, nthreads, participant_dash_label, output_dash_spaces, bold2t1w_dash_dof,w,omp_dash_nthreads, TEMPLATEFLOW_HOME, FS_LICENSE)
            print(finalcmdstr)
            #run fMRIprep
            os.system(finalcmdstr)
            curstatus='passed'
        except Exception as curstatus:
            errorreport.append([participant_dash_label, str(curstatus)])
    print(errorreport)

