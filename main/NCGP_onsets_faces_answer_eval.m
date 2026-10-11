% =========================================================================
% Generate face-task GLM onsets with behavioural answer evaluation.
%
% Duplicate of NCGP_onsets_faces. The original function is unchanged.
%
% Response mapping is determined INDEPENDENTLY for each behavioural file:
%   thumbs_key (or a supported legacy column name) always means "Yes".
%   If Yes = a, No = b; if Yes = b, No = a;
%   if Yes = c, No = d; if Yes = d, No = c.
%   The middle-finger-key column is not required.
%
% RawAnswer: Yes, No, or the literal string "NA" for missing, unreadable,
%            or keys not belonging to the file's configured pair.
% AnswerEval: 1 = correct, 0 = incorrect OR not evaluable (NA response
%             or invalid/missing GroupNBackModelAnswer). Zero can be used
%             by downstream code to exclude all non-correct trials.
% RawAnswer = "NA" retains the distinction between missing and incorrect.
%
% Source behavioural spreadsheets remain unchanged. Each behavioural
% file's Face values are passed to NCGP_groupnback_model_answers to obtain
% the expected GroupNBackModelAnswer column IN MEMORY. The first trial
% is NA and excluded from answer scoring. The final events file is written
% only ONCE, including GroupNBackModelAnswer and AnswerEval.
% Existing first-level GLMs ignore extra columns unless changed.
%
% Also produces a participant-by-session accuracy CSV and grouped bar
% plot (PNG + editable MATLAB FIG), pooled over successfully read runs.
% Accuracy denominator: valid, evaluable trials only; NA is excluded.
% This denominator is computed before mapping non-evaluable trials to zero.
% =========================================================================
function facessessruns = NCGP_onsets_faces_answer_eval(wf)

p = NCGP_paths(wf);

% The supplied run-order CSV has no header. Preserve its first data row.
scanorder = readtable(fullfile(p.pre, 'select_runorder_here.csv'), ...
    'ReadVariableNames', false, 'TextType', 'string');
nSessions = numel(wf.sessions);
nHemis = numel(wf.hemis);
nSubjects = numel(wf.subs);

facessessruns = cell(nSessions, nHemis);
nRuns = zeros(nSubjects, nSessions);
nTrials = zeros(nSubjects, nSessions);
nCorrect = zeros(nSubjects, nSessions);
nValid = zeros(nSubjects, nSessions);

% One QC record per attempted behavioural file. Count each run once, even
% when multiple cortical hemispheres are processed.
% Fields: subject, session, run, sourceFile, outputFile, status,
% totalTrials, validAnswers, correctAnswers, incorrectAnswers,
% invalidAnswers, unexpectedInvalidAnswers, censoredTrials, accuracyPct,
% errorID, details.
fileAudit = cell(0, 16);

for hi = 1:nHemis
    for sesi = 1:nSessions
        curses = wf.sessions{sesi};
        % Convert known session labels; other labels flow to run-order
        % matching without a separate session-validation error.
        sesname = replace(replace(string(curses), "ses-02", "pre"), ...
            "ses-03", "post");

        facessessruns{sesi, hi} = cell(nSubjects, 1);
        for subi = 1:nSubjects
            cursub = wf.subs{subi};
            submin = str2double(strrep(cursub, 'sub-', ''));
            cursesdir = fullfile(p.presub{subi}, curses, 'func');
            matching = string(scanorder{:, 8}) == string(cursub) & ...
                string(scanorder{:, 9}) == string(sesname);
            if nnz(matching) ~= 1
                warning('NCGP:RunOrderMismatch', ...
                    'Expected one run-order record for %s %s, found %d. Skipping.', ...
                    cursub, sesname, nnz(matching));
                facessessruns{sesi, hi}{subi} = cell(0, 2);
                if hi == 1
                    fileAudit(end + 1, :) = { ...
                        string(cursub), string(curses), "NA", "", "", ...
                        "run_order_error", NaN, NaN, NaN, NaN, NaN, ...
                        NaN, NaN, NaN, "NCGP:RunOrderMismatch", ...
                        sprintf('Expected one run-order row, found %d.', nnz(matching)) ...
                    }; %#ok<AGROW>
                end
                continue;
            end

            curorder = string(scanorder{matching, 2:7});
            runNumbers = erase(curorder, 'GN');
            successRuns = cell(0, 2);

            for ri = 1:6
                runNumber = char(runNumbers(ri));
                behaviouralName = sprintf( ...
                    '%d_fMRI_groupnback%s_results_%s.xlsx', ...
                    submin, runNumber, sesname);
                behaviouralFile = fullfile(cursesdir, behaviouralName);
                outputName = sprintf( ...
                    '%s_%s_task-%s_run-0%s_events.xlsx', ...
                    cursub, curses, wf.task, runNumber);
                outputFile = fullfile(cursesdir, outputName);

                % Retain any known trial count even if a subsequent step
                % fails. Unknown counts are reported as NaN, not zero.
                readTrials = NaN;
                try
                    oldtbl = readtable(behaviouralFile);
                    readTrials = height(oldtbl);
                    required = {'Person', 'PresentationTimes', ...
                        'RawAnswer', 'Face'};
                    if ~all(ismember(required, oldtbl.Properties.VariableNames))
                        error('NCGP:MissingColumns', ...
                            'Missing required behavioural columns in %s.', ...
                            behaviouralName);
                    end

                    % Calculate the real group 1-back expected answers
                    % directly from this behavioural source in memory.
                    % This helper never accesses or writes event files.
                    oldtbl.GroupNBackModelAnswer = ...
                        NCGP_groupnback_model_answers(oldtbl);

                    % Determine Yes from the thumbs key; derive No from its
                    % complementary key. Never require middlekeylist.
                    yesKey = getThumbsKey(oldtbl, behaviouralName);
                    switch yesKey
                        case "a"
                            noKey = "b";
                        case "b"
                            noKey = "a";
                        case "c"
                            noKey = "d";
                        case "d"
                            noKey = "c";
                        otherwise
                            % Without a recognized thumb mapping, answers
                            % stay NA and AnswerEval stays zero; the run's
                            % invalid-response count captures this.
                            noKey = "";
                    end

                    % Only a single valid key from the configured pair can
                    % be interpreted as a response. Others become "NA".
                    rawKeys = normalizeAnswerKeys(oldtbl.RawAnswer);
                    mappedRaw = repmat("NA", height(oldtbl), 1);
                    mappedRaw(rawKeys == yesKey & rawKeys ~= "") = "Yes";
                    mappedRaw(rawKeys == noKey & rawKeys ~= "") = "No";
                    oldtbl.RawAnswer = mappedRaw; % Change only in memory.

                    model = lower(strtrim(string(oldtbl.GroupNBackModelAnswer)));
                    model(ismissing(model)) = "";
                    validModel = ismember(model, ["yes", "no"]);
                    modelOutput = repmat("NA", height(oldtbl), 1);
                    modelOutput(model == "yes") = "Yes";
                    modelOutput(model == "no") = "No";

                    validAnswer = mappedRaw ~= "NA";
                    % One-back responses start at trial 2. Trial 1 has
                    % no predecessor and is neither scored nor warned on.
                    expectedResponse = (1:height(oldtbl))' > 1;
                    evaluable = validAnswer & validModel & expectedResponse;
                    % Missing/unreadable responses must be numeric zero
                    % in onset files so they can be censored downstream.
                    trialEval = zeros(height(oldtbl), 1);
                    trialEval(evaluable) = double( ...
                        lower(mappedRaw(evaluable)) == model(evaluable));

                    missingModels = expectedResponse & ~validModel;
                    missingResponses = expectedResponse & ~validAnswer;
                    if any(missingModels)
                        warning('NCGP:MissingModelAnswer', ...
                            '%s has %d invalid GroupNBackModelAnswer entries; marked NA.', ...
                            behaviouralName, nnz(missingModels));
                    end
                    if any(missingResponses)
                        fprintf('%s: %d missing/unreadable responses marked NA.\n', ...
                            behaviouralName, nnz(missingResponses));
                    end

                    trialTypes = string(oldtbl.Person);
                    if isnumeric(oldtbl.PresentationTimes)
                        onsets = double(oldtbl.PresentationTimes);
                    else
                        onsets = str2double(string(oldtbl.PresentationTimes));
                    end
                    onsets = onsets(:);
                    if any(~isfinite(onsets))
                        error('NCGP:InvalidOnset', ...
                            'Invalid PresentationTimes in %s.', behaviouralName);
                    end

                    if wf.modelblackresponse
                        % Both events inherit their source trial's evaluation.
                        n = height(oldtbl);
                        trial_type = strings(2 * n, 1);
                        onset = zeros(2 * n, 1);
                        duration = zeros(2 * n, 1);
                        AnswerEval = repelem(trialEval, 2);
                        RawAnswer = repelem(mappedRaw, 2);
                        GroupNBackModelAnswer = repelem(modelOutput, 2);

                        for i = 1:n
                            faceRow = 2 * i - 1;
                            blackRow = 2 * i;
                            trial_type(faceRow) = trialTypes(i) + "_Face";
                            onset(faceRow) = onsets(i);
                            duration(faceRow) = 1.5;

                            trial_type(blackRow) = trialTypes(i) + "_BlackResponse";
                            onset(blackRow) = onsets(i) + 1.5;
                            if i < n
                                duration(blackRow) = onsets(i + 1) - onset(blackRow);
                            else
                                duration(blackRow) = 3.5;
                            end
                        end
                        if any(duration < 0)
                            error('NCGP:NegativeDuration', ...
                                'Negative black-response duration in %s.', ...
                                behaviouralName);
                        end
                    else
                        trial_type = trialTypes;
                        onset = onsets;
                        duration = 5 * ones(height(oldtbl), 1);
                        AnswerEval = trialEval;
                        RawAnswer = mappedRaw;
                        GroupNBackModelAnswer = modelOutput;
                    end

                    newtbl = table(cellstr(trial_type), onset, duration, ...
                        AnswerEval, RawAnswer, GroupNBackModelAnswer, ...
                        'VariableNames', {'trial_type', 'onset', 'duration', ...
                                         'AnswerEval', 'RawAnswer', 'GroupNBackModelAnswer'});
                    writetable(newtbl, outputFile);

                    successRuns(end + 1, :) = {curses, ['run-0' runNumber]}; %#ok<AGROW>

                    % Count behavioural TRIALS exactly once, not once for
                    % each hemisphere and not twice in split-event mode.
                    if hi == 1
                        nRuns(subi, sesi) = nRuns(subi, sesi) + 1;
                        nTrials(subi, sesi) = nTrials(subi, sesi) + height(oldtbl);
                        nValid(subi, sesi) = nValid(subi, sesi) + nnz(evaluable);
                        nCorrect(subi, sesi) = nCorrect(subi, sesi) + ...
                            nnz(trialEval == 1);

                        % Distinguish valid but incorrect responses from
                        % invalid/NA responses. Trial 1 is always NA in
                        % the 1-back task and is not flagged as a problem.
                        fileCorrect = nnz(trialEval == 1);
                        fileValid = nnz(evaluable);
                        fileIncorrect = fileValid - fileCorrect;
                        fileInvalid = height(oldtbl) - fileValid;
                        fileUnexpectedInvalid = nnz(expectedResponse & ~evaluable);
                        fileCensored = height(oldtbl) - fileCorrect;
                        fileAccuracy = NaN;
                        if fileValid > 0
                            fileAccuracy = 100 * fileCorrect / fileValid;
                        end

                        status = "processed";
                        detail = "";
                        if fileUnexpectedInvalid > 0
                            status = "processed_with_invalid_answers";
                            detail = sprintf( ...
                                '%d non-evaluable answer(s) beyond the expected first trial.', ...
                                fileUnexpectedInvalid);
                        end

                        fileAudit(end + 1, :) = { ...
                            string(cursub), string(curses), ...
                            string(['run-0' runNumber]), ...
                            string(behaviouralName), string(outputName), ...
                            status, height(oldtbl), fileValid, fileCorrect, ...
                            fileIncorrect, fileInvalid, fileUnexpectedInvalid, ...
                            fileCensored, fileAccuracy, "", detail ...
                        }; %#ok<AGROW>
                    end

                catch ME
                    warning('NCGP:OnsetsFacesEvalSkippedRun', ...
                        'Unable to process %s (%s %s): %s', ...
                        behaviouralName, cursub, curses, ME.message);
                    if hi == 1
                        fileAudit(end + 1, :) = { ...
                            string(cursub), string(curses), ...
                            string(['run-0' runNumber]), ...
                            string(behaviouralName), string(outputName), ...
                            "failed", readTrials, NaN, NaN, NaN, NaN, ...
                            NaN, NaN, NaN, string(ME.identifier), ...
                            string(ME.message) ...
                        }; %#ok<AGROW>
                    end
                end
            end
            facessessruns{sesi, hi}{subi} = successRuns;
        end
    end
end

% Save detailed run-level quality and failure reports FIRST, so QC survives
% any plot-export problem. Valid-answer counts exclude NA/non-evaluable
% trials, while AnswerEval=0 additionally includes incorrect trials.
writeFacesAnswerQualityReport(wf, p, fileAudit, ...
    nRuns, nTrials, nCorrect, nValid);

% Preserve the existing participant-by-session accuracy figure and CSV.
writeSubjectAccuracyFigures( ...
    wf, p, nRuns, nTrials, nCorrect, nValid);
end

function key = getThumbsKey(tbl, behaviouralName)
% Support the new name plus the legacy PsychoPy key-column variants.
aliases = ["thumbs_key", "thumb_key", "thumbkeylist", ...
           "thumbskey", "thumbkey"];
names = string(tbl.Properties.VariableNames);
idx = find(ismember(lower(names), lower(aliases)), 1);

% No required-column or key-consistency assertions: use the first
% recognized a/b/c/d key in the available column. If no usable mapping
% exists, return an empty key so that all responses are represented as NA.
key = "";
if ~isempty(idx)
    % Serialized PsychoPy values such as "('d',)" become "d".
    tokens = normalizeAnswerKeys(tbl.(char(names(idx))));
    candidates = tokens(ismember(tokens, ["a", "b", "c", "d"]));
    if ~isempty(candidates)
        key = candidates(1);
    end
end
end

function keys = normalizeAnswerKeys(rawValues)
% Convert case/spacing/serialized single-key representations to a/b/c/d.
% Any other value will remain non-key and is subsequently treated as NA.
keys = lower(strtrim(string(rawValues)));
keys(ismissing(keys)) = "";
keys = regexprep(keys, '[^a-z]', '');
keys = keys(:);
end

function writeSubjectAccuracyFigures(wf, p, runs, trials, correct, valid)
% Output one row per selected subject/session and one multi-subject figure.
nSubjects = numel(wf.subs);
nSessions = numel(wf.sessions);
nRows = nSubjects * nSessions;

subject = strings(nRows, 1);
session = strings(nRows, 1);
runsProcessed = zeros(nRows, 1);
totalTrials = zeros(nRows, 1);
correctAnswers = zeros(nRows, 1);
incorrectAnswers = zeros(nRows, 1);
naAnswers = zeros(nRows, 1);
validAnswers = zeros(nRows, 1);
accuracyPct = nan(nRows, 1);
accuracyMatrix = nan(nSubjects, nSessions);

k = 0;
for subi = 1:nSubjects
    for sesi = 1:nSessions
        k = k + 1;
        subject(k) = string(wf.subs{subi});
        session(k) = string(wf.sessions{sesi});
        runsProcessed(k) = runs(subi, sesi);
        totalTrials(k) = trials(subi, sesi);
        correctAnswers(k) = correct(subi, sesi);
        validAnswers(k) = valid(subi, sesi);
        incorrectAnswers(k) = valid(subi, sesi) - correct(subi, sesi);
        naAnswers(k) = trials(subi, sesi) - valid(subi, sesi);
        if valid(subi, sesi) > 0
            accuracyMatrix(subi, sesi) = 100 * ...
                correct(subi, sesi) / valid(subi, sesi);
            accuracyPct(k) = accuracyMatrix(subi, sesi);
        end
    end
end

summary = table(subject, session, runsProcessed, totalTrials, ...
    correctAnswers, incorrectAnswers, naAnswers, validAnswers, ...
    accuracyPct, 'VariableNames', ...
    {'subject', 'session', 'runsProcessed', 'totalTrials', ...
     'correctAnswers', 'incorrectAnswers', 'naAnswers', ...
     'validAnswers', 'accuracyPct'});

outdir = fullfile(p.pre, 'faces_answer_evaluation');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
stem = ['task-' char(wf.task) '_accuracy_by_subject'];
writetable(summary, fullfile(outdir, [stem '.csv']));

if ~any(valid(:) > 0)
    warning('NCGP:NoEvaluableTrials', ...
        'No evaluable answers were found; summary CSV saved, no figure drawn.');
    return;
end

fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100, 100, max(900, 65 * nSubjects), 550]);
    ax = axes('Parent', fig);
    bar(ax, accuracyMatrix, 'grouped');
    ylim(ax, [0, 100]);
    xlim(ax, [0.5, nSubjects + 0.5]);
    xticks(ax, 1:nSubjects);
    xticklabels(ax, wf.subs);
    xtickangle(ax, 45);
    ylabel(ax, 'Correct answers / evaluable answers (%)');
    xlabel(ax, 'Participant');
    title(ax, 'Face-task behavioural accuracy by participant');
    grid(ax, 'on');

    legendLabels = strings(1, nSessions);
    for si = 1:nSessions
        switch wf.sessions{si}
            case 'ses-02'
                legendLabels(si) = "Pre (ses-02)";
            case 'ses-03'
                legendLabels(si) = "Post (ses-03)";
            otherwise
                legendLabels(si) = string(wf.sessions{si});
        end
    end
    legend(ax, cellstr(legendLabels), 'Location', 'bestoutside');

    saveas(fig, fullfile(outdir, [stem '.png']));
    savefig(fig, fullfile(outdir, [stem '.fig']));
    close(fig);
end

function writeFacesAnswerQualityReport(wf, p, fileAudit, runs, trials, correct, valid)
% Write machine-readable QC and human-readable overview. Data reported
% here are BEHAVIOURAL TRIALS, never doubled face/black event rows.
% "validAnswers" = evaluable Yes/No; "invalidAnswers" = missing/NA;
% "censoredTrials" = all AnswerEval=0 (incorrect + invalid).

outdir = fullfile(p.pre, 'faces_answer_evaluation');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
stem = ['task-' char(wf.task)];
names = {'subject', 'session', 'run', 'sourceFile', 'outputFile', ...
    'status', 'totalTrials', 'validAnswers', 'correctAnswers', ...
    'incorrectAnswers', 'invalidAnswers', 'unexpectedInvalidAnswers', ...
    'censoredTrials', 'accuracyPct', 'errorID', 'details'};
% Build a typed table: text columns are strings and count columns
% are numeric doubles (including NaN for failed or unreadable files).
% Mixed-type cell variables are not reliably writable with writetable.
strCol = @(i) string(cellfun(@(x) char(string(x)), ...
    fileAudit(:, i), 'UniformOutput', false));
numCol = @(i) cellfun(@double, fileAudit(:, i));
files = table( ...
    strCol(1), strCol(2), strCol(3), strCol(4), strCol(5), ...
    strCol(6), numCol(7), numCol(8), numCol(9), numCol(10), ...
    numCol(11), numCol(12), numCol(13), numCol(14), ...
    strCol(15), strCol(16), 'VariableNames', names);

bad = ~strcmp(string(files.status), "processed");
problems = files(bad, :);
writetable(files, fullfile(outdir, [stem '_run_quality.csv']));
writetable(problems, fullfile(outdir, [stem '_problematic_files.csv']));

% Subject/session QC includes failed file counts, unlike the original
% accuracy summary, which covers successfully processed runs only.
nSubjects = numel(wf.subs);
nSessions = numel(wf.sessions);
nRows = nSubjects * nSessions;
subj = strings(nRows, 1);
sess = strings(nRows, 1);
processedFiles = zeros(nRows, 1);
failedFiles = zeros(nRows, 1);
totalTrials = zeros(nRows, 1);
validAnswers = zeros(nRows, 1);
correctAnswers = zeros(nRows, 1);
incorrectAnswers = zeros(nRows, 1);
invalidAnswers = zeros(nRows, 1);
censoredTrials = zeros(nRows, 1);
accuracyPct = nan(nRows, 1);
row = 0;
for subi = 1:nSubjects
    for sesi = 1:nSessions
        row = row + 1;
        subj(row) = string(wf.subs{subi});
        sess(row) = string(wf.sessions{sesi});
        processedFiles(row) = runs(subi, sesi);
        fileMask = string(files.subject) == subj(row) & ...
            string(files.session) == sess(row);
        failedFiles(row) = nnz(string(files.status(fileMask)) == "failed");
        totalTrials(row) = trials(subi, sesi);
        validAnswers(row) = valid(subi, sesi);
        correctAnswers(row) = correct(subi, sesi);
        incorrectAnswers(row) = validAnswers(row) - correctAnswers(row);
        invalidAnswers(row) = totalTrials(row) - validAnswers(row);
        censoredTrials(row) = totalTrials(row) - correctAnswers(row);
        if validAnswers(row) > 0
            accuracyPct(row) = 100 * correctAnswers(row) / validAnswers(row);
        end
    end
end
subjects = table(subj, sess, processedFiles, failedFiles, ...
    totalTrials, validAnswers, correctAnswers, incorrectAnswers, ...
    invalidAnswers, censoredTrials, accuracyPct, ...
    'VariableNames', {'subject', 'session', 'processedFiles', 'failedFiles', ...
    'totalTrials', 'validAnswers', 'correctAnswers', 'incorrectAnswers', ...
    'invalidAnswers', 'censoredTrials', 'accuracyPct'});
writetable(subjects, fullfile(outdir, [stem '_subject_quality.csv']));

allValid = sum(valid(:));
allCorrect = sum(correct(:));
allTrials = sum(trials(:));
allProcessed = sum(runs(:));
allFailed = nnz(string(files.status) == "failed");
allRunOrderProblems = nnz(string(files.status) == "run_order_error");
allProblemRecords = height(problems);
allUnexpectedInvalid = sum(files.unexpectedInvalidAnswers( ...
    files.status == "processed_with_invalid_answers"));
allAccuracy = NaN;
if allValid > 0
    allAccuracy = 100 * allCorrect / allValid;
end
overview = table(6*nSubjects*nSessions, allProcessed, allFailed, ...
    allRunOrderProblems, allProblemRecords, allTrials, allValid, ...
    allCorrect, allValid - allCorrect, allTrials - allValid, ...
    allUnexpectedInvalid, allTrials - allCorrect, allAccuracy, ...
    'VariableNames', {'expectedRunFiles', 'processedRunFiles', ...
    'failedRunFiles', 'runOrderProblems', 'problemRecords', ...
    'processedTrials', 'validAnswers', 'correctAnswers', ...
    'incorrectAnswers', 'invalidAnswers', 'unexpectedInvalidAnswers', ...
    'censoredTrials', 'accuracyPct'});
writetable(overview, fullfile(outdir, [stem '_answer_quality_overview.csv']));

% Consolidate into one reviewable workbook, alongside CSV reports.
book = fullfile(outdir, [stem '_answer_quality_report.xlsx']);
writetable(overview, book, 'Sheet', 'Overview');
writetable(subjects, book, 'Sheet', 'BySubjectSession');
writetable(files, book, 'Sheet', 'ByRunFile');
writetable(problems, book, 'Sheet', 'ProblematicFiles');

% Text summary states denominator conventions explicitly.
txtpath = fullfile(outdir, [stem '_answer_quality_report.txt']);
fid = fopen(txtpath, 'w');
    fprintf(fid, 'Face task answer-quality report\n');
    fprintf(fid, '==============================\n');
    fprintf(fid, 'Expected run files: %d\n', 6*nSubjects*nSessions);
    fprintf(fid, 'Processed run files: %d\n', allProcessed);
    fprintf(fid, 'Failed run files: %d\n', allFailed);
    fprintf(fid, 'Run-order problems: %d\n', allRunOrderProblems);
    fprintf(fid, 'Problem records: %d\n', allProblemRecords);
    fprintf(fid, 'Trials in processed files: %d\n', allTrials);
    fprintf(fid, 'Valid/evaluable answers: %d\n', allValid);
    fprintf(fid, 'Correct answers: %d\n', allCorrect);
    fprintf(fid, 'Incorrect but evaluable answers: %d\n', allValid - allCorrect);
    fprintf(fid, 'Invalid/NA answers (including first trial): %d\n', allTrials - allValid);
    fprintf(fid, 'Unexpected invalid answers beyond first trial: %d\n', ...
        allUnexpectedInvalid);
    fprintf(fid, 'Censored trials (AnswerEval=0): %d\n', allTrials - allCorrect);
    fprintf(fid, 'Accuracy among evaluable answers: %.2f%%\n', allAccuracy);
    fprintf(fid, '\nProblematic source files and reasons:\n');
    for i = 1:height(problems)
        fprintf(fid, '%s %s %s | %s | %s | %s\n', ...
            char(string(problems.subject(i))), ...
            char(string(problems.session(i))), ...
            char(string(problems.run(i))), ...
            char(string(problems.sourceFile(i))), ...
            char(string(problems.status(i))), ...
            char(string(problems.details(i))));
    end
    fclose(fid);
fprintf('Faces answer QC: %d processed, %d failed, %d evaluable, %d invalid/NA, %d correct.\n', ...
    allProcessed, allFailed, allValid, allTrials - allValid, allCorrect);
end
