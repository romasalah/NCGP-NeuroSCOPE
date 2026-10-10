function report = compress_spm_residuals_par(datasetDir, dryRun, minAgeMinutes, numWorkers)
%COMPRESS_SPM_RESIDUALS Parallel, lossless compression of SPM Res_XXXX.nii.
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
%   compress_spm_residuals('D:\Omar\NCGP\data\derivatives', true);
%   r = compress_spm_residuals('D:\Omar\NCGP\data\derivatives', false, 60, 4);
%   r = compress_spm_residuals('D:\Omar\NCGP\data\derivatives', false, 60, 8);
%
% Parallel execution requires Parallel Computing Toolbox for numWorkers > 1.
% All workers must access datasetDir and have enough temporary disk space.
% Each worker may temporarily use disk space equal to an uncompressed NIfTI.
%
% IMPORTANT: Do not run while SPM or another process is writing/resizing
% any of these NIfTIs or archives. This function is for FINISHED old GLMs.
%
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

    if dryRun
        % No need to start a parallel pool just to preview paths.
        fprintf('DRY RUN: No files will be changed.\n');
        for k = 1:n
            results{k} = processOneResidual(paths{k}, minAgeMinutes, true);
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

            % Each worker processes an ENTIRE DISTINCT file, including
            % compression and independent temporary-folder verification.
            % Collect messages to print cleanly after parfor finishes.
            parfor k = 1:n
                results{k} = processOneResidual(paths{k}, minAgeMinutes, false);
            end
        end
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
% Verify one gzip archive by decompressing to a UNIQUE temporary folder.
% This costs temporary disk space equal to one NIfTI PER active worker.
    tempDir = tempname;
    [ok,msg] = mkdir(tempDir);
    if ~ok
        error('Cannot create verification folder %s: %s', tempDir, msg);
    end
    cleanup = onCleanup(@() rmdir(tempDir, 's')); %#ok<NASGU>

    out = gunzip(gz, tempDir);
    if numel(out) ~= 1 || ~isfile(out{1})
        error('Archive did not decompress to exactly one file: %s', gz);
    end
    unpacked = out{1};

    srcInfo = dir(src);
    outInfo = dir(unpacked);
    if isempty(srcInfo) || isempty(outInfo) || ...
            srcInfo.bytes ~= outInfo.bytes
        error('Decompressed file size differs from original: %s', gz);
    end

    fid1 = fopen(src, 'rb');
    if fid1 < 0
        error('Cannot read original: %s', src);
    end
    c1 = onCleanup(@() fclose(fid1)); %#ok<NASGU>

    fid2 = fopen(unpacked, 'rb');
    if fid2 < 0
        error('Cannot read decompressed file: %s', unpacked);
    end
    c2 = onCleanup(@() fclose(fid2)); %#ok<NASGU>

    blockBytes = 1024 * 1024;
    while true
        a = fread(fid1, blockBytes, '*uint8');
        b = fread(fid2, blockBytes, '*uint8');
        if ~isequal(a, b)
            error('Byte-for-byte verification failed: %s', gz);
        end
        if isempty(a)
            break;
        end
    end
end
