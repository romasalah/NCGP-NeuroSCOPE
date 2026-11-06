function report = uncompress_volumetric_func_niftis_par(datasetDir, dryRun, minAgeMinutes, numWorkers)
%UNCOMPRESS_VOLUMETRIC_FUNC_NIFTIS_PAR Restore volumetric func_N.nii files from .nii.gz archives.
%
% report = uncompress_volumetric_func_niftis_par(datasetDir)
% report = uncompress_volumetric_func_niftis_par(datasetDir, dryRun, minAgeMinutes, numWorkers)
%
% Recursively finds NIfTI archives ending in func_<digits>.nii.gz only
% when their immediate parent folder is named exactly 'volumetric'.
% Restores each .nii alongside its .nii.gz archive; the .gz is never deleted.
% Existing .nii files are skipped (never intentionally overwritten).
%
% Inputs:
%   datasetDir       Root folder, including nested directories.
%   dryRun           Preview only (default false).
%   minAgeMinutes    Skip archives modified less than this many minutes
%                    ago (default 60; set to 0 to process all archives).
%   numWorkers       Parallel workers (default existing pool, otherwise
%                    up to 4). Use 1 for serial processing.
%
% Examples:
%   uncompress_volumetric_func_niftis_par('D:\Omar\NCGP\data\derivatives', true);
%   r = uncompress_volumetric_func_niftis_par('D:\Omar\NCGP\data\derivatives', false, 0, 4);
%
% Do not run while another process is creating or replacing these files.
% Extraction is staged in a unique folder next to each archive, not in
% the system temporary directory. Decompression verifies gzip integrity.
% A live progress bar in the Command Window tracks completed files in both
% serial and parallel modes (skipped and failed files count as processed).
% Parallel progress is reported on the MATLAB client using DataQueue.

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

    if ~islogical(dryRun) || ~isscalar(dryRun)
        error('dryRun must be a scalar logical.');
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

    rootFiles = dir(fullfile(datasetDir, '*func_*.nii.gz'));
    subFiles  = dir(fullfile(datasetDir, '**', '*func_*.nii.gz'));
    files = [rootFiles; subFiles];

    paths = cell(0,1);
    for k = 1:numel(files)
        if ~files(k).isdir && ~isempty(regexp(files(k).name, ...
                '(?:^|[._])func_[0-9]+\.nii\.gz$', 'once'))
            [~, folderName] = fileparts(files(k).folder);
            if strcmp(folderName, 'volumetric')
                paths{end+1,1} = fullfile(files(k).folder, files(k).name); %#ok<AGROW>
            end
        end
    end
    paths = unique(paths, 'stable');
    n = numel(paths);

    report = struct('found', n, 'decompressed', 0, ...
        'skippedExisting', 0, 'skippedRecent', 0, 'previewed', 0, ...
        'disappeared', 0, 'failed', 0, 'bytesRestored', 0, ...
        'parallelWorkers', 0, 'elapsedSeconds', 0);

    fprintf('Found %d compressed NIfTI files in volumetric folders under %s\n', n, datasetDir);
    if n == 0
        return;
    end

    tAll = tic;
    results = cell(n,1);
    completed = 0;
    progressStep = max(1, ceil(n / 100)); % Limit display updates to ~100.

    fprintf('Progress: [%s]   0%% (0/%d)', repmat('.', 1, 30), n);

    if dryRun
        fprintf('DRY RUN: No files will be changed.\n');
        for k = 1:n
            results{k} = restoreOneVolumetricFunc(paths{k}, minAgeMinutes, true);
            updateProgress();
        end
    else
        if isempty(numWorkers)
            pool = gcp('nocreate');
            if isempty(pool)
                cluster = parcluster('local');
                numWorkers = min(4, cluster.NumWorkers);
            else
                numWorkers = pool.NumWorkers;
            end
        end

        if numWorkers == 1
            report.parallelWorkers = 1;
            fprintf('Serial decompression.\n');
            for k = 1:n
                results{k} = restoreOneVolumetricFunc(paths{k}, minAgeMinutes, false);
                updateProgress();
            end
        else
            pool = gcp('nocreate');
            if isempty(pool)
                pool = parpool('local', numWorkers);
            elseif pool.NumWorkers ~= numWorkers
                warning('Existing pool has %d workers; using it instead of %d.', ...
                    pool.NumWorkers, numWorkers);
            end
            report.parallelWorkers = pool.NumWorkers;
            fprintf('Parallel decompression using %d workers.\n', ...
                report.parallelWorkers);

            % Workers report completion to the client; no shared counter
            % is written inside parfor.
            progressQueue = parallel.pool.DataQueue;
            afterEach(progressQueue, @(~) updateProgress());
            parfor k = 1:n
                results{k} = restoreOneVolumetricFunc(paths{k}, minAgeMinutes, false);
                send(progressQueue, 1);
            end
        end
    end

    % Ensure 100% is displayed even if DataQueue callbacks are delayed.
    if completed < n
        completed = n - 1;
        updateProgress();
    end
    fprintf('\n');

    for k = 1:n
        result = results{k};
        report.bytesRestored = report.bytesRestored + result.bytesRestored;
        report.(result.status) = report.(result.status) + 1;
        if strcmp(result.status, 'failed')
            fprintf(2, '%s\n', result.message);
        else
            fprintf('%s\n', result.message);
        end
    end
    report.elapsedSeconds = toc(tAll);
    fprintf('\nRestored=%d, existing=%d, recent=%d, previewed=%d, ', ...
        report.decompressed, report.skippedExisting, ...
        report.skippedRecent, report.previewed);
    fprintf('disappeared=%d, failed=%d\n', report.disappeared, report.failed);
    fprintf('Restored: %.2f GiB; workers=%d; elapsed=%.1f s\n', ...
        report.bytesRestored / 1024^3, ...
        report.parallelWorkers, report.elapsedSeconds);

    function updateProgress()
        % Called on the client, including callbacks from parallel workers.
        if completed >= n
            return;
        end
        completed = completed + 1;
        if mod(completed, progressStep) ~= 0 && completed ~= n
            return;
        end
        fraction = completed / n;
        filled = round(30 * fraction);
        fprintf('\rProgress: [%s%s] %3.0f%% (%d/%d)', ...
            repmat('=', 1, filled), repmat('.', 1, 30-filled), ...
            100 * fraction, completed, n);
    end
end

function result = restoreOneVolumetricFunc(gz, minAgeMinutes, dryRun)
% Restore one archive without changing the archive or existing .nii files.
    result = struct('status', 'failed', 'bytesRestored', 0, 'message', '');
    target = gz(1:end-3);  % Remove .gz extension.

    info = dir(gz);
    if isempty(info)
        result.status = 'disappeared';
        result.message = sprintf('[SKIP disappeared] %s', gz);
        return;
    end
    if isfile(target)
        result.status = 'skippedExisting';
        result.message = sprintf('[SKIP existing .nii] %s', target);
        return;
    end
    if (now - info.datenum) * 24 * 60 < minAgeMinutes
        result.status = 'skippedRecent';
        result.message = sprintf('[SKIP recent archive] %s', gz);
        return;
    end
    if dryRun
        result.status = 'previewed';
        result.message = sprintf('[WOULD DECOMPRESS, keep .gz] %s', gz);
        return;
    end

    % Place staging data on the same filesystem, avoiding system temp.
    tempDir = tempname(fileparts(gz));
    try
        [ok, msg] = mkdir(tempDir);
        if ~ok
            error('Cannot create staging directory %s: %s', tempDir, msg);
        end
        cleanup = onCleanup(@() cleanupFolder(tempDir)); %#ok<NASGU>

        extracted = gunzip(gz, tempDir); % gunzip leaves the .gz untouched
        if numel(extracted) ~= 1 || ~isfile(extracted{1})
            error('Archive did not produce exactly one NIfTI: %s', gz);
        end

        current = dir(gz);
        if isempty(current) || current.bytes ~= info.bytes || ...
                current.datenum ~= info.datenum
            error('Archive changed during extraction: %s', gz);
        end
        if isfile(target)
            result.status = 'skippedExisting';
            result.message = sprintf('[SKIP .nii appeared] %s', target);
            return;
        end

        % Do NOT pass the force flag. Never overwrite an existing .nii.
        [ok, msg] = movefile(extracted{1}, target);
        if ~ok
            error('Cannot restore %s: %s', target, msg);
        end

        restored = dir(target);
        if isempty(restored) || restored.bytes == 0
            error('Restored NIfTI is missing or empty: %s', target);
        end
        result.status = 'decompressed';
        result.bytesRestored = restored.bytes;
        result.message = sprintf('[RESTORED .nii, KEPT .gz] %s', target);
    catch ME
        result.status = 'failed';
        result.message = sprintf('[FAILED, .gz retained] %s\n  %s', ...
            gz, ME.message);
        % The unique staging directory is removed by onCleanup if created.
        if ~exist('cleanup', 'var') && isfolder(tempDir)
            cleanupFolder(tempDir);
        end
    end
end

function cleanupFolder(folder)
    if isfolder(folder)
        try
            rmdir(folder, 's');
        catch ME
            warning('Cannot remove staging folder %s: %s', folder, ME.message);
        end
    end
end
