% ==========================================================================
% Overall goal (user-provided): Overall goal: % splits the neighborhood in multiple smaller neighborhoods that can
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: % splits the neighborhood in multiple smaller neighborhoods that can 
% used in parallel
% Note:
% ==========================================================================
% Function signature detected
function nbrhood_cell=split_nbrhood_for_workers(nbrhood,center_ids,nproc)

    ncenters=numel(center_ids);

    block_size=ceil(ncenters/nproc);
    nproc_used=ceil(ncenters/block_size);
    nbrhood_cell=cell(nproc_used,1);

    first=1;
% Section: for-block starts
    for block=1:nproc_used
        last=min(first+block_size-1,ncenters);
        block_idxs=first:last;

        block_center_ids=center_ids(block_idxs);

        block_nbrhood=struct();
        block_nbrhood.neighbors=nbrhood.neighbors(block_center_ids);
        block_nbrhood.a=nbrhood.a;
% Toolbox call → cosmo_slice
        block_nbrhood.fa=cosmo_slice(nbrhood.fa,block_center_ids,2,...
                                                            'struct');
        block_nbrhood.fa.center_ids=block_center_ids(:)';

        nbrhood_cell{block}=block_nbrhood;

        first=last+1;
    end
