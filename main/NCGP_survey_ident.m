% ==========================================================================
% Overall goal (user-provided): Overall goal: Calculates the group identification score and reverse scores questions 3, 4, 9, 12 then Calculates the mean
% ==========================================================================
fname='C:\Users\CENs-Admin\Desktop\NCGP_latest_filtered.csv';
rawsurvey=readtable(fname);
varnames=rawsurvey.Properties.VariableNames;
scorelabels={'Stimme überhaupt nicht zu', 'Stimme nicht zu', 'Stimme eher nicht zu', 'Stimme eher zu', 'Stimme zu', 'Stimme stark zu'};
scorenums={'1', '2', '3', '4', '5', '6'};
ahidentloc=find(contains(varnames,'AH_ident'));
natidentloc=find(contains(varnames,'NAT_ident'));
allgpmemberships=rawsurvey.Q49;
% Section: for-block starts
for i=1:length(allgpmemberships)
    gpmembership=allgpmemberships{i};
% Section: switch-block starts
    switch gpmembership
% Section: case-block starts
        case 'Naturwissenschaften'
            curident = rawsurvey{i,natidentloc};
% Section: case-block starts
        case 'Geisteswissenschaften'
            curident = rawsurvey{i,ahidentloc};
    end
% Section: for-block starts
    for ri=1:length(scorelabels)
        curident=strrep(curident,scorelabels{ri}, scorenums{ri});
    end
    gpident=str2double(cellstr(curident));
    %% Reverse Score specific Questions (Q3, Q4, Q9, Q12)
    minscore=1;maxscore=6;
    rcwrong=gpident([3 4 9 12]);
    gpident_corrected=gpident;
    gpident_corrected([3 4 9 12])=(minscore-rcwrong)+maxscore;
    identmean(i)=mean(gpident_corrected); % get the average value of all the 16 group identity questions for each subject.
end
scoredfname=strrep(fname, '.csv','_scored.xlsx');
%scoredtbl=[rawsurvey array2table(identmean','VariableNames',{'Ident_score'})];
writetable(rawsurvey,scoredfname);
disp(identmean);
