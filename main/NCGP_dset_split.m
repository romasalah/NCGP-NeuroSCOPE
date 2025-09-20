% Overall goal: Splits a whole-brain NIML dataset into Right and Left
% hemisphere for better visualization of the medial surface.
% File handling is done with surfing toolbox.
function NCGP_dset_split(dsetfolder,dsetprefix)
%Right hemisphere values are always first
dsetlist=dir([dsetfolder filesep dsetprefix '*.dset']);
dsetlist= dsetlist(~contains({dsetlist.name},'_rh'));
dsetlist= dsetlist(~contains({dsetlist.name},'_lh'));
% Toolbox call → surfing_read
surf=surfing_read('/Volumes/EVO8602TB/NCGP/Data/SPMprep/sub-001/T1/ico100_lh.semiinflated_al.asc');
% Section: for-block starts
for i=1:length(dsetlist)
    curdsetfn=[dsetlist(i).folder filesep dsetlist(i).name];
    
% Toolbox call → surfing_read
    curdset=surfing_read(curdsetfn);
    rhfn=strrep(curdsetfn,'.niml.dset','_rh.niml.dset');
    lhfn=strrep(curdsetfn,'.niml.dset','_lh.niml.dset');
    halfpoint=length(curdset.data)/2;
    curdset_rh=curdset;
    curdset_rh.data=curdset.data(1:halfpoint);
    curdset_rh.node_indices=curdset.node_indices(1:halfpoint);
    curdset_lh=curdset;
    curdset_lh.data=curdset.data(halfpoint+1:end);
    curdset_lh.node_indices=curdset.node_indices(1:halfpoint);
% Section: if-block starts
    if isfield(curdset,'misc')
    curdset_rh.misc.PYMVPA_FA_node_indices=  curdset.misc.PYMVPA_FA_node_indices(1:halfpoint);
    curdset_lh.misc.PYMVPA_FA_node_indices=  curdset.misc.PYMVPA_FA_node_indices(1:halfpoint);
    end
% Toolbox call → surfing_write
    surfing_write(rhfn, curdset_rh)
% Toolbox call → surfing_write
    surfing_write(lhfn, curdset_lh)
end
end
