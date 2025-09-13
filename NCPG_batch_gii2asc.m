% Overall goal: batch file to convert multiple files from GIFTI standard to
% ASCII standard used by freesurfer
% Note: 
% Function signature detected
function NCPG_batch_gii2asc(p, sub)
sumafolder=p.refsuma;
%bashbase=['. ~/.bash_profile;OMP_NUM_THREADS=16;'];
cmd0=[p.bashbase ' bash -c "cd ' sumafolder '; 3dcopy ' sub '_SurfVol.nii ' sub '_SurfVol+orig"'];
cmd0=strrep(cmd0,p.mainpathout, p.mainpathin);
cmd0=strrep(cmd0,filesep, '/');
unix(cmd0);
SurfVolfile=[sumafolder filesep sub '_SurfVol+orig'];
giidir=dir([sumafolder filesep '*.gii']);
% Section: for-block starts
for gi =1:length(giidir)
giifile=[giidir(1).folder filesep giidir(gi).name];
% Call → NCPG_surf_gii2asc
NCPG_surf_gii2asc(p,giifile, SurfVolfile)
end
end
