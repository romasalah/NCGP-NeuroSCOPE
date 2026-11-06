% Nichols et al. (2005) conjunction null: both positive components pass.
% Read marginal TFCE maps computed using sign flips of independent subjects.
function signodes = NCGP_LDt_TFCE_vol2surf_persub(wf,maskname,curhemi,spmmat,maskfile)
p=fileparts(spmmat);
g=gifti(fullfile(p,'C1_T_signflip.gii')); t1=double(g.cdata(:));
g=gifti(fullfile(p,'C2_T_signflip.gii')); t2=double(g.cdata(:));
g=gifti(fullfile(p,'C1_TFCE_log_pFWE.gii')); logp1=double(g.cdata(:));
g=gifti(fullfile(p,'C2_TFCE_log_pFWE.gii')); logp2=double(g.cdata(:));
g=gifti(maskfile); valid=g.cdata(:)>0;

% Each p-value is FWE-corrected across surface vertices.
alpha=0.05;
sigC1=valid & t1>0 & logp1>-log10(alpha);
sigC2=valid & t2>0 & logp2>-log10(alpha);
intersection=sigC1 & sigC2;
minLogp=min(logp1,logp2);
minLogp(~valid)=0;

paths=NCGP_paths(wf);
outdir=fullfile(paths.mp,'derivatives','LDC','group',wf.pre,wf.glm, ...
    ['hemi-' curhemi '_mask-' maskname '_persub_conjunction']);
if ~isfolder(outdir), mkdir(outdir); end
meshfile=fullfile(paths.refsuma,[lower(curhemi) 'h.pial.gii']);
if ~isfile(meshfile)
    meshfile=fullfile(paths.mp,'derivatives',wf.refsub,'SUMA',[lower(curhemi) 'h.pial.gii']);
end

writeMetric(double(sigC1),'C1_sig_FWE.gii');
writeMetric(double(sigC2),'C2_sig_FWE.gii');
writeMetric(double(intersection),'H2_conjunction_FWE.gii');
writeMetric(minLogp,'H2_conjunction_minLogpFWE.gii');

signodes.C1=t1;
signodes.C2=t2;
signodes.C1_logpFWE=logp1;
signodes.C2_logpFWE=logp2;
signodes.C1_sig=sigC1;
signodes.C2_sig=sigC2;
signodes.intersection=intersection;
signodes.conjunction_minLogpFWE=minLogp;
signodes.valid_mask=valid;
signodes.sessdiff=t2;
signodes.postcontrast=t1;
signodes.intwbpc=double(intersection).*t1;
signodes.outputfolder=outdir;
fprintf('H2 conjunction %s: C1=%d, C2=%d, both=%d vertices (FWE p<%.2f).\n', ...
    curhemi,nnz(sigC1),nnz(sigC2),nnz(intersection),alpha);

    function writeMetric(data,name)
        g=gifti;
        g.cdata=double(data(:));
        g.private.metadata(1).name='SurfaceID';
        g.private.metadata(1).value=meshfile;
        save(g,fullfile(outdir,name),'ExternalFileBinary');
    end
end
