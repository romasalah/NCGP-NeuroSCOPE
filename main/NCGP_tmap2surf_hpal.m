% ==========================================================================
% Overall goal: Project volumetric t-maps from GLM to fsaverage6 cortical surface (GIFTI/NIML).
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function [clustfn, smoothedfn, clustvolname]=NCGP_tmap2surf_hpal(wf,contrastimg, spmdir)
% Call → NCGP_paths: Project function call
p = NCGP_paths(wf);
% Section: for-block starts
for hi =1:length(wf.hemis)
    curhemi=wf.hemis{hi};
    curimg=contrastimg{hi};
    curspmdir=spmdir{hi};
% Call → NCGP_vol2surf: Sample volumetric data to surface nodes (fsaverage6), creating per-vertex data from 3D images.
    NCGP_vol2surf(wf, curimg, curspmdir, curhemi, 'n');
    smoothedfn={};
% Call → NCGP_surfsmooth: Project function call
    %smoothedfn{hi}=NCGP_surfsmooth(wf, p,curspmdir, curimg, curhemi);
    dsetpath=[curspmdir filesep curimg];
% Call → NCGP_surfclust: Project function call
    clustfn{hi}=NCGP_surfclust(wf, dsetpath, curhemi);
% Call → NCGP_surf2vol: Project function call
    %clustvolname{hi} = NCGP_surf2vol(wf, curspmdir, clustfn{hi}, curhemi);
end
end
