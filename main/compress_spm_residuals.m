function report = compress_spm_residuals(datasetDir, dryRun, minAgeMinutes, numWorkers)
%COMPRESS_SPM_RESIDUALS Parallel, verified compression of SPM Res_XXXX.nii.
%
% report = compress_spm_residuals(datasetDir)
% report = compress_spm_residuals(datasetDir, dryRun, minAgeMinutes, numWorkers)
%
% Recursively finds SPM residuals named Res_XXXX.nii (exactly 4 digits).
% Each file is gzip-compressed and decompressed into an independent temporary
% directory for BYTE-FOR-BYTE verification. The .nii is deleted ONLY after
% successful verification. Existing .nii.gz files are never overwritten.
%
% Inputs:
%   datasetDir       Root directory to search, including all subfolders.
%   dryRun           Preview only (default false).
%   minAgeMinutes    Skip .nii files modified less than this many minutes
%                    ago (default 60). Age alone does NOT guarantee safety.
%   numWorkers       Number of local MATLAB parallel workers (default: use
%                    an existing pool, or up to 4 workers). 1 = serial.
%
% Examples:
%   compress_spm_residuals('E:\NCGP2\data\derivatives', true);
%   r = compress_spm_residuals('E:\NCGP2\data\derivatives', false, 60, 4);
%   r = compress_spm_residuals('E:\NCGP2\data\derivatives', false, 60, 8);
%
% Parallel execution requires Parallel Computing Toolbox for numWorkers > 1.
% All workers must access datasetDir and have enough temporary disk space.
% Each worker may temporarily use disk space equal to an uncompressed NIfTI.
%
% IMPORTANT: Do not run while SPM or another process is writing/resizing
% any of these NIfTIs or archives. This function is for FINISHED old GLMs.
%
% Verification extracts into a unique directory beside each NIfTI, not
% AppData/Local/Temp. Its removal is checked before any .nii is deleted.
% A live command-window progress indicator works in serial and parfor modes.
% The original reporting fields from the serial version are preserved.

    if nargin < 1 || isempty(datasetDir)
        error('Provide the root dataset directory.');
    end
    if nargin < 2 || isempty(dryRun)
        dryRun = false;
    end
    if nargin < 3 || isempty(minAgeMinutes)
        minAgeMinutes = 60;
    end
    if nargin < 4
        numWorkers = [];
    end

    if ~(islogical(dryRun) && isscalar(dryRun))
        error('dryRun must be a scalar logical true or false.');
    end
    if ~isnumeric(minAgeMinutes) || ~isscalar(minAgeMinutes) || ...
            ~isfinite(minAgeMinutes) || minAgeMinutes < 0
        error('minAgeMinutes must be a nonnegative number.');
    end
    if ~isempty(numWorkers) && (~isnumeric(numWorkers) || ...
            ~isscalar(numWorkers) || ~isfinite(numWorkers) || ...
            numWorkers < 1 || numWorkers ~= floor(numWorkers))
        error('numWorkers must be a positive integer.');
    end

    datasetDir = char(datasetDir);
    if ~isfolder(datasetDir)
        error('Directory does not exist: %s', datasetDir);
    end

    % Include files in both the root and all nested directories.
    rootFiles = dir(fullfile(datasetDir, 'Res_*.nii'));
    subFiles  = dir(fullfile(datasetDir, '**', 'Res_*.nii'));
    files = [rootFiles; subFiles];

    paths = cell(0,1);
    for k = 1:numel(files)
        if ~files(k).isdir && ~isempty(regexp(files(k).name, ...
                '^Res_[0-9]{4}\.nii$', 'once'))
            paths{end+1,1} = fullfile(files(k).folder, files(k).name); %#ok<AGROW>
        end
    end
    paths = unique(paths, 'stable');
    n = numel(paths);

    report = struct('found', n, 'compressed', 0, ...
        'verifiedExisting', 0, 'skippedRecent', 0, 'previewed', 0, ...
        'failed', 0, 'bytesRemoved', 0, ...
        'disappeared', 0, 'parallelWorkers', 0, 'elapsedSeconds', 0);

    fprintf('Found %d SPM residual NIfTI files in %s\n', n, datasetDir);
    if n == 0
        return;
    end

    tAll = tic;
    results = cell(n,1);
    completed = 0;
    progressStep = max(1, ceil(n / 100));
    fprintf('Progress: 0%% (0/%d)\n', n);

    if dryRun
        % No need to start a parallel pool just to preview paths.
        fprintf('DRY RUN: No files will be changed.\n');
        for k = 1:n
            results{k} = processOneResidual(paths{k}, minAgeMinutes, true);
            updateProgress();
        end
        report.parallelWorkers = 0;
    else
        % Choose an existing pool if available; otherwise default to <=4
        % process workers. More workers can saturate the storage device.
        if isempty(numWorkers)
            existingPool = gcp('nocreate');
            if ~isempty(existingPool)
                numWorkers = existingPool.NumWorkers;
            else
                cluster = parcluster('local');
                numWorkers = min(4, cluster.NumWorkers);
            end
        end

        if numWorkers == 1
            report.parallelWorkers = 1;
            fprintf('Serial compression (1 CPU worker).\n');
            for k = 1:n
                results{k} = processOneResidual(paths{k}, minAgeMinutes, false);
                updateProgress();
            end
        else
            pool = gcp('nocreate');
            if isempty(pool)
                pool = parpool('local', numWorkers);
            elseif pool.NumWorkers ~= numWorkers
                warning(['An existing pool has %d workers, but %d were ' ...
                    'requested. Using the existing pool without deleting it.'], ...
                    pool.NumWorkers, numWorkers);
            end
            report.parallelWorkers = pool.NumWorkers;
            fprintf('Parallel compression using %d CPU workers.\n', ...
                report.parallelWorkers);

            % One distinct file per worker. Progress is reported by the
            % workers to the client, without writing a shared parfor counter.
            q = parallel.pool.DataQueue;
            afterEach(q, @(~) updateProgress());
            parfor k = 1:n
                results{k} = processOneResidual(paths{k}, minAgeMinutes, false);
                send(q, 1);
            end
        end
    end

    if completed < n
        completed = n - 1;
        updateProgress();
    end

    % Summarize on client (avoids race conditions on report counters).
    for k = 1:n
        result = results{k};
        report.bytesRemoved = report.bytesRemoved + result.bytesRemoved;
        switch result.status
            case 'compressed'
                report.compressed = report.compressed + 1;
            case 'verifiedExisting'
                report.verifiedExisting = report.verifiedExisting + 1;
            case 'skippedRecent'
                report.skippedRecent = report.skippedRecent + 1;
            case 'previewed'
                report.previewed = report.previewed + 1;
            case 'disappeared'
                report.disappeared = report.disappeared + 1;
            case 'failed'
                report.failed = report.failed + 1;
        end
        if strcmp(result.status, 'failed')
            fprintf(2, '%s\n', result.message);
        else
            fprintf('%s\n', result.message);
        end
    end

    report.elapsedSeconds = toc(tAll);
    fprintf('\nSummary: found=%d, newly compressed=%d, verified existing=%d, ', ...
        report.found, report.compressed, report.verifiedExisting);
    fprintf('recent skips=%d, previewed=%d, disappeared=%d, failures=%d\n', ...
        report.skippedRecent, report.previewed, ...
        report.disappeared, report.failed);
    fprintf('Original bytes removed: %.2f GiB\n', ...
        report.bytesRemoved / 1024^3);
    fprintf('Workers=%d, elapsed=%.1f seconds\n', ...
        report.parallelWorkers, report.elapsedSeconds);

    function updateProgress()
        completed = completed + 1;
        if mod(completed, progressStep) == 0 || completed == n
            fprintf('Progress: %3.0f%% (%d/%d)\n', 100*completed/n, completed, n);
        end
    end
end

function result = processOneResidual(src, minAgeMinutes, dryRun)
% One independent worker transaction. Never overwrite an existing archive.
    result = struct('status', 'failed', 'bytesRemoved', 0, 'message', '');
    gz = [src '.gz'];
    info = dir(src);

    if isempty(info)
        result.status = 'disappeared';
        result.message = sprintf('[SKIP disappeared] %s', src);
        return;
    end

    ageMinutes = (now - info.datenum) * 24 * 60;
    if ageMinutes < minAgeMinutes
        result.status = 'skippedRecent';
        result.message = sprintf('[SKIP recent] %s', src);
        return;
    end

    if dryRun
        result.status = 'previewed';
        if isfile(gz)
            result.message = sprintf('[WOULD VERIFY existing .gz] %s', src);
        else
            result.message = sprintf('[WOULD COMPRESS] %s', src);
        end
        return;
    end

    archiveExistedAtStart = isfile(gz);
    createdByThisRun = false;
    try
        if ~archiveExistedAtStart
            gzip(src);  % gzip keeps the original uncompressed NIfTI.
            createdByThisRun = true;
        end
        if ~isfile(gz)
            error('gzip did not create archive: %s', gz);
        end

        % Also verifies pre-existing archives before deleting originals.
        assertGzipMatchesSource(src, gz);

        % Reject obviously changed originals. This is not a file lock;
        % SPM MUST be stopped before using the cleanup function.
        current = dir(src);
        if isempty(current) || current.bytes ~= info.bytes || ...
                current.datenum ~= info.datenum
            error('Original changed during processing: %s', src);
        end

        delete(src);  % Only after successful bytewise verification.
        result.bytesRemoved = info.bytes;
        if createdByThisRun
            result.status = 'compressed';
            result.message = sprintf('[COMPRESSED / VERIFIED / DELETED] %s', src);
        else
            result.status = 'verifiedExisting';
            result.message = sprintf('[EXISTING .gz VERIFIED / DELETED .nii] %s', src);
        end
    catch ME
        result.status = 'failed';
        result.message = sprintf('[FAILED, original retained] %s\n  %s', ...
            src, ME.message);

        % Only remove failed archives created by THIS invocation.
        % Never delete/overwrite a pre-existing user archive.
        if ~archiveExistedAtStart && isfile(gz) && isfile(src)
            try
                delete(gz);
            catch
                result.message = sprintf('%s\n  Could not clean %s', ...
                    result.message, gz);
            end
        end
    end
end

function assertGzipMatchesSource(src, gz)
% Verify losslessly without writing into the Windows user Temp directory.
% The staging directory must be removed BEFORE this function returns.
    stage = tempname(fileparts(src));
    [ok, msg] = mkdir(stage);
    if ~ok
        error('Cannot create verification directory %s: %s', stage, msg);
    end
    guard = onCleanup(@() removeVerificationStage(stage, false)); %#ok<NASGU>

    out = gunzip(gz, stage);
    if numel(out) ~= 1 || ~isfile(out{1})
        error('Archive did not decompress to one file: %s', gz);
    end

    % File descriptors are closed when this helper returns, including errors.
    compareFilesBytewise(src, out{1});
    removeVerificationStage(stage, true);
end

function compareFilesBytewise(src, unpacked)
% The two file handles are scoped to this helper, so they are closed
% before the caller attempts to remove the staging directory.
    srcInfo = dir(src);
    outInfo = dir(unpacked);
    if isempty(srcInfo) || isempty(outInfo) || srcInfo.bytes ~= outInfo.bytes
        error('Decompressed size differs from original: %s', src);
    end

    fid1 = fopen(src, 'rb');
    if fid1 < 0
        error('Cannot read original: %s', src);
    end
    close1 = onCleanup(@() fclose(fid1)); %#ok<NASGU>

    fid2 = fopen(unpacked, 'rb');
    if fid2 < 0
        error('Cannot read decompressed file: %s', unpacked);
    end
    close2 = onCleanup(@() fclose(fid2)); %#ok<NASGU>

    while true
        a = fread(fid1, 1024*1024, '*uint8');
        b = fread(fid2, 1024*1024, '*uint8');
        if ~isequal(a, b)
            error('Byte-for-byte verification failed: %s', src);
        end
        if isempty(a)
            break;
        end
    end
end

function removeVerificationStage(stage, strict)
% Check cleanup explicitly. A failure prevents deletion of the source .nii.
% onCleanup retries after errors to avoid orphaned temporary files.
    if ~isfolder(stage)
        return;
    end
    msg = '';
    for attempt = 1:3
        [ok, msg] = rmdir(stage, 's');
        if ok || ~isfolder(stage)
            return;
        end
        pause(0.25);
    end
    if strict
        error('Verification cleanup failed for %s: %s', stage, msg);
    else
        warning('Could not remove verification files from %s: %s', stage, msg);
    end
end
