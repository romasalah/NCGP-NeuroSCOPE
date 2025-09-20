% ==========================================================================
% Overall goal: Aggregate correlation values across runs; prepare per-searchlight correlation statistics.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function [LLM_LDtcorr, LDtcorr, sigFDR_idx, q_values, LDtcorr_pval, sig_FDR_coef, corr_sesshemi, pval_sesshemi]=NCGP_LDtcorr_AvgRun(wf2, ds, LDt_byrun, taskname, vo, fo, mask, maskidx_subsesshemi)

for si = 1: length(wf2.sessions)
    % Section: for-block starts
    for hi = 1:length(wf2.hemis)
        curmask_subses{si,hi}=1:size(vo{si,hi},1);
    end
end

for ti = 1:length(taskname)
    curtaskname=taskname{ti};
    wf2.curRDM=  mean(wf2.targetRSM_post{ti},3);
    %% Correlation of LDC values and behavioural RDM
    % Call → NCGP_RDMcorr: Compute correlations between behavioral RDMs (physical/personality/social) and neural LDt per searchlight.
    [LDtcorr{ti}, LDtcorr_pval{ti}, sigidx{ti}, sigidx_coefs{ti}] = NCGP_RDMcorr(wf2, LDt_byrun, wf2.curRDM, wf2.RDMcorr.Method, wf2.RDMcorr.htail, wf2.RDMcorr.alpha); % LDt from all CrossValidation runs
    %% Generate Null distribution
    % Call → NCGP_LDt_permute: Project function call
    [corr_sesshemi{ti}, pval_sesshemi{ti}]=NCGP_LDt_permute(wf2, LDt_byrun,ds,wf2.curRDM, wf2.RDMcorr.Method, wf2.RDMcorr.htail, wf2.RDMcorr.alpha);
    %% Separate CrossValidation Runs: Do Wilcoxon Sign-Rank for all the CrossValidation runs +  FDR correction for RDM correlation values
    % Call → NCGP_LDtCorr_AvgRun_stats: Project function call
    [sigFDR_idx{ti}, q_values{ti}, sig_FDR_coef{ti}]=NCGP_LDtCorr_AvgRun_stats(wf2, LDtcorr{ti}', LDtcorr_pval{ti}');
    %% Export FDR-corrected RDM correlation values into SUMA images
    % Call → NCGP_RDMcorr_plot: Export correlation maps (localizer-masked and whole-brain) for visualization.
    NCGP_RDMcorr_plot(wf2, LDtcorr{ti}', vo, fo, curtaskname, mask, curmask_subses, sigidx{ti}', ds, 'none', wf2.RDMcorr.alpha, wf2.RDMcorr.htail);
    % Call → NCGP_RDMcorr_plot: Export correlation maps (localizer-masked and whole-brain) for visualization.
    NCGP_RDMcorr_plot(wf2, LDtcorr{ti}', vo, fo, curtaskname, mask, curmask_subses, sigFDR_idx{ti}, ds, 'FDR', wf2.RDMcorr.alpha, wf2.RDMcorr.htail);
    %% Create an LLM design from FDR corrected RDM correlation values to excel sheet for LLM
    % Call → NCGP_searchlightRDM2LLM: Package searchlight correlation/LDt values into tabular form for LLM ingestion.
    LLM_LDtcorr{ti}=NCGP_searchlightRDM2LLM(wf2, LDtcorr{ti}', sigFDR_idx{ti}, [], curtaskname, 'none');

end
end
