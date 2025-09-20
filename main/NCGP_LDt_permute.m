% Overall goal: Hypothesis 3: Creates a null distribution of Linear Discriminant
% t-values. It calculates the correlation between bevaioural RDM and the permuted
% searchlights for each permutation.
function [corr_sesshemi, pval_sesshemi]=NCGP_LDt_permute(wf, brainRDMscell,oldds, targetRDM, corrmethod, hTail, alpha)
targetRDM_full= targetRDM + targetRDM';
% Toolbox call → cosmo_squareform
targetRDMvec=cosmo_squareform(targetRDM_full);
% Section: for-block starts
for hi =1:length(wf.hemis)
% Section: for-block starts
    for si = 1:length(wf.sessions)
        curRDMs= brainRDMscell{si,hi};
        curds=oldds{si,hi};
        slnum=size(curRDMs,1);
        nperm=1000;
        permutations2=zeros(nperm,slnum);
        % Generate permutations
% Section: for-block starts
        for i = 1:nperm
            permutations2(i, :) = randperm(slnum);
        end
        curcoefs=cell(slnum,nperm);
        curpvals=cell(slnum,nperm);
        h=parfor_progressbar(nperm,'Generating null distribution of correlation values');
% Section: parfor-block starts
        parfor (pi=1:nperm,16)
            curperm=permutations2(pi,:)';
            curRDMs_perm=curRDMs(curperm);
% Section: for-block starts
            for mi = 1:slnum
                curboldRDM_ri=curRDMs_perm{mi};
                curboldRDM_full=curboldRDM_ri + curboldRDM_ri';
% Toolbox call → cosmo_squareform
                RDMvec=cosmo_squareform(curboldRDM_full);
                [curcoefs{mi,pi}, curpvals{mi,pi}]=corr(RDMvec', targetRDMvec','type',corrmethod, 'tail', hTail,'rows','complete');
            end
            h.iterate(1);
        end
        close(h);
        corr_sesshemi{si,hi}=curcoefs;
        pval_sesshemi{si,hi}=curpvals;
    end
end
