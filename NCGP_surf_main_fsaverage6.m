% ==========================================================================
% Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
function NCGP_surf_main_fsaverage6(mainpath,preprocopt)
%% Variable Naming
% Variable naming is following the pipeline as mentioned in Surfing toolbox
% manual
%% Settings and directories
mainpath = '/Volumes/EVO8602TB/NCPG/Data/';
bashbase=['. ~/.bash_profile;OMP_NUM_THREADS=16;'];
subjid='fsaverage6';
fsdir=[mainpath filesep 'freesurfer'];
subjsurfacepath=[fsdir filesep subjid];
t1folder=[subjsurfacepath filesep 'mri'];
t1fname='brain.mgz';
coregsurfacedir=[t1folder filesep 'coreg'];
sixruns={'run-01','run-02','run-03','run-04','run-05','run-06'};
allsessions={'ses-01','ses-02'};
icosahedronedges=100;
icoressurffiles={...
    ['ico' num2str(icosahedronedges) '_rh.pial_al.asc'],...
    ['ico' num2str(icosahedronedges) '_rh.semiinflated_al.asc'],...
    ['ico' num2str(icosahedronedges) '_rh.intermediate_al.asc'],...
    ['ico' num2str(icosahedronedges) '_rh.inflated_al.asc'],...
    ['ico' num2str(icosahedronedges) '_rh.smoothwm_al.asc']};
%% Step 1: Coreg T1 to functional, Convert NIFTI to AFNI and skull strip it
niifname=strrep(t1fname,'.mgz','.nii.gz');
convertmgz2nii=['cd ' t1folder '; mri_convert ' t1fname ' ' niifname];
unix([bashbase convertmgz2nii]);
newcoregT1=[strrep(niifname,'.nii.gz','') '+orig'];
convertnii2afni=['cd ' t1folder '; 3dcopy ' niifname ' ' newcoregT1];
unix([bashbase convertnii2afni]);
%% Step 3: Create standard topology from surfaces, Step 4: Calculate & move surfaces from AFNI space to func space, Step 5:move the standard topology to func space
if preprocopt.ico
surfing_suma_align('action','all','subjid',subjid,...
    'origvolfn',newcoregT1,'fssurfdir',subjsurfacepath,'aligndir',coregsurfacedir,'edges',icosahedronedges);%% Step 6:
%% Step 6: Merge two hemispheres
NCPG_batch_combinesurf(t1folder, icoressurffiles);
%% Step 7 convert ICO files to AFNI
%unix([bashbase '@SUMA_make_spec_FS -fspath ' subjsurfacepath ' -sid ' subjid])
end
end