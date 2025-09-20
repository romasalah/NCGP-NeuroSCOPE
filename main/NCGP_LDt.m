function [ldt_cv_sess, ldt_cv_avg_sess] = NCGP_LDt(wf, betasfn, nbrhoods_idx, nscans_subrun, maskname)

for si = 1:length(wf.sessions)
    p = NCGP_paths(wf);

    for hi = 1:length(wf.hemis)
        curnbrhoods_idx = nbrhoods_idx{si,hi};
        ldt_fn{si,hi} = [p.mp filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm ...
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

            % Build residuals for this ROI across runs
            for runi = 1:size(css,1)
                Residuals_curroi{mi}(1:css{runi,5}, :, runi) = ...
                    A(css{runi,4}(1:css{runi,5}), vox{mi});
            end

            Faces_LDC = cell(length(cvo.TrainSize), 1);
            betasbycond_train = cell(length(cvo.TrainSize), 1);
            residuals_train   = cell(length(cvo.TrainSize), 1);
            betasbycond_test  = cell(length(cvo.TrainSize), 1);

            for tri = 1:length(cvo.TrainSize)
                trainruns = training(cvo, tri);
                testruns  = test(cvo, tri);

                betasbycond_train{tri} = mean(betas_currroi(:,:,trainruns), 3);
                betasbycond_test{tri}  = betas_currroi(:,:,testruns);
                residuals_train{tri}   = mean(Residuals_curroi{mi}(:,:,trainruns), 3);

                Faces_LDC{tri} = NCGP_LDt_compute(betasbycond_train{tri}, ...
                                                  betasbycond_test{tri}, ...
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
