% ==========================================================================
% Overall goal (user-provided): Overall goal: Clusterize a surface data image with radius rmm and area amm
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Clusterize a surface data image with radius rmm and area amm
% Note:
% ==========================================================================
% Function signature detected
function outfn=NCPG_surfclust(wf, inputdset, curhemi)
curhemifull=[lower(curhemi) 'h'];
% Call → NCPG_paths
p = NCPG_paths(wf);
sumadir=p.refsuma;
cmdbase='SurfClust ';
inputdset=strrep(inputdset, '.nii', '+orig.niml.dset');
outfn=strrep(inputdset, '+orig', '_clust+orig');
% Section: if-block starts
if exist(outfn, 'file')~=2
    fullcmd=[p.bashbase 'sh -c "cd ' sumadir '; ' ...
        cmdbase ...
        ' -i '  sumadir filesep curhemifull '.pial.asc'...
        ' -input ' inputdset ' 0' ...
        ' -rmm -10' ...
        ' -out_roidset '...
        ' -athresh 0 ' ...
        ' -amm2 10'...
        ' -thresh_col 0'...
        ' -prefix ' outfn '"'];
    fullcmd=strrep(fullcmd,p.mainpathout, p.mainpathin);
    fullcmd=strrep(fullcmd,filesep, '/');
    system(fullcmd)
% Section: else-block starts
else
    disp(['File Exists: ' outfn]);
end
end
