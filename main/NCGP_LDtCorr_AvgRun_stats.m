% ==========================================================================
% Overall goal (user-provided): Overall goal: Run FDR on uncorrected P-values, filter out above-threshold p--values and plot only the significant ones.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Run FDR on uncorrected P-values, filter out above-threshold p--values and plot only the significant ones.
function [sigFDR_idx, sigp, sig_FDR_corr]=NCGP_LDtCorr_AvgRun_stats(wf, corrvals, pvals_uncorrected)
for si =1:length(wf.sessions)
% Section: for-block starts
    for hi = 1:length(wf.hemis)
            roinum=size(corrvals{si,hi}, 1);
            corr_AvgRun=corrvals{si,hi};
% Call → NCGP_FDR
            p_FDR_nonnan=NCGP_FDR(pvals_uncorrected{si,hi},'storey');
            p_FDR_all{si,hi}=p_FDR_nonnan;
            sigFDR_idx{si,hi}=p_FDR_all{si,hi}<0.05;
            sigp{si,hi}=p_FDR_all{si,hi}(sigFDR_idx{si,hi});
            sig_FDR_corr{si,hi}=corr_AvgRun(sigFDR_idx{si,hi}); % only used for plotting
            scatter(1:length(sig_FDR_corr{si,hi}),sig_FDR_corr{si,hi});
            hold on;
        end
    end
end