
function [preb_vols,prew_vols,postb_vols,postw_vols] = NCGP_LDt_TFCE_prepostsurf(wf,LDCvals,curhemi,maskname)

paths = NCGP_paths(wf);

% Load surface mesh
sumafolder = 'E:\NCGP2\data\derivatives\fsaverage6\SUMA\';
meshfile = fullfile(sumafolder,[lower(curhemi) 'h.pial.gii']);
mesh = gifti(meshfile);

nvertices = size(mesh.vertices,1);
fprintf('Vertices: %d\n',nvertices);
fprintf('Faces:    %d\n',size(mesh.faces,1));

assert(nvertices == 40962);
assert(size(mesh.vertices,2) == 3);
assert(size(mesh.faces,2) == 3);
assert(all(mesh.faces(:) >= 1 & mesh.faces(:) <= nvertices));

% Output directory
outputfolder = fullfile(paths.mp,'derivatives','LDC','group', ...
    wf.pre,wf.glm,['hemi-' curhemi '_mask-' maskname]);
if ~isfolder(outputfolder)
    mkdir(outputfolder);
end

imgdesc = ['mask-' maskname '_hemi-' curhemi '_'];

% Save all four conditions
preb_vols  = save_metrics(LDCvals.preb, 'preb', outputfolder,imgdesc,meshfile,nvertices);
prew_vols  = save_metrics(LDCvals.prew, 'prew', outputfolder,imgdesc,meshfile,nvertices);
postb_vols = save_metrics(LDCvals.postb,'postb',outputfolder,imgdesc,meshfile,nvertices);
postw_vols = save_metrics(LDCvals.postw,'postw',outputfolder,imgdesc,meshfile,nvertices);

end


function files = save_metrics(data,prefix,outputfolder,imgdesc,meshfile,nvertices)

assert(size(data,1) == nvertices);
files = cell(1,size(data,2));

for i = 1:size(data,2)
    files{i} = fullfile(outputfolder, ...
        [prefix '_' imgdesc sprintf('%02d',i) '.gii']);

    g = gifti;
    g.cdata = data(:,i);
    g.private.metadata(1).name = 'SurfaceID';
    g.private.metadata(1).value = meshfile;

    save(g,files{i},'ExternalFileBinary');
end

end
