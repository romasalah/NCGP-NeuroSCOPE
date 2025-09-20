% ==========================================================================
% Overall goal (user-provided): Overall goal: batch file to combine 2 hemispheres
% (surface-based) into one sutface. Either using surfing toolbox or using AFNI
% Note: Comments only; code unchanged.
% Function signature detected
function NCGP_batch_combinesurf(wf, subjsurfacepath, surffiles, method, ico)
% Section: for-block starts
for i=1:length(surffiles)
    rt=[subjsurfacepath filesep surffiles{i}];
    lt=strrep(rt, 'rh', 'lh');
% Section: switch-block starts
    switch method
% Section: case-block starts
        case 'surfing'
% Call → NCGP_combinesurfaces
            NCGP_combinesurfaces({rt, lt});
% Section: case-block starts
        case 'AFNI'
% Call → NCGP_combinesurfaces_AFNI
            NCGP_combinesurfaces_AFNI(wf, rt, lt);
    end
end
% Call → NCGP_paths
p=NCGP_paths(wf);
sumafolder=p.refsuma;
fs=filesep;
unixfs='/';
disp(['Creating Spec file for Combined hemispheres']);
% Section: if-block starts
if exist([sumafolder filesep 'fsaverage6_lrh.spec'])~=2
    fullcmd=([p.bashbase 'sh -c "cd ' sumafolder ' && quickspecSL '...
        ' -out_spec fsaverage6_lrh '...
        '-surf_A lrh.smoothwm.gii -surf_B lrh.pial.gii' ...
        ' -infl_surf_A  lrh.inf_200.gii"']);
    fullcmd=strrep(fullcmd,p.mainpathout, p.mainpathin);
    fullcmd=strrep(fullcmd,fs, unixfs);
    system(fullcmd)
% Section: else-block starts
else
    disp(['File Exists: ' sumafolder filesep 'fsaverage6_lrh.spec']);
end
end
