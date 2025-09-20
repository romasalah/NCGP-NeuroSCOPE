% ==========================================================================
% Overall goal: Run TFCE or surface-based cluster enhancement and output corrected maps.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
    function NCGP_surface_tfce(wf, surfdscell, nulldscells,cluster_nbrhood,maskname, mask_idx,tasknames,oldds,vo,fo)
%% Run Threshold-Free Cluster Enhancement (TFCE)

% All data is prepared; surf_ds has 8 samples and 5124 nodes. We want to
% see if there are clusters that show a significant difference from zero in
% their response. Thus, .sa.targets is set to all ones (the same
% condition), whereas .sa.chunks is set to (1:8)', indicating that all
% samples are assumed to be independent.
%
% (While this is a within-subject analysis, exactly the same logic can be
% applied to a group-level analysis)

% define neighborhood for each feature
% (cosmo_cluster_neighborhood can be used also for meeg or volumetric
% fmri datasets)
% Toolbox call → cosmo_cluster_neighborhood
%cluster_nbrhood=cosmo_cluster_neighborhood(surf_ds, 'vertices',vo,'faces',fo);
opt=struct();
% number of null iterations. for publication-quality, use >=1000;
% 10000 is even better
%opt.niter=250;
% in this case we run a one-sample test against a mean of 0, and it is
% necessary to specify the mean under the null hypothesis
% (when testing classification accuracies, h0_mean should be set to chance
% level, assuming a balanced crossvalidation scheme was used)
opt.h0_mean=0;
% this example uses the data itself (with resampling) to obtain cluster
% statistcs under the null hypothesis. This is (in this case) somewhat
% conservative due to how the resampling is performed.
% Alternatively, and for better estimates (at the cost of computational
% cost), one can generate a set of (say, 50) datasets using permuted data
% e.g. using cosmo_randomize_targets), put them in a cell and provide
% them as the null argument.
opt.feature_stat='none';
opt.cluster_stat='tfce';
opt.seed=1;
% Run TFCE-based cluster correction for multiple comparisons.
% The output has z-scores for each node indicating the probablity to find
% the same, or higher, TFCE value under the null hypothesis
% Call → NCGP_paths: Project function call
p=NCGP_paths(wf);
outputpath=[p.mp filesep 'RDMcorr\group\fmriprep\SPM_GLM\'];
% Section: for-block starts
for ti =1:length(wf.targetRSM_post)
% Section: for-block starts
    for hi =1:length(wf.hemis)
% Section: for-block starts
        for si =1:length(wf.sessions)
            curnull=nulldscells{ti}{si,hi}';
            curds{si,hi}=oldds{si,hi};
            corrdsname=['sub-group_' wf.sessions{si} '_task-' tasknames{ti}...
                '_hemi-' wf.hemis{hi} '_mask-' maskname '_corr-TFCE_correlation'];
            curvo=vo{si,hi};
            curfo=fo{si,hi};
% Section: for-block starts
            for permi =1:1000
                curnullds{permi}=curds{si,hi};
                curnullds{permi}.samples=cell2mat(curnull(permi,:));
                curnullds{permi}.sa.targets=1;
                curnullds{permi}.sa.chunks=1;
                curnullds{permi}.sa.labels='';
            end
            surf_ds=surfdscell{ti}{si}(:,hi);
            surf_ds(surf_ds<0)=0;
            curds{si,hi}.samples=surf_ds';
            curds{si,hi}.sa=struct();
            curds{si,hi}.sa.targets=1;
            curds{si,hi}.sa.chunks=1;
            curds{si,hi}.sa.labels='';
            opt.dh=0.1;
            opt.null=curnullds;
% Toolbox call → cosmo_cluster_neighborhood
            cluster_nbrhood{si,hi}=cosmo_cluster_neighborhood(curds{si,hi},...
                'vertices',curvo,'faces',curfo);
% Toolbox call → cosmo_montecarlo_cluster_stat
            tfce_ds=cosmo_montecarlo_cluster_stat(curds{si,hi},cluster_nbrhood{si,hi},opt);
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(curds{si,hi}, [ outputpath corrdsname '_debug.niml.dset']);
            %% Plot the sorted z-scores
            fprintf('TFCE z-score dataset\n');
            nfeatures=size(tfce_ds.samples,2);
            percentiles=(1:nfeatures)/nfeatures*100;
            figure;plot(percentiles,sort(tfce_ds.samples))
            title('sorted TFCE z-scores');
            xlabel('feature percentile');
            ylabel('z-score');
            %% limit results to top 5 percent (one-tailed)
            p = 0.05;
            p_str=strrep(num2str(p),'0.','');
            z_th = norminv(1-p/1); % from https://sushrutthorat.com/2020/02/09/tfce-cosmomvpa
            tfce_ds_sig=tfce_ds;
            % Create thresholded maps and save them
            pos_voxs_loc = tfce_ds.samples >= z_th;
            % map of all responses significantly above the baseline
            tfce_ds_sig.samples(~pos_voxs_loc)=0;
            % Weigh significant searchlights by the correlation value
            tfce_ds_wbcorr=tfce_ds_sig;
            binary_sig_sls=tfce_ds_sig.samples~=0;
            tfce_ds_wbcorr.samples=binary_sig_sls .* curds{si,hi}.samples;
            %% view and export results
            fn_tfce_ds=[outputpath corrdsname '_alpha-' p_str '_tail-right.niml.dset'];
            fn_tfce_ds_unth=[outputpath corrdsname '_unthresholded.niml.dset'];
            fn_tfce_ds_wbcorr=[outputpath corrdsname '_alpha-' p_str '_tail-right_WBCorr.niml.dset'];
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tfce_ds_sig, fn_tfce_ds);
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tfce_ds_wbcorr, fn_tfce_ds_wbcorr);
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tfce_ds, fn_tfce_ds_unth);
            nvertices=size(curvo,1);
            disp_opt=struct();
            DispIVSurf(curvo,curfo,1:nvertices,tfce_ds.samples',0,disp_opt);
        end
    end
end
end
