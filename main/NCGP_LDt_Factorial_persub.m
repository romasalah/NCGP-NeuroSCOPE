% One paired SPM Flexible Factorial model with C1 and C2 for every subject.
% Subject order is identical in both condition blocks: C1(1:n), C2(1:n).
function [spmmat,blocksFile] = NCGP_LDt_Factorial_persub(wf,C1_files,C2_files,maskfile,maskname,curhemi)
nsub=numel(wf.origsubs);
scans=[C1_files(:);C2_files(:)];
if numel(scans)~=2*nsub || ~all(cellfun(@isfile,scans))
    error('Expected matching C1 and C2 images for all subjects.');
end

p=NCGP_paths(wf);
outdir=fullfile(p.mp,'derivatives','LDC','group',wf.pre,wf.glm, ...
    ['hemi-' curhemi '_mask-' maskname '_persub_paired']);
if ~isfolder(outdir), mkdir(outdir); end
spmmat=fullfile(outdir,'SPM.mat');
if isfile(spmmat), error('Existing SPM.mat: %s. Clear the paired model folder before rerunning.',spmmat); end

% Exchangeability block i identifies C1_i and C2_i, in that exact order.
blocks=[(1:nsub)';(1:nsub)'];
blocksFile=fullfile(outdir,'exchangeability_blocks_paired.txt');
writematrix(blocks,blocksFile,'Delimiter','tab');

spm('defaults','fmri');
spm_jobman('initcfg');
clear matlabbatch
matlabbatch{1}.spm.stats.factorial_design.dir={outdir};
fblock=struct();
fblock.fac(1)=struct('name','subject','dept',0,'variance',0,'gmsca',0,'ancova',0);
fblock.fac(2)=struct('name','Condition','dept',1,'variance',1,'gmsca',0,'ancova',0);
fblock.fsuball.specall.scans=scans;
fblock.fsuball.specall.imatrix=[ones(2*nsub,1),blocks,[ones(nsub,1);2*ones(nsub,1)]];
fblock.maininters{1}.fmain.fnum=1;
fblock.maininters{2}.fmain.fnum=2;
matlabbatch{1}.spm.stats.factorial_design.des.fblock=fblock;
matlabbatch{1}.spm.stats.factorial_design.cov=struct('c',{},'cname',{},'iCFI',{},'iCC',{});
matlabbatch{1}.spm.stats.factorial_design.multi_cov=struct('files',{},'iCFI',{},'iCC',{});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none=1;
matlabbatch{1}.spm.stats.factorial_design.masking.im=0;
matlabbatch{1}.spm.stats.factorial_design.masking.em={maskfile};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit=1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no=1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm=1;
spm_jobman('run',matlabbatch);

S=load(spmmat,'SPM');
X=S.SPM.xX.X; iH=S.SPM.xX.iH; iB=S.SPM.xX.iB;
if size(X,1)~=2*nsub || numel(iH)~=2 || numel(iB)~=nsub
    error('Unexpected paired SPM design matrix: inspect SPM.xX.');
end
[~,observedBlocks]=max(X(:,iB),[],2);
if ~isequal(observedBlocks(:),blocks)
    error('SPM design row order differs from exchangeability_blocks_paired.txt.');
end

% Full-rank estimable mean contrasts incorporate the average subject effect.
% This is necessary because SPM's two cell means plus 17 subject effects
% have one redundant (non-identifiable) parameter.
c1=zeros(1,size(X,2)); c1(iH(1))=1; c1(iB)=1/nsub;
c2=zeros(1,size(X,2)); c2(iH(2))=1; c2(iB)=1/nsub;
cdiff=zeros(1,size(X,2)); cdiff(iH)=[1 -1];
if max(abs([c1;c2;cdiff]-[c1;c2;cdiff]*pinv(X)*X),[],'all')>1e-7
    error('SPM contrasts are not estimable.');
end

clear matlabbatch
matlabbatch{1}.spm.stats.fmri_est.spmmat={spmmat};
matlabbatch{1}.spm.stats.fmri_est.write_residuals=0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical=1;
spm_jobman('run',matlabbatch);

clear matlabbatch
matlabbatch{1}.spm.stats.con.spmmat={spmmat};
names={'C1_positive','C2_positive','C1_minus_C2'};
weights={c1,c2,cdiff};
for i=1:3
    matlabbatch{1}.spm.stats.con.consess{i}.tcon.name=names{i};
    matlabbatch{1}.spm.stats.con.consess{i}.tcon.weights=weights{i};
    matlabbatch{1}.spm.stats.con.consess{i}.tcon.sessrep='none';
end
matlabbatch{1}.spm.stats.con.delete=1;
spm_jobman('run',matlabbatch);
fprintf('Estimated combined C1/C2 model for %d participants (%s).\n',nsub,curhemi);
end
