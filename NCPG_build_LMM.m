% ==========================================================================
% Overall goal (user-provided): Overall goal: Creates a condition response table compatible with doing Linear Mixed Modelling in JASP or R
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Creates a condition response table compatible with doing Linear Mixed Modelling in JASP or R
% Note: 
% ==========================================================================
% Function signature detected
function [alltbls,allsubtables,allsubsavgs]=NCPG_build_LMM(wf,pretables,posttables,ingpnames)
alltbls=cell(0,7);
allsubtables=[];
allsubsavgs=[];
lbls={'phys_face1', 'phys_face2', 'physical', 'persoc_face1', 'persoc_face2', 'personality', 'social life'};
% Section: for-block starts
for subi=1:size(pretables,1)
    curpre=pretables{subi,1};
% Section: if-block starts
    if size(curpre,2)==8
        locs=[4,5,6,4,5,7,8];

% Section: elseif-block starts
    elseif size(curpre,2)==11
        locs=[5,6,7,8,9,10,11];

    end
    curpost=posttables{subi,1};
    [~,preidx]=sort(str2num(char(pretables(:,2))));
    [~,postidx]=sort(str2num(char(posttables(:,2))));
    pretables{subi,1}=pretables{subi,1}(preidx,:);
    posttables{subi,1}=posttables{subi,1}(postidx,:);
    idtblpre=array2table(strrep(cellstr(num2str(zeros(size(curpre,1),1))),'0',[pretables{subi,2}]),'VariableNames',{'ID'});
    idtblpost=array2table(strrep(cellstr(num2str(zeros(size(curpre,1),1))),'0',[pretables{subi,2}]),'VariableNames',{'ID'});
    phystask=array2table(strrep(cellstr(num2str(zeros(size(curpre,1),1))),'0','Physical'),'VariableNames',{'Task'});
    pertask=array2table(strrep(cellstr(num2str(zeros(size(curpre,1),1))),'0','Personality'),'VariableNames',{'Task'});
    soctask=array2table(strrep(cellstr(num2str(zeros(size(curpre,1),1))),'0','Social'),'VariableNames',{'Task'});
    pretime=array2table(strrep(cellstr(num2str(zeros(size(curpre,1),1))),'0','t1-Pre'),'VariableNames',{'Time'});
    posttime=array2table(strrep(cellstr(num2str(zeros(size(curpost,1),1))),'0','t2-Post'),'VariableNames',{'Time'});
    ts1=[idtblpre, array2table([curpre{:,locs(1:2)} num2cell(curpre{:,locs(3)})],'VariableNames',{'Face1','Face2','rating'}), phystask, pretime];
    ts2=[idtblpre, array2table([curpre{:,locs(4:5)} num2cell(curpre{:,locs(6)})],'VariableNames',{'Face1','Face2','rating'}), pertask, pretime];
    ts3=[idtblpre, array2table([curpre{:,locs(4:5)} num2cell(curpre{:,locs(7)})],'VariableNames',{'Face1','Face2','rating'}), soctask, pretime];
    ts4=[idtblpost, array2table([curpost{:,locs(1:2)} num2cell(curpost{:,locs(3)})],'VariableNames',{'Face1','Face2','rating'}), phystask, posttime];
    ts5=[idtblpost, array2table([curpost{:,locs(4:5)} num2cell(curpost{:,locs(6)})],'VariableNames',{'Face1','Face2','rating'}), pertask, posttime];
    ts6=[idtblpost, array2table([curpost{:,locs(4:5)} num2cell(curpost{:,locs(7)})],'VariableNames',{'Face1','Face2','rating'}), soctask, posttime];
    cursubtbl0=[ts1;ts2;ts3;ts4;ts5;ts6];
    ingp=ingpnames{subi};
% Section: if-block starts
    if strcmpi(ingp,'AH')
        outgp='NAT';
% Section: elseif-block starts
    elseif strcmpi(ingp,'NAT')
        outgp='AH';
    end
    ingpf1_ingpf2=contains(regexprep(cursubtbl0.Face1,'\d',''),ingp) & contains(regexprep(cursubtbl0.Face2,'\d',''),ingp);
    outgpf1_outgpf2=contains(regexprep(cursubtbl0.Face1,'\d',''),outgp) & contains(regexprep(cursubtbl0.Face2,'\d',''),outgp);
    withingroup=cellstr(num2str(ingpf1_ingpf2+outgpf1_outgpf2 ));
    %isingpf1=contains(regexprep(cursubtbl0.Face1,'\d',''),ingp);
    %isingpf2=contains(regexprep(cursubtbl0.Face2,'\d',''),ingp);
    %isoutgpf1=contains(regexprep(cursubtbl0.Face1,'\d',''),outgp);
    %isoutgpf2=contains(regexprep(cursubtbl0.Face2,'\d',''),outgp);
    %ingpingp=cellstr(num2str(isingpf1==isingpf2));
    %outgpoutgp=cellstr(num2str(isoutgpf1==isoutgpf2));
    %withingroup=cellstr(num2str(isingpf1==isingpf2 + isoutgpf1==isoutgpf2));
    comparisontypenum=strrep(withingroup,'0','Between-groups');
    comparisontypenum=strrep(comparisontypenum,'1','Within-groups');
    ts7=array2table(comparisontypenum,'VariableNames',{'Comparison_type'});
    curtable=[[ts1;ts2;ts3;ts4;ts5;ts6] ,ts7];
    %% Plot average values
    pause(1);
    comptypes={'Within-groups','Between-groups'};
    tasktypes={'Physical','Personality','Social'};
    timetypes={'Post','Pre'};
    cursubtbl{subi}=array2table(nan(32,13));
    colnum=0;
% Section: for-block starts
    for i=1:length(tasktypes)
        tasktbls{i}= curtable(contains(curtable.Task,tasktypes{i}),:);
% Section: for-block starts
        for i2=1:length(timetypes)
            tasktbls_time{i}{i2}=tasktbls{i}(contains(tasktbls{i}.Time,timetypes{i2}),:);
% Section: for-block starts
            for i3=1:length(comptypes)
                colnum=colnum+1;
                curseltbl=tasktbls_time{i}{i2}(contains(tasktbls_time{i}{i2}.Comparison_type,comptypes{i3}),:);
                curvarnames{colnum}=[ tasktypes{i} '_' timetypes{i2} '_' comptypes{i3}];
                cursubtbl{subi}(1:size(curseltbl,1),1)= array2table(str2num(cell2mat(curseltbl.ID)),'VariableNames',{'ID'});
                cursubavg{subi}(1,1)= array2table(str2num(cell2mat(curseltbl.ID(1))),'VariableNames',{'ID'});
% Section: if-block starts
                if colnum==1
                    curtesttbl=array2table(cell2mat(curseltbl.rating),'VariableNames',{curvarnames{colnum}});
                    cursubtbl{subi}(1:size(curtesttbl,1),2)= curtesttbl;
                    cursubavg{subi}(1,2)= curtesttbl(1,1);
% Section: else-block starts
                else
                    curtesttbl=array2table(cell2mat(curseltbl.rating),'VariableNames',{curvarnames{colnum}});
                    cursubtbl{subi}(1:size(curtesttbl,1),colnum+1)= curtesttbl;
                    cursubavg{subi}(1,colnum+1)= array2table(mean(table2array(curtesttbl)),'VariableNames',{'mm'});
                end

            end
        end
    end
    cursubavg{subi}.Properties.VariableNames=['ID', curvarnames];
    cursubtbl{subi}.Properties.VariableNames=['ID', curvarnames];
    allsubtables=[allsubtables; cursubtbl{subi}];
    allsubsavgs=[allsubsavgs; cursubavg{subi}];
    alltbls=[alltbls; curtable];
end
end
