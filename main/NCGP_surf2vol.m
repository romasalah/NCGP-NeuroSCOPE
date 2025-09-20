% ==========================================================================
% Overall goal (user-provided): Overall goal: Projects a NIML surface dataset into a volume using fsaverage6 surfacevolume
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Projects a NIML surface dataset into a volume using fsaverage6 surfacevolume
% ==========================================================================
% Function signature detected
function volname=NCGP_surf2vol(wf, curfolderdir, curimg, curhemi)
curhemifull=[lower(curhemi) 'h'];
pialfile=[curhemifull '.pial'];
specfile=['fsaverage6_' curhemifull '.spec'];
fsout=filesep;
fsin='/';
% Call → NCGP_paths
p = NCGP_paths(wf);
sumasuffix='freesurfer/fsaverage6/SUMA/';
sumafolder=[p.mainpathin 'derivatives/' sumasuffix '/'];
sumafolderout=[p.mainpathout 'derivatives' filesep 'freesurfer' fsout wf.refsub fsout 'SUMA' fsout];
surfvol=[sumafolder 'fsaverage6_SurfVol+orig'];
cur1Dfnout=[sumafolderout 'cur1d.1D'];
% Call → NCGP_pathout2in
cur1Dfnin=NCGP_pathout2in(cur1Dfnout,p.mainpathout,p.mainpathin);
curimg=strrep(curimg,'.nii','');
curprefix=strrep(curimg, '.niml.dset','');
% Call → NCGP_pathout2in
curprefixin=NCGP_pathout2in(curprefix,p.mainpathout,p.mainpathin);
% Call → NCGP_pathout2in
curspmdirin=NCGP_pathout2in(curfolderdir,p.mainpathout,p.mainpathin);
shortprefix=strrep(curprefixin,[curspmdirin fsin],'');
T1AFNI=[sumafolder 'T1+orig'];
% Toolbox call → surfing_read
dsetst=surfing_read([curfolderdir filesep curimg]);
delete(cur1Dfnout);
dlmwrite(cur1Dfnout,dsetst.data);
delete([p.refsuma filesep curprefixin '+orig.BRIK']);
delete([p.refsuma filesep curprefixin '+orig.HEAD']);
msgs=system([p.bashbase 'sh -c "cd ' sumafolder '; 3dSurf2Vol -spec ' specfile ' -surf_A ' pialfile ...
    ' -sdata ' cur1Dfnin ' -sv ' surfvol ' -prefix ' curprefixin...
    ' -map_func ave -grid_parent ' T1AFNI '"']);
briknamesumain=([p.refsuma filesep curprefixin '+orig.BRIK.gz']);
headnamesumain=([p.refsuma  filesep curprefixin '+orig.HEAD']);
briknameldtin=([curfolderdir curprefixin '+orig.BRIK.gz']);
headnameldtin=([curfolderdir curprefixin '+orig.HEAD']);
movefile(briknamesumain,briknameldtin);
movefile(headnamesumain,headnameldtin);

system([p.bashbase 'sh -c "cd ' curspmdirin '&& 3dAFNItoNIFTI ' curspmdirin shortprefix '+orig -prefix ' shortprefix '"'])
volname=[curfolderdir curprefixin '.nii.gz'];
gunzip(volname);
delete(briknameldtin);
delete(headnameldtin);
delete(volname);
end
