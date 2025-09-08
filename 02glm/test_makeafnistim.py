def make_afni_stimtimes_exemplar(in_files, start=0, per_run=False):
    """Given event files, return stim times for AFNI for every exemplar

    Parameters
    ----------
    in_files: list of list
    start: int
        if we need to assume there are `start` runs before these ones. it
        will append `start` asterisks (*) to the stimulus files
    per_run: bool
        whether to get the stimulus times for each run instead of across runs
    """
    import numpy as np
    import pandas as pd
    from collections import defaultdict, OrderedDict
    from os.path import basename, abspath
    from six import iteritems


    def make_dict_onsets(filename):
        events = pd.read_csv(filename, sep='\t')
        onsets = defaultdict(list)
        for row in events.itertuples():
            # model the first trial separately
            key = '_'.join([row.value])
            onsets[key].append("{0:.2f}".format(row.onset))
        onsets = dict(onsets)
        return onsets

    onsets = dict()
    for f in in_files:
        on = make_dict_onsets(f)
        keep_keys = []
        # format them
        for k, o in iteritems(on):
            # do not store empty stimtimes
            if list(set(o)) != ['* *']:
                on[k] = ' '.join(o)
                keep_keys.append(k)
        onsets[f] = {k: on[k] for k in keep_keys}

    # get stim labels
    stim_labels = sorted(list(onsets[in_files[0]].keys()))

    # create stim files
    stim_files = dict()
    if per_run:
        #  we need to keep the run information, and add extra '* *' for every
        #  run we skip
        for irun, f in enumerate(in_files, 1):
            print(f)
            onsets_run = onsets[f]
            for sl, on in iteritems(onsets_run):
                lbl = sl + '_run{0:02d}'.format(irun)
                stim_files[lbl] = on
    else:
        for sl in stim_labels:
            stim_files[sl] = []
            for f in in_files:
                if sl in onsets[f]:
                    toadd = onsets[f][sl]
                else:
                    toadd = '* *'
                stim_files[sl].append(toadd)
    stim_files=OrderedDict(sorted(stim_files.items()))
    # save
    header = '\n'.join(['* *'] * start) + '\n' if start else ''
    fns = []
    for lbl, stim_times in iteritems(stim_files):
        fns.append(abspath(lbl) + '.txt')
        with open(fns[-1], 'w') as f:
            f.write(header)
            f.write('\n'.join(stim_times))
    return fns

if __name__=="__main__":
    in_files = ['/idata2/data/sub-001/ses-01/func/sub-001_ses-01_task-faces_run-01_events.tsv', '/idata2/data/sub-001/ses-02/func/sub-001_ses-02_task-faces_run-01_events.tsv', '/idata2/data/sub-001/ses-01/func/sub-001_ses-01_task-faces_run-02_events.tsv', '/idata2/data/sub-001/ses-02/func/sub-001_ses-02_task-faces_run-02_events.tsv', '/idata2/data/sub-001/ses-01/func/sub-001_ses-01_task-faces_run-03_events.tsv', '/idata2/data/sub-001/ses-02/func/sub-001_ses-02_task-faces_run-03_events.tsv', '/idata2/data/sub-001/ses-01/func/sub-001_ses-01_task-faces_run-04_events.tsv', '/idata2/data/sub-001/ses-02/func/sub-001_ses-02_task-faces_run-04_events.tsv', '/idata2/data/sub-001/ses-01/func/sub-001_ses-01_task-faces_run-05_events.tsv', '/idata2/data/sub-001/ses-02/func/sub-001_ses-02_task-faces_run-05_events.tsv', '/idata2/data/sub-001/ses-01/func/sub-001_ses-01_task-faces_run-06_events.tsv', '/idata2/data/sub-001/ses-02/func/sub-001_ses-02_task-faces_run-06_events.tsv']
    per_run = True
    make_afni_stimtimes_exemplar(in_files, 0, per_run)