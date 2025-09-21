# NCGP-NeuroSCOPE

## 1. General information

## 2. Minimum Hardware requirements & Software requirements
	- 64 GB RAM (required to run MATLAB operations in parallel)
	- 1 TB virtual RAM (page file) on an SSD.
	- 2 TB SSD drive (for data) and 1 TB SSD (for virtual RAM).
    - The code is written to run on windows (minimum windows 10).
	- This analysis produces an enoromous amount of data (more than 10 Terabytes). It's recommended to run the analysis on an NTFS-formatted partition on a Solid State Drive (SSD) **with file compression enabled**
	- Matlab Parrallel processing toolbox (for a much faster performance). Setup your default parallel pool to have the maximum numbr of workers your processor can provide.
    - JASP for windows (version 0.18.1) available under the link: https://github.com/jasp-stats/jasp-desktop/releases/tag/v0.18.1

## 3. Acquire the datasets and analysis code
	- Download the dataset from openneuro.org ().
	- Download this Repository and place it in the same root folder as the folder named "data".
    - Download the Singularity image which contains the AFNI/SUMA code and place it in a folder named "singularity" and place it in the same root folder.
    - make up to 17 copies of the singularity image and change the names into neurodockerV5{a to q}, so you will have the files neurodockerV5a.img to 
    neurodockerV5q.img in the singularity folder.
    

## 4. Dataset structure (Before the analysis)
    Your data and code must be in the following structure for the analysis to work well.

    ├───data
        ├───derivatives             # Contains fMRI datasets
        │   ├───fmriprep                # Preprocessed dataset in fsaverage6 space
        │   ├───freesurfer              # Constructed surface using freesurfer, We included fsaverage6 surface only.
        │   │   └───fsaverage6		    
        │   │        └──SUMA			     # fsaverage6 brain surfaces converted to AFNI/SUMA format.
        │   ├───hpal                    # Contains hyperalignment projection maps which transform the dataset in root\derivatives\fmriprep into the dataset in root\derivatives\hpalfunc
        │   │    └──sub-004 to sub-024      # each subject folder contains two H5 maps (~700MB each).
        │   ├───hpalfunc                # Contains Preprocessed files after mapping to a shared hyperalignment space
        │   └──sub-004 to sub-024           # There should be a folder for each subject
        │   │   │   ├───ses-01                  # Inside each session folder, there is a 4D surface dataset (in NIML format) for each run.
        │   │   │   │   └───func
        │   │   │   ├───ses-02
        │   │   │   │   └───func
        │   │   │   └───ses-03
        │   │   │       └───func
        ├───BehavNCGP               # Contains behavioral dataset
        ├───scripts                 # Containts analysis code
        └───singularity             # Contains singularity image (neurodockerV5)


## 5. Analysis pipeline
    The main analysis script is NCGP_main_hpal.m. The analysis is divided into two steps:

    1. The first step includes; a) Projecting functional images to the shared hyperalignment space. b) Converting 4D NIML surface data into 3D
    volumetric NIFTI images. c) Calculating subject-level General Linear Models (GLMs).

    2. The second step includes; a) Defining searchlights, Converting GLMs beta and residual images into a surface
    projections. b) Calculating Linear Discriminant t-values (LDts). c) functions that test Hyothesis 1, 2, and 3.

    You should run the analysis in 2 steps. First specify the variable "Step=1" and run the function. then change
    the value to "Step=2" and run the function again. It's recommended that you run the function at Step=1 another
    time before switching to Step=2, so that you make sure that all necessary images are converted.

### 5.1 Analysis Starting Points
    There are 2 options to start the analysis from. you can either start from:

    1. Preprocessed dataset in the fsaverage6 space, located in the folder "root/derivatives/fmriprep". 
    In this case, you will have to apply the projection maps located in "root/derivatives/hpal"
    to the fmriprep dataset to regenerate the functional dataset projected to the shared space which
    will be found in "root/derivatives/hpalfunc". If you already downloaded the "hpalfunc" folder,
    please rename it first to "hpalfunc_original".

    2. Preprocessed dataset in the shared hyperalignment space, located in the folder 
    "root/derivatives/hpalfunc". In this case, you can skip the function "NCGP_hpal_map.m" and start
    by converting the surface based data into volumetric data using the function "NCGP_niml2nii.m".

### 5.2 Setting Script default paths and parameters
    1. open "data/scripts/NCGP_osdir.m" and edit the default path for the home directory (data folder)
    e.g homedir='F:\NCGP\data\';

### 5.3 Analysis scripts output
    After running the main analysis script (NCGP_main_hpal.m) to the end, the output will be as follows:
    1. Hypothesis 1: the script only prepares the data for a follow-up hypothesis testing. 
## 6. Results Visualization
    For viewing results using SUMA, you can:
        1. install AFNI on windows WSL1 (Problematic).
        2. install AFNI on another Mac or Linux PC and view the results on it.
        3. the best solution, install a linux distribution on VirtualBox for windows.
### 6.1 Visualising Hypothesis 1 results
	The MATLAB script NCGP_main_hpal.m outputs preprocessed behavioral data and exports it in tables, but it doesn't do hypothesis testing. To test for and visualize hypothesis 1 results, you need to open each one of the three included .jasp files using JASP software, then re-sync the data table to the exported table () which is in /{YourRootFolder}/BehavOutputs. The jasp files will update the analysis based on your data.

 ### 6.2 Visualising Hypothesis 2 results
 	Hypothesis 2 results are exported to /{YourRootFolder}/LDt/group/fmriprep/SPM_GLM/LDCdiff. The folder contains one figure for each searchlight, which significantly satisfies the alternate hypothesis (H1). The figure is structured as follows:
	1. Top row: 3D mesh of the brain surface showing the location of the searclight.
	2. Bottom left and center: 2D approximation of the difference between brain activity in this searchlight during each of the 8 conditions, each condtion is repesented as a dot, and the distances between the dots represent the difference in activitay pattern between the dots. The conditions are labelled either as AH (face perception of a humanities student) or as NAT (face perception of a Natural Science student). The left and center bottom plots represent the distance before and after the intervention, respectively.

## 7. Expected dataset structure (After the analysis)

    ├───data				# datasets folder
        ├───derivatives     	# Contains all datasets derived from the Original dataset.
        │   ├───fmriprep		    # Preprocessed dataset, the starting point of the analysis.
        │   ├───freesurfer  	    # Constructed surface using freesurfer.
        │   │   └───fsaverage6		    # We included fsaverage6 surface only.
        │   │       ├───SUMA			    # fsaverage6 brain surfaces converted to AFNI/SUMA format.
        │   ├───hpal			    # Contains hyperalignment projection maps which transform the dataset in root\derivatives\fmriprep into the dataset in root\derivatives\hpalfunc
        │   │   ├───SPM_GLM
        │   │   │   ├───group
        │   │   │   │   └───fmriprep
        │   │   │   │       ├───task-faces_ses-02_hemi-L_smooth-S0
        │   │   │   │       ├───task-faces_ses-02_hemi-R_smooth-S0
        │   │   │   │       ├───task-faces_ses-03_hemi-L_smooth-S0
        │   │   │   │       ├───task-faces_ses-03_hemi-R_smooth-S0
        │   │   │   ├───sub-004 to sub-024 each subject folder contains two H5 maps (~700MB each).
        │   ├───hpalfunc		    # Contains Preprocessed files after mapping to a shared hyperalignment space
        │   │   ├───sub-004			    # There should be a folder for each subject
        │   │   │   ├───ses-01		    	# For each session, there is a 4D surface dataset (in NIML format) for each run.
        │   │   │   │   └───func
        │   │   │   ├───ses-02
        │   │   │   │   └───func
        │   │   │   │       └───volumetric          # in the sessions that involved the task "faces", each 4D NIML surface datasets are projected to the volumetric space of fsaverage6 then extracted to a series of 3D volumes.
        │   │   │   └───ses-03
        │   │   │       └───func
        │   │   │           └───volumetric
        │   │   ├───sub-005 to sub-024 
        │   ├───LDC				# Contains the results of hypothesis 2 testing.
        │   │   └───group
        │   │       └───fmriprep
        │   │           └───SPM_GLM
        │   │               ├───hemi-L_mask-none # Whole-brain, left hemisphere results.
        │   │               ├───hemi-R_mask-none # Whole-brain, right hemisphere results.	
        │   │               └───LDCdiff
        │   └───SPM_GLM         # first level analysis: SPM-based Volumetric General Linear Model for each subject  
        │       ├───group
        │       │   └───fmriprep
        │       │       ├───task-faces_ses-02_hemi-L_smooth-S0
        │       │       ├───task-faces_ses-02_hemi-R_smooth-S0
        │       │       ├───task-faces_ses-03_hemi-L_smooth-S0
        │       │       ├───task-faces_ses-03_hemi-R_smooth-S0
        │       ├───sub-004
        │       │   └───fmriprep
        │       │       ├───task-faces_ses-02_hemi-L_smooth-S0_onsets-face
        │       │       ├───task-faces_ses-02_hemi-R_smooth-S0_onsets-face
        │       │       ├───task-faces_ses-03_hemi-L_smooth-S0_onsets-face
        │       │       └───task-faces_ses-03_hemi-R_smooth-S0_onsets-face
        │       ├───sub-005 to sub-024

## 8. Disclaimers
	- Some matlab code from Tsantani et al. 2019, Castello et al. 2021.
	- External libraries included are; CosomoMVPA v1.1.0, Surfing toolbox v0.6, and Decoding toolbox v3.997.
	- Helper functions tsv_read.m (https://www.mathworks.com/matlabcentral/fileexchange/32782-tsvread-importing-tab-separated-data), parfor_progressbar.m (https://www.mathworks.com/matlabcentral/fileexchange/53773-parfor_progressbar)

## 9. Todo
    - Hypothesis 1 testing using JASP, ready JASP files.
    - Hypothesis 2 & 3 results location and format.
    - Needed software and setup for hypothesis 2 results visualization.
    - Update and confirm the after-analysis data structure. 
