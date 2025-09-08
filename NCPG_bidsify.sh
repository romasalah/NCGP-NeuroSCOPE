#export PATH="$HOME/dcm2niix/build/bin/:$PATH"
#dcm2bids_scaffold -o /Volumes/EVO8602TB/NCPG/BIDS/NCPG_003/source/S1/BIDS
#echo "study imaging data" > dcm2bids_scaffold -o /Volumes/EVO8602TB/NCPG/BIDS/NCPG_003/source/S1/BIDS/README
#dcm2bids -d /Volumes/EVO8602TB/NCPG/BIDS/NCPG_003/source/S1 -p 003 -s 01 -c /Volumes/EVO8602TB/NCPG/BIDS/NCPG_003/source/S1/BIDS_configuration.json -o /Volumes/EVO8602TB/NCPG/BIDS/NCPG_003/source/S1/BIDS --forceDcm2niix
import os
session_list=[1]
ptnum_list=[9]
for pti in ptnum_list:
  subdir= "/Volumes/EVO8602TB/NCPG/BIDS/Main1/NCGP00" + str(pti) + "/NCGP00" + str(pti) + "_NCGP00" + str(pti)
  for cursess in session_list:
    sessname = "S" +str(cursess)
    sessdir= subdir + "/" + sessname
    bidsdir= sessdir + "/BIDS"
    os.execute( "dcm2bids_scaffold -o " + bidsdir)
    os.execute( "dcm2bids -d " + sessdir )

#dcm2bids_scaffold -o /Volumes/EVO8602TB/NCPG/BIDS/Main1/NCGP004/NCGP004_NCGP004/S1/BIDS
#dcm2bids -d /Volumes/EVO8602TB/NCPG/BIDS/Main1/NCGP004/NCGP004_NCGP004/S1 -p 004 -s 01 -c /Volumes/EVO8602TB/NCPG/BIDS/Main1/NCGP004/NCGP004_NCGP004/S1/BIDS_configuration.json -o /Volumes/EVO8602TB/NCPG/BIDS/NCPG_002/source/S2/BIDS --forceDcm2niix
#
#dcm2bids_scaffold -o /Volumes/EVO8602TB/NCPG/BIDS/NCPG_002/source/S3/BIDS
#echo "study imaging data" > /Volumes/EVO8602TB/NCPG/BIDS/NCPG_002/source/S3/BIDS/README
#dcm2bids -d /Volumes/EVO8602TB/NCPG/BIDS/NCPG_002/source/S3 -p 002 -s 03 -c /Volumes/EVO8602TB/NCPG/BIDS/NCPG_002/source/S3/BIDS_configuration.json -o /Volumes/EVO8602TB/NCPG/BIDS/NCPG_002/source/S3/BIDS --forceDcm2niix