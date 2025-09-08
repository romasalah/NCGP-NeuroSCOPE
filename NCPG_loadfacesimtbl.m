% ==========================================================================
% Overall goal (user-provided): Overall goal: Loads data from the pre- and post-intervention behavioral similarity ratings.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Loads data from the pre- and post-intervention behavioral similarity ratings.
% Note:
% ==========================================================================
% Function signature detected
function [allfacesimtbls, allgpnames, allingpnames]=NCPG_loadfacesimtbl(wf, datatime)
gpnames_AH={'AH1','AH2','AH3','AH4','NAT1','NAT2','NAT3','NAT4'};
gpnames_NAT={'NAT1','NAT2','NAT3','NAT4','AH1','AH2','AH3','AH4'};
gpnames_inout=strrep(gpnames_AH,'AH','Ingroup');
gpnames_inout=strrep(gpnames_inout,'NAT','Outgroup');
% Section: switch-block starts
switch datatime
% Section: case-block starts
    case 'pre'
        timestr='pre_';
        cursess='ses-02';
% Section: case-block starts
    case 'post'
        timestr='post_';
        cursess='ses-03';
end
subs=wf.subs;
subs_num=wf.subs_num;
% Section: for-block starts
for subi=1:length(subs)
    subid=num2str(subs_num(subi));
% Section: switch-block starts
    switch wf.exp
% Section: case-block starts
        case 'NCGP'
            behavfolder= [wf.mainpath filesep wf.pre filesep subs{subi} filesep cursess filesep 'behav' filesep];
        case 'BehavNCGP'
            behavfolder= [wf.mainpath filesep];
    end
    %% Load results
    subfile=[behavfolder subid 'facesimilarity_' timestr 'output.xlsx'];
    opts = detectImportOptions(subfile);
    opts.VariableTypes{3}='char';
    facesimtbl=readtable(subfile,opts);
    facesimtbl=facesimtbl(2:end,:);
    allfacesimtbls{subi,1}= facesimtbl;
    allfacesimtbls{subi,2}= subid;
    %% Arrange ingp and outgp names according to participant group
    ingpname=facesimtbl{1,3};
    ingpname=ingpname{1};
    allingpnames{subi}=ingpname;
% Section: if-block starts
    if strcmpi(ingpname,'AH')
        gpnames=gpnames_AH;
% Section: elseif-block starts
    elseif strcmpi(ingpname,'NAT')
        gpnames=gpnames_NAT;
    end
    allgpnames{subi}=gpnames;
end
end
