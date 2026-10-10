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
            for ri=1:6
                g{ri}=[num2str(submin) '_fMRI_groupnback' curordermin{ri} '_results_' sesname '.xlsx'];
                fileprefix=[cursub '_' curses '_task-' wf.task '_run-0' curordermin{ri} '_events'];
                disp('cursesdir: ')
                disp(cursesdir)
                disp('curorder: ')
                disp( curorder)
                disp('curordermin: ')
                disp( curordermin)
                disp('g{ri}: ')
                disp( g{ri})
                disp('fileprefix: ')
                disp( fileprefix)
            end
        end
    end
end