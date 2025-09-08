% ==========================================================================
% Overall goal (user-provided): Overall goal: extract values from the a list of regions of interest ROIs
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: extract values from the a list of regions of interest ROIs
% Note:
% ==========================================================================
% Function signature detected
function [Y,allmasknames]=NCPG_extract_ROI_vals(img,allrois)
% simple sanity check to ensure all attributes are set properly
%% Extract values
% Section: for-block starts
for mi=1:length(allrois)
    curmask=[allrois(1).folder filesep allrois(mi).name];
    allmasknames{mi}=allrois(mi).name;
    curmaskmat=load(curmask);
    curmaskmat=loadobj(curmaskmat.roi);
    Y{mi}= getdata(curmaskmat,img);
end
end
