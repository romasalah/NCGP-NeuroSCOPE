function [ldt_cv_sess, ldt_cv_avg_sess] = NCGP_LDt_concat(wf, betasfn, nbrhoods_idx, nscans_subrun, maskname)

for si = 1:length(wf.sessions)
    p = NCGP_paths(wf);

    for hi = 1:length(wf.hemis)
        curnbrhoods_idx = nbrhoods_idx{si,hi};
        ldt_fn{si,hi} = [p.mp filesep 'LDt' filesep 'group' filesep wf.pre filesep wf.glm ...
            filesep 'LDtbyrun_sub-group_' wf.sessions{si}  '_hemi-' wf.hemis{hi} '_mask-' maskname '.mat'];

        fprintf('\n \n ##################### Session %d ###################### \n \n', si);

        allroinum      = length(curnbrhoods_idx);
        ldt_cv_avg     = cell(allroinum, length(wf.hemis));
        ldt_cv         = cell(allroinum, length(wf.hemis));
        voxel_indices  = curnbrhoods_idx;
        Residuals_curroi = cell(allroinum,1);
        curnscans_subrun = nscans_subrun{si, hi};

        % --- Load exactly the variables you need (ensures they exist) ---
        S = load(betasfn{si,hi}, 'betas_condbyrun', 'allres');
        betas_condbyrun = S.betas_condbyrun;
        allres          = S.allres;

        runnum = size(betas_condbyrun{1}, 2);
        cvo    = cvpartition(runnum, 'LeaveOut');
        trcellbase = cell(length(cvo.TrainSize), 1);

        % --- Make sure the pool exists and attach needed files to workers ---
        pool = gcp('nocreate');
        if isempty(pool)
            pool = parpool(5);  % or wf.numWorkers if you have one
        end
        % Attach this file + dependencies used inside parfor:
        toAttach = {};
        thisFile = mfilename('fullpath');   if ~isempty(thisFile), toAttach{end+1} = [thisFile '.m']; end
        f1 = which('NCGP_LDt_compute.m');   if ~isempty(f1), toAttach{end+1} = f1; end
        f2 = which('parfor_progressbar.m'); if ~isempty(f2), toAttach{end+1} = f2; end
        if ~isempty(toAttach), addAttachedFiles(pool, toAttach); end

        % (Optional) Ensure the scripts directory is on all workers' path:
        % pctRunOnAll addpath(genpath(fileparts(thisFile)));

        % --- Broadcast large read-only data once to all workers ---
        allres_c          = parallel.pool.Constant(allres);
        voxel_indices_c   = parallel.pool.Constant(voxel_indices);
        curnscans_c       = parallel.pool.Constant(curnscans_subrun);
        betas_condbyrun_c = parallel.pool.Constant(betas_condbyrun);

        f = waitbar(0,'Please wait...');
        hbar = parfor_progressbar(allroinum, 'running LDC for all rois');

        parfor mi = 1:allroinum
            hbar.iterate(1);

            betas_condbyrun2 = betas_condbyrun_c.Value;  % local handle
            betas_currroi = permute(betas_condbyrun2{mi}, [1 3 2]);

            A   = allres_c.Value;
            css = curnscans_c.Value;
            vox = voxel_indices_c.Value;

            % Keep every valid residual scan from each run, without padding.
            run_residuals = cell(size(css,1),1);
            run_lengths = cell2mat(css(:,2));
            assert(sum(run_lengths) == size(A,1), ...
                'Residual scan counts do not match the stored surface residuals.');
            run_starts = [1; 1+cumsum(run_lengths(1:end-1))];
            for runi = 1:size(css,1)
                idx = run_starts(runi):(run_starts(runi)+run_lengths(runi)-1);
                run_residuals{runi} = A(idx, vox{mi});
            end
            Residuals_curroi{mi} = run_residuals;

            Faces_LDC = cell(length(cvo.TrainSize), 1);
            betasbycond_train = cell(length(cvo.TrainSize), 1);
            residuals_train   = cell(length(cvo.TrainSize), 1);
            betasbycond_test  = cell(length(cvo.TrainSize), 1);

            for tri = 1:length(cvo.TrainSize)
                trainruns = training(cvo, tri);
                testruns  = test(cvo, tri);

                % Retain all training-run beta patterns (features x conditions x runs).
                % Each run contributes its own normalized discriminant.
                betasbycond_train{tri} = betas_currroi(:,:,trainruns);
                betasbycond_test{tri}  = betas_currroi(:,:,testruns);
                residuals_train{tri}   = vertcat(run_residuals{trainruns});

                Faces_LDC{tri} = compute_ldc_all_training_runs( ...
                    betasbycond_train{tri}, betasbycond_test{tri}, ...
                    residuals_train{tri});
            end

            % Stack and average across CV folds
            tmp = cat(3, Faces_LDC{:});
            ldt_cv{mi,hi}     = tmp;
            ldt_cv_avg{mi,hi} = mean(tmp, 3);
        end

        delete(f)
        save(ldt_fn{si,hi}, 'ldt_cv', 'ldt_cv_avg');
        ldt_cv_avg_sess{si} = ldt_cv_avg;
        ldt_cv_sess{si}     = ldt_cv;
    end
end
end


% Evaluate every training run separately, without first averaging run-wise
% beta patterns. Uses one covariance estimated from concatenated training
% residuals, and keeps the held-out test run independent.
%
% NOTE: This is an all-training-run discriminant ensemble, NOT the joint
% training-partition GLM used by Tsantani et al. (2019). Reproducing their
% method requires refitting a GLM to original fMRI data for each fold.
function dist = compute_ldc_all_training_runs(train_betas, test_betas, train_residuals)
    nfeatures = size(train_betas,1);
    ncond = size(train_betas,2);
    ntrain = size(train_betas,3);
    assert(isequal(size(test_betas), [nfeatures,ncond]), ...
        'The held-out test pattern dimensions do not match training patterns.');

    Sigma = Function_covdiag(double(train_residuals));
    dist = zeros(ncond,ncond);
    for c1 = 1:(ncond-1)
        for c2 = (c1+1):ncond
            % Each column is an independent training run's face contrast.
            train_delta = reshape( ...
                double(train_betas(:,c1,:) - train_betas(:,c2,:)), ...
                nfeatures,ntrain);
            weights = Sigma \ train_delta;
            lengths = sqrt(sum(weights.^2,1));
            assert(all(isfinite(lengths) & lengths > 0), ...
                'Non-finite or zero-length training discriminant.');
            weights = weights ./ lengths;

            test_delta = double(test_betas(:,c1) - test_betas(:,c2));
            % Average held-out projections, not training beta patterns.
            dist(c1,c2) = mean(test_delta' * weights);
        end
    end
end
