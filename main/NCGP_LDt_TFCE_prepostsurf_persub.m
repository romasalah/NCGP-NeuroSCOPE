% Export one C1 and one C2 GIfTI map per participant, using a common mask.
function [C1_files,C2_files,maskfile] = NCGP_LDt_TFCE_prepostsurf_persub( ...
    wf,LDCvals,curhemi,maskname)
p=NCGP_paths(wf);
meshfile=fullfile(p.refsuma,[lower(curhemi) 'h.pial.gii']);
assert(isfile(meshfile),'Reference GIfTI mesh not found: %s.',meshfile);
mesh=gifti(meshfile);
nvertices=size(mesh.vertices,1);
assert(nvertices==40962 && size(mesh.vertices,2)==3 && ...
    size(mesh.faces,2)==3,'Unexpected fsaverage6 surface geometry.');
nsub=numel(wf.origsubs);
assert(isequal(size(LDCvals.C1),[nvertices nsub]) && ...
    isequal(size(LDCvals.C2),[nvertices nsub]), ...
    'Expected identical vertex order: %d x %d (vertices x subjects).', ...
    nvertices,nsub);
valid=logical(LDCvals.valid_mask(:));
assert(numel(valid)==nvertices && any(valid),'Invalid common vertex mask.');
assert(all(isfinite(LDCvals.C1(valid,:)),'all') && ...
    all(isfinite(LDCvals.C2(valid,:)),'all'), ...
    'Nonfinite contrast values inside the common vertex mask.');

outdir=fullfile(p.mp,'derivatives','LDC','group',wf.pre,wf.glm, ...
    ['hemi-' curhemi '_mask-' maskname '_persub']);
if ~isfolder(outdir), mkdir(outdir); end

maskfile=fullfile(outdir,['valid_vertices_hemi-' curhemi '.gii']);
save_metric(double(valid),maskfile,meshfile);
C1_files=cell(nsub,1);
C2_files=cell(nsub,1);
for subi=1:nsub
    subject=char(wf.origsubs{subi});
    C1_files{subi}=fullfile(outdir,[subject '_C1_hemi-' curhemi '.gii']);
    C2_files{subi}=fullfile(outdir,[subject '_C2_hemi-' curhemi '.gii']);
    c1=LDCvals.C1(:,subi);
    c2=LDCvals.C2(:,subi);
    % These zeros are only OUTSIDE the explicit SPM mask.
    c1(~valid)=0;
    c2(~valid)=0;
    save_metric(c1,C1_files{subi},meshfile);
    save_metric(c2,C2_files{subi},meshfile);
end
fprintf('Saved %d C1 + %d C2 surface maps, %d valid vertices.\n', ...
    nsub,nsub,nnz(valid));
end

function save_metric(data,filename,meshfile)
g=gifti;
g.cdata=double(data(:));
g.private.metadata(1).name='SurfaceID';
g.private.metadata(1).value=meshfile;
save(g,filename,'ExternalFileBinary');
end
