% ==========================================================================
% Overall goal: Master driver for the hyperalignment-based, surface MVPA workflow: runs onset parsing, GLMs, localizer contrasts, surface projections, searchlight neighborhoods, LDt computation, group stats, and map export.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ========n==================================================================
% Independent H2 duplicate: H1 and H3 remain in NCGP_main_hpal.m.
Step=2;
if Step == 1
    % Build directory config and execution order for the overall analysis workflow.
    wf1=NCGP_create_workflow('faces', {'R'},'NCGP','hpal');
    % Build directory config and execution order for the overall analysis workflow.
    wfloc1=NCGP_create_workflow('localizer', {'L'},'NCGP','hpal');
    %% Apply Hyperalignment (Generates NIML dset from GIFTI)
    % NCGP_hpal_map(wf1)
    % NCGP_hpal_map(wf1)
    %% Importing fMRIprep data From NIML dset to NIFTI
    %   NCGP_niml2nii(wf1);
    % NCGP_niml2nii(wfloc1);
    %% GLM: localizer:
    loc_runs=NCGP_onsets_localizer(wfloc1);
    wfloc1.group=1;
    firstleveldir=NCGP_firstlevel_fmriprep_localizer_hpal(wfloc1, [0,0], loc_runs);
    % [conimgname,conimg_clustNum,spmdir]=NCGP_localiser_contrasts_hpal(wfloc1, loc_runs);
    %% GLM: Faces:
    % Parse and format the 00main task (faces) onsets and condition labels for first-level GLMs.
    [faces_runs]=NCGP_onsets_faces(wf1);
    % Run first-level GLM per subject (whole-brain/surface) using fMRIPrep outputs.
    %NCGP_firstlevel_fmriprep_hpal_glmpersub(wf1, [0, 0], faces_runs);
    %% #######  ALign localizer mask to sessions and extract ROIs  #######
    % [S1_allnii,allroismat,S1_wholeroismat,combinedrois_binname]=NCGP_tmap2mask_allruns(localiserspmmatdir,conimgname,...
    %    {S1_taskrunsprefix, S2_taskrunsprefix},0);
elseif Step==2
    %% Participant-level H2: ses-02 (pre) and ses-03 (post)
    wf2=NCGP_create_workflow('faces', {'L'},'NCGP','hpal');
    wf2.sessions={'ses-02','ses-03'};
    faces_runs=NCGP_onsets_faces(wf2);
    wf2.origsubs=wf2.subs;
    wf2.subs={'group'};

    %% Searchlights, beta estimates, residuals.
    % Reuse validated beta cache when beta_run_chunks match the run order.
    [ds, fullnbr_subsesshemi, vo, fo, out2in, betasfn, allnbrhoods, ...
        nscans_subrun, nbrorig_subsesshemi] = ...
        NCGP_surficial_neighborhood_persub(wf2,faces_runs,1);

    %% Crossvalidated Mahalanobis LDC within participant only.
    [ldt_byrun_persub, ldt_avgruns_persub] = NCGP_LDt_persub_opt_mah( ...
        wf2,betasfn,fullnbr_subsesshemi,nscans_subrun,'none');

    %% H2: contrast maps, two one-sample surface GLMs, TFCE and conjunction.
    [statresults_persub,signodes_surf_persub] = ...
        NCGP_LDt_stats_prepost_persub(wf2,'none',ldt_avgruns_persub);
end
