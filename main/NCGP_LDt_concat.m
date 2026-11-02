function [ldt_cv_sess, ldt_cv_avg_sess] = NCGP_LDt_concat(wf, betasfn, nbrhoods_idx, nscans_subrun, maskname)

p = NCGP_paths(wf);
ldt_cv_sess = cell(numel(wf.sessions),1);
ldt_cv_avg_sess = cell(numel(wf.sessions),1);

% Use exactly 22 MATLAB thread workers, not separate worker processes.
pool = gcp('nocreate');
if ~isempty(pool) && (~isa(pool,'parallel.ThreadPool') || pool.NumWorkers ~= 22)
    delete(pool);
    pool = [];
end
if isempty(pool)
    parpool('Threads',22);
end

for si = 1:numel(wf.sessions)
    ldt_cv = cell(0,numel(wf.hemis));
    ldt_cv_avg = cell(0,numel(wf.hemis));

    for hi = 1:numel(wf.hemis)
        S = load(betasfn{si,hi},'betas_condbyrun','allres','beta_run_chunks');
        assert(isfield(S,'beta_run_chunks'), ...
            'Rebuild the beta cache to verify beta/residual run alignment.');
        betas = S.betas_condbyrun;
        allres = S.allres;
        voxels = nbrhoods_idx{si,hi};
        css = nscans_subrun{si,hi};

        nrun = size(betas{1},2);
        ncond = size(betas{1},3);
        run_lengths = cell2mat(css(:,2));
        assert(ncond == 8, 'Expected eight face conditions.');
        assert(numel(run_lengths) == nrun && ...
            isequal(S.beta_run_chunks(:),(1:nrun)'), ...
            'Beta and residual run IDs differ. Check missing runs and ordering.');
        assert(sum(run_lengths) == size(allres,1), ...
            'Residual scan counts do not match the SPM run metadata.');

        run_starts = [1; 1+cumsum(run_lengths(1:end-1))];
        nroi = numel(voxels);
        cv = cell(nroi,1);
        avg = cell(nroi,1);
        valid_fold_counts = cell(nroi,1);
        failed_counts = zeros(nroi,1);

        fprintf('Session %s, hemisphere %s: %d runs, %d searchlights\n', ...
            wf.sessions{si}, wf.hemis{hi}, nrun, nroi);

        % Receive progress updates on the client, without temporary files.
        completed = 0;
        progress_total = nroi;
        progress_started = tic;
        progressbar = waitbar(0,sprintf('0/%d searchlights',nroi));
        q = parallel.pool.DataQueue;
        afterEach(q,@update_progress);

        parfor (mi = 1:nroi,22)
            B = permute(betas{mi},[1 3 2]); % vertices x 8 conditions x runs
            R = double(allres(:,voxels{mi}));
            residuals = cell(nrun,1);
            for r = 1:nrun
                idx = run_starts(r):(run_starts(r)+run_lengths(r)-1);
                residuals{r} = R(idx,:) - mean(R(idx,:),1);
            end

            folds = zeros(ncond,ncond,nrun);
            nfailed = 0;
            for test = 1:nrun
                train = [1:test-1, test+1:nrun];
                [folds(:,:,test), failed] = NCGP_compute_ldc_all_training_runs( ...
                    B(:,:,train), B(:,:,test), residuals(train));
                nfailed = nfailed + failed;
            end

            cv{mi} = folds;
            avg{mi} = mean(folds,3,'omitnan');
            valid_fold_counts{mi} = sum(isfinite(folds),3);
            failed_counts(mi) = nfailed;
            send(q,1);
        end

        if isgraphics(progressbar), close(progressbar); end
        ldt_cv(1:nroi,hi) = cv;
        ldt_cv_avg(1:nroi,hi) = avg;

        ldt_fn = fullfile(p.mp,'LDt','group',wf.pre,wf.glm, ...
            ['LDtbyrun_concat_sub-group_' wf.sessions{si} ...
             '_hemi-' wf.hemis{hi} '_mask-' maskname '.mat']);
        outdir = fileparts(ldt_fn);
        if ~exist(outdir,'dir')
            mkdir(outdir);
        end
        save(ldt_fn,'ldt_cv','ldt_cv_avg','failed_counts','valid_fold_counts','-v7.3');
        fprintf('Failed training discriminants: %d\n',sum(failed_counts));
    end

    ldt_cv_sess{si} = ldt_cv;
    ldt_cv_avg_sess{si} = ldt_cv_avg;
end

    function update_progress(~)
        completed = completed + 1;
        step = max(1,ceil(progress_total/100));
        if isgraphics(progressbar) && ...
                (mod(completed,step) == 0 || completed == progress_total)
            remaining = toc(progress_started)/completed*(progress_total-completed);
            waitbar(completed/progress_total,progressbar, ...
                sprintf('%d/%d searchlights (%.0f%%), ~%.0f min left', ...
                completed,progress_total,100*completed/progress_total,remaining/60));
        end
    end
end
