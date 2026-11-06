% Calculate subject-specific H2 condition means and contrast maps.
function [statresults,signodes_surf] = NCGP_LDt_stats_prepost_persub(wf,maskname,ldt_avgruns)
if ~isequal(wf.sessions,{'ses-02','ses-03'})
    error('H2 requires ses-02 (pre), ses-03 (post), in that order.');
end
nsub=numel(wf.origsubs);
[r,c]=find(triu(true(8),1));
between=r<=4 & c>=5;
idxB=sub2ind([8,8],r(between),c(between));
idxW=sub2ind([8,8],r(~between),c(~between));

fields={'PreB','PreW','PostB','PostW','C1','C2'};
statresults=cell(1,numel(wf.hemis));
signodes_surf=cell(1,numel(wf.hemis));
for hi=1:numel(wf.hemis)
    statresults{hi}=struct();
    nroi=numel(ldt_avgruns{1,hi,1});
    for k=1:numel(fields)
        statresults{hi}.(fields{k})=NaN(nroi,nsub);
    end
    for subi=1:nsub
        pre=ldt_avgruns{1,hi,subi};
        post=ldt_avgruns{2,hi,subi};
        if numel(pre)~=nroi || numel(post)~=nroi
            error('Searchlight order/count mismatch in %s.',wf.origsubs{subi});
        end
        for vi=1:nroi
            a=pre{vi}; b=post{vi};
            if isempty(a) || isempty(b), continue; end
            pairs=[a(idxB);a(idxW);b(idxB);b(idxW)];
            if any(~isfinite(pairs)), continue; end

            PreB=mean(a(idxB)); PreW=mean(a(idxW));
            PostB=mean(b(idxB)); PostW=mean(b(idxW));
            statresults{hi}.PreB(vi,subi)=PreB;
            statresults{hi}.PreW(vi,subi)=PreW;
            statresults{hi}.PostB(vi,subi)=PostB;
            statresults{hi}.PostW(vi,subi)=PostW;
            statresults{hi}.C1(vi,subi)=PostB-PostW;
            statresults{hi}.C2(vi,subi)=(PostB-PostW)-(PreB-PreW);
        end
    end

    % Use exactly the same estimable cortical vertices for both tests.
    c1=statresults{hi}.C1; c2=statresults{hi}.C2;
    valid=all(isfinite(c1) & isfinite(c2),2) & var(c1,0,2)>0 & var(c2,0,2)>0;
    if ~any(valid), error('No valid group-level vertices in hemisphere %s.',wf.hemis{hi}); end
    statresults{hi}.valid_mask=valid;
    statresults{hi}.subjects=wf.origsubs(:);
    fprintf('H2 %s: %d/%d vertices across %d subjects.\n',wf.hemis{hi},nnz(valid),nroi,nsub);
    signodes_surf{hi}=NCGP_LDt_TFCE_prepost_persub(wf,statresults{hi},[],wf.hemis{hi},maskname);
end
end
