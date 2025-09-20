% ==========================================================================
% Overall goal: Parse and format the 00main task (faces) onsets and condition labels for first-level GLMs.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function facessessruns= NCGP_onsets_faces(wf)
% Call → NCGP_paths: Project function call
p=NCGP_paths(wf);
scanorder=readtable([p.pre 'select_runorder_here.csv']);
hemis=wf.hemis;
% Section: for-block starts
for hi =1:length(hemis)
% Section: for-block starts
    for sesi=1:length(wf.sessions)
        curses=wf.sessions{sesi};
        facessessruns{sesi,hi}={};
% Section: for-block starts
        for subi=1:length(wf.subs)
            cursub= wf.subs{subi};
            facessessruns{sesi,hi}{subi}={};
            submin=str2num(strrep(cursub, 'sub-',''));
% Section: switch-block starts
            switch curses
% Section: case-block starts
                case 'ses-02'
                    sesname='pre';
% Section: case-block starts
                case 'ses-03'
                    sesname= 'post';
            end
            cursesdir=[p.presub{subi} filesep curses filesep filesep 'func' filesep];
            curorder=scanorder{strcmp(scanorder{:,8},cursub) & strcmp(scanorder{:,9},sesname),2:end};
            curordermin=strrep(curorder(1:6),'GN','');
% Section: for-block starts
            for ri=1:6
% Section: try-block starts
                try
                    g{ri}=[num2str(submin) '_fMRI_groupnback' curordermin{ri} '_results_' sesname '.xlsx'];
                    fileprefix=[cursub '_' curses '_task-' wf.task '_run-0' curordermin{ri} '_events'];
                    newfn=[cursesdir fileprefix '.xlsx'];
                    oldtbl=readtable([cursesdir g{ri}]);
                    newtbl=table;
                    newtbl.trial_type=oldtbl.Person;
                    newtbl.onset=oldtbl.PresentationTimes;
% Section: if-block starts
                    if wf.modelblackresponse
                        doubledarr={};
                        facepr_duration=1.5;
                        blank_duration=3.5;

% Section: for-block starts
                        for i = 1:height(oldtbl)
                            doubledarr(end+1,1)=cellstr([newtbl.trial_type{i} '_Face']);
                            facepr_start=newtbl.onset(i);
                            doubledarr(end,2)=num2cell(facepr_start);
                            doubledarr(end,3)=num2cell(facepr_duration);
                            doubledarr(end+1,1)=cellstr([newtbl.trial_type{i} '_BlackResponse']);
                            blank_start=facepr_start+facepr_duration;
                            doubledarr(end,2)=num2cell(blank_start);
% Section: if-block starts
                            if i < height(oldtbl)
                                nextface_start=newtbl.onset(i+1);
                                doubledarr(end,3)=num2cell(nextface_start - blank_start);
% Section: else-block starts
                            else
                                doubledarr(end,3)=num2cell(blank_duration);
                            end
                        end
                        newtbl=array2table(doubledarr, 'VariableNames',{'trial_type', 'onset', 'duration'});

% Section: else-block starts
                    else
                        newtbl.duration=zeros(height(newtbl),1)+5;
                    end
                    writetable(newtbl,newfn);
                    facessessruns{sesi,hi}{subi}{end+1,1}=curses;
                    facessessruns{sesi,hi}{subi}{end,2}=['run-0' curordermin{ri}];
% Section: catch-block starts
                catch ME
                    disp(ME.message)
                end
            end
        end
    end
end
end
