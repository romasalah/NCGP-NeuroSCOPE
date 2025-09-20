% ==========================================================================
% Overall goal (user-provided): Overall goal: Retrieves the participant ingroup (AH or NAT) and creates a string of 4 ingroups and 4 outgroups based on the participant group membership.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Retrieves the participant ingroup (AH or NAT) and creates a string of 4 ingroups and 4 outgroups based on the participant group membership.
% Note:
% ==========================================================================
% Function signature detected
function [allingpnames, gpnames,allgpnames, gpnames_inout]=NCGPH_gpname(subs)
gpnames_AH={'AH1','AH2','AH3','AH4','NAT1','NAT2','NAT3','NAT4'};
gpnames_NAT={'NAT1','NAT2','NAT3','NAT4','AH1','AH2','AH3','AH4'};
gpnames_inout=strrep(gpnames_AH,'AH','Ingroup');
gpnames_inout=strrep(gpnames_inout,'NAT','Outgroup');
% Section: for-block starts
for subi=1:length(subs)
    subid=num2str(subs(subi));
    %% Load results
    subfile=[subid 'facesimilarity_post_output.xlsx'];
    opts = detectImportOptions(subfile);
    opts.VariableTypes{3}='char';
    facesimtbl=readtable(subfile,opts);
    facesimtbl=facesimtbl(2:end,:);
    allfacesimtbls{subi}= facesimtbl;
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
