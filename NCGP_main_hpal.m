% ==========================================================================
% Overall goal: Master driver for the hyperalignment-based, surface MVPA workflow: runs onset parsing, GLMs, localizer contrasts, surface projections, searchlight neighborhoods, LDt computation, group stats, and map export.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ========n==================================================================
Step=1;
if Step == 1
    % Build directory config and execution order for the overall analysis workflow.
    wf1=NCGP_create_workflow('faces', {'R'},'NCGP','hpal');
    % Build directory config and execution order for the overall analysis workflow.
    wfloc1=NCGP_create_workflow('localizer', {'R'},'NCGP','hpal');
    %% Apply Hyperalignment (Generates NIML dset from GIFTI)
    % NCGP_hpal_map(wf1)
    % NCGP_hpal_map(wf1)
    %% Importing fMRIprep data From NIML dset to NIFTI
%   NCGP_niml2nii(wf1);
   % NCGP_niml2nii(wfloc1);
    %% GLM: localizer:
    % loc_runs=NCGP_onsets_localizer(wfloc1);
    % wfloc1.group=1;
    % firstleveldir=NCGP_firstlevel_fmriprep_localizer_hpal(wfloc1, [0,0], loc_runs);
    % [conimgname,conimg_clustNum,spmdir]=NCGP_localiser_contrasts_hpal(wfloc1, loc_runs);
    %% GLM: Faces:
    % Parse and format the 00main task (faces) onsets and condition labels for first-level GLMs.
    [faces_runs]=NCGP_onsets_faces_answer_eval(wf1);
    % Run first-level GLM per subject (whole-brain/surface) using fMRIPrep outputs.
    NCGP_firstlevel_fmriprep_hpal_glmpersub(wf1, [0, 0], faces_runs);
    %% #######  ALign localizer mask to sessions and extract ROIs  #######
% [S1_allnii,allroismat,S1_wholeroismat,combinedrois_binname]=NCGP_tmap2mask_allruns(localiserspmmatdir,conimgname,...
%    {S1_taskrunsprefix, S2_taskrunsprefix},0);
elseif Step==2
    %% Part 2: Must be done for session 2 and 3 simultaneoulsy
    %% Create workflows
    wf2=NCGP_create_workflow('faces', {'R'},'NCGP','hpal');
    wfbehav=NCGP_create_workflow('', {'R'},'BehavNCGP','hpal');
    wf2.sessions={ 'ses-03'};
    [faces_runs]=NCGP_onsets_faces(wf2);
    wf2.origsubs=wf2.subs;wf2.subs={'group'};
    %% Hypothesis 1
    % Compute pre vs post session differences (e.g., between-/within-group LDt change).
    [wf2.targetRSM_pre, wf2.targetRSM_post, taskname]=NCGP_prepost(wfbehav,1);
    %% 
    %% Searchlights: Neighbourhoods, Betas , and Residuals
    [ds, fullnbr_subsesshemi, vo, fo, out2in, betasfn,allnbrhoods,nscans_subrun,...
        nbrorig_subsesshemi]=NCGP_surficial_neighborhood_persub(wf2, faces_runs, 0);
    %% Calculate, visualise & save Discriminability between conditions (LDt)
    % >>>>>>>>>> Whole brain LDt <<<<<<<<
    % Orchestrate LDt computation across sessions (and hemispheres); handles loading/storing betas/residuals.
    [ldt_byrun, ldt_avgruns]=NCGP_LDt_subses(wf2, betasfn, fullnbr_subsesshemi, nscans_subrun, 'none');
    %% Hypthesis 2: Chang_LDt_subses(wf2, betasfn, fullnbr_subsesshemi, nscans_subrun, 'none');
    % 
    % Export LDt (or RDM-like) matrices across sessions/hemispheres into files for later stats/LLM usage.
   % FFXtbl_subsesshemi=NCGP_RDM_export(wf2, ldt_avgruns, fullnbr_subsesshemi, vo, fo, 'none', []);
    % Optional plotting of LDt values
    % NCGP_plot_lDt(wf2,nbrhood_e in discriminability scores
    % >>>>>>>Whole Brain<<<<<<<<spm fmri
    % Searchlight-level statistical testing of LDt changes (between-group vs within-group) with multiple-comparison control.
    [ statresults,signodes_surf]=NCGP_LDt_stats(wf2, 'none', 'TFCE',ds, ldt_avgruns);

    [ statresults,signodes_surf]=NCGP_LDt_stats_prepost(wf2, 'none', ldt_avgruns);
    % Plot and store MDS from LDt distances for visualization.
    NCGP_plot_MDS_LDC(wf2,ldt_avgruns,fullnbr_subsesshemi, TFCE_stats, stats, slnames,'none','TFCE')
    %% Hypothesis 3: Searchlight RSA (LDt Correlation with behavioural RDMs)
    % >>>>>>>Whole Brain<<<<<<<<
    % Aggregate correlation values across runs; prepare per-searchlight correlation statistics.
    [LLM_LDtcorr, LDtcorr, sigFDR_idx, q_values, LDtcorr_pval, sig_FDR_coef, corr_sesshemi, pval_sesshemi]=NCGP_LDtcorr_AvgRun(...
        wf2, ds, ldt_avgruns, taskname, vo, fo, 'none');
    % Run TFCE or surface-based cluster enhancement and output corrected maps.
    NCGP_surface_tfce(wf2, LDtcorr,corr_sesshemi, nbrorig_subsesshemi, 'none', [], taskname, ds,vo,fo);
end