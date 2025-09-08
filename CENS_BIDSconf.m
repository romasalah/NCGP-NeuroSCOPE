% ==========================================================================
% Overall goal (user-provided): Overall goal: Creates a BIDS configuration file based on scans.xlsx file which lists run numbers (as in DICOM files) and run task
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Creates a BIDS configuration file based on scans.xlsx file which lists run numbers (as in DICOM files) and run task
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
% Function signature detected
function CENS_BIDSconf(flag)
%% User defined Variables
RootDir='E:\Omar\DICOM\';
NumOfSessions=2;
ParticiantIDs=[1,10,12];
taskname='theNameOfYourTask';
%% Start of Script
subprefix='sub';
sesslist={};
% Section: for-block starts
for i=1:NumOfSessions
    sesslist=horzcat(sesslist,['S' num2str(i)]);
end
% Section: for-block starts
for subi=1:length(ParticiantIDs)
    cursubfull=[subprefix '0' num2str(ParticiantIDs(subi))];
    cursubfolder = [RootDir filesep cursubfull filesep 'MRI' filesep];
    scanstbl=[cursubfolder 'scans.xlsx'];
    sctbl=readtable(scanstbl);
    curmax=[];
% Section: for-block starts
    for si=1:length(sesslist)
        conf.descriptions=[];
        funclist=[];
        si_double=si*2;
        h=[];
        maxrows=cellfun(@isempty, sctbl{:,si_double});
        h=find(maxrows);
% Section: if-block starts
        if ~isempty(h)
        curmax(si)= h(1)-1;
% Section: else-block starts
        else
        curmax(si)= size(sctbl,1);
        end
        cursctbl{si}=[sctbl(1:curmax(si), si_double-1) sctbl(1:curmax(si), si_double)];
            mrun_counter=0;
            frun_counter=0;
            lrun_counter=0;
            gfmrun_counter=0;
% Section: for-block starts
        for seqi=1:size(cursctbl{si},1)
            dtype="";
            mL="";
            scC="";
            scF="";
            cL="";
            disp(seqi)
            curseq= cursctbl{si}{seqi,2};
            curseqidx=cursctbl{si}{seqi,1}{1};
            curseqidxnum=str2num(curseqidx);
            zerfill=getzerosnum(curseqidxnum);
            numstr=['0' curseqidx];
% Section: switch-block starts
            switch curseq{1}
% Section: case-block starts
                case taskname
                    funclist=[funclist seqi-1];
                    frun_counter=frun_counter+1;
                    zerfill=getzerosnum(frun_counter);
                    frun_c_str=[zerfill num2str(frun_counter)];
                    dtype="func";
                    mL="bold";
                    scC=string(taskname);
                    scF=[numstr '*' ];
                    cL=['task-' taskname '_run-' frun_c_str];
% Section: case-block starts
                case 'gfm'
                    gfmrun_counter=gfmrun_counter+1;
% Section: if-block starts
                    if gfmrun_counter==1
                       mL="magnitude";
% Section: elseif-block starts
                    elseif gfmrun_counter==2
                       mL="phasediff";
                    end
                    dtype="fmap";
                    scF=[numstr '*'];
                    scC="";
                    cL='';
% Section: case-block starts
                case 't1w'
                    dtype="anat";
                    mL="T1w"; 
                    scF=[numstr '*'];
                    scC="";
            end
% Section: if-block starts
            if contains(dtype,'fmap')
                conf.descriptions(seqi).IntendedFor=funclist;
            end
            conf.descriptions(seqi).dataType=dtype;
            conf.descriptions(seqi).modalityLabel=mL;
            conf.descriptions(seqi).customLabels=cL;
            conf.descriptions(seqi).criteria.SidecarFilename=scF;
% Section: if-block starts
            if ~isempty(scC)
            conf.descriptions(seqi).sidecarChanges.TaskName=scC;
            end
        end
        confjson=jsonencode(conf);
        cursessfolder=[cursubfolder filesep sesslist{si}];
        curjsonfname=[cursessfolder filesep 'BIDS_configuration.json'];
        delete(curjsonfname)
        fid=fopen(curjsonfname,'a');
        fwrite(fid,confjson)
        fclose(fid)
    end
    
    
end
end
% Function signature detected
function [zerfill, zerlen]=getzerosnum(curseqidxnum)
zerfill='';
zerlen=0;
% Section: if-block starts
if curseqidxnum < 10
zerfill='0';
zerlen=1;
end
end