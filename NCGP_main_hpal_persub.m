% Participant-level H2 only; original NCGP_main_hpal.m remains unchanged.
wf2=NCGP_create_workflow('faces',{'L'},'NCGP','hpal');
wf2.sessions={'ses-02','ses-03'};
faces_runs=NCGP_onsets_faces(wf2);
wf2.origsubs=wf2.subs;
wf2.subs={'group'};

% Shared searchlight geometry and validated beta/residual run order.
[ds,fullnbr_subsesshemi,vo,fo,out2in,betasfn,allnbrhoods,nscans_subrun, ...
    nbrorig_subsesshemi]=NCGP_surficial_neighborhood_persub(wf2,faces_runs,1);

% Compute LDC independently within each participant.
[ldt_byrun_persub,ldt_avgruns_persub]=NCGP_LDt_persub_opt_mah( ...
    wf2,betasfn,fullnbr_subsesshemi,nscans_subrun,'none');

% One paired SPM model; surface TFCE with valid component sign flips.
[statresults_persub,signodes_surf_persub]=NCGP_LDt_stats_prepost_persub( ...
    wf2,'none',ldt_avgruns_persub);
