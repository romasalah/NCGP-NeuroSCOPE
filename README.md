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
	
## Disclaimers
	- Some matlab code from Tsantani et al. 2019, Castello et al. 2021.
	- External libraries included are; CosomoMVPA v1.1.0, Surfing toolbox v0.6, and Decoding toolbox v3.997.
	- Helper functions tsv_read.m (https://www.mathworks.com/matlabcentral/fileexchange/32782-tsvread-importing-tab-separated-data), parfor_progressbar.m (https://www.mathworks.com/matlabcentral/fileexchange/53773-parfor_progressbar)