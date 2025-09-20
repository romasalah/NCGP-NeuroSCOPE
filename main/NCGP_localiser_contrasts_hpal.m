% ==========================================================================
% Overall goal: Define and estimate localizer contrast maps (e.g., Faces > Objects) after GLM, compatible with hyperaligned workflow.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [conimgname,conimg_clustNum,spmdir]=NCGP_localiser_contrasts_hpal(wf, runscell)
hemis=wf.hemis;
% Section: for-block starts
for hi=1:length(hemis)
    curhemi=hemis{hi};
% Section: if-block starts
    if wf.group==0
% Section: for-block starts
        for subi=1:length(wf.subs)
            subfolder=wf.subs{subi};
            ff=dir([wf.mainpath filesep wf.glm filesep subfolder filesep wf.pre filesep 'task-' wf.task '_*_hemi-' curhemi '*']);
            spmdir{hi}=[ff(1).folder filesep ff(1).name];
% Call → NCGP_localiser_contrast: Project function call
            [conimgname{hi}, conimg_clustNum{hi}]=NCGP_localiser_contrast(wf,spmdir{hi}, wf.threshold, wf.mink, runscell);
        end
% Section: else-block starts
    else
        subfolder='group';
        ff=dir([wf.mainpath filesep 'derivatives' filesep wf.glm filesep subfolder filesep wf.pre filesep 'task-' wf.task '*hemi-' curhemi '_smooth-' wf.smooth]);
        spmdir{hi}=[ff(1).folder filesep ff(1).name];
% Call → NCGP_localiser_contrast: Project function call
        [conimgname{hi}, conimg_clustNum{hi}]=NCGP_localiser_contrast(wf,spmdir{hi}, wf.threshold, wf.mink, runscell);
    end
end
end
