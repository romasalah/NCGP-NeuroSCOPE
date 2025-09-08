import os
BIDS_root=r"E:\Omar\NCPG\data"
output_dir=r"E:\Omar\NCPG\MRIQC"
ptlbls=[ "004", "006",
 "008", "009","010","011",
 "012","013","014","015",
 "016", "017", "019", "021", "022", "023", "024"]
lbls=""
for sub in ptlbls:
    cmd="docker run -i --rm --memory=\"40gb\" -v " + BIDS_root + ":/data:ro -v " + output_dir + ":/out nipreps/mriqc:latest /data /out participant --no-sub --write-graph --nprocs 4 --participant-label " + sub
    print(cmd)
    os.system(cmd)