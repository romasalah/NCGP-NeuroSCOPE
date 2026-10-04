#!/usr/bin/env python
"""Script to run hyperalignment for Budapest movie. You should remember to
have enough space in /tmp (so for example by mounting /tmp in the singularity
container to a location with enough storage), as well as setting
OMP_NUM_THREADS to 1 in your environment variables, to avoid using too many
resources."""

import matplotlib
matplotlib.use('Agg')
from mvpa2 import debug
debug.active += ['SHPAL', 'SLC']
import argparse
import numpy as np
from mvpa2.datasets import niml, vstack
from mvpa2.mappers.zscore import zscore
from mvpa2.base.hdf5 import h5save
from mvpa2.misc.surfing.queryengine import SurfaceQueryEngine
from mvpa2.algorithms.searchlight_hyperalignment import \
    SearchlightHyperalignment
from mvpa2.support.nibabel import surf
import os
import os.path as op
from glob import glob
from dateutil.parser import parse
from joblib.parallel import Parallel, delayed
import math
def nscans_per_dset(skipvols):
    tr=2.5
    durations=[570, 516, 669, 459, 615]
    scannums=[]
    for curd in durations:
        scannums.append([skipvols , int(math.ceil((curd/tr) + skipvols))])
    return scannums


def load_datasets(fns, skip):
    """Load a list of datasets, skipping initial TRs as specified in skip,
    and return a stacked dataset"""
    scansidx=nscans_per_dset(skip)
    dss = []
    for i, (fn, sk) in enumerate(zip(fns, scansidx)):
        ds = niml.read(fn)
        ds.sa['chunks'] = [i]
        # remove first 10 seconds + overlap
        ds = ds[sk[0]:sk[1]]
        zscore(ds)
        ds.fa['node_indices'] = np.arange(ds.nfeatures)
        dss.append(ds)
    dss = vstack(dss)
    return dss


def hyperalign(dss, qe, hemi, **hpalkwargs):
    hpal = SearchlightHyperalignment(queryengine=qe, **hpalkwargs)
    mappers_tempfiles = hpal(dss)
    import pandas as pd
    tempf_csv='/idata/tmp/tempfiles_' + hemi + '.csv'
    tempf_df = pd.DataFrame(mappers_tempfiles, columns=['tempfiles'])
    tempf_df.to_csv(tempf_csv, index=False)
    # import pickle
    # objlist=[hpal, dss, hpalkwargs, qe, "hpal, dss, hpalkwargs, qe"]
    # with open('hpaldss_backup_15subs.pkl', 'wb') as output_file:
    #     pickle.dump(objlist, output_file)
    return tempf_csv

def export_matrices(dss, tempfiles, qe, **hpalkwargs):
    hpal = SearchlightHyperalignment(queryengine=qe, **hpalkwargs)
    if tempfiles != '':
        import pandas as pd
        csvlist= pd.read_csv(tempfiles)
    tmpfnames=csvlist['tempfiles'].to_list()
    mappers = hpal(dss, tmpfnames)
    return mappers

def load_mask(hemi, fsdir):
    mask_fn = '{}.maskmedial.niml.dset'.format(hemi)
    mask = niml.read(op.join(fsdir, 'fsaverage6/SUMA', mask_fn))
    return mask


def get_qe(hemi, fsdir, radius=20.0):
    surf_fn = '{}.white.gii'.format(hemi)
    s = surf.read(op.join(fsdir, 'fsaverage6/SUMA', surf_fn))
    qe = SurfaceQueryEngine(s, radius=radius)
    return qe


def run(list_fns, subjects, hemi, fsdir, outdir, nproc=1, batches=1, batchIndex=1, nblocks=1, tempfiles=''):
    outdir=outdir
    hemi2fshemi = {'L': 'lh', 'R': 'rh'}
    fshemi = hemi2fshemi[hemi]
    skipvols=0
    print("Got the following datasets: {}".format(list_fns))
    print("Loading datasets")
    dss = Parallel(n_jobs=nproc)(delayed(load_datasets)(fns, skipvols) for fns in list_fns)
    mask = load_mask(fshemi, fsdir)
    # mask_idx = np.where(mask.samples[0])[0][:100]  # debug
    mask_idx = np.where(mask.samples[0])[0]
    # mask datasets
    #mask_idx=mask_idx[0:10]
    print("Masking datasets")
    dss = [ds[:, mask_idx] for ds in dss]
    qe = get_qe(fshemi, fsdir)
    allnodes= np.unique(dss[0].fa.node_indices)
    nodeslist = np.array_split(allnodes, batches)
    currentnodes= nodeslist[batchIndex-1]
    print(currentnodes)
    kwargs = dict(
        ref_ds=0, nproc=nproc, featsel=1.0,
        mask_node_ids=currentnodes,
        compute_recon=False,
        nblocks=nblocks )
    if tempfiles == '':
        print("Running Hyperalignment")
        tempfiles_csv = hyperalign(dss, qe, hemi, **kwargs)
        print("Exporting Projection Matrices")
        mappers = export_matrices(dss, tempfiles_csv, qe, **kwargs)
    else:
        print("Exporting Projection Matrices")
        mappers = export_matrices(dss, tempfiles, qe, **kwargs)
    out_fn = '{0}_task-movie_space-fsaverage6_hemi-{1}_target-hpal_mapper.h5'
    for subj, mapper in zip(subjects, mappers):
        outdir_ = op.join(outdir, subj)
        if not op.exists(outdir_):
            os.makedirs(outdir_)
        out_fn_ = op.join(outdir_,
                          out_fn.format(subj, hemi))
        print("Saving {}".format(out_fn_))
        h5save(out_fn_, mapper)


def main():
    # p = parse_args()
    # subjects = sorted(map(op.basename, glob(op.join(p.input_dir, 'sub-*'))))
    # list_fns = [
    #     sorted(glob(op.join(
    #         p.input_dir, subj, '*{}.func*.niml.dset').format(p.hemi)))
    #     for subj in subjects
    # ]
    # run(list_fns, subjects, p.hemi, p.fsdir, p.output_dir, p.nproc, p.batches, p.batchIndex, p.nblocks, p.temp)
    input_dir="/idata/hpal-preproc"
    subjects = sorted(map(op.basename, glob(op.join(input_dir, 'sub-*'))))
    hemi="R"
    nproc=1
    output_dir="/idata/derivatives/hpal"
    fsdir="/idata/derivatives/freesurfer"
    batches=1
    batchIndex=1
    nblocks=100
    tempfiles=''
    list_fns = [
        sorted(glob(op.join(
            input_dir, subj, '*{}.func*.niml.dset').format(hemi)))
        for subj in subjects
    ]
    run(list_fns, subjects, hemi, fsdir, output_dir, nproc, batches, batchIndex, nblocks, tempfiles)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--input-dir', '-i', type=str,
                        help='input directory containing subdirectories '
                             'with data to train hyperalignment on for ' 
                             'each participant',
                        required=True)
    parser.add_argument('--hemi', '-m', type=str,
                        help='which hemisphere to run hpal on',
                        required=True, choices=['L', 'R'])
    parser.add_argument('--fsdir', '-f', type=str,
                        help='freesurfer directory',
                        required=True)
    parser.add_argument('--nproc', '-n', type=int,
                        help='number of procs to use for hpal',
                        required=True)
    parser.add_argument('--output-dir', '-o', type=str,
                        help='output directory. mappers will be stored '
                             'within one folder for each subject',
                        required=True)
    parser.add_argument('--batches', '-bs', type=int,
                        help='For Distributed Computing: the number of batches the dataset is divided into',
                        required=False)
    parser.add_argument('--batchIndex', '-bi', type=int,
                        help='For Distributed Computing: index of the current batch of searchlights ',
                        required=False)
    parser.add_argument('--nblocks', '-nb', type=int,
                        help='Number of blocks to divide the task into',
                        required=False)
    parser.add_argument('--temp', 'tmp', type=str,
                        help='precalculated temporary hdf5 files in a csv list',
                        required=False, default='')
    return parser.parse_args()


if __name__ == '__main__':
    main()
