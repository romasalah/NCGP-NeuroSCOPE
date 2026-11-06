% Second-level one-sample GLM on independent participant-contrast maps.
% Retains the source function name with _persub for the H2 duplicate tree.
function spmmat = NCGP_LDt_Factorial_persub( ...
    wf,subjectImages,maskfile,maskname,curhemi,conname)
assert(ismember(conname,{'C1','C2'}),'Expected C1 or C2.');
assert(iscell(subjectImages) && numel(subjectImages)==numel(wf.origsubs) && ...
    numel(subjectImages)>1,'Expected one map per participant.');
assert(all(cellfun(@isfile,subjectImages)), ...
    'Some participant contrast GIfTI images are missing.');
assert(isfile(maskfile),'Missing explicit shared surface mask.');

p=NCGP_paths(wf);
outdir=fullfile(p.mp,'derivatives','LDC','group',wf.pre,wf.glm, ...
    ['hemi-' curhemi '_mask-' maskname '_persub_' conname]);
if ~isfolder(outdir), mkdir(outdir); end
spmmat=fullfile(outdir,'SPM.mat');
assert(~isfile(spmmat), ...
    'SPM model already exists at %s. Clear this H2 model directory to rerun.', ...
    spmmat);
spm('defaults','fmri');
spm_jobman('initcfg');

% Build the design first. Input image order equals wf.origsubs.
clear matlabbatch
matlabbatch{1}.spm.stats.factorial_design.dir={outdir};
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans=subjectImages(:);
matlabbatch{1}.spm.stats.factorial_design.cov= ...
    struct('c',{},'cname',{},'iCFI',{},'iCC',{});
matlabbatch{1}.spm.stats.factorial_design.multi_cov= ...
    struct('files',{},'iCFI',{},'iCC',{});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none=1;
matlabbatch{1}.spm.stats.factorial_design.masking.im=0;
matlabbatch{1}.spm.stats.factorial_design.masking.em={maskfile};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit=1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no=1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm=1;
save(fullfile(outdir,'design_batch_persub.mat'),'matlabbatch');
spm_jobman('run',matlabbatch);

clear matlabbatch
matlabbatch{1}.spm.stats.fmri_est.spmmat={spmmat};
matlabbatch{1}.spm.stats.fmri_est.write_residuals=0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical=1;
spm_jobman('run',matlabbatch);

clear matlabbatch
matlabbatch{1}.spm.stats.con.spmmat={spmmat};
matlabbatch{1}.spm.stats.con.consess{1}.tcon.name=[conname '_positive'];
matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights=1;
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep='none';
matlabbatch{1}.spm.stats.con.delete=1;
spm_jobman('run',matlabbatch);

S=load(spmmat,'SPM');
assert(size(S.SPM.xX.X,1)==numel(subjectImages) && ...
    size(S.SPM.xX.X,2)==1, ...
    'Unexpected second-level design; check participant independence.');
fprintf('Estimated H2 %s one-sample model: %d participants (%s).\n', ...
    conname,numel(subjectImages),curhemi);
end
