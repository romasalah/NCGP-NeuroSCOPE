function report = compress_spm_residuals(datasetDir, dryRun, minAgeMinutes)
%COMPRESS_SPM_RESIDUALS Safely gzip completed SPM Res_XXXX.nii files.
%
% report = compress_spm_residuals(datasetDir)
% report = compress_spm_residuals(datasetDir, dryRun, minAgeMinutes)
%
% Recursively scans datasetDir for Res_XXXX.nii (exactly four digits).
% A source .nii is deleted ONLY when its .nii.gz archive decompresses
% byte-for-byte identically to the source. Existing archives are never
% overwritten. Avoid running while SPM is writing into datasetDir.
%
% Inputs:
%   datasetDir       Root dataset directory (required)
%   dryRun           true: preview only; false: compress (default false)
%   minAgeMinutes    Skip recently modified NIfTIs (default 60 minutes)
%
% Example:
%   r = compress_spm_residuals('D:\Omar\NCGP\data\derivatives\SPM_GLM');
%   r = compress_spm_residuals('D:\Omar\NCGP\data', true);  % Preview
%
% Requires MATLAB's built-in gzip and gunzip functions.

    if nargin < 1 || isempty(datasetDir)
        error('Provide the root dataset directory.');
    end
    if nargin < 2 || isempty(dryRun)
        dryRun = false;
    end
    if nargin < 3 || isempty(minAgeMinutes)
        minAgeMinutes = 60;
    end
    if ~(islogical(dryRun) && isscalar(dryRun))
        error('dryRun must be true or false.');
    end
    if ~isnumeric(minAgeMinutes) || ~isscalar(minAgeMinutes) || ...
            ~isfinite(minAgeMinutes) || minAgeMinutes < 0
        error('minAgeMinutes must be a nonnegative number.');
    end

    datasetDir = char(datasetDir);
    if ~isfolder(datasetDir)
        error('Directory does not exist: %s', datasetDir);
    end

    % Include files directly in the root, and recursively in subfolders.
    rootFiles = dir(fullfile(datasetDir, 'Res_*.nii'));
    subFiles  = dir(fullfile(datasetDir, '**', 'Res_*.nii'));
    files = [rootFiles; subFiles];

    % Guard against directory patterns matching anything beyond SPM's
    % four-digit residual naming scheme, and remove any duplicate paths.
    paths = {};
    for k = 1:numel(files)
        if ~files(k).isdir && ~isempty(regexp(files(k).name, ...
                '^Res_[0-9]{4}\.nii$', 'once'))
            paths{end+1,1} = fullfile(files(k).folder, files(k).name); %#ok<AGROW>
        end
    end
    paths = unique(paths, 'stable');

    report = struct('found', numel(paths), 'compressed', 0, ...
        'verifiedExisting', 0, 'skippedRecent', 0, 'previewed', 0, ...
        'failed', 0, 'bytesRemoved', 0);

    fprintf('Found %d SPM residual NIfTI files in %s\n', ...
        report.found, datasetDir);
    if dryRun
        fprintf('DRY RUN: No files will be changed.\n');
    end

    for k = 1:numel(paths)
        src = paths{k};
        gz = [src '.gz'];
        info = dir(src);
        if isempty(info)
            fprintf('[SKIP] Disappeared: %s\n', src);
            continue;
        end

        ageMinutes = (now - info.datenum) * 24 * 60;
        if ageMinutes < minAgeMinutes
            report.skippedRecent = report.skippedRecent + 1;
            fprintf('[SKIP recent] %s\n', src);
            continue;
        end

        if dryRun
            report.previewed = report.previewed + 1;
            if isfile(gz)
                fprintf('[WOULD VERIFY existing .gz] %s\n', src);
            else
                fprintf('[WOULD COMPRESS] %s\n', src);
            end
            continue;
        end

        createdByThisRun = false;
        try
            if ~isfile(gz)
                gzip(src);                 % Lossless, leaves .nii intact.
                createdByThisRun = true;
            end
            if ~isfile(gz)
                error('gzip did not create %s', gz);
            end

            % gunzip checks archive integrity, then bytewise comparison
            % checks that it represents *this exact* original NIfTI.
            assertGzipMatchesSource(src, gz);

            % Recheck the original before deleting. This catches obvious
            % concurrent writes but is not a lock: keep SPM idle.
            current = dir(src);
            if isempty(current) || current.bytes ~= info.bytes || ...
                    current.datenum ~= info.datenum
                error('Original changed during compression: %s', src);
            end

            delete(src);
            report.bytesRemoved = report.bytesRemoved + info.bytes;
            if createdByThisRun
                report.compressed = report.compressed + 1;
                fprintf('[COMPRESSED / VERIFIED / DELETED] %s\n', src);
            else
                report.verifiedExisting = report.verifiedExisting + 1;
                fprintf('[EXISTING .gz VERIFIED / DELETED .nii] %s\n', src);
            end
        catch ME
            report.failed = report.failed + 1;
            fprintf(2, '[FAILED, original retained] %s\n  %s\n', ...
                src, ME.message);
            % Remove only a failed archive created by THIS execution.
            % Never delete/overwrite an existing user archive.
            if createdByThisRun && isfile(gz) && isfile(src)
                try
                    delete(gz);
                catch
                    warning('Could not clean up failed archive: %s', gz);
                end
            end
        end
    end

    fprintf('\nSummary: found=%d, newly compressed=%d, verified existing=%d, ', ...
        report.found, report.compressed, report.verifiedExisting);
    fprintf('recent skips=%d, previewed=%d, failures=%d\n', ...
        report.skippedRecent, report.previewed, report.failed);
    fprintf('Original bytes removed: %.2f GiB\n', ...
        report.bytesRemoved / 1024^3);
end

function assertGzipMatchesSource(src, gz)
% Decompress one file to an isolated temp folder and compare bytewise.
% This uses additional temporary space equal to one uncompressed NIfTI.
    tempDir = tempname;
    mkdir(tempDir);
    cleanup = onCleanup(@() rmdir(tempDir, 's')); %#ok<NASGU>

    out = gunzip(gz, tempDir);
    if numel(out) ~= 1 || ~isfile(out{1})
        error('Archive did not decompress to exactly one file: %s', gz);
    end
    unpacked = out{1};

    srcInfo = dir(src);
    outInfo = dir(unpacked);
    if srcInfo.bytes ~= outInfo.bytes
        error('Decompressed file size differs from original.');
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
