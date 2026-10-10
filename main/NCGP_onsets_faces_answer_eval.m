% =========================================================================
% Duplicate of NCGP_onsets_faces, with trial-level behavioural accuracy.
%
% For each behavioural .xlsx file:
%   - Read the response-key mapping from thumbkeylist / middlekeylist
%     (or their supported alias names).
%   - Convert RawAnswer key presses to Yes / No in memory.
%   - Compare them with ModelAnswer, producing AnswerEval = 1 or 0.
%   - Append AnswerEval to the exported first-level GLM event table.
%
% Unanswered trials receive AnswerEval = 0. Source behavioural .xlsx files
% are NEVER modified. This function does not change the downstream GLM
% design: the existing first-level GLM currently uses trial_type, onset,
% and duration, and ignores extra event-table columns.
% =========================================================================
function facessessruns = NCGP_onsets_faces_answer_eval(wf)

p = NCGP_paths(wf);

% The provided run-order CSV has no header. Read its first row as data.
scanorder = readtable(fullfile(p.pre, 'select_runorder_here.csv'), ...
    'ReadVariableNames', false, 'TextType', 'string');

if width(scanorder) < 9
    error('NCGP:InvalidRunOrder', ...
        'Run-order CSV must contain at least nine columns.');
end

facessessruns = cell(numel(wf.sessions), numel(wf.hemis));

for hi = 1:numel(wf.hemis)
    for sesi = 1:numel(wf.sessions)
        curses = wf.sessions{sesi};
        switch curses
            case 'ses-02'
                sesname = 'pre';
            case 'ses-03'
                sesname = 'post';
            otherwise
                error('NCGP:InvalidSession', ...
                    'Unsupported faces session: %s', curses);
        end

        facessessruns{sesi, hi} = cell(numel(wf.subs), 1);
        for subi = 1:numel(wf.subs)
            cursub = wf.subs{subi};
            submin = str2double(strrep(cursub, 'sub-', ''));
            if isnan(submin)
                error('NCGP:InvalidSubject', 'Invalid subject ID: %s', cursub);
            end

            cursesdir = fullfile(p.presub{subi}, curses, 'func');
            matching = string(scanorder{:, 8}) == string(cursub) & ...
                string(scanorder{:, 9}) == string(sesname);
            if nnz(matching) ~= 1
                warning('NCGP:RunOrderMismatch', ...
                    'Expected one run-order record for %s %s; found %d. Skipping.', ...
                    cursub, sesname, nnz(matching));
                facessessruns{sesi, hi}{subi} = cell(0, 2);
                continue;
            end

            curorder = string(scanorder{matching, 2:7});
            curordermin = erase(curorder, 'GN');
            successRuns = cell(0, 2);

            for ri = 1:6
                runNumber = char(curordermin(ri));
                behaviouralName = sprintf('%d_fMRI_groupnback%s_results_%s.xlsx', ...
                    submin, runNumber, sesname);
                behaviouralFile = fullfile(cursesdir, behaviouralName);
                outputName = sprintf('%s_%s_task-%s_run-0%s_events.xlsx', ...
                    cursub, curses, wf.task, runNumber);
                outputFile = fullfile(cursesdir, outputName);

                try
                    oldtbl = readtable(behaviouralFile);
                    required = {'Person', 'PresentationTimes', 'RawAnswer', 'ModelAnswer'};
                    if ~all(ismember(required, oldtbl.Properties.VariableNames))
                        error('NCGP:MissingColumns', ...
                            'Required columns are missing from %s.', behaviouralName);
                    end

                    % These key bindings are per file, not per trial.
                    yesKey = getResponseKey(oldtbl, ...
                        {'thumbkeylist', 'thumb_key', 'thumbkey'}, behaviouralName);
                    noKey = getResponseKey(oldtbl, ...
                        {'middlekeylist', 'middle_finger_key', ...
                         'middlefingerkey', 'middle_key'}, behaviouralName);
                    if yesKey == noKey
                        error('NCGP:DuplicateResponseKeys', ...
                            'Yes and No map to the same key in %s.', behaviouralName);
                    end

                    % Convert the raw responses from d/c to Yes/No in memory.
                    raw = lower(strtrim(string(oldtbl.RawAnswer)));
                    raw(ismissing(raw)) = "";
                    raw = regexprep(raw, '[^a-z]', '');
                    raw(ismember(raw, ["nan", "none", "null", "missing"])) = "";
                    unknown = raw ~= "" & raw ~= yesKey & raw ~= noKey;
                    if any(unknown)
                        error('NCGP:UnknownResponse', ...
                            'Unrecognized RawAnswer key on row(s) %s in %s.', ...
                            mat2str(find(unknown)' + 1), behaviouralName);
                    end
                    mappedRaw = strings(height(oldtbl), 1);
                    mappedRaw(raw == yesKey) = "Yes";
                    mappedRaw(raw == noKey) = "No";
                    oldtbl.RawAnswer = mappedRaw;

                    expected = lower(strtrim(string(oldtbl.ModelAnswer)));
                    expected(ismissing(expected)) = "";
                    if any(~ismember(expected, ["yes", "no"]))
                        error('NCGP:InvalidModelAnswer', ...
                            'ModelAnswer must contain Yes or No in %s.', behaviouralName);
                    end
                    answerEval = double(mappedRaw ~= "" & ...
                        lower(mappedRaw) == expected);

                    trialTypes = string(oldtbl.Person);
                    if any(ismissing(trialTypes) | strlength(trialTypes) == 0)
                        error('NCGP:MissingIdentity', ...
                            'A Person (face identity) is missing in %s.', behaviouralName);
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
                        % Copy accuracy to both events originating from a trial.
                        ntrials = height(oldtbl);
                        trial_type = strings(2 * ntrials, 1);
                        onset = zeros(2 * ntrials, 1);
                        duration = zeros(2 * ntrials, 1);
                        AnswerEval = repelem(answerEval, 2);
                        for i = 1:ntrials
                            faceRow = 2 * i - 1;
                            blackRow = 2 * i;
                            trial_type(faceRow) = trialTypes(i) + "_Face";
                            onset(faceRow) = onsets(i);
                            duration(faceRow) = 1.5;

                            trial_type(blackRow) = trialTypes(i) + "_BlackResponse";
                            onset(blackRow) = onsets(i) + 1.5;
                            if i < ntrials
                                duration(blackRow) = onsets(i + 1) - onset(blackRow);
                            else
                                duration(blackRow) = 3.5;
                            end
                        end
                        if any(duration < 0)
                            error('NCGP:NegativeDuration', ...
                                'Overlapping onsets cause negative durations in %s.', ...
                                behaviouralName);
                        end
                    else
                        trial_type = trialTypes;
                        onset = onsets;
                        duration = 5 * ones(height(oldtbl), 1);
                        AnswerEval = answerEval;
                    end

                    newtbl = table(cellstr(trial_type), onset, duration, AnswerEval, ...
                        'VariableNames', {'trial_type', 'onset', 'duration', 'AnswerEval'});
                    writetable(newtbl, outputFile);
                    successRuns(end + 1, :) = {curses, ['run-0' runNumber]}; %#ok<AGROW>

                catch ME
                    warning('NCGP:OnsetsFacesEvalSkippedRun', ...
                        'Could not process %s (%s %s): %s', ...
                        behaviouralName, cursub, curses, ME.message);
                end
            end
            facessessruns{sesi, hi}{subi} = successRuns;
        end
    end
end
end

function key = getResponseKey(tbl, aliases, behaviouralName)
% Accept direct keys (d/c) and serialized representations, e.g. ('d',).
columnNames = string(tbl.Properties.VariableNames);
columnIndex = find(ismember(lower(columnNames), lower(string(aliases))), 1);
if isempty(columnIndex)
    error('NCGP:MissingKeyColumn', ...
        'Missing response-key column (%s) in %s.', ...
        strjoin(aliases, ' / '), behaviouralName);
end

values = lower(strtrim(string(tbl.(char(columnNames(columnIndex))))));
values(ismissing(values)) = "";
values = regexprep(values, '[^a-z]', '');
values(ismember(values, ["nan", "none", "null", "missing"])) = "";
keys = unique(values(values ~= ""));

if numel(keys) ~= 1 || ~ismember(keys, ["d", "c"])
    error('NCGP:InvalidKeyMapping', ...
        'Response-key column %s must specify exactly one key (d or c) in %s.', ...
        char(columnNames(columnIndex)), behaviouralName);
end
key = keys(1);
end
