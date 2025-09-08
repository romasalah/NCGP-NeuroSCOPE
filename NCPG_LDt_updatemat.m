% ==========================================================================
% Overall goal (user-provided): Overall goal: a Utility function to update a preexisting matrix of Linear discriminant t-values
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: a Utility function to update a preexisting matrix of Linear discriminant t-values
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
% Function signature detected
function NCPG_LDt_updatemat(lDtmatreader, curldtcv, curldtcv_avg, mi, hi)
lDtmatreader.ldt_cv(mi,hi)=curldtcv;
lDtmatreader.ldt_cv_avg(mi,hi)=curldtcv_avg;
end
