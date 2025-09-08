# ==========================================================================
# Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
# Note: Comments added only at the top; code unchanged.
# ==========================================================================
from mvpa2.suite import *
from mvpa2.support.nibabel import surf
from mvpa2.suite import *
from mvpa2.support.nibabel import surf
import nibabel as nib
surface_dataset = niml.read(r'C:\Users\CENs-Admin\Documents\Omar\NCPG\hpal\SPM_GLM\group\fmriprep\task-faces_ses-02_hemi-R_run-010203040506\Res_0007+orig.niml.dset')
mask = niml.read(r'C:\Users\CENs-Admin\Documents\Omar\NCPG\hpal\SPM_GLM\group\fmriprep\task-localizer_ses-01_hemi-R_run-01020304\spmT_0001_Faces_morethan_Objects_Scenes+orig.niml.dset')
radius = 10.0  # radius in mm

# Create the query engine
qe = SurfaceVerticesQueryEngine(surface_dataset, radius)

# Instantiate the searchlight
sl = Searchlight(qe, nproc=1)
