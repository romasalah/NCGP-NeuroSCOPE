% Overall goal: Calculates the group identification score and reverse
% scores questions 3, 4, 9, 12 then Calculates the mean
function [identclass, identtable]=NCGP_identscore(subsfolder,subs)
identmean=[];
% Section: for-block starts
for subi=1:length(subs)
    %subid=num2str(subs(subi));
    cursub=subs{subi};
    %% Load results
    gpidentfile=[subsfolder filesep cursub '_ident_output.xlsx'];
% Section: if-block starts
    if exist(gpidentfile, 'file')==2
    gpidenttbl=readtable(gpidentfile);
    allgpident(:,subi)=gpidenttbl.GroupIdent_results;
    %% Reverse Score specific Questions (Q3, Q4, Q9, Q12)
    minscore=1;maxscore=6;
    rcwrong=allgpident([3 4 9 12],subi);
    allgpident_corrected(:,subi)=allgpident(:,subi);
    allgpident_corrected([3 4 9 12],subi)=(minscore-rcwrong)+maxscore;
    identmean(end+1,2)=mean(allgpident_corrected(:,subi)); % get the average value of all the 16 group identity questions for each subject.
    identmean(end,1)=str2num(cursub);
    else
        disp(['No separate scores file found for participant' ])
    end
end
identtable=array2table(identmean, 'VariableNames', {'sub', 'score'});
%writetable(identtable, [subsfolder 'NCGPBehav_identscores.xlsx']);
idmumed=median(identmean,2); % calculate the median point
% Section: for-block starts
for subi2=1:length(identmean)
    curscore=identmean(subi2,2);
% Section: if-block starts
    if curscore > idmumed
        identclass{subi2}='HighIdentifier';
% Section: elseif-block starts
    elseif curscore <= idmumed
        identclass{subi2}='LowIdentifier';
    end
end
end