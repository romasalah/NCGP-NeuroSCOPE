% ==========================================================================
% Overall goal (user-provided): Overall goal: Iterates over searchlights and extracts residuals of the General Linear Model for all searchlight voxels over the six runs.
% ==========================================================================
function Residuals_currentidx=NCGP_residuals_condbyrun(allres, searchlight_idx,nscans_subrun)
Residuals_currentidx=cell(length(searchlight_idx),1);
f = waitbar(0,'Please wait...');
% Section: for-block starts
for roi = 1:length(searchlight_idx)
    waitbar(roi/length(searchlight_idx),f,['Searchlight ' num2str(roi) ' out of ' num2str(length(searchlight_idx))])
    cursl=searchlight_idx{roi};
    %% Extracting residuals
% Section: for-block starts
    for runi=1:size(nscans_subrun,1)
        Residuals_currentidx{roi}(1:nscans_subrun{runi,5},:,runi)=allres(nscans_subrun{runi,4}(1:nscans_subrun{runi,5}),cursl);
    end
    [m, n, p] = size(Residuals_currentidx{roi}); % Get the size of each dimension
    Residuals_currentidx{roi} = reshape(Residuals_currentidx{roi}, [m*p, n]);
end
delete(f);
end
