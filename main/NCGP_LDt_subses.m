% ==========================================================================
% Overall goal: Orchestrate LDt computation across sessions (and hemispheres); handles loading/storing betas/residuals.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function [ldt_cv_sess, ldt_cv_subses_avg]=NCGP_LDt_subses(wf, betasfn, nbrhoods_idx, nscans_subrun, mask)
LDt_done=[];
% Section: for-block starts
for subi =1:length(wf.subs)
% Section: for-block starts
    for si =1:length(wf.sessions)
% Section: for-block starts
        for hi =1:length(wf.hemis)
            %% Try to load LDts or find the empty ones
% Call → NCGP_paths: Project function call
            p=NCGP_paths(wf);
            ldt_fn_dir=[p.mp filesep 'LDt' filesep 'group' filesep wf.pre filesep wf.glm];
            mkdir(ldt_fn_dir);
            ldt_fn{si,hi}=[ldt_fn_dir filesep 'LDtbyrun_sub-' wf.subs{subi} '_' wf.sessions{si} '_hemi-' wf.hemis{hi} '_mask-' mask '.mat'];
% Call → NCGP_LDt_CheckSave: Cache-control for LDt results: detect and reuse previously computed LDt scores to avoid recomputation.
            [LDt_done(end+1), ldt_cv_sess{si,hi}, ldt_cv_subses_avg{si,hi}, empLDts{si,hi}]=NCGP_LDt_CheckSave(wf, ldt_fn{si,hi}, nbrhoods_idx{si,hi});
        end
    end
end
% Section: if-block starts
if sum(LDt_done)==length(LDt_done)
    return
end
wf.sessions={wf.sessions{~LDt_done}};
% Call → NCGP_LDt: Compute linear discriminability t-statistic (LDt) per searchlight using shrinkage covariance and cross-validation.
[ldt_cv_sess, ldt_cv_subses_avg] = NCGP_LDt_opt(wf, betasfn, nbrhoods_idx, nscans_subrun, mask);
end
