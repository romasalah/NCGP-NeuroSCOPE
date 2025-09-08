% ==========================================================================
% Overall goal (user-provided): Overall goal: Utility function that corrects the path strings from Windows path to UNiX path for commands that will run inside the singularity image.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Utility function that corrects the path strings from Windows path to UNiX path for commands that will run inside the singularity image.
% Note:
% ==========================================================================
% Function signature detected
function pathin=NCPG_pathout2in(pathout,mainpathout,mainpathin)
fsout=filesep;
fsin='/';
pathin=strrep(pathout, mainpathout, mainpathin);
pathin= strrep(pathin, fsout, fsin);
end
