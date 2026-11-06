% Read GIfTI TFCE results and test the conjunction null (Nichols et al. 2005).
% For each vertex BOTH positive one-sided tests must pass FWE correction.
% Nothing needs volume-to-surface conversion in this participant-level path.
function signodes = NCGP_LDt_TFCE_vol2surf_persub( ...
    wf,maskname,curhemi,spmmatC1,spmmatC2,maskfile)
alpha=0.05;
threshold=-log10(alpha);
p1=fileparts(spmmatC1);
p2=fileparts(spmmatC2);

t1file=fullfile(p1,'spmT_0001.gii');
t2file=fullfile(p2,'spmT_0001.gii');
fwe1file=fullfile(p1,'TFCE_log_pFWE_0001.gii');
fwe2file=fullfile(p2,'TFCE_log_pFWE_0001.gii');
filenames={t1file,t2file,fwe1file,fwe2file,maskfile};
assert(all(cellfun(@isfile,filenames)), ...
    'Missing SPM t-map, TFCE-corrected map, or common surface mask.');

g=gifti(t1file); t1=double(g.cdata(:));
g=gifti(t2file); t2=double(g.cdata(:));
g=gifti(fwe1file); logp1=double(g.cdata(:));
g=gifti(fwe2file); logp2=double(g.cdata(:));
g=gifti(maskfile); valid=g.cdata(:)>0;
assert(numel(t1)==numel(valid) && numel(t2)==numel(valid) && ...
    numel(logp1)==numel(valid) && numel(logp2)==numel(valid), ...
    'Surface vertex counts do not match.');
assert(all(isfinite(t1(valid))) && all(isfinite(t2(valid))) && ...
    all(~isnan(logp1(valid))) && all(~isnan(logp2(valid))), ...
    'Nonfinite surface statistics inside the common mask.');

% Modified SPM TFCE maps encode the positive effect as +(-log10(p_FWE)).
sigC1=valid & t1>0 & logp1>threshold;
sigC2=valid & t2>0 & logp2>threshold;
intersection=sigC1 & sigC2;
% min(-log10 p_C1, -log10 p_C2) corresponds to max(p_C1,p_C2)
% for positive tails: the conjunction-null component p-value.
minLogp=min(logp1,logp2);
minLogp(~valid)=0;

paths=NCGP_paths(wf);
outdir=fullfile(paths.mp,'derivatives','LDC','group', ...
    wf.pre,wf.glm,['hemi-' curhemi '_mask-' maskname '_persub_conjunction']);
if ~isfolder(outdir), mkdir(outdir); end
meshfile=fullfile(paths.refsuma,[lower(curhemi) 'h.pial.gii']);
if ~isfile(meshfile)
    meshfile=fullfile(paths.mp,'derivatives',wf.refsub,'SUMA', ...
        [lower(curhemi) 'h.pial.gii']);
end
assert(isfile(meshfile),'Reference surface not found: %s',meshfile);
save_metric(double(sigC1),'C1_sig_FWE.gii');
save_metric(double(sigC2),'C2_sig_FWE.gii');
save_metric(double(intersection),'H2_conjunction_FWE.gii');
save_metric(minLogp,'H2_conjunction_minLogpFWE.gii');

signodes.C1=t1;
signodes.C2=t2;
signodes.C1_logpFWE=logp1;
signodes.C2_logpFWE=logp2;
signodes.C1_sig=sigC1;
signodes.C2_sig=sigC2;
signodes.intersection=intersection;
signodes.conjunction_minLogpFWE=minLogp;
signodes.valid_mask=valid;
% Retain original output names (C2=sessdiff, C1=postcontrast).
signodes.sessdiff=t2;
signodes.postcontrast=t1;
signodes.intwbpc=double(intersection).*t1;
signodes.outputfolder=outdir;
fprintf('H2 conjunction %s: C1 %d, C2 %d, both %d vertices at FWE p<%.2f.\n', ...
    curhemi,nnz(sigC1),nnz(sigC2),nnz(intersection),alpha);

    function save_metric(data,name)
        g=gifti;
        g.cdata=double(data(:));
        g.private.metadata(1).name='SurfaceID';
        g.private.metadata(1).value=meshfile;
        save(g,fullfile(outdir,name),'ExternalFileBinary');
    end
end
