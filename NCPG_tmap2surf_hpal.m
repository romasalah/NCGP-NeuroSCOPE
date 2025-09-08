% ==========================================================================
% Overall goal: Project volumetric t-maps from GLM to fsaverage6 cortical surface (GIFTI/NIML).
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [clustfn, smoothedfn, clustvolname]=NCPG_tmap2surf_hpal(wf,contrastimg, spmdir)
% Call → NCPG_paths: Project function call
p = NCPG_paths(wf);
% Section: for-block starts
for hi =1:length(wf.hemis)
    curhemi=wf.hemis{hi};
    curimg=contrastimg{hi};
    curspmdir=spmdir{hi};
% Call → NCPG_vol2surf: Sample volumetric data to surface nodes (fsaverage6), creating per-vertex data from 3D images.
    NCPG_vol2surf(wf, curimg, curspmdir, curhemi, 'n');
    smoothedfn={};
% Call → NCPG_surfsmooth: Project function call
    %smoothedfn{hi}=NCPG_surfsmooth(wf, p,curspmdir, curimg, curhemi);
    dsetpath=[curspmdir filesep curimg];
% Call → NCPG_surfclust: Project function call
    clustfn{hi}=NCPG_surfclust(wf, dsetpath, curhemi);
% Call → NCPG_surf2vol: Project function call
    %clustvolname{hi} = NCPG_surf2vol(wf, curspmdir, clustfn{hi}, curhemi);
end
end
