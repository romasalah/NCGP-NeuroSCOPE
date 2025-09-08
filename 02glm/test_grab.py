
def bidsgrabber(base_dir, query):
    from bids.layout import BIDSLayout
    try:
        layout = BIDSLayout(base_dir, extensions=['derivatives'])
    except TypeError:  # newever version of pybids
        layout = BIDSLayout((base_dir, ['bids', 'derivatives']))
    files = layout.get(**query)
    if len(files) == 0:
        raise ValueError("Query returned 0 files")
    else:
        print(files)
    return [f.filename for f in files]

if __name__=="__main__":
    base_dir = '/idata2/derivatives103/fmriprep'
    query= {'task': 'faces', 'extensions': '.tsv', 'subject': '001'}
    bidsgrabber(base_dir, query)

