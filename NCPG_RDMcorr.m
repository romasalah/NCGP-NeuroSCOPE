% ==========================================================================
% Overall goal: Compute correlations between behavioral RDMs (physical/personality/social) and neural LDt per searchlight.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [coefs, pvals, sigidx, sigidx_coefs]=NCPG_RDMcorr(wf, RDMS_subsesshemi, targetRDM, corrmethod, hTail, alpha)
targetRDM_full= targetRDM + targetRDM';
% Toolbox call → cosmo_squareform
targetRDMvec=cosmo_squareform(targetRDM_full);
% Call → NCPG_paths: Project function call
p=NCPG_paths(wf);
% Section: for-block starts
for si =1:length(wf.sessions)
% Section: for-block starts
    for hi = 1:length(wf.hemis)
        %ldt_fn{si}=[p.mp filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'LDtbyrun_sub-group_' wf.sessions{si} '_hemi-' wf.hemis{hi}  '_mask-' masknone '.mat'];
        %ldtmat=matfile(ldt_fn{si});
        %RDMS_subsesshemi=ldtmat.ldt_cv_avg;
        curRDM=RDMS_subsesshemi{si,hi};
% Section: for-block starts
        for mi = 1:size(curRDM,1)
            curboldRDM_ri=curRDM{mi};
            curboldRDM_full=curboldRDM_ri + curboldRDM_ri';
% Toolbox call → cosmo_squareform
            RDMvec=cosmo_squareform(curboldRDM_full);
            [curcoefs(mi,hi), curpvals(mi,hi)]=corr(RDMvec', targetRDMvec','type',corrmethod, 'tail', hTail,'rows','complete');
        end
        cursigidx=curpvals(:,hi)<alpha;
        coefs{si}(:,hi)=curcoefs;
        pvals{si}(:,hi)=curpvals;
        sigidx{si}(:,hi)=cursigidx;
        curcoefs(~cursigidx)=0;
        sigidx_coefs{si}(:,hi)=curcoefs;
    end
end
end