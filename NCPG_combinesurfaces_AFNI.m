% ==========================================================================
% Overall goal (user-provided): Overall goal: Merge right and left hemispheres datasets into one using AFNI
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Merge right and left hemispheres datasets into one using AFNI
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
% Function signature detected
function lrt_fn = NCPG_combinesurfaces_AFNI(wf, rt,lt)
% Call → NCPG_paths
p=NCPG_paths(wf);
sumafolder=p.refsuma;
fs=filesep;
unixfs='/';
lrt_fn=strrep(rt,'rh','lrh');
lrt_fn=strrep(lrt_fn,'.asc','');
% Section: if-block starts
if exist([lrt_fn '.gii'], 'file')~=2
fullcmd=[p.bashbase 'sh -c "cd ' sumafolder ' && ' ...
    'ConvertSurface -i ' lt ' -i ' rt ' -merge_surfs -o_gii ' lrt_fn '"'];
fullcmd=strrep(fullcmd,p.mainpathout, p.mainpathin);
fullcmd=strrep(fullcmd,fs, unixfs);
system(fullcmd)
% Section: else-block starts
else
    disp(['File Exists: ' lrt_fn '.gii']);
end
end
