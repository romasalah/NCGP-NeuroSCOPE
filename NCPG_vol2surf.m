% ==========================================================================
% Overall goal: Sample volumetric data to surface nodes (fsaverage6), creating per-vertex data from 3D images.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function NCPG_vol2surf(wf, inputvol, outputdir, curhemi, imgsfx)
wf.sfx=imgsfx;
% Section: if-block starts
if exist("imgsfx",'var')
wf.sfx=imgsfx;
end
% Call → NCPG_paths: Project function call
p = NCPG_paths(wf);
curspec=[lower(curhemi) 'h'];
curhemifull=curspec;
fs=filesep;
unixfs='/';
refsub=wf.refsub;
sumadir=p.refsuma;
specfile=[refsub '_' curspec '.spec'];
T1file='T1w+orig';
surfvolfile=[refsub '_SurfVol+orig'];
% disp("Copying T1 as AFNI ");
% cmd0=[bashbase 'sh -c "cd ' sumadir '; 3dcopy ' 'T1.nii.gz ' T1file '"'];
% cmd0=strrep(cmd0,mainpathout, mainpathin);
% cmd0=strrep(cmd0,fs, unixfs);
% system(cmd0);
inputvol_AFNI=strrep(inputvol,'.nii','+orig');
disp(['Copying ' inputvol ' as AFNI ']);
cmd1=[p.bashbase 'sh -c "cd ' outputdir '; 3dcopy ' inputvol ' ' inputvol_AFNI '"'];
cmd1=strrep(cmd1,p.mainpathout, p.mainpathin);
cmd1=strrep(cmd1,fs, unixfs);
unix(cmd1);
cmdbase='3dVol2Surf ';
surfAfn=[sumadir filesep curhemifull '.pial'];
surfBfn=[sumadir filesep curspec '.smoothwm'];
specfn=[sumadir filesep specfile];
surfvolfn=[sumadir filesep surfvolfile];
prefix=[inputvol_AFNI '.niml.dset'];
fullcmd=[p.bashbase 'sh -c "cd ' outputdir ' && ' ...
    cmdbase ' -spec ' specfn ...
    ' -surf_A ' surfAfn...
    ' -surf_B ' surfBfn...
    ' -sv ' surfvolfn ...
    ' -grid_parent ' inputvol ...
    ' -map_func max'...
    ' -out_niml ' prefix '"'];
fullcmd=strrep(fullcmd,p.mainpathout, p.mainpathin);
fullcmd=strrep(fullcmd,fs, unixfs);
disp(['Converting ' inputvol ' to Surface dataset ']);
system(fullcmd)
prefix1D=[inputvol_AFNI '.1D'];
delete([outputdir filesep prefix1D]);
fullcmd=[p.bashbase 'sh -c "cd ' outputdir '; ' ...
    cmdbase ' -spec ' specfn ...
    ' -surf_A ' surfAfn ...
    ' -surf_B ' surfBfn ...
    ' -sv ' surfvolfn ...
    ' -grid_parent ' inputvol ...
    ' -map_func ave'...
    ' -out_1D ' prefix1D '"'];
fullcmd=strrep(fullcmd,p.mainpathout, p.mainpathin);
fullcmd=strrep(fullcmd,fs, unixfs);
system(fullcmd)
end
