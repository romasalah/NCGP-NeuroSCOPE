Node: glm_wf (datasource_stranger (grab_confs (utility)
=======================================================


 Hierarchy : glmtent-sid000005-both.glm_wf.datasource_stranger.grab_confs
 Exec ID : grab_confs.a0


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

* query : {'extensions': '.tsv', 'task': 'str1back', 'type': 'confounds', 'subject': 'sid000005'}

