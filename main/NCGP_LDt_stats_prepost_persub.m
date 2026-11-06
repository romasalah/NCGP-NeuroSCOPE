% Participant-specific H2, retaining subject as the random-effects unit.
% C1 = PostB - PostW; C2 = (PostB - PostW) - (PreB - PreW).
function [statresults,signodes_surf] = NCGP_LDt_stats_prepost_persub(wf,maskname,ldt_avgruns)
assert(numel(wf.sessions)==2 && strcmp(wf.sessions{1},'ses-02') && ...
    strcmp(wf.sessions{2},'ses-03'), ...
    'H2 requires ses-02 (pre) followed by ses-03 (post).');
assert(isfield(wf,'origsubs') && ~isempty(wf.origsubs), ...
    'Missing wf.origsubs participant IDs.');
nsub=numel(wf.origsubs);
assert(size(ldt_avgruns,1)==2 && ...
    size(ldt_avgruns,2)==numel(wf.hemis) && ...
    size(ldt_avgruns,3)==nsub, ...
    'Expected input {session, hemisphere, participant}.');

% Eight identities: first four AH and last four NAT.
[r,c]=find(triu(true(8),1));
between=r<=4 & c>=5;
idxB=sub2ind([8 8],r(between),c(between));
idxW=sub2ind([8 8],r(~between),c(~between));
assert(numel(idxB)==16 && numel(idxW)==12);

statresults=cell(1,numel(wf.hemis));
signodes_surf=cell(1,numel(wf.hemis));
fields={'PreB','PreW','PostB','PostW','C1','C2'};
for hi=1:numel(wf.hemis)
    nroi=numel(ldt_avgruns{1,hi,1});
    assert(nroi>0,'No searchlights for hemisphere %s.',wf.hemis{hi});
    for fi=1:numel(fields)
        statresults{hi}.(fields{fi})=NaN(nroi,nsub);
    end
    for subi=1:nsub
        pre=ldt_avgruns{1,hi,subi};
        post=ldt_avgruns{2,hi,subi};
        assert(numel(pre)==nroi && numel(post)==nroi, ...
            'Searchlight count differs for participant %s, hemisphere %s.', ...
            wf.origsubs{subi},wf.hemis{hi});
        for vi=1:nroi
            a=pre{vi};
            b=post{vi};
            if isempty(a) || isempty(b)
                continue
            end
            assert(isequal(size(a),[8 8]) && isequal(size(b),[8 8]), ...
                'Expected 8x8 LDC matrices at searchlight %d.',vi);
            pairs=[a(idxB);a(idxW);b(idxB);b(idxW)];
            if ~all(isfinite(pairs))
                continue
            end
            PreB=mean(a(idxB));
            PreW=mean(a(idxW));
            PostB=mean(b(idxB));
            PostW=mean(b(idxW));
            statresults{hi}.PreB(vi,subi)=PreB;
            statresults{hi}.PreW(vi,subi)=PreW;
            statresults{hi}.PostB(vi,subi)=PostB;
            statresults{hi}.PostW(vi,subi)=PostW;
            statresults{hi}.C1(vi,subi)=PostB-PostW;
            statresults{hi}.C2(vi,subi)=(PostB-PostW)-(PreB-PreW);
        end
    end
    % Restrict BOTH tests to identical vertices across ALL participants.
    common=true(nroi,1);
    for fi=1:numel(fields)
        common=common & all(isfinite(statresults{hi}.(fields{fi})),2);
    end
    assert(any(common),'No common valid searchlights in %s.',wf.hemis{hi});
    statresults{hi}.valid_mask=common;
    statresults{hi}.subjects=wf.origsubs(:);
    fprintf('H2 %s: %d/%d vertices valid across %d participants.\n', ...
        wf.hemis{hi},nnz(common),nroi,nsub);
    signodes_surf{hi}=NCGP_LDt_TFCE_prepost_persub( ...
        wf,statresults{hi},[],wf.hemis{hi},maskname);
end
end
