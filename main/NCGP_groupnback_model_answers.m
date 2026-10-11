function GroupNBackModelAnswer = NCGP_groupnback_model_answers(behaviour)
%NCGP_GROUPNBACK_MODEL_ANSWERS Compute expected group 1-back responses.
%
%   GroupNBackModelAnswer = NCGP_groupnback_model_answers(behaviour)
%
% Input
%   behaviour: table read from a behavioural results XLSX with a Face
%              column holding image filenames.
%
% Output
%   GroupNBackModelAnswer: nTrials-by-1 string column containing "Yes",
%              "No", or "NA". Trial 1 is "NA", because it has no preceding
%              face. All subsequent trials compare group prefixes:
%                  same AH/NAT prefix as preceding face -> "Yes"
%                  different prefix                  -> "No"
%
% This function only returns a column; it reads/writes NO files.
% The logic is extracted from addGroupNBackAnswerToEventFile in the former
% NCGP_onsets_faces_answer_eval implementation.

if ~istable(behaviour) || ~ismember('Face', behaviour.Properties.VariableNames)
    error('NCGP:MissingNBackSourceColumns', ...
        'Input must be a behavioural table containing a Face column.');
end

nTrials = height(behaviour);
if nTrials == 0
    error('NCGP:EmptyNBackSource', ...
        'No face presentations found in the behavioural table.');
end

% Extract the AH or NAT group from each face-image filename. Use the
% original filename pattern so existing input validation stays unchanged.
prefix = strings(nTrials, 1);
for trial = 1:nTrials
    imageText = char(string(behaviour.Face(trial)));
    imageMatch = regexp(imageText, ...
        '(AH|NAT)[1-4]_groupnback1[01]\.png', ...
        'tokens', 'once', 'ignorecase');
    if isempty(imageMatch)
        error('NCGP:UnrecognizedNBackFace', ...
            'Unrecognized face image at trial %d: %s', ...
            trial, imageText);
    end
    prefix(trial) = upper(string(imageMatch{1}));
end

GroupNBackModelAnswer = repmat("NA", nTrials, 1);
for trial = 2:nTrials
    if prefix(trial) == prefix(trial - 1)
        GroupNBackModelAnswer(trial) = "Yes";
    else
        GroupNBackModelAnswer(trial) = "No";
    end
end
end
