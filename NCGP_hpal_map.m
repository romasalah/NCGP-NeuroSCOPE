%% Overall goal: this function calls python functions which uses surface
% projection maps (in Hdf5 format) to project surface based functional
% images (GIFTI) from fsaverage6 space to the "hyperalignment space"
function NCGP_hpal_map(wf)
p=NCPG_paths(wf);
space= ' ';
fullscriptpath=[p.imgpathin 'scripts/01hyperalignment/' 'apply_hpal_singularity.sh'];
hemis = {'R','L'};
for subi = 1:length(wf.subs)
    cursub=strrep(wf.subs{subi},'sub-','');
for hi = 1:length(hemis)
curhemi = hemis{hi};
system(['wsl bash ' fullscriptpath space p.imgpathin space cursub space curhemi])
end
end
end