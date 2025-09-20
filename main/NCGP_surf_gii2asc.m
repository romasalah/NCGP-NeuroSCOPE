% ==========================================================================
% Overall goal (user-provided): Overall goal: Converts a plain surface mesh (without data overlay) from GIFTI to ASCII standard using freesurfer
% ==========================================================================
function NCGP_surf_gii2asc(p, giifile, SurfVolfile)
% Section: if-block starts
if exist(strrep(giifile, '.gii', '.asc'))~=2
    cmd=[p.bashbase 'ConvertSurface -i_gii ' giifile ' -o_fs ' strrep(giifile, '.gii', '') ' -sv ' SurfVolfile];
    cmd=strrep(cmd,p.mainpathout, p.mainpathin);
    cmd=strrep(cmd,filesep, '/');
    unix(cmd);
% Section: else-block starts
else
    disp(['File Exists: ' strrep(giifile, '.gii', '.asc')]);
end
end
