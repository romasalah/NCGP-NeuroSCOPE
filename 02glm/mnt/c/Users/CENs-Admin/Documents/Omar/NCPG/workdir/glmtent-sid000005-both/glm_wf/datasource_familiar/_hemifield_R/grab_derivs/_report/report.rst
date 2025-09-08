Node: glm_wf (datasource_familiar (grab_derivs (utility)
========================================================


 Hierarchy : glmtent-sid000005-both.glm_wf.datasource_familiar.grab_derivs
 Exec ID : grab_derivs.a1


Original Inputs
---------------


* base_dir : /idata/scripts/02glm/mnt/c/Users/CENs-Admin/Documents/Omar/NCPG/fmriprep
* function_str : def bidsgrabber(base_dir, query):
    from bids.layout import BIDSLayout
    try:
        layout = BIDSLayout(base_dir, extensions=['derivatives'])
    except TypeError:  # newever version of pybids
        layout = BIDSLayout((base_dir, ['bids', 'derivatives']))
    files = layout.get(**query)
    if len(files) == 0:
        raise ValueError("Query returned 0 files")
    return [f.filename for f in files]

* query : {'task': 'fam1back', 'extensions': 'niml.dset', 'subject': 'sid000005', 'space': 'hpalsid000005fsaverage6'}

