% ==========================================================================
% Overall goal: Parse and format localizer task onsets (e.g., Faces/Objects) for first-level GLM design matrices.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function localizersessruns=NCGP_onsets_localizer(wf)
mainPath=wf.mainpath;
subjects=wf.subs;
sessions=wf.sessions;
runs=wf.runs;
% Section: for-block starts
for subi =1:length(subjects)
    cursubdir=[mainPath filesep 'derivatives' filesep wf.pre filesep subjects{subi} filesep];
    localizersessruns{subi}={};
% Section: for-block starts
    for si=1:length(sessions)
        cursessname=sessions{si};
% Section: for-block starts
        for ri=1:length(runs)
            currun=runs{ri};
            onsetsdir = [cursubdir filesep cursessname filesep 'func' filesep];
            fnamebase=[onsetsdir subjects{subi} '_' cursessname '_task-' wf.task '_' runs{ri} '_events'];
            fnametsvdir=dir([fnamebase '.tsv']);
            %% Create an organised onsets table
% Section: if-block starts
            if isempty(fnametsvdir)
                fnametxtdir=dir([fnamebase '.txt']);
% Section: if-block starts
                if isempty(fnametxtdir)
                    warning(['No Onsets for the localizer run No. ' num2str(ri) ' in session No. ' num2str(si)]);
                    continue
                end
                fname=[fnametxtdir(1).folder filesep fnametxtdir(1).name];
                onsetsraw=readtable(fname,'Delimiter',{'Tab'}, 'ReadVariableNames',false);
                headloc=find(contains(onsetsraw{:,1},'stim_type') & contains(onsetsraw{:,1},'repetition'));
                onsetsraw=onsetsraw{headloc+1:end,:};
                onsetscell=cell(size(onsetsraw,1), 7);

                splitarr=arrayfun(@(z) strsplit(z{1}, '\t'),onsetsraw, 'UniformOutput', false);
% Section: for-block starts
                for i=1:size(splitarr,1)
                    onsetscell(i,1:length(splitarr{i}))=splitarr{i};
                end
                onsetstbl=array2table(onsetscell,'VariableNames',{'TimeFromStart', 'type', 'onset', 'duration','stim_type', 'stim_name', 'repetition'});
                writetable(onsetstbl, [fnamebase '_temp.xlsx'])
                onsetstbl=readtable([fnamebase '_temp.xlsx']);
                onsetstbl=onsetstbl(~contains(onsetstbl.type,'EXP'),:);


            loctype=zeros(size(onsetstbl(:,1),1),1);
            stimuluslist=cell(size(onsetstbl(:,1),1),1);
            onsets=zeros(size(onsetstbl(:,1),1),1);
            stimdurations=zeros(size(onsetstbl(:,1),1),1);
% Section: for-block starts
            for i=1:size(onsetstbl(:,1),1)
                currow=onsetstbl{i,:};
                currowdiv= currow;
% Section: if-block starts
                if i==1
                    first_onset(i)=str2num(currowdiv{1});
                end
% Section: if-block starts
                if strcmpi(currowdiv{2},'EXP')==0
                    onsets(i)=str2num(currowdiv{1});
% Section: if-block starts
                    if strcmpi(currowdiv{2},'BIDS')==1
                        stimdurations(i)=str2num(currowdiv{4});
% Section: elseif-block starts
                    elseif strcmpi(currowdiv{2},'DATA')==1
                        stimdurations(i)=0;
                        loctype(i)=1;
                        stimuluslist{i}='Key_press';
                    end
% Section: if-block starts
                    if strcmpi(currowdiv{2},'EXP')==0
% Section: if-block starts
                        if sum(contains(currowdiv,'Scrambled15G\obj'))>0
                            loctype(i)=1;
                            stimuluslist{i}='Scrambled_Object';
% Section: elseif-block starts
                        elseif sum(contains(currowdiv,'Bodies'))>0
                            loctype(i)=2;
                            stimuluslist{i}='Body';
% Section: elseif-block starts
                        elseif sum(contains(currowdiv,'Faces\'))>0
                            loctype(i)=3;
                            stimuluslist{i}='Face';
% Section: elseif-block starts
                        elseif sum(contains(currowdiv,'Objects\'))>0
                            loctype(i)=4;
                            stimuluslist{i}='Object';
% Section: elseif-block starts
                        elseif sum(contains(currowdiv,'Scenes\'))>0
                            loctype(i)=5;
                            stimuluslist{i}='Scene';
% Section: elseif-block starts
                        elseif sum(strcmpi(currowdiv,'d'))>0
                            loctype(i)=6;
                            stimuluslist{i}='Thumb';
% Section: elseif-block starts
                        elseif sum(strcmpi(currowdiv,'c'))>0
                            loctype(i)=7;
                            stimuluslist{i}='Index';
% Section: elseif-block starts
                        elseif sum(strcmpi(currowdiv,'fixation'))>0
                            loctype(i)=8;
                            stimuluslist{i}='Fixation';
                        end
                    end
                end
            end
            finalonsets=array2table([num2cell(onsets - onsets(1)) num2cell(stimdurations) num2cell(loctype) stimuluslist],'VariableNames',{'Onset','Duration','Stimulus_Index','Stimulus_Type'});
            nonempt=~cellfun(@isempty,finalonsets.Stimulus_Type);
            finalonsets=finalonsets(nonempt,:);
            finalonsets.Properties.VariableNames={'onset','duration','stimulus_index', 'trial_type'};
            fn=[onsetsdir subjects{subi} '_' cursessname '_task-' wf.task '_' runs{ri} '_events.xlsx'];
            writetable(finalonsets, fn);

            txtfn=strrep(fn, '.xlsx', '.txt');
            tsvfn=strrep(fn, '.xlsx', '.tsv');
            writetable(finalonsets,txtfn,"Delimiter",'tab');
            copyfile(txtfn,tsvfn);
            delete(txtfn);
% Section: else-block starts
            else
                fn=[fnamebase '.xlsx'];
                onsetstbl=readtable(fn);
% Section: if-block starts
                if sum(contains(onsetstbl.Properties.VariableNames,{'onset','duration','stimulus_index', 'trial_type'}))==4
                    disp(['Valid NCGP onsets file: ' fn]);
% Section: else-block starts
                else
                    error(['invalid NCGP onsets file: ' fn]);
                end
            end
            localizersessruns{subi}{end+1,1}=cursessname;
            localizersessruns{subi}{end,2}=runs{ri};
        end
    end
end
end
