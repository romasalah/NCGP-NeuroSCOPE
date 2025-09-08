from bids.layout import BIDSLayout
def bidsgrabber(base_dir, query):
    try:
        layout = BIDSLayout(base_dir, extensions=['derivatives'])
    except TypeError:  # newever version of pybids
        layout = BIDSLayout((base_dir, ['bids', 'derivatives']))
    files = layout.get(**query)
    f=[f.filename for f in files]
    print(f)
    if len(files) == 0:
        raise ValueError("Query returned 0 files")
    return [f.filename for f in files]

if __name__=="__main__":
    # query = {'task': 'movie', 'extensions': '.nii.gz', 'modality': 'func', 'space': 'T1w', 'subject': 'sid000005'}
    query= {'task': 'movie', 'extensions': '.gii', 'modality': 'func', 'space': 'fsaverage', 'subject': 'sid000005'}
    base_dir=r"C:\Users\CENs-Admin\Documents\Omar\Castello_2021\derivatives103-budapest\fmriprep"
    res=bidsgrabber(base_dir, query)