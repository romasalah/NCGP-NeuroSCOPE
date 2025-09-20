% Overall goal: Smoothes a NIML surface dataset using freesurfer's HEAT_07 method with a custom kernelsize.
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
% Function signature detected
function NCGP_dset_smooth(surf, surffolder, dset, kernelsize)
bashbase=['. ~/.bash_profile;export DYLD_LIBRARY_PATH=/opt/X11/lib/flat_namespace;'];
speccmd=[bashbase 'cd ' surffolder  '; quickspec -tn FS ' surf];
system(speccmd);
specfile=[surffolder filesep 'quick.spec'];
output=strrep(dset,'.niml.dset', ['_s' num2str(kernelsize) '.niml.dset']);
cmd= [bashbase 'SurfSmooth -met HEAT_07 -spec ' specfile ' -surf_A ' surf ...
' -input ' dset ' -output ' output ...
' -fwhm ' num2str(kernelsize)];
system(cmd);
end
