% ==========================================================================
% Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
% ==========================================================================
function NCGP_surf_main(preprocopt, coregprefix, wf)
%% Variable Naming
% Variable naming is following the pipeline as mentioned in Surfing toolbox
% manual
%% Settings and directories
mainPath = wf.mainpath;
bashbase=['. ~/.bash_profile;OMP_NUM_THREADS=16;'];
persons=[1];
subjName = ['sub-00' num2str(persons(1))];
subjPath = [mainPath wf.pre filesep subjName filesep];
t1dir = dir([subjPath filesep  'T1' filesep 'sNCGP*.nii']);
t1folder=[t1dir(1).folder filesep];
sixruns={'run-01','run-02','run-03','run-04','run-05','run-06'};
allsessions={'ses-01','ses-02'};
coregsurfacedir= [t1folder filesep];
subjid=wf.refsub;
icosahedronedges=100;
subjsurfacepath=['/Volumes/EVO8602TB/NCGP/Data/freesurfer/10'];
icoressurffiles={['ico' num2str(icosahedronedges) '_rh.pial_al.asc'], ['ico' num2str(icosahedronedges) '_rh.semiinflated_al.asc'], ['ico' num2str(icosahedronedges) '_rh.intermediate_al.asc'], ['ico' num2str(icosahedronedges) '_rh.inflated_al.asc'], ['ico' num2str(icosahedronedges) '_rh.smoothwm_al.asc']};
%% Step 1: Coreg T1 to functional, Convert NIFTI to AFNI and skull strip it
CoregT1_1=NCGP_preprocess_T1(allsessions,sixruns, coregprefix, wf);
coregt1dir=dir(CoregT1_1);
newcoregT1=[coregt1dir(1).folder filesep strrep(coregt1dir(1).name,'.nii','') '+orig'];
convertnii2afni=['cd ' t1folder '; 3dcopy ' CoregT1_1 ' ' newcoregT1];
unix([bashbase convertnii2afni]);
ssfname=strrep(newcoregT1,'+orig','_ss+orig');
skullstrip=['3dSkullStrip -overwrite -input ' newcoregT1  ' -prefix ' ssfname];
unix([bashbase skullstrip]);
%% Step 2: Reconstruct surfaces and convert them to AFNI
if preprocopt.recon
% t=[bashbase 'recon-all -all -parallel -openmp 16 -i ' t1fn ' -subjid ' subjid];
% unix(t)
end
if preprocopt.FS2SUMA
unix([bashbase '@SUMA_make_spec_FS -fspath ' subjsurfacepath ' -sid ' subjid])
end
%% Step 3: Create standard topology from surfaces, Step 4: Calculate & move surfaces from AFNI space to func space, Step 5:move the standard topology to func space
if preprocopt.ico
surfing_suma_align('action','all','subjid',subjid,...
    'origvolfn',newcoregT1,'fssurfdir',subjsurfacepath,'aligndir',coregsurfacedir,'edges',icosahedronedges);%% Step 6:
%% Step 6: Merge two hemispheres
NCGP_batch_combinesurf(t1folder, icoressurffiles);
%% Step 7 convert ICO files to AFNI
%unix([bashbase '@SUMA_make_spec_FS -fspath ' subjsurfacepath ' -sid ' subjid])
end
end