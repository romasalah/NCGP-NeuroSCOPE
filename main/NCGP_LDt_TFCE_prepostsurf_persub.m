% Export paired C1/C2 GIfTI images with identical participant ordering.
function [C1_files,C2_files,maskfile] = NCGP_LDt_TFCE_prepostsurf_persub(wf,LDCvals,curhemi,maskname)
p=NCGP_paths(wf);
meshfile=fullfile(p.refsuma,[lower(curhemi) 'h.pial.gii']);
if ~isfile(meshfile)
    meshfile=fullfile(p.mp,'derivatives',wf.refsub,'SUMA',[lower(curhemi) 'h.pial.gii']);
end
mesh=gifti(meshfile);
nvertices=size(mesh.vertices,1);
nsub=numel(wf.origsubs);
if ~isequal(size(LDCvals.C1),[nvertices,nsub]) || ~isequal(size(LDCvals.C2),[nvertices,nsub])
    error('Contrasts must be [vertices x participants] in reference mesh order.');
end
valid=logical(LDCvals.valid_mask(:));

outdir=fullfile(p.mp,'derivatives','LDC','group',wf.pre,wf.glm, ...
    ['hemi-' curhemi '_mask-' maskname '_persub']);
if ~isfolder(outdir), mkdir(outdir); end
maskfile=fullfile(outdir,['valid_vertices_hemi-' curhemi '.gii']);
writeMetric(double(valid),maskfile,meshfile);

C1_files=cell(nsub,1); C2_files=cell(nsub,1);
for subi=1:nsub
    subject=char(wf.origsubs{subi});
    C1_files{subi}=fullfile(outdir,[subject '_C1_hemi-' curhemi '.gii']);
    C2_files{subi}=fullfile(outdir,[subject '_C2_hemi-' curhemi '.gii']);
    c1=LDCvals.C1(:,subi); c2=LDCvals.C2(:,subi);
    c1(~valid)=0; c2(~valid)=0;
    writeMetric(c1,C1_files{subi},meshfile);
    writeMetric(c2,C2_files{subi},meshfile);
end
fprintf('Saved %d paired C1/C2 maps in %s.\n',nsub,outdir);
end

function writeMetric(data,filename,meshfile)
g=gifti;
g.cdata=double(data(:));
g.private.metadata(1).name='SurfaceID';
g.private.metadata(1).value=meshfile;
save(g,filename,'ExternalFileBinary');
end
