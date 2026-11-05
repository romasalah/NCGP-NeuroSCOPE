function [ldt_cv_sess, ldt_cv_avg_sess] = NCGP_LDt_persub_opt_mah( ...
    wf, betasfn, nbrhoods_idx, nscans_subrun, maskname)
% Participant-specific leave-one-run-out crossvalidated Mahalanobis LDC.
% Each participant's training and test runs come from that participant only.
% Training betas and residuals are still averaged early, as in the source.
% Outputs are indexed as {session, hemisphere, participant} and each
% participant's complete surface-searchlight results are saved separately.

p = NCGP_paths(wf);
nsub = numel(wf.origsubs);
nsess = numel(wf.sessions);
nhemi = numel(wf.hemis);

ldt_cv_sess = cell(nsess, nhemi, nsub);
ldt_cv_avg_sess = cell(nsess, nhemi, nsub);

% Use 22 shared-memory thread workers, as in the source.
pool = gcp('nocreate');
if ~isempty(pool) && ...
        (~isa(pool, 'parallel.ThreadPool') || pool.NumWorkers ~= 22)
    delete(pool);
    pool = [];
end
if isempty(pool)
    parpool('Threads', 22);
end

for si = 1:nsess
    for hi = 1:nhemi
        curnbrhoods_idx = nbrhoods_idx{si,hi};
        curnscans_subrun = nscans_subrun{si,hi};
        allroinum = numel(curnbrhoods_idx);

        S = load(betasfn{si,hi}, ...
            'betas_condbyrun', 'allres', 'beta_run_chunks');
        betas_condbyrun = S.betas_condbyrun;
        allres = S.allres;

        runnum = size(betas_condbyrun{1}, 2);
        assert(size(curnscans_subrun,1) == runnum, ...
            'Mismatch between beta runs and residual-run metadata.');
        assert(isfield(S, 'beta_run_chunks') && ...
            isequal(S.beta_run_chunks(:), (1:runnum)'), ...
            'Beta run IDs are missing or misaligned with residual runs.');
        assert(size(betas_condbyrun,1) == allroinum, ...
            'Beta searchlights and neighborhood indices differ.');
        assert(size(betas_condbyrun{1},3) == 8, ...
            'Expected eight face conditions.');

        % Column 1 identifies the participant; columns 4 and 5 give
        % residual-scan indices and the common run length respectively.
        nScans = cell2mat(curnscans_subrun(:,5));
        assert(all(nScans > 0), 'Nonpositive residual-run length.');

        for subi = 1:nsub
            subject_id = char(wf.origsubs{subi});
            subjectRunIdx = find(strcmp(curnscans_subrun(:,1), subject_id));
            nSubRuns = numel(subjectRunIdx);
            assert(nSubRuns >= 2, ...
                'Subject %s needs at least two runs for crossvalidation.', subject_id);

            fprintf('\n##### %s, Session %s, Hemisphere %s: %d runs, %d searchlights #####\n', ...
                subject_id, wf.sessions{si}, wf.hemis{hi}, ...
                nSubRuns, allroinum);

            % Local run indices refer ONLY to this participant.
            trainIdx = cell(nSubRuns,1);
            for tri = 1:nSubRuns
                trainIdx{tri} = [1:tri-1, tri+1:nSubRuns];
            end
            subNScans = nScans(subjectRunIdx);
            maxScans = max(subNScans);
            if any(subNScans ~= maxScans)
                warning('Unequal run lengths for %s: residuals will be zero-padded as in NCGP_LDt_opt_mah.', subject_id);
            end

            ldt_cv = cell(allroinum,1);
            ldt_cv_avg = cell(allroinum,1);

            nDone = 0;
            f = waitbar(0, sprintf('Computing LDC: %s, %s, %s', ...
                subject_id, wf.sessions{si}, wf.hemis{hi}));
            q = parallel.pool.DataQueue;
            listener = afterEach(q, @updateProgress);

            parfor mi = 1:allroinum
                vox = curnbrhoods_idx{mi};
                if isempty(vox)
                    ldt_cv{mi} = [];
                    ldt_cv_avg{mi} = [];
                    send(q, []);
                    continue
                end

                % Subset betas before any training/test split.
                betas_currroi = permute( ...
                    betas_condbyrun{mi}(:,subjectRunIdx,:), [1 3 2]);

                residuals_roi = zeros( ...
                    maxScans, numel(vox), nSubRuns, 'like', allres);
                for runi = 1:nSubRuns
                    globalRun = subjectRunIdx(runi);
                    scanIdx = curnscans_subrun{globalRun,4};
                    n = subNScans(runi);
                    residuals_roi(1:n,:,runi) = allres(scanIdx(1:n),vox);
                end

                Faces_LDC = cell(nSubRuns,1);
                for tri = 1:nSubRuns
                    trainruns = trainIdx{tri};

                    % Retain the original early averaging for simplicity.
                    betas_train = mean(betas_currroi(:,:,trainruns),3);
                    betas_test = betas_currroi(:,:,tri);
                    residuals_train = mean(residuals_roi(:,:,trainruns),3);

                    Faces_LDC{tri} = NCGP_LDt_compute_mah( ...
                        betas_train, betas_test, residuals_train);
                end

                tmp = cat(3, Faces_LDC{:});
                ldt_cv{mi} = tmp;
                ldt_cv_avg{mi} = mean(tmp,3);
                send(q, []);
            end

            delete(listener);
            if isgraphics(f)
                delete(f);
            end

            % Never overwrite group-pooled outputs or another participant.
            outputDir = fullfile(p.mp, 'LDt', 'persub', wf.pre, wf.glm);
            if ~isfolder(outputDir)
                mkdir(outputDir);
            end
            session = wf.sessions{si};
            hemisphere = wf.hemis{hi};
            run_indices = subjectRunIdx(:);
            outputFile = fullfile(outputDir, ...
                ['LDtbyrun_persub_mah_' subject_id '_' session ...
                 '_hemi-' hemisphere '_mask-' maskname '.mat']);
            save(outputFile, 'ldt_cv', 'ldt_cv_avg', 'subject_id', ...
                'run_indices', 'session', 'hemisphere', '-v7.3');

            ldt_cv_sess{si,hi,subi} = ldt_cv;
            ldt_cv_avg_sess{si,hi,subi} = ldt_cv_avg;
            fprintf('Saved: %s\n', outputFile);
        end

        clear betas_condbyrun allres
    end
end

    % Client-only progress callback.
    function updateProgress(~)
        nDone = nDone + 1;
        if isgraphics(f)
            waitbar(nDone / allroinum, f, ...
                sprintf('Completed %d/%d searchlights', nDone, allroinum));
        end
    end
end

% Conventional crossvalidated Mahalanobis distance (crossnobis).
% Keep training beta and residual averaging unchanged in the caller.
% Normalize by feature count, not by discriminant-vector length.
function LDCmat = NCGP_LDt_compute_mah(betas_train, betas_test, residuals_train)
[nfeatures, ncond] = size(betas_train);
[Sigma,~,~] = Function_covdiag(double(residuals_train));
LDCmat = zeros(ncond,ncond);

% Mark undefined dissimilarities rather than treating them as zero.
if any(~isfinite(Sigma(:)))
    LDCmat(triu(true(ncond),1)) = NaN;
    return
end

SigmaInv = pinv(Sigma);
for i = 1:ncond-1
    for j = i+1:ncond
        delta_train = double(betas_train(:,i) - betas_train(:,j));
        delta_test  = double(betas_test(:,i) - betas_test(:,j));
        LDCmat(i,j) = (delta_train' * SigmaInv * delta_test) / nfeatures;
    end
end
end
