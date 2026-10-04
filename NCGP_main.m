%% #######  Settings  #######
wfloc.sessions={'ses-01'};
wfloc.runs={'run-01','run-02', 'run-03','run-04'};
wfloc.pre='fmriprep';
wfloc.glm='SPM_GLM';
wfloc.mainpath='/Volumes/EVO8602TB/NCPG/BIDS/Main1/';
wfloc.derivpath=[wfloc.mainpath filesep 'derivatives'];
wfloc.task='localizer';
wfloc.modeltype='localizer';
subs=string(5);
wfloc.subs={};
for i=1:length(subs)
    wfloc.subs{end+1}=['sub-00' subs{i}];
end
wfloc.volskip=0;
wfloc.smooth=0;
wfloc.threshold=0.001;
wfloc.mink=3;
wfloc.refsub='fsaverage6';
wfloc.group=1;
wfloc.normalise=0;
wfloc.glmderiv=[1 1];
wfloc.alignment='aal';
realignpersession=1;
modeltype='regperidentity';
GLMperrun=1; % One GLM for each run?
min_validROIsize=16; %minimum observations per RDM
threshold=0.01;mink=5;
loc_runs={'run_1'};loc_sessions = {'S1_localiser','S2_localiser'};
sixruns={'run_1','run_2','run_3','run_4','run_5','run_6'};
sixruns_fmriprep={'run-01','run-02','run-03','run-04','run-05','run-06'};
allsessions={'S1'};
mdlprefix={'pre','post'};
%namedrois={'lFFA','lpSTS','ltOFA','ltV2','rFFA','rFFAant','rpSTS'};
namedrois={'rOFA','rFFA','rpSTS'};
%% ####### Localizer Univariate Analysis - fMRIprep #####
NCPG_onsets(wfloc)
for i=1:length(wfloc.subs)
    %NCPG_preprocess_normalise(wfloc,[2 2 3], wfloc.subs{i})
    NCPG_preprocess_smooth(wfloc, [6 6 6], wfloc.subs{i})
end
NCPG_firstlevel_fmriprep(wfloc, wfloc.glmderiv);
[localiserspmmatdir,conimgname]=NCPG_firstlevel_localiser({'contrasts'},wfloc,wfloc.glmderiv,wfloc.threshold,wfloc.mink);
%% #######  First level GLM #######
%  firstlevel localiser runs
wf1.pre='SPMprep';wf1.decoding='Cosmo_surfdecoding';wf1.stats='perm_stats';wf1.glm='SPM_GLM';wf1.mcc='FDR_MCC';
wf1.radius=10; wf1.classifier='libsvm';
wf1.t1folder=['/Volumes/EVO8602TB/NCPG/BIDS/Main1/' wf1.pre '/sub-001/T1/'];
NCPG_firstlevel_localiser({'FFXspecAndEst'},wfloc,'',wfloc.glmderiv);
[localiserspmmatdir,conimgname]=NCPG_firstlevel_localiser({'contrasts'},wfloc,'uraf',wfloc.glmderiv,threshold,mink);

% for ri=1:length(sixruns)
%     NCPG_firstlevel({'FFXspecAndEst'},{'S1'},{sixruns{ri}},'uraf',HRFderivatives,modeltype, wf1);
%     NCPG_firstlevel({'FFXspecAndEst'},{'S2'},{sixruns{ri}},'uraf',HRFderivatives,modeltype, wf1);
% end
%% #######  ALign localizer mask to sessions and extract ROIs  #######
[S1_allnii,allroismat,S1_wholeroismat,combinedrois_binname]=NCPG_tmap2mask_allruns(localiserspmmatdir,conimgname,...
   {S1_taskrunsprefix, S2_taskrunsprefix},0);
%% ####### Replicate Tsantani et al. 2021 Correlation of Brain RDM with Models' RDMs #######
%% Replicate with over whole Localiser ROIs
named_roismat=dir([localiserspmmatdir filesep '*named*roi.mat']);
named_roismat=named_roismat(contains({named_roismat(:).name},namedrois));
named_roismat={named_roismat, named_roismat};
[voxcondrun, validrois, S1_voxcondrun_res]=NCPG_getRDMs_singleruns({'S1','S2'},sixruns,named_roismat,min_validROIsize, modeltype); %Get RDMs, Modeled response and Residuals
ldt_cv=NCPG_LDt(voxcondrun, S1_voxcondrun_res); %Calculate LDC
curroiname=NCPG_fn2ROIn(validrois);
NCPG_runconsistency(voxcondrun(:,1),curroiname,6,0)
NCPG_runconsistency(voxcondrun(:,2),curroiname,6,0)
NCPG_ROI_behavrsm(ldt_cv, validrois);
%% Replicate with over all Localiser ROIs
allroismat={allroismat, allroismat};
[voxcondrun, validrois, S1_voxcondrun_res]=NCPG_getRDMs_singleruns({'S1','S2'},sixruns,allroismat,min_validROIsize, modeltype); %Get RDMs, Modeled response and Residuals
ldt_cv=NCPG_LDt(voxcondrun, S1_voxcondrun_res); %Calculate LDC
curroiname=NCPG_fn2ROIn(validrois);
NCPG_runconsistency(voxcondrun(:,1),curroiname,6,0)
NCPG_runconsistency(voxcondrun(:,2),curroiname,6,0)
NCPG_ROI_behavrsm(ldt_cv, validrois);
%% Replicate with Tsantani group average ROIs
tsamaskdir='C:\Users\CENs-Admin\Documents\Omar\NCPG\scripts\Faces and voices in the Brain\ROIs\Original_group_masks';
tsa21iw_roismat=dir([tsamaskdir filesep 'iw_F*.mat']);
tsa21iw_roismat={tsa21iw_roismat, tsa21iw_roismat};
[voxcondrun, validrois, S1_voxcondrun_res]=NCPG_getRDMs_singleruns({'S1','S2'},1:6,tsa21iw_roismat,16, '');
ldt_cv=NCPG_LDt(voxcondrun, S1_voxcondrun_res);
curroiname=NCPG_fn2ROIn(validrois);
NCPG_ROI_behavrsm(ldt_cv, validrois);
%% Search within Localiser ROIs
flags.normaliseoutput=0;
sls=[10:20:150];
    for i=1:length(sls)
          [ds_rsm_behav,imagenames]=NCPG_fmri_searchlight_rsm(allsessions,sixruns,modeltype,conimgname,'Whole Brain',sls(i),flags);
    end
%% ####### Rerun Tsantani 2021 Original Data with own code #######
[ROInames_tsa, betaruns]= NCPG_sta21_RDMs(flag);
NCPG_runconsistency(betaruns,ROInames_tsa',3, 0);
NCPG_ROI_behavrsm_tsantani21(flag)
%% ######### Castello et al. 2021 (pre:SPM - GLM:SPM - MVPA:CosmoMVPA) Surface-based Face identitiy decoding ##########
ICOedgesnum=100; preprocopt.ico=1; preprocopt.FS2SUMA=0; preprocopt.recon=0;
NCPG_surf_main(preprocopt, wf1)
NCPG_firstlevel({'FFXspecAndEst'},{'ses-01', 'ses-02'},sixruns_fmriprep,'uraf',HRFderivatives,modeltype, wf1);
NCPG_decoding_surface_fmriprep(t1folder, 'libsvm', 10, {'ses-01', 'ses-02'}, sixruns_fmriprep, ICOedgesnum, 0, 'regperidentity',wf1);
NCPG_decoding_surface_permute_fmriprep(t1folder, 'libsvm', 10,  {'ses-01', 'ses-02'}, sixruns_fmriprep, ICOedgesnum, 0, 'regperidentity',100, wf1);
NCPG_decoding_surface_fdr({'ses-01', 'ses-02'}, ICOedgesnum, wf1);
NCPG_replotres(wf1.t1folder, wf1.classifier, wf1.radius, {'ses-01', 'ses-02'}, ICOedgesnum, 'semiinflated', wf1)
%% ######### Castello et al. 2021 (pre:fMRIprep - GLM:AFNI - MVPA:CosmoMVPA) Surface-based Face identitiy decoding ##########
ICOedgesnum=100; preprocopt.ico=1; preprocopt.FS2SUMA=0; preprocopt.recon=0;
wf2.pre='fmriprep';wf2.decoding='Cosmo_surfdecoding';wf2.stats='perm_stats';wf2.glm='SPM_GLM';wf2.mcc='FDR_MCC';
wf2.radius=10; wf2.classifier='libsvm';
wf2.t1folder=['/Volumes/EVO8602TB/NCPG/Data/' wf2.pre '/sub-001/T1/'];
coregfirst='sub-001_ses-01_task-faces_run-01_bold_space-T1w_preproc_00001';
NCPG_surf_main(preprocopt, coregfirst, wf2) %should I redo the alignment for fmriprep results?
NCPG_firstlevel_fmriprep({'FFXspecAndEst'},{'ses-01', 'ses-02'},sixruns_fmriprep,'uraf',HRFderivatives,modeltype, wf2);
NCPG_decoding_surface_fmriprep(wf2.t1folder, 'libsvm', 10, {'ses-01', 'ses-02'}, sixruns_fmriprep, ICOedgesnum, 0, 'regperidentity',wf2);
NCPG_decoding_surface_permute_fmriprep(wf2.t1folder, 'libsvm', 10,  {'ses-01','ses-02'}, sixruns_fmriprep, ICOedgesnum, 0, 'regperidentity',100, wf2);
NCPG_decoding_surface_fdr({'ses-01','ses-02'}, ICOedgesnum, wf2);
NCPG_replotres(wf2.t1folder, wf2.classifier, wf2.radius, {'ses-01', 'ses-02'}, ICOedgesnum, 'semiinflated', wf2)
%% AFNI workflow
wf3.pre='fmriprep';wf3.decoding='Cosmo_surfdecoding';wf3.stats='perm_stats';
wf3.glm='SPM_GLM';wf3.mcc='FDR_MCC';wf3.radius=10; wf3.classifier='libsvm';
wf3.t1folder=['/Volumes/EVO8602TB/NCPG/Data/' wf3.pre '/sub-001/T1/'];
NCPG_decoding_surface_fdr({'ses-01','ses-02'}, 0, wf3);
respath='/Volumes/EVO8602TB/NCPG/Data/FDR_MCC/sub-001/fmriprep/AFNI_GLM/Cosmo_surfdecoding/perm_stats/';
NCPG_dset_split([respath  'slclfbwsbj-blockrun-remlfit-fsaverage6-pre'],'*avgfdr')
NCPG_dset_split([respath  'slclfbwsbj-blockrun-remlfit-fsaverage6-post'],'*avgfdr')
NCPG_SUMA_viz([respath,], dsetfolder, hemi, subj)
%% ######### Volumetric Face identitiy decoding ##########
sls=[10:20:150];
cls={'lda','libsvm','knn','nb'};
for clsi=1:length(cls)
    for i=1:length(sls)
        cosomo_searchlight_lda(allsessions,sixruns,'','Whole Brain',cls{clsi},sls(i),0,modeltype);
    end
end