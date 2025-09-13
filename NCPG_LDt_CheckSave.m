% ==========================================================================
% Overall goal: Cache-control for LDt results: detect and reuse previously computed LDt scores to avoid recomputation.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [LDt_done, ldt_cv, ldt_cv_avg, empLDts, empLDts_avg]=NCPG_LDt_CheckSave(wf, ldt_fn, nbrhoods_idx)
LDt_done=0;
% Section: if-block starts
if exist(ldt_fn, "file")==2
    load(ldt_fn);
% Section: for-block starts
    for hi=1:length(wf.hemis)
        empLDts(:,hi)=cellfun(@isempty, ldt_cv(:,hi));
        empLDts_avg(:,hi)=cellfun(@isempty, ldt_cv_avg(:,hi));
% Section: if-block starts
        if sum(empLDts(:,hi)) == 0 && sum(empLDts_avg(:,hi)) == 0
            LDt_done=1;
        end
    end
% Section: else-block starts
else
    ldt_cv= cell(length(nbrhoods_idx{1}),length(wf.hemis));
    ldt_cv_avg= cell(length(nbrhoods_idx{1}),length(wf.hemis));
    empLDts= ones(length(nbrhoods_idx{1}),length(wf.hemis));
    empLDts_avg= ones(length(nbrhoods_idx{1}),length(wf.hemis));
    save(ldt_fn,'ldt_cv', 'ldt_cv_avg')
end
end