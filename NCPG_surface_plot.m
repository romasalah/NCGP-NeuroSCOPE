% ==========================================================================
% Overall goal (user-provided): Overall goal: visualize the preloaded NIML data on surfaces, if the afni matlab toolbox is present
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: visualize the preloaded NIML data on surfaces, if the afni matlab toolbox is present
% Note:
% ==========================================================================
% Function signature detected
function NCPG_surface_plot(vo,fo,dsetdata,show_edge)
nvertices=size(vo,1);
opt=struct();
    opt.ShowEdge=show_edge;
% Section: if-block starts
    if show_edge
        t='with edges';
% Section: else-block starts
    else
        t='without edges';
    end
    header=strrep([' ' t],'_',' ');
    DispIVSurf(vo,fo,1:nvertices,dsetdata,0,opt);
    title(sprintf('Original %s', header));
end
