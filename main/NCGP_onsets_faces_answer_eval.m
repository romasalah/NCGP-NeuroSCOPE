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
%             or invalid/missing ModelAnswer). Numeric zeros can be used
%             by downstream code to exclude all non-correct trials.
% RawAnswer = "NA" retains the distinction between missing and incorrect.
%
% Source behavioural spreadsheets and original *_events.xlsx files remain
% unchanged. Additional *_events_nbackans.xlsx copies contain a
% GroupNBackModelAnswer column computed from consecutive Face filenames.
% The first trial of each run is NA. Existing first-level GLMs still read
% the original event files unless explicitly reconfigured.
%
% Also produces a participant-by-session accuracy CSV and grouped bar
% plot (PNG + editable MATLAB FIG), pooled over successfully read runs.
% Accuracy denominator: valid, evaluable trials only; NA is excluded.
% This denominator is computed before mapping non-evaluable trials to zero.
% =========================================================================
function facessessruns = NCGP_onsets_faces_answer_eval(wf)

p = NCGP_paths(wf);

% =========================================================================
% Preprocess existing face-event files for the selected pre/post sessions.
% Use Face filenames from the matching behavioural XLSX, because generated
% events contain trial_type but do not include the original Face column.
% Save a separate *_events_nbackans.xlsx, leaving source files unchanged.
% =========================================================================
for sesiNback = 1:numel(wf.sessions)
    selectedSession = wf.sessions{sesiNback};
    switch selectedSession
        case 'ses-02'
            selectedSessionName = 'pre';
        case 'ses-03'
            selectedSessionName = 'post';
        otherwise
            error('NCGP:InvalidSession', ...
                'Unsupported face-task session: %s', selectedSession);
    end

    for subiNback = 1:numel(wf.subs)
        selectedSubject = wf.subs{subiNback};
        subjectNumber = str2double(erase(string(selectedSubject), 'sub-'));
        if ~isfinite(subjectNumber)
            error('NCGP:InvalidSubject', ...
                'Invalid participant identifier: %s', selectedSubject);
        end

        eventDir = fullfile(p.presub{subiNback}, selectedSession, 'func');
        eventPattern = sprintf('%s_%s_task-%s_run-*_events.xlsx', ...
            selectedSubject, selectedSession, wf.task);
        existingEventFiles = dir(fullfile(eventDir, eventPattern));

        for eventIndex = 1:numel(existingEventFiles)
            eventName = existingEventFiles(eventIndex).name;
            runToken = regexp(eventName, ...
                '_run-0*([1-6])_events\.xlsx$', 'tokens', 'once');
            if isempty(runToken)
                warning('NCGP:InvalidNBackEventFilename', ...
                    'Unrecognized event filename: %s', eventName);
                continue;
            end
            runNumber = str2double(runToken{1});
            behaviouralName = sprintf( ...
                '%d_fMRI_groupnback%d_results_%s.xlsx', ...
                subjectNumber, runNumber, selectedSessionName);
            behaviouralFile = fullfile(eventDir, behaviouralName);
            eventFile = fullfile(eventDir, eventName);

            try
                writeGroupNBackEventCopy(eventFile, behaviouralFile);
            catch ME
                warning('NCGP:ExistingNBackAnswerExportFailed', ...
                    'Unable to export 1-back answers for %s: %s', ...
                    eventName, ME.message);
            end
        end
    end
end

% The supplied run-order CSV has no header. Preserve its first data row.
scanorder = readtable(fullfile(p.pre, 'select_runorder_here.csv'), ...
    'ReadVariableNames', false, 'TextType', 'string');
if width(scanorder) < 9
    error('NCGP:InvalidRunOrder', ...
        'Run-order CSV must contain at least nine columns.');
end

nSessions = numel(wf.sessions);
nHemis = numel(wf.hemis);
nSubjects = numel(wf.subs);

facessessruns = cell(nSessions, nHemis);
nRuns = zeros(nSubjects, nSessions);
nTrials = zeros(nSubjects, nSessions);
nCorrect = zeros(nSubjects, nSessions);
nValid = zeros(nSubjects, nSessions);

for hi = 1:nHemis
    for sesi = 1:nSessions
        curses = wf.sessions{sesi};
        switch curses
            case 'ses-02'
                sesname = 'pre';
            case 'ses-03'
                sesname = 'post';
            otherwise
                error('NCGP:InvalidSession', ...
                    'Unsupported face-task session: %s', curses);
        end

        facessessruns{sesi, hi} = cell(nSubjects, 1);
        for subi = 1:nSubjects
            cursub = wf.subs{subi};
            submin = str2double(strrep(cursub, 'sub-', ''));
            if isnan(submin)
                error('NCGP:InvalidSubject', ...
                    'Invalid participant identifier: %s', cursub);
            end

            cursesdir = fullfile(p.presub{subi}, curses, 'func');
            matching = string(scanorder{:, 8}) == string(cursub) & ...
                string(scanorder{:, 9}) == string(sesname);
            if nnz(matching) ~= 1
                warning('NCGP:RunOrderMismatch', ...
                    'Expected one run-order record for %s %s, found %d. Skipping.', ...
                    cursub, sesname, nnz(matching));
                facessessruns{sesi, hi}{subi} = cell(0, 2);
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

                try
                    oldtbl = readtable(behaviouralFile);
                    required = {'Person', 'PresentationTimes', ...
                        'RawAnswer', 'ModelAnswer'};
                    if ~all(ismember(required, oldtbl.Properties.VariableNames))
                        error('NCGP:MissingColumns', ...
                            'Missing required behavioural columns in %s.', ...
                            behaviouralName);
                    end

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
                            error('NCGP:InvalidThumbsKey', ...
                                'Unsupported Yes key in %s.', behaviouralName);
                    end

                    % Only a single valid key from the configured pair can
                    % be interpreted as a response. Others become "NA".
                    rawKeys = normalizeAnswerKeys(oldtbl.RawAnswer);
                    mappedRaw = repmat("NA", height(oldtbl), 1);
                    mappedRaw(rawKeys == yesKey) = "Yes";
                    mappedRaw(rawKeys == noKey) = "No";
                    oldtbl.RawAnswer = mappedRaw; % Change only in memory.

                    model = lower(strtrim(string(oldtbl.ModelAnswer)));
                    model(ismissing(model)) = "";
                    validModel = ismember(model, ["yes", "no"]);
                    modelOutput = repmat("NA", height(oldtbl), 1);
                    modelOutput(model == "yes") = "Yes";
                    modelOutput(model == "no") = "No";

                    validAnswer = mappedRaw ~= "NA";
                    evaluable = validAnswer & validModel;
                    % Missing/unreadable responses must be numeric zero
                    % in onset files so they can be censored downstream.
                    trialEval = zeros(height(oldtbl), 1);
                    trialEval(evaluable) = double( ...
                        lower(mappedRaw(evaluable)) == model(evaluable));

                    if any(~validModel)
                        warning('NCGP:MissingModelAnswer', ...
                            '%s has %d invalid ModelAnswer entries; marked NA.', ...
                            behaviouralName, nnz(~validModel));
                    end
                    if any(~validAnswer)
                        fprintf('%s: %d missing/unreadable responses marked NA.\n', ...
                            behaviouralName, nnz(~validAnswer));
                    end

                    trialTypes = string(oldtbl.Person);
                    if any(ismissing(trialTypes) | strlength(trialTypes) == 0)
                        error('NCGP:MissingIdentity', ...
                            'A Person (face identity) is missing in %s.', ...
                            behaviouralName);
                    end
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
                        ModelAnswer = repelem(modelOutput, 2);

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
                        ModelAnswer = modelOutput;
                    end

                    newtbl = table(cellstr(trial_type), onset, duration, ...
                        AnswerEval, RawAnswer, ModelAnswer, ...
                        'VariableNames', {'trial_type', 'onset', 'duration', ...
                                         'AnswerEval', 'RawAnswer', 'ModelAnswer'});
                    writetable(newtbl, outputFile);

                    % Also export from freshly generated event files so a
                    % clean first run creates the N-back copies immediately.
                    try
                        writeGroupNBackEventCopy(outputFile, behaviouralFile);
                    catch nbackME
                        warning('NCGP:NBackAnswerExportFailed', ...
                            'Unable to export 1-back answers for %s: %s', ...
                            outputName, nbackME.message);
                    end
                    successRuns(end + 1, :) = {curses, ['run-0' runNumber]}; %#ok<AGROW>

                    % Count behavioural TRIALS exactly once, not once for
                    % each hemisphere and not twice in split-event mode.
                    if hi == 1
                        nRuns(subi, sesi) = nRuns(subi, sesi) + 1;
                        nTrials(subi, sesi) = nTrials(subi, sesi) + height(oldtbl);
                        nValid(subi, sesi) = nValid(subi, sesi) + nnz(evaluable);
                        nCorrect(subi, sesi) = nCorrect(subi, sesi) + ...
                            nnz(trialEval == 1);
                    end

                catch ME
                    warning('NCGP:OnsetsFacesEvalSkippedRun', ...
                        'Unable to process %s (%s %s): %s', ...
                        behaviouralName, cursub, curses, ME.message);
                end
            end
            facessessruns{sesi, hi}{subi} = successRuns;
        end
    end
end

% Report and visualize accuracy pooled over the successful runs of each
% participant/session. Non-evaluable responses are zero in AnswerEval,
% but excluded from the accuracy denominator using evaluable trial counts.
writeSubjectAccuracyFigures( ...
    wf, p, nRuns, nTrials, nCorrect, nValid);
end

function writeGroupNBackEventCopy(eventFile, behaviouralFile)
% Add GroupNBackModelAnswer to a COPY of the event workbook.
% Compare the AH/NAT prefix of successive Face image filenames.
% The first trial has no previous face and is assigned "NA".
% ModelAnswer, RawAnswer and AnswerEval remain unchanged.

behaviour = readtable(behaviouralFile, 'TextType', 'string');
events = readtable(eventFile, 'TextType', 'string');
requiredBehaviour = {'Face', 'Person', 'PresentationTimes'};
requiredEvents = {'trial_type', 'onset'};
if ~all(ismember(requiredBehaviour, behaviour.Properties.VariableNames))
    error('NCGP:MissingNBackSourceColumns', ...
        'Face, Person or PresentationTimes missing in %s.', behaviouralFile);
end
if ~all(ismember(requiredEvents, events.Properties.VariableNames))
    error('NCGP:MissingNBackEventColumns', ...
        'trial_type or onset missing in %s.', eventFile);
end

nTrials = height(behaviour);
if nTrials == 0
    error('NCGP:EmptyNBackSource', ...
        'No face presentations found in %s.', behaviouralFile);
end

% One event per face or two events (face plus response screen) per trial.
if height(events) == nTrials
    trialRows = (1:nTrials)';
    expectedTypes = string(behaviour.Person);
    splitEvents = false;
elseif height(events) == 2 * nTrials
    trialRows = (1:2:(2 * nTrials))';
    expectedTypes = string(behaviour.Person) + "_Face";
    splitEvents = true;
else
    error('NCGP:NBackTrialCountMismatch', ...
        'Event row count does not match trials in %s.', behaviouralFile);
end

% Protect against associating an event file with the wrong behavioural run.
actualTypes = string(events.trial_type(trialRows));
behaviourOnsets = str2double(string(behaviour.PresentationTimes));
eventOnsets = str2double(string(events.onset(trialRows)));
if ~isequal(actualTypes(:), expectedTypes(:)) || ...
        any(~isfinite(behaviourOnsets)) || any(~isfinite(eventOnsets)) || ...
        any(abs(behaviourOnsets(:) - eventOnsets(:)) > 0.02)
    error('NCGP:NBackEventAlignmentMismatch', ...
        'Face identities or onset times do not align for %s.', eventFile);
end

prefix = strings(nTrials, 1);
for trial = 1:nTrials
    imageText = char(string(behaviour.Face(trial)));
    imageMatch = regexp(imageText, ...
        '(AH|NAT)[1-4]_groupnback1[01]\.png', ...
        'tokens', 'once', 'ignorecase');
    if isempty(imageMatch)
        error('NCGP:UnrecognizedNBackFace', ...
            'Unrecognized face image in %s at trial %d: %s', ...
            behaviouralFile, trial, imageText);
    end
    prefix(trial) = upper(string(imageMatch{1}));
end

groupAnswer = repmat("NA", nTrials, 1);
for trial = 2:nTrials
    if prefix(trial) == prefix(trial - 1)
        groupAnswer(trial) = "Yes";
    else
        groupAnswer(trial) = "No";
    end
end

if splitEvents
    groupAnswer = repelem(groupAnswer, 2);
end
events.GroupNBackModelAnswer = groupAnswer;
[eventFolder, eventStem] = fileparts(eventFile);
exportFile = fullfile(eventFolder, [eventStem '_nbackans.xlsx']);
writetable(events, exportFile);
end

function key = getThumbsKey(tbl, behaviouralName)
% Support the new name plus the legacy PsychoPy key-column variants.
aliases = ["thumbs_key", "thumb_key", "thumbkeylist", ...
           "thumbskey", "thumbkey"];
names = string(tbl.Properties.VariableNames);
idx = find(ismember(lower(names), lower(aliases)), 1);
if isempty(idx)
    error('NCGP:MissingThumbsKey', ...
        'Missing thumbs_key or supported alias in %s.', behaviouralName);
end

% Serialized PsychoPy values such as "('d',)" are interpreted as "d".
tokens = normalizeAnswerKeys(tbl.(char(names(idx))));
keys = unique(tokens(ismember(tokens, ["a", "b", "c", "d"])));
invalidNonempty = tokens ~= "" & ~ismember(tokens, ["a", "b", "c", "d", ...
    "na", "nan", "none", "null", "missing"]);
if any(invalidNonempty) || numel(keys) ~= 1
    error('NCGP:InvalidThumbsKey', ...
        '%s must contain exactly one consistent a/b/c/d thumbs key.', ...
        behaviouralName);
end
key = keys(1);
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

fig = [];
try
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
catch ME
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
    warning('NCGP:AccuracyFigureFailure', ...
        'Accuracy summary CSV saved, but figure export failed: %s', ...
        ME.message);
end
end
