% TFCE for one combined SPM paired model plus valid marginal H2 tests.
% Pair swaps (exchangeability blocks) test C1-C2, NOT C1>0 or C2>0.
% C1>0 and C2>0 use subject-wise sign flips of their own 17 maps.
function NCGP_LDt_TFCE_estimate_persub(wf,spmmat,maskfile,blocksFile,C1_files,C2_files,curhemi)
nsub=numel(wf.origsubs);
blocks=readmatrix(blocksFile);
if ~isequal(blocks(:),[(1:nsub)';(1:nsub)'])
    error('Exchangeability blocks must match C1 then C2 participant order.');
end

% Exploratory paired difference: swap C1_i/C2_i within each subject.
spm('defaults','fmri');
spm_jobman('initcfg');
clear matlabbatch
matlabbatch{1}.spm.tools.tfce_estimate.data={spmmat};
matlabbatch{1}.spm.tools.tfce_estimate.nproc=20;
matlabbatch{1}.spm.tools.tfce_estimate.mask={''};
matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr='';
matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts=3;
matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm=10000;
matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method=0;
matlabbatch{1}.spm.tools.tfce_estimate.tbss=0;
matlabbatch{1}.spm.tools.tfce_estimate.exch_blocks={blocksFile};
matlabbatch{1}.spm.tools.tfce_estimate.singlrthreaded=0;
spm_jobman('run',matlabbatch);

% The Nichols conjunction is built from two marginal, valid null tests.
p=NCGP_paths(wf);
meshfile=fullfile(p.refsuma,[lower(curhemi) 'h.pial.gii']);
if ~isfile(meshfile)
    meshfile=fullfile(p.mp,'derivatives',wf.refsub,'SUMA',[lower(curhemi) 'h.pial.gii']);
end
mesh=gifti(meshfile);
g=gifti(maskfile); valid=logical(g.cdata(:));
outdir=fileparts(spmmat);
maps={C1_files,C2_files};
names={'C1','C2'};
for ci=1:2
    signflip_tfce(maps{ci},valid,mesh.faces,outdir,names{ci},meshfile,10000,20261106+ci);
end
end

function signflip_tfce(files,valid,faces,outdir,name,meshfile,nperm,seed)
nsub=numel(files);
nvertices=numel(valid);
Y=zeros(nvertices,nsub);
for subi=1:nsub
    g=gifti(files{subi});
    Y(:,subi)=double(g.cdata(:));
end
Y(~valid,:)=0;
obsSum=sum(Y,2);
sumSquares=sum(Y.^2,2);
denom=(sumSquares-obsSum.^2/nsub)/(nsub*(nsub-1));
tmap=zeros(nvertices,1);
tmap(valid)=(obsSum(valid)/nsub)./sqrt(max(denom(valid),realmin));

% Use the same surface TFCE kernel as the modified SPM toolbox.
tmap(~isfinite(tmap))=0;
tfce=double(tfceMex_maxtree(tmap,1,2,0,double(faces)));
tfce=max(tfce,0);
tfce(~valid)=0;
nullMax=zeros(nperm,1);

% Compute sign-flip t statistics efficiently from invariant sum of squares.
oldstate=rng;
restoreRng=onCleanup(@()rng(oldstate));
rng(seed,'twister');
signs=2*(rand(nsub,nperm)>0.5)-1;
batchSize=20;
for k=1:batchSize:nperm
    idx=k:min(k+batchSize-1,nperm);
    sm=Y*signs(:,idx);
    variance=(sumSquares-sm.^2/nsub)/(nsub*(nsub-1));
    permT=(sm/nsub)./sqrt(max(variance,realmin));
    permT(~valid,:)=0;
    permTFCE=tfceMex_maxtree_batch(double(permT),1,2,0,double(faces),20);
    nullMax(idx)=max(permTFCE(valid,:),[],1);
end
clear restoreRng

% Maximum-statistic FWE p across the whole hemisphere surface.
logp=zeros(nvertices,1);
active=find(valid & tmap>0);
for k=1:500:numel(active)
    idx=active(k:min(k+499,numel(active)));
    exceed=sum(nullMax>=tfce(idx)',1);
    logp(idx)=-log10((1+exceed(:))/(nperm+1));
end

writeMetric(tmap,fullfile(outdir,[name '_T_signflip.gii']),meshfile);
writeMetric(logp,fullfile(outdir,[name '_TFCE_log_pFWE.gii']),meshfile);
fprintf('%s: %d participant sign flips, %d valid vertices, %d permutations.\n', ...
    name,nsub,nnz(valid),nperm);
end

function writeMetric(data,filename,meshfile)
g=gifti;
g.cdata=double(data(:));
g.private.metadata(1).name='SurfaceID';
g.private.metadata(1).value=meshfile;
save(g,filename,'ExternalFileBinary');
end
