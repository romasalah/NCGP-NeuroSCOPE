% ==========================================================================
% Overall goal: Wrap surface/HPA steps: fsaverage6 templates/masks, niml/nii conversions, or SUMA interfacing.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function NCGP_surf_hpal(wf)
%% Variable Naming
% Variable naming is following the pipeline as mentioned in Surfing toolbox
% manual
%% Settings and directories
% Call → NCGP_paths: Project function call
p = NCGP_paths(wf);
fs=filesep;
unixfs='/';
sumafolder= p.refsuma;
fsfolder = p.fs;
t1folder=sumafolder;
niftiT1=[sumafolder filesep 'T1w'];
icoressurffiles={'rh.pial.asc','rh.inf_200.asc','rh.inflated.asc', 'rh.white.asc', 'rh.smoothwm.asc'};
%% Step 1: Coreg T1 to functional, Convert NIFTI to AFNI and skull strip it
newcoregT1=[sumafolder filesep 'T1w+orig'];
convertnii2afnicmd=['wsl -c "3dcopy ' niftiT1 ' ' newcoregT1 '"'];
ssfname=strrep(newcoregT1,'+orig','_ss+orig');
skullstripcmd=['wsl -c "3dSkullStrip -overwrite -input ' newcoregT1  ' -prefix ' ssfname '"'];
makespeccmd=['wsl -c "@SUMA_Make_Spec_FS -NIFTI -fspath ' fsfolder ' -sid ' wf.refsub '"'];
% fix paths
makespeccmd=strrep(makespeccmd,p.mainpathout, p.mainpathin);
makespeccmd=strrep(makespeccmd,fs, unixfs);
% Execute
out3=unix(makespeccmd)
% Call → NCGP_batch_gii2asc: Project function call
NCGP_batch_gii2asc(p, wf.refsub);
%% Step 6: Merge two hemispheres
% Call → NCGP_batch_combinesurf: Project function call
NCGP_batch_combinesurf(wf, t1folder, icoressurffiles, 'AFNI');
end
