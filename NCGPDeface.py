#runs only on python 3
import os
bids_dir = 'E:\\Omar\\NCPG\\data'
runcmd=f"docker run -i --rm -v {bids_dir}:/bids_dataset peerherholz/bidsonym  /bids_dataset  group --deid mri_deface --brainextraction bet --bet_frac 0.5"
print(runcmd)