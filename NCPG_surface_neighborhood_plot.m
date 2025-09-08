% ==========================================================================
% Overall goal (user-provided): Overall goal: Plot each searchlight iteratively on the brain surface. Then all the searchlights together
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Plot each searchlight iteratively on the brain surface. Then all the searchlights together
% Note:
% ==========================================================================
% Function signature detected
function NCPG_surface_neighborhood_plot(nbrhood_sl,pial_fn)
% Toolbox call → surfing_read
[vo,fo]=surfing_read(pial_fn);
node_indices=1:length(vo);
nodesvec=1:length(node_indices);
opt.ShowEdge=0;
opt.DispMode='Add';
opt.Hold=' on';
curfig=0;
allnodesinsl=[];
plotinterval=50;
close all;
figure;
% Section: for-block starts
for ni=1:length(nbrhood_sl)
    curnbrhood=nbrhood_sl{ni};
    curnodeidx{ni}=[];
% Section: for-block starts
    for ndi=1:length(curnbrhood)
        curnodeidx{ni}(ndi)=node_indices(curnbrhood(ndi));
    end
    allnodesinsl=[allnodesinsl curnodeidx{ni}];
    curslmask=zeros(length(node_indices),1);
    curslmask(curnodeidx{ni})=1;
% Section: if-block starts
    if mod(ni,plotinterval)==0
        DispIVSurf(vo,fo,nodesvec,curslmask,1,opt);gcf;view(90,0);
        title(['Searchlight No. ' num2str(ni)])
    end
end
allnodesinsl=unique(allnodesinsl);
curslmask=zeros(length(node_indices),1);
curslmask(allnodesinsl)=1;
close all;
DispIVSurf(vo,fo,nodesvec,curslmask,1,opt);gcf;view(90,0);
title('All searchlights');
end
