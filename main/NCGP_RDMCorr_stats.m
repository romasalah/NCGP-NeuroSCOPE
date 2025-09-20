% ==========================================================================
% Overall goal (user-provided): Overall goal: Hypothesis 3: calculates which correlation values are statistically significant by doing a signed rank test, then doing FDR correction for multiple comparisons
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Hypothesis 3: calculates which correlation values are statistically significant by doing a signed rank test, then doing FDR correction for multiple comparisons
% ==========================================================================
% Function signature detected
function [sigFDR_idx, p_uncorrected, p_FDR_all, sig_FDR_meancorr, nonnan_idx_subses]=NCGP_RDMCorr_stats(wf, corrvals)
% At the group level, for each ROI we compared the single-subject
% correlations for each of the four comparisons (two crossmodal, two
% unimodal) against zero using one-sample one-tailed Wilcoxon signed-rank
% tests (because correlations are not normally distributed). P values were
% corrected for multiple comparisons (48 comparisons: 4 tests x 12 ROIs)
% controlling for FDR with q < 0.05
numhemis=2;
numsess=1;
pooledcorr=[];
% Section: for-block starts
for subi=1:length(wf.subs) 
% Section: for-block starts
    for si =1:length(wf.sessions)
% Section: for-block starts
        for hi =1:length(wf.hemis)
            figure;
            roinum=size(corrvals{subi,si}{hi}, 1);
            stats{subi,si}{hi}=cell(roinum,1);
            h{subi,si}{hi}=zeros(roinum,1);
            p_uncorrected{subi,si}{hi}=ones(roinum,1);
            nonnan_idx=logical(ones(roinum,1));
            p_FDR_all{subi,si}{hi}=ones(roinum,1);
% Section: for-block starts
            for roi = 1:roinum
                curcorr=corrvals{subi,si}{hi}(roi,:);
% Section: try-block starts
                try
                [p_uncorrected{subi,si}{hi}(roi),h{subi,si}{hi}(roi),stats{subi,si}{hi}{roi}]=signrank(curcorr);
% Section: catch-block starts
                catch
                    disp(['skipping Searchlight No. ' num2str(roi)]);
                    nonnan_idx(roi)=0; % nan location
                end
            end
            meancorr=mean(corrvals{subi,si}{hi}, 2);
% Call → NCGP_FDR
            p_FDR_nonnan=NCGP_FDR(p_uncorrected{subi,si}{hi}(nonnan_idx)');
            p_FDR_all{subi,si}{hi}(nonnan_idx)=p_FDR_nonnan;
            sigFDR_idx{subi,si}{hi}=p_FDR_all{subi,si}{hi}<0.05;
            sigp{subi,si}{hi}=p_FDR_all{subi,si}{hi}(sigFDR_idx{subi,si}{hi});
            sig_FDR_meancorr{subi,si}{hi}=meancorr(sigFDR_idx{subi,si}{hi}); % only used for plotting
            nonnan_idx_subses{subi,si}{hi}=nonnan_idx;
            scatter(1:length(sig_FDR_meancorr{subi,si}{hi}),sig_FDR_meancorr{subi,si}{hi});
            hold on;
        end
    end
end
end
