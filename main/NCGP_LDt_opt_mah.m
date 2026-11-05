
function [ldt_cv_sess, ldt_cv_avg_sess] = NCGP_LDt_opt_mah( ...
    wf, betasfn, nbrhoods_idx, nscans_subrun, maskname)

p = NCGP_paths(wf);

ldt_cv_sess     = cell(length(wf.sessions), 1);
ldt_cv_avg_sess = cell(length(wf.sessions), 1);

% Use memory-efficient thread workers
pool = gcp('nocreate');

if isempty(pool) || ~isa(pool, 'parallel.ThreadPool')
    if ~isempty(pool)
        delete(pool);
    end
    pool = parpool('Threads', 22);
end

for si = 1:length(wf.sessions)
    for hi = 1:length(wf.hemis)

        fprintf('\n##### Session %d, Hemisphere %d #####\n', si, hi);

        curnbrhoods_idx = nbrhoods_idx{si,hi};
        curnscans_subrun = nscans_subrun{si,hi};

        allroinum = numel(curnbrhoods_idx);

        ldt_cv     = cell(allroinum, length(wf.hemis));
        ldt_cv_avg = cell(allroinum, length(wf.hemis));

        % Load data
        S = load(betasfn{si,hi}, ...
            'betas_condbyrun', 'allres');

        betas_condbyrun = S.betas_condbyrun;
        allres = S.allres;
        clear S

        runnum = size(betas_condbyrun{1}, 2);

        assert(size(curnscans_subrun,1) == runnum, ...
            'Mismatch between beta runs and residual runs.');

        % Precompute leave-one-run-out partitions
        cvo = cvpartition(runnum, 'LeaveOut');

        trainIdx = cell(runnum,1);
        testIdx  = cell(runnum,1);

        for tri = 1:runnum
            trainIdx{tri} = training(cvo,tri);
            testIdx{tri}  = test(cvo,tri);
        end

        nScans = cell2mat(curnscans_subrun(:,5));
        maxScans = max(nScans);

        if any(nScans ~= maxScans)
            warning(['Unequal run lengths: residuals will be ' ...
                     'zero-padded as in the original implementation.']);
        end

        % Progress bar on client only
        f = waitbar(0, 'Computing crossvalidated Mahalanobis LDC...');
        nDone = 0;

        q = parallel.pool.DataQueue;
        listener = afterEach(q, @updateProgress);

        parfor mi = 1:allroinum

            vox = curnbrhoods_idx{mi};

            if isempty(vox)
                ldt_cv{mi,hi} = [];
                ldt_cv_avg{mi,hi} = [];
                send(q, []);
                continue;
            end

            % Extract beta values for this ROI
            betas_currroi = permute( ...
                betas_condbyrun{mi}, [1 3 2]);

            % Allocate residuals locally
            residuals_roi = zeros( ...
                maxScans, numel(vox), runnum, ...
                'like', allres);

            for runi = 1:runnum
                scanIdx = curnscans_subrun{runi,4};
                n = nScans(runi);

                residuals_roi(1:n,:,runi) = ...
                    allres(scanIdx(1:n), vox);
            end

            Faces_LDC = cell(runnum,1);

            for tri = 1:runnum

                trainruns = trainIdx{tri};
                testruns  = testIdx{tri};

                betas_train = mean( ...
                    betas_currroi(:,:,trainruns), 3);

                betas_test = ...
                    betas_currroi(:,:,testruns);

                residuals_train = mean( ...
                    residuals_roi(:,:,trainruns), 3);

                Faces_LDC{tri} = NCGP_LDt_compute_mah( ...
                    betas_train, ...
                    betas_test, ...
                    residuals_train);
            end

            tmp = cat(3, Faces_LDC{:});

            ldt_cv{mi,hi} = tmp;
            ldt_cv_avg{mi,hi} = mean(tmp,3);

            send(q, []);
        end

        delete(listener);

        if isgraphics(f)
            delete(f);
        end

        % Save results
        outputDir = fullfile(p.mp, 'LDt', 'group', ...
            wf.pre, wf.glm);

        if ~isfolder(outputDir)
            mkdir(outputDir);
        end

        outputFile = fullfile(outputDir, ...
            ['LDtbyrun_mah_sub-group_' wf.sessions{si} ...
             '_hemi-' wf.hemis{hi} ...
             '_mask-' maskname '.mat']);

        save(outputFile, 'ldt_cv', 'ldt_cv_avg', '-v7.3');

        ldt_cv_sess{si} = ldt_cv;
        ldt_cv_avg_sess{si} = ldt_cv_avg;

        clear betas_condbyrun allres
    end
end

    % Executed on the MATLAB client, not workers
    function updateProgress(~)
        nDone = nDone + 1;

        if isgraphics(f)
            waitbar(nDone / allroinum, f, ...
                sprintf('Completed %d/%d ROIs', ...
                nDone, allroinum));
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
