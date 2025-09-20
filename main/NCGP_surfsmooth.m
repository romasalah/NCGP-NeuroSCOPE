% ==========================================================================
% Overall goal (user-provided): Overall goal: Uses freesurfer to smooth the surface using Heat 07 method.
% ==========================================================================
function outfn=NCGP_surfsmooth(wf, outputdir, inputvol, curhemi,singimg)
curhemifull=[lower(curhemi) 'h'];
% Call → NCGP_osdir
[~,pcnum]=NCGP_osdir(wf.exp);
% Call → NCGP_paths
p = NCGP_paths(wf);
% Section: if-block starts
if ~exist("singimg","Var")
    singimg='neurodockerV4e.img';
end
fs=filesep;
unixfs='/';
% Section: if-block starts
if pcnum==1
bashbase=['. ~/.bash_profile;OMP_NUM_THREADS=16;'];
mainpathin=wf.mainpath;
mainpathout=wf.mainpath;

% Section: else-block starts
else
    mainpathin='/idata/';
    mainpathout=p.mp;
    IMG=[p.wslbasedir 'singularity/' singimg];
    bashbase=['wsl singularity exec -B ' p.wslbasedir ':/idata ' IMG ' '];     
end
refsub=wf.refsub;
sumadir=p.refsuma;
specfile=[refsub '_' curhemifull '.spec'];
smoothingkernel=wf.smkernel;
cmdbase='SurfSmooth ';
fname=strrep(inputvol, '.nii', '');
prefix=[outputdir filesep fname ];
outfn=[prefix '_S' num2str(smoothingkernel) '.niml.dset'];
fullcmd=[bashbase 'sh -c "cd ' sumadir '; ' ...
    cmdbase ...
    ' -spec ' specfile ...
    ' -met HEAT_07 -input ' outputdir filesep fname '.niml.dset -fwhm '...
    num2str(smoothingkernel) ...
    ' -output ' outfn '"'];
fullcmd=strrep(fullcmd,mainpathout, mainpathin);
fullcmd=strrep(fullcmd,fs, unixfs);
system(fullcmd)
end
