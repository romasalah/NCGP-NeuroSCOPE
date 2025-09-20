% ==========================================================================
% Overall goal (user-provided): Overall goal: Calculates LDt values without averaging the 6 runs done by each participant
% ==========================================================================
function [LLM_LDtcorr_SepRun_alltasks, LLM_LDtcorr, LDtcorr, sigFDR_idx, p_FDR, p_uncorrected, sig_FDR_meancorr]=NCGP_LDtcorr_SeparateRuns(wf2, ds, LDt_byrun, taskname, vo, fo, mask, maskidx_subsesshemi)
LLM_LDtcorr_SepRun_alltasks={};
% Section: for-block starts
for ti = 1:length(taskname)
    curtaskname=taskname{ti};
    wf2.curRDM=  mean(wf2.targetRSM_pre{ti},3);
    %% Correlation of LDC values and behavioural RDM
% Call → NCGP_RDMcorr
    LDtcorr{ti} = NCGP_RDMcorr(wf2, LDt_byrun, wf2.curRDM, 'spearman','right', 0.05); % LDt from all CrossValidation runs
    %% Separate CrossValidation Runs: Do Wilcoxon Sign-Rank for all the CrossValidation runs +  FDR correction for RDM correlation values
% Call → NCGP_RDMCorr_stats
    [sigFDR_idx{ti}, p_uncorrected{ti}, p_FDR{ti}, sig_FDR_meancorr{ti}]=NCGP_RDMCorr_stats(wf2, LDtcorr{ti});
    %% Export FDR-corrected RDM correlation values into SUMA images
% Call → NCGP_RDMcorr_plot
    NCGP_RDMcorr_plot(wf2, LDtcorr{ti}, vo, fo, curtaskname, mask, sigFDR_idx{ti}, ds);
    %% Create an LLM design from FDR corrected RDM correlation values to excel sheet for LLM
% Call → NCGP_searchlightRDM2LLM
    LLM_LDtcorr{ti}=NCGP_searchlightRDM2LLM(wf2, LDtcorr{ti}, sigFDR_idx{ti}, maskidx_subsesshemi, curtaskname, 'localizer');
    LLM_LDtcorr_SepRun_alltasks=[LLM_LDtcorr_SepRun_alltasks; LLM_LDtcorr{ti} ];
end
end
