"""Searchlight-based hyperalignment"""

import os
import numpy as np

from tempfile import mktemp
from numpy.linalg import LinAlgError

import mvpa2
from mvpa2.base.state import ClassWithCollections
from mvpa2.base.param import Parameter
from mvpa2.base.constraints import *
from mvpa2.algorithms.hyperalignment import Hyperalignment
from mvpa2.mappers.staticprojection import StaticProjectionMapper
from mvpa2.misc.neighborhood import IndexQueryEngine, Sphere
from mvpa2.base.progress import ProgressBar
from mvpa2.base import externals, warning
from mvpa2.support import copy
from mvpa2.featsel.helpers import FixedNElementTailSelector
from mvpa2.base.types import is_datasetlike
from mvpa2.misc.surfing.queryengine import SurfaceVerticesQueryEngine

if externals.exists('h5py'):
    from mvpa2.base.hdf5 import h5save, h5load

if externals.exists('scipy'):
    from scipy.sparse import coo_matrix, csc_matrix

from mvpa2.support.due import due, Doi

import psutil

def print_system_resources():
    # CPU usage
    cpu_usage = psutil.cpu_percent(interval=1)
    # Memory usage
    mem = psutil.virtual_memory()
    mem_usage_pct = mem.percent
    # Virtual memory usage
    swap = psutil.swap_memory()
    swap_usage_pct = swap.percent
    # Disk usage for the partition where the script is running
    disk_usage = psutil.disk_usage(os.path.abspath('/'))
    free_storage_pct = 100 - disk_usage.percent
    print("CPU Usage: {}%".format(cpu_usage) + ", Memory Usage: {}%".format(mem_usage_pct) + ", Swap Memory Usage: {}%".format(swap_usage_pct) + ", Free Storage: {}%".format(free_storage_pct))

def compute_feature_scores(datasets, exclude_from_model=None):
    """
    Takes a list of datasets and computes a magical feature score for each feature in each dataset :ref:`Haxby et al., Neuron (2011) <HGC+11>`
    Parameters. datasets : list or tuple of datasets  exclude_from_model: list of dataset indices that won't participate in voxel selection of others
    Returns-- list : a list of feature scores; higher the score, better the feature. NOTE: This function assumes that the datasets are zscored
    """
    if exclude_from_model is None:
        exclude_from_model = []
    feature_scores = [np.zeros(sd.nfeatures) for sd in datasets]
    for i, sd in enumerate(datasets):
        for j, sd2 in enumerate(datasets[i + 1:]):
            corr_temp = np.dot(sd.samples.T, sd2.samples)
            if j + i + 1 not in exclude_from_model:
                feature_scores[i] += np.max(corr_temp, axis=1)
            if i not in exclude_from_model:
                feature_scores[j + i + 1] += np.max(corr_temp, axis=0)
    return feature_scores


class FeatureSelectionHyperalignment(ClassWithCollections):
    """A helper which brings feature selection and hyperalignment in a single call It was created to facilitate its usage in any searchlight or ROI, where
    hyperalignment is trained and called on the same list of datasets.  But unlike Hyperalignment, it doesn't need to be separately trained.
    Called with a list of datasets, it returns a list of Mappers, one per each dataset, similarly to how Hyperalignment does.
    """
    def __init__(self, ref_ds=0, hyperalignment=Hyperalignment(ref_ds=0),
                 featsel=1.0, full_matrix=True, use_same_features=False,
                 exclude_from_model=None, dtype='float32', **kwargs):
        """
        For description of parameters see :class:`SearchlightHyperalignment`
        """
        super(FeatureSelectionHyperalignment, self).__init__(**kwargs)
        self.ref_ds = ref_ds
        self.hyperalignment = hyperalignment
        self.featsel = featsel
        self.use_same_features = use_same_features
        self.exclude_from_model = exclude_from_model
        if self.exclude_from_model is None:
            self.exclude_from_model = []
        self.full_matrix = full_matrix
        self.dtype = dtype

    def __call__(self, datasets):
        ref_ds = self.ref_ds
        nsamples, nfeatures = datasets[ref_ds].shape
        if 'roi_seed' in datasets[ref_ds].fa and np.any(datasets[ref_ds].fa['roi_seed']):
            seed_index = np.where(datasets[ref_ds].fa.roi_seed)
        else:
            if not self.full_matrix:
                raise ValueError(
                    "Setting full_matrix=False requires roi_seed `fa` in the "
                    "reference dataset indicating center feature and some "
                    "feature(s) being marked as `roi_seed`.")
            seed_index = None
        # Voxel selection within Searchlight
        # Usual metric of between-subject between-voxel correspondence
        # Making sure ref_ds has most features, if not force feature selection on others
        nfeatures_all = [sd.nfeatures for sd in datasets]
        bigger_ds_idxs = [i for i, sd in enumerate(datasets) if sd.nfeatures > nfeatures]
        if self.featsel != 1.0:
            # computing feature scores from the data
            feature_scores = compute_feature_scores(datasets, self.exclude_from_model)
            nfeatures_sel = nfeatures  # default
            if self.featsel < 1.0 and int(self.featsel * nfeatures) > 0:
                nfeatures_sel = int(self.featsel * nfeatures)
            if self.featsel > 1.0:
                nfeatures_sel = min(nfeatures, self.featsel)
            fselector = FixedNElementTailSelector(nfeatures_sel, tail='upper', mode='select', sort=False)
            # XXX Artificially make the seed_index feature score high to keep it(?)
            if self.use_same_features:
                if len(self.exclude_from_model):
                    feature_scores = [feature_scores[ifs] for ifs in range(len(datasets))
                                      if ifs not in self.exclude_from_model]
                feature_scores = np.mean(np.asarray(feature_scores), axis=0)
                if seed_index is not None:
                    feature_scores[seed_index] = max(feature_scores)
                features_selected = fselector(feature_scores)
                datasets = [sd[:, features_selected] for sd in datasets]
            else:
                features_selected = []
                for fs in feature_scores:
                    if seed_index is not None:
                        fs[seed_index] = max(fs)
                    features_selected.append(fselector(fs))
                datasets = [sd[:, fsel] for fsel, sd in zip(features_selected, datasets)]
        elif bigger_ds_idxs:
            # compute feature scores and select for bigger datasets
            feature_scores = compute_feature_scores(datasets, self.exclude_from_model)
            feature_scores = [feature_scores[isub] for isub in bigger_ds_idxs]
            fselector = FixedNElementTailSelector(nfeatures, tail='upper', mode='select', sort=False)
            features_selected = [fselector(fs) for fs in feature_scores]
            for selected_features, isub in zip(features_selected, bigger_ds_idxs):
                datasets[isub] = datasets[isub][:, selected_features]
        # Try hyperalignment
        try:
            # it is crucial to retrain hyperalignment, otherwise it would simply
            # project into the common space of a previous iteration
            if len(self.exclude_from_model) == 0:
                self.hyperalignment.train(datasets)
            else:
                self.hyperalignment.train([datasets[i] for i in range(len(datasets))
                                           if i not in self.exclude_from_model])
            mappers = self.hyperalignment(datasets)
            if mappers[0].proj.dtype is self.dtype:
                mappers = [m.proj for m in mappers]
            else:
                mappers = [m.proj.astype(self.dtype) for m in mappers]
            if self.featsel != 1.0:
                # Reshape the projection matrix from selected to all features
                mappers_full = [np.zeros((nfeatures_all[im], nfeatures_all[ref_ds]))
                                for im in range(len(mappers))]
                if self.use_same_features:
                    for mf, m in zip(mappers_full, mappers):
                        mf[np.ix_(features_selected, features_selected)] = m
                else:
                    for mf, m, fsel in zip(mappers_full, mappers, features_selected):
                        mf[np.ix_(fsel, features_selected[ref_ds])] = m
                mappers = mappers_full
            elif bigger_ds_idxs:
                for selected_features, isub in zip(features_selected, bigger_ds_idxs):
                    mapper_full = np.zeros((nfeatures_all[isub], nfeatures_all[ref_ds]))
                    mapper_full[np.ix_(selected_features, range(nfeatures))] = mappers[isub]
                    mappers[isub] = mapper_full
        except LinAlgError:
            print "SVD didn't converge. Try with a new reference, may be."
            mappers = [np.eye(nfeatures, dtype='int')] * len(datasets)
        # Extract only the row/column corresponding to the center voxel if full_matrix is False
        if not self.full_matrix:
            mappers = [np.squeeze(m[:, seed_index]) for m in mappers]
        return mappers


class SearchlightHyperalignment(ClassWithCollections):
    """
    Given a list of datasets, provide a list of mappers into common space using searchlight based hyperalignment.
    :ref:`Guntupalli et al., Cerebral Cortex (2016)`  1) Input datasets should all be of the same size in terms of
    nsamples and nfeatures, and be coarsely aligned (using anatomy). 2) All features in all datasets should be zscored.
    3) Datasets should have feature attribute `voxel_indices` containing spatial coordinates of all features
    """
    ref_ds = Parameter(0, constraints=EnsureInt() & EnsureRange(min=0))
    queryengine = Parameter(None)
    radius = Parameter(3, constraints=EnsureInt() & EnsureRange(min=1))
    nproc = Parameter(1, constraints=EnsureInt() & EnsureRange(min=1) | EnsureNone())
    nblocks = Parameter(None, constraints=EnsureInt() & EnsureRange(min=1) | EnsureNone())
    sparse_radius = Parameter(None, constraints=EnsureRange(min=1) & EnsureInt() | EnsureNone())
    hyperalignment = Parameter(Hyperalignment(ref_ds=None))
    combine_neighbormappers = Parameter(True, constraints=EnsureBool())
    compute_recon = Parameter(True, constraints=EnsureBool())
    featsel = Parameter(1.0, constraints=EnsureFloat() & EnsureRange(min=0.0, max=1.0) | EnsureInt() & EnsureRange(min=2))
    use_same_features = Parameter(False, constraints=EnsureBool())
    exclude_from_model = Parameter([], constraints=EnsureListOf(int))
    mask_node_ids = Parameter(None, constraints=EnsureListOf(int) | EnsureNone())
    dtype = Parameter('float32', constraints='str')
    results_backend = Parameter('hdf5', constraints=EnsureChoice('hdf5', 'native'))
    tmp_prefix = Parameter('tmplsl', constraints='str')

    def __init__(self, **kwargs):
        print("Initializing.")
        ClassWithCollections.__init__(self, **kwargs)
        self.ndatasets = 0
        self.nfeatures = 0
        self.projections = None
        # This option makes the roi_seed in each SL to be selected during feature selection
        self.force_roi_seed = True

    def _proc_block(self, block, datasets, featselhyper, queryengines, seed=None, iblock='main'):
        if seed is not None:
            mvpa2.seed(seed)
        print('SLC', 'Starting computing block for %i elements' % len(block))
        bar = ProgressBar()
        projections = [csc_matrix((self.nfeatures, self.nfeatures), dtype=self.params.dtype) for isub in range(self.ndatasets)]
        for i, node_id in enumerate(block):
            # retrieve the feature ids of all features in the ROI from the query engine
            # Find the neighborhood for that selected nearest node
            roi_feature_ids_all = [qe[node_id] for qe in queryengines]
            # handling queryengines that return AttrDatasets
            for isub in range(len(roi_feature_ids_all)):
                if is_datasetlike(roi_feature_ids_all[isub]):
                    # making sure queryengine returned proper shaped output
                    assert(roi_feature_ids_all[isub].nsamples == 1)
                    roi_feature_ids_all[isub] = roi_feature_ids_all[isub].samples[0, :].tolist()
            if len(roi_feature_ids_all) == 1:
                # just one was provided to be "broadcasted"
                roi_feature_ids_all *= len(datasets)
            # if qe returns zero-sized ROI for any subject, pass...
            if any(len(x)==0 for x in roi_feature_ids_all):
                continue

            # selecting neighborhood for all subject for hyperalignment
            ds_temp = [sd[:, ids] for sd, ids in zip(datasets, roi_feature_ids_all)]
            if self.force_roi_seed:
                roi_seed = np.array(roi_feature_ids_all[self.params.ref_ds]) == node_id
                ds_temp[self.params.ref_ds].fa['roi_seed'] = roi_seed
            msg = 'ROI (%i/%i), %i features' % (i + 1, len(block), ds_temp[self.params.ref_ds].nfeatures)
            print('SLC', bar(float(i + 1) / len(block), msg))
            hmappers = featselhyper(ds_temp)
            assert(len(hmappers) == len(datasets))
            roi_feature_ids_ref_ds = roi_feature_ids_all[self.params.ref_ds]
            for isub, roi_feature_ids in enumerate(roi_feature_ids_all):
                I, J, V = [], [], []
                for f2, roi_feature_id_ref_ds in enumerate(roi_feature_ids_ref_ds):
                    I += roi_feature_ids
                    J += [roi_feature_id_ref_ds] * len(roi_feature_ids)
                    V += hmappers[isub][:, f2].tolist()
                proj = coo_matrix((V, (I, J)), shape=(max(self.nfeatures, max(I) + 1), max(self.nfeatures, max(J) + 1)),dtype=self.params.dtype)
                proj = proj.tocsc()
                # Cleaning up the current subject's projections to free up memory
                hmappers[isub] = [[] for _ in hmappers]
                projections[isub] = projections[isub] + proj

        if self.params.results_backend == 'native':
            return projections
        elif self.params.results_backend == 'hdf5':
            # store results in a temporary file and return a filename
            results_file = mktemp(prefix=self.params.tmp_prefix, suffix='-%s.hdf5' % iblock)
            print('SLC', "Storing results into %s" % results_file)
            print_system_resources()
            h5save(results_file, projections)
            print('SLC_', "Results stored")
            return results_file
        else:
            raise RuntimeError("Must not reach this point")

    def __handle_results(self, results):
        if self.params.results_backend == 'hdf5':
            # 'results' must be just a filename
            assert(isinstance(results, str))
            print('SLC', "Loading results from %s" % results)
            results_data = h5load(results)
            os.unlink(results)
            print('SLC_', "Loaded results of len=%d from" % len(results_data))
            for isub, res in enumerate(results_data):
                self.projections[isub] = self.projections[isub] + res
            print('SLC_', "Finished adding results")
            return

    def __handle_all_results(self, results):
        for r in results:
            yield self.__handle_results(r)


    def __call__(self, datasets):
        """Estimate mappers for each dataset using searchlight-based hyperalignment Parameters"""
        params = self.params
        ndatasets = len(datasets)
        self.ndatasets = ndatasets
        print("SearchlightHyperalignment %s for %i datasets" % (self, self.ndatasets))
        selected = [_ for _ in range(ndatasets) if _ not in params.exclude_from_model]
        ref_ds_train = selected.index(params.ref_ds)
        params.hyperalignment.params.ref_ds = ref_ds_train

        # verify that datasets were zscored prior the alignment since it is assumed/required preprocessing step
        for ids, ds in enumerate(datasets):
            for f, fname, tval in ((np.mean, 'means', 0), (np.std, 'stds', 1)):
                vals = f(ds, axis=0)
                vals_comp = np.abs(vals - tval) > 1e-5

        # we need to know which original features where comprising the individual SL ROIs
        print('Initializing FeatureSelectionHyperalignment.')
        hmeasure = FeatureSelectionHyperalignment(
            ref_ds=params.ref_ds, featsel=params.featsel, hyperalignment=params.hyperalignment,
            full_matrix=params.combine_neighbormappers, use_same_features=params.use_same_features,
            exclude_from_model=params.exclude_from_model,  dtype=params.dtype)

        # Performing SL processing manually
        params.nproc = 1
        queryengines = self._get_trained_queryengines( datasets, params.queryengine, params.radius, params.ref_ds)
        # For surface nodes to voxels queryengines, roi_seed hardly makes sense
        qe = queryengines[(0 if len(queryengines) == 1 else params.ref_ds)]
        if isinstance(qe, SurfaceVerticesQueryEngine):
            self.force_roi_seed = False
        self.nfeatures = datasets[params.ref_ds].nfeatures
        print("Performing Hyperalignment in searchlights")
        # Setting up centers for running SL Hyperalignment
        roi_ids = self._get_verified_ids(queryengines)  if params.mask_node_ids is None  else params.mask_node_ids
        print('Initializing projection matrices')
        self.projections = [csc_matrix((self.nfeatures, self.nfeatures), dtype=params.dtype)  for isub in range(self.ndatasets)]
        params.nblocks = 1
        node_blocks = np.array_split(roi_ids, params.nblocks)
        p_results = [self._proc_block(block, datasets, hmeasure, queryengines) for block in node_blocks]
        results_ds = self.__handle_all_results(p_results)
        list(results_ds)
        print('Wrapping projection matrices into StaticProjectionMappers')
        self.projections = [ StaticProjectionMapper(proj=proj, recon=proj.T) if params.compute_recon else StaticProjectionMapper(proj=proj) for proj in self.projections]
        return self.projections

    def _get_verified_ids(self, queryengines):
        """Helper to return ids of queryengines, verifying that they are the same"""
        qe0 = queryengines[0]
        roi_ids = qe0.ids
        for qe in queryengines:
            if qe is not qe0:
                # if a different query engine (so wasn't just replicated)
                if np.any(qe.ids != qe0.ids):
                    raise RuntimeError(
                        "Query engine %s provided different ids than %s. Not supported"
                        % (qe0, qe))
        return roi_ids

    def _get_trained_queryengines(self, datasets, queryengine, radius, ref_ds):
        """Helper to return trained query engine(s), either list of one or one per each dataset
        if queryengine is None then IndexQueryEngine based on radius is created
        """
        ndatasets = len(datasets)
        if queryengine:
            if isinstance(queryengine, (list, tuple)):
                queryengines = queryengine
                if len(queryengines) != ndatasets:
                    raise ValueError(
                        "%d query engines were specified although %d datasets "
                        "provided" % (len(queryengines), ndatasets))
                print("Training provided query engines")
                for qe, ds in zip(queryengines, datasets):
                    qe.train(ds)
            else:
                queryengine.train(datasets[ref_ds])
                queryengines = [queryengine]
        else:
            print('No custom query engines were provided. Setting up the volumetric query engine on voxel_indices.')
            queryengine = IndexQueryEngine(voxel_indices=Sphere(radius))
            queryengine.train(datasets[ref_ds])
            queryengines = [queryengine]
        return queryengines


def split_into_batches(dataset, batch_size):
    return [dataset[:, i:i + batch_size] for i in range(0, dataset.shape[1], batch_size)]
def simulate_analysis(qe, dss, hpalkwargs):
    hpal  =SearchlightHyperalignment(queryengine = qe, **hpalkwargs)
    curmapper = hpal(dss)
    return  curmapper

def merge_results(nodeslist, splitted_files, batch_idx):
    # Step 1: Pair the elements of the two lists
    paired_lists = list(zip(batch_idx, splitted_files))
    # Step 2: Sort the paired list based on the elements from the first list
    sorted_pairs = sorted(paired_lists)
    # Step 3: Unzip the pairs back into two lists
    sorted_list1, sorted_list2 = zip(*sorted_pairs)
    # Convert tuples back to lists (optional, for better usability)
    sorted_idx = list(sorted_list1)
    sorted_splitted = list(sorted_list2)
    from mvpa2.base.hdf5 import h5save, h5load
    for curfile in sorted_splitted:
        splitted_file = h5load(curfile)
        print(curfile)


    return [np.hstack(result_set) for result_set in results]

import psutil
import os
import re


def print_system_resources():
    # CPU usage
    cpu_usage = psutil.cpu_percent(interval=1)
    # Memory usage
    mem = psutil.virtual_memory()
    mem_usage_pct = mem.percent
    # Virtual memory usage
    swap = psutil.swap_memory()
    swap_usage_pct = swap.percent
    # Disk usage for the partition where the script is running
    disk_usage = psutil.disk_usage(os.path.abspath('/'))
    free_storage_pct = 100 - disk_usage.percent
    print("CPU Usage: {}%".format(cpu_usage) + ", Memory Usage: {}%".format(mem_usage_pct) + ", Swap Memory Usage: {}%".format(swap_usage_pct) + ", Free Storage: {}%".format(free_storage_pct))


def find_files_and_batch_numbers(directory, pattern):
    """Find files matching a pattern and extract batch numbers from their paths."""
    matches = []
    batch_numbers = []
    batch_pattern = re.compile(r'No_(\d+)')  # Regex to find "batch_{number}"

    for root, dirnames, filenames in os.walk(directory):
        for filename in filenames:
            if glob.fnmatch.fnmatch(filename, pattern):
                file_path = os.path.join(root, filename)
                matches.append(file_path)

                # Search for batch number in the file path
                match = batch_pattern.search(file_path)
                if match:
                    batch_numbers.append(int(match.group(1)))  # Extract batch number
                else:
                    batch_numbers.append(None)  # No batch number found
    return matches, batch_numbers

import pickle
import numpy as np
import glob
import os
num_batches = 10000
nodeslist = np.array_split(np.arange(1,37472), num_batches)



# # Example usage
# directory = r'C:\Users\CENs-Admin\Documents\Omar\NCPG\hpal'
# pattern = 'sub-004*R_*.h5'  # Example pattern to match text files
# splitted_files, batch_idx = find_files_and_batch_numbers(directory, pattern)
# merged_results = merge_results(nodeslist, splitted_files, batch_idx)

with open(r'C:\Users\CENs-Admin\Documents\Omar\NCPG\scripts\01hyperalignment\hpaldss_backup_15subs.pkl', 'rb') as input_file:
    varlist = pickle.load(input_file)
hpal= varlist[0]
dss = varlist[1]
hpalkwargs = varlist[2]
qe = varlist[3]
desc = varlist[4]

# Execute the function
print_system_resources()
for curpc in range(0, 1):
    hpalkwargs['mask_node_ids'] = nodeslist[curpc]
    reslist = simulate_analysis(qe, dss, hpalkwargs)
print(reslist)

