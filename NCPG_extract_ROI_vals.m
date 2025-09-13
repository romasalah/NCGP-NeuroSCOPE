%% Overall goal: extract values from the a list of regions of interest ROIs
function [Y,allmasknames]=NCPG_extract_ROI_vals(img,allrois)
for mi=1:length(allrois)
    curmask=[allrois(1).folder filesep allrois(mi).name];
    allmasknames{mi}=allrois(mi).name;
    curmaskmat=load(curmask);
    curmaskmat=loadobj(curmaskmat.roi);
    Y{mi}= getdata(curmaskmat,img);
end
end
