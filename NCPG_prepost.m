% ==========================================================================
% Overall goal: Compute pre vs post session differences (e.g., between-/within-group LDt change).
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [alltasksmat_pre, alltasksmat_post,taskname]=NCPG_prepost(wf, plotflag)
close all;
%% settings
taskname={'Physical','Personality','Social life'};
gpnames_AH={'AH1','AH2','AH3','AH4','NAT1','NAT2','NAT3','NAT4'};
%% exclude participants
selectgender='mf';
exc_str='_all_participants';
% Section: switch-block starts
switch wf.exp
% Section: case-block starts
    case 'NCGP'
        idadd=200;
% Section: case-block starts
    case 'BehavNCGP'
        idadd=0;
end
wf.subs_num=cellfun(@(z) str2num(z)+ idadd, strrep(wf.subs,'sub-',''));
% %% load demographics
% alldemos=readtable([gh filesep 'demos_all.xlsx']);
% subdemos=alldemos(ismember(alldemos.ID,subs),:);
% %% select gender
% if ~strcmpi(selectgender,'mf')
%     subdemos=alldemos(contains(alldemos.Gender,selectgender),:);
%     subs=subdemos.ID;
% end
%% Pre-post analysis
%% load tables
% Call → NCPG_loadfacesimtbl: Project function call
allfacesimtbls_pre0=NCPG_loadfacesimtbl(wf,'pre');
% Call → NCPG_loadfacesimtbl: Project function call
[allfacesimtbls_post0, allgpnames, allingpnames]=NCPG_loadfacesimtbl(wf,'post');
gpnames_inout=gpnames_AH;
%% get prepost IDs
allfacesimtbls_pre=allfacesimtbls_pre0(~cellfun(@isempty,{allfacesimtbls_pre0{:,1}}),1);
ff=cellstr(allfacesimtbls_pre0(~cellfun(@isempty,{allfacesimtbls_pre0{:,1}}),2));
validids_pre=str2double(ff);
validids_pre_loc=ismember(str2double({allfacesimtbls_post0{:,2}}'),validids_pre);
allfacesimtbls_post=allfacesimtbls_post0(validids_pre_loc,1);
%% get participant data
% switch wf.exp
%     case 'Behav'
%         ptidfn=[wf.mainpath 'NCGPBehav_identscores.xlsx'];
%         ptidtbl=readtable(ptidfn);
%         identscores=ptidtbl.score;
%     case 'NCGP'
% Call → NCPG_paths: Project function call
%         paths=NCPG_paths(wf);
%         ptidfn=[paths.pre 'NCGP_participants_scored.xlsx'];
%         ptidtbl=readtable(ptidfn);
%         ptitdtbl_min=ptidtbl(ismember(ptidtbl.EXPID,wf.subs_num - idadd),:);
%         identscores=ptitdtbl_min.Ident_score;
% end
% idmumed=median(identscores); % calculate the median point
% identclass={};
% for subi2=1:length(identscores)
%     if identscores(subi2) > idmumed
%         identclass{subi2,1}='HighIdentifier';
%     elseif identscores(subi2) <= idmumed
%         identclass{subi2,1}='LowIdentifier';
%     end
% end
%allconditions=NCPGH_getcondition(validids_pre);
%% LMM
% Call → NCPG_build_LMM: Project function call
[alltbls,cursubtbl, allsubavgs]=NCPG_build_LMM(wf, allfacesimtbls_pre0,allfacesimtbls_post0,allingpnames);
behavoutputfolder=[wf.mainpath 'behav' filesep ];
mkdir(behavoutputfolder);
writetable(cursubtbl,[behavoutputfolder 'LMM' exc_str '_' selectgender 'subjectbased.csv'])
writetable(alltbls,['LMM' exc_str '_' selectgender '.csv'])
%% Get ratings
% Call → NCPG_facesim_ratings_alltasks: Project function call
[alltasksmat_pre,allingpsim_pre,alloutgpsim_pre,allbtgpsim_pre,allingpsim_distavg_pre,alloutgpsim_distavg_pre, allbtgpsim_distavg_pre]=NCPG_facesim_ratings_alltasks(validids_pre,allfacesimtbls_pre,allgpnames,'pre',wf.exp);
% Call → NCPG_facesim_ratings_alltasks: Project function call
[alltasksmat_post,allingpsim_post,alloutgpsim_post,allbtgpsim_post,allingpsim_distavg_post,alloutgpsim_distavg_post, allbtgpsim_distavg_post]=NCPG_facesim_ratings_alltasks(validids_pre,allfacesimtbls_post,allgpnames,'post',wf.exp);
%% plot ratings
% Section: if-block starts
if plotflag==1
% Call → NCPG_plot: Project function call
    NCPG_plot(alltasksmat_pre, allingpsim_pre, alloutgpsim_pre,allbtgpsim_pre, allingpsim_distavg_pre, alloutgpsim_distavg_pre,allbtgpsim_distavg_pre, allingpnames, taskname, gpnames_AH,gpnames_inout,'pre');
% Call → NCPG_plot: Project function call
    NCPG_plot(alltasksmat_post, allingpsim_post, alloutgpsim_post,allbtgpsim_post, allingpsim_distavg_post, alloutgpsim_distavg_post, allbtgpsim_distavg_post,allingpnames, taskname, gpnames_AH,gpnames_inout,'post');
end
% Call → NCPG_plotMCR: Project function call
[intragroupsim_pre_avg,intragroupsim_post_avg,intergpsim_pre_avg,intergpsim_post_avg]=NCPG_plotMCR(allingpsim_pre,alloutgpsim_pre,allbtgpsim_pre,allingpsim_post,alloutgpsim_post,allbtgpsim_post,allingpnames,taskname, plotflag);
% %% table and export
distances_prepost=array2table([ allingpnames', ...
    num2cell(intragroupsim_post_avg{1} - intragroupsim_pre_avg{1})', num2cell(intergpsim_post_avg{1} - intergpsim_pre_avg{1})',...
    num2cell(intragroupsim_post_avg{2} - intragroupsim_pre_avg{2})', num2cell(intergpsim_post_avg{2} - intergpsim_pre_avg{2})',...
    num2cell(intragroupsim_post_avg{3} - intragroupsim_pre_avg{3})', num2cell(intergpsim_post_avg{3} - intergpsim_pre_avg{3})',...
    ],'VariableNames',{'Group',...
    'Phys_withingpsim_diff','Phys_intergpsim_diff',...
    'Per_withingpsim_diff','Per_intergpsim_diff',...
    'Soc_withingpsim_diff','Soc_intergpsim_diff',...
    });
writetable([distances_prepost],['distances_prepost' exc_str '_' selectgender '.csv'])
subrestbl_prepost=array2table([ allingpnames', ...
    num2cell(allingpsim_distavg_post{1} - allingpsim_distavg_pre{1})', num2cell(alloutgpsim_distavg_post{1} - alloutgpsim_distavg_pre{1})',...
    num2cell(allingpsim_distavg_post{2} - allingpsim_distavg_pre{2})', num2cell(alloutgpsim_distavg_post{2} - alloutgpsim_distavg_pre{2})',...
    num2cell(allingpsim_distavg_post{3} - allingpsim_distavg_pre{3})', num2cell(alloutgpsim_distavg_post{3} - alloutgpsim_distavg_pre{3})',...
    ],'VariableNames',{'Group',...
    'Inpg_Phys_withingpsim_diff','Outpg_Phys_withingpsim_diff',...
    'Inpg_Per_withingpsim_diff','Outpg_Per_withingpsim_diff',...
    'Inpg_Soc_withingpsim_diff','Outpg_Soc_withingpsim_diff',...
    });
writetable([subrestbl_prepost],['subrestbl_prepost' exc_str '_' selectgender '.csv'])
end
