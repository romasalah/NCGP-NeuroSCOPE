# NCGP-NeuroSCOPE

## General information
	- The code is written to run on windows (minimum windows 10).
	- This analysis produces an enouromous amount of data (more than 10 Terabytes). It's recommended to run the analysis on an NTFS-formatted partition on a Solid State Drive (SSD) **with file compression enabled**
	
### Minimum Hardware requirements
	- 64 GB RAM (required to run MATLAB operations in parallel)
	- 1 TB virtual RAM (page file) on an SSD.
	- 2 TB SSD drive (for data) and 1 TB SSD (for virtual RAM).

## Expected dataset
	- Download the dataset from openneuro.org ().
	- The expected data is preprocessed with fMRIprep 1.0.3 and structured in BIDS format.

## Expected dataset structure (After Analysis)

    ├───data					# root folder
        ├───derivatives     	# Contains all datasets derived from the Original dataset.
        │   ├───fmriprep		# Preprocessed dataset, the starting point of the analysis.
        │   ├───freesurfer  	# Constructed surface using freesurfer.
        │   │   └───fsaverage6		# We included fsaverage6 surface only.
        │   │       ├───SUMA			# fsaverage6 brain surfaces converted to AFNI/SUMA format.
        │   ├───hpal			# 
        │   │   ├───SPM_GLM
        │   │   │   ├───group
        │   │   │   │   └───fmriprep
        │   │   │   │       ├───task-faces_ses-02_hemi-L_smooth-S0
        │   │   │   │       ├───task-faces_ses-02_hemi-R_smooth-S0
        │   │   │   │       ├───task-faces_ses-03_hemi-L_smooth-S0
        │   │   │   │       ├───task-faces_ses-03_hemi-R_smooth-S0
        │   │   │   ├───sub-004
        │   │   │   │   └───fmriprep
        │   │   │   │       ├───task-faces_ses-02_hemi-L_smooth-S0_onsets-face
        │   │   │   │       ├───task-faces_ses-02_hemi-R_smooth-S0_onsets-face
        │   │   │   │       ├───task-faces_ses-03_hemi-L_smooth-S0_onsets-face
        │   │   │   │       └───task-faces_ses-03_hemi-R_smooth-S0_onsets-face
        │   │   │   ├───sub-005 to sub-024
        │   ├───hpalfunc		# Contains Preprocessed files after mapping to a shared hyperalignment space
        │   │   ├───sub-004			# There should be a folder for each subject
        │   │   │   ├───ses-01			# For each session, there is a 4D surface dataset (in NIML format) for each run.
        │   │   │   │   └───func
        │   │   │   ├───ses-02
        │   │   │   │   └───func
        │   │   │   │       └───volumetric # in the sessions that involved the task "faces", each 4D NIML surface datasets are projected to the volumetric space of fsaverage6 then extracted to a series of 3D volumes.
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
        │   └───SPM_GLM
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
## Disclaimers
	- Some matlab code from Tsantani et al. 2019, Castello et al. 2021.
	- External libraries included are; CosomoMVPA v1.1.0, Surfing toolbox v0.6, and Decoding toolbox v3.997.
	- Helper functions tsv_read.m (https://www.mathworks.com/matlabcentral/fileexchange/32782-tsvread-importing-tab-separated-data), parfor_progressbar.m (https://www.mathworks.com/matlabcentral/fileexchange/53773-parfor_progressbar)