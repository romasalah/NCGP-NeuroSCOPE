% ==========================================================================
% Overall goal (user-provided): Overall goal: Converts hypothesis 2 results from surface-based NIML datasets to volumetric images.
% ==========================================================================
function [preb_vols,prew_vols,postb_vols,postw_vols]=NCGP_LDt_TFCE_prepostsurf(wf, LDCvals,oldds,curhemi,maskname)
% Call → NCGP_paths
paths=NCGP_paths(wf);
sumafolder='D:\Omar\NCGP\data\derivatives\fsaverage6\SUMA\';
meshfile = fullfile(sumafolder,[lower(curhemi) 'h.pial.gii']);
mesh = gifti(meshfile);
fprintf('Vertices: %d\n',size(mesh.vertices,1));
fprintf('Faces:    %d\n',size(mesh.faces,1));
assert(size(mesh.vertices,1)==40962);
assert(size(mesh.vertices,2)==3);
assert(size(mesh.faces,2)==3);
assert(min(mesh.faces(:))>=1);
assert(max(mesh.faces(:))<=40962);

outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
mkdir(outputfolder);
imgdesc=['mask-' maskname '_hemi-' curhemi '_'];
%% limit t-vals to the mask
curpreb=LDCvals.preb;
curprew=LDCvals.prew;
curpostb=LDCvals.postb;
curpostw=LDCvals.postw;
% Section: for-block starts
for prebi=1:size(curpreb,2)
    curimg_name=['preb_' imgdesc sprintf('%02d',prebi)];
    cur_data=curpreb(:,prebi);
    assert(size(cur_data,1) == 40962);
    g = gifti;
    g.cdata = cur_data;
    g.private.metadata(1).name = 'SurfaceID';
    g.private.metadata(1).value = meshfile;
     preb_vols{prebi} = fullfile(outputfolder, ...
       [curimg_name '.gii']);
    save(g,preb_vols{prebi},'ExternalFileBinary');
    metricfile = preb_vols{prebi};
    g = gifti(metricfile);
    size(g.cdata)
end
% Section: for-block starts
for prewi=1:size(curprew,2)
    curimg_name=['prew_' imgdesc sprintf('%02d',prewi)];
% Section: switch-block starts
    cur_data=curprew(:,prewi);
    assert(size(cur_data,1) == 40962);
    g = gifti;
    g.cdata = cur_data;
    g.private.metadata(1).name = 'SurfaceID';
    g.private.metadata(1).value = meshfile;
    prew_vols{prewi} = fullfile(outputfolder, ...
        [curimg_name '.gii']);
    save(g,prew_vols{prewi},'ExternalFileBinary');
    metricfile = prew_vols{prewi};
    g = gifti(metricfile);
    size(g.cdata)
end
% Section: for-block starts
for postbi=1:size(curpostb,2)
% Section: switch-block starts
    curimg_name=['postb_' imgdesc sprintf('%02d',postbi)];
    cur_data=curpostb(:,postbi);
    assert(size(cur_data,1) == 40962);
    g = gifti;
    g.cdata = cur_data;
    g.private.metadata(1).name = 'SurfaceID';
    g.private.metadata(1).value = meshfile;
    postb_vols{postbi} = fullfile(outputfolder, ...
        [curimg_name '.gii']);
    save(g,postb_vols{postbi},'ExternalFileBinary');
    metricfile = postb_vols{postbi};
    g = gifti(metricfile);
    size(g.cdata)
end
% Section: for-block starts
for postwi=1:size(curpostw,2)
    curimg_name=['postw_' imgdesc sprintf('%02d',postwi)];
% Section: switch-block starts
    cur_data=curpostw(:,postwi);
    assert(size(cur_data,1) == 40962);
    g = gifti;
    g.cdata = cur_data;
    g.private.metadata(1).name = 'SurfaceID';
    g.private.metadata(1).value = meshfile;
    postw_vols{postwi} = fullfile(outputfolder, ...
        [curimg_name '.gii']);
    save(g,postw_vols{postwi},'ExternalFileBinary');
    metricfile = postw_vols{postwi};
    g = gifti(metricfile);
    size(g.cdata)

    %% temporary checks, visualize example file
    m = gifti(meshfile);
    d = gifti(preb_vols{1});

    figure;

    patch( ...
        'Vertices', double(m.vertices), ...
        'Faces', double(m.faces), ...
        'FaceVertexCData', double(d.cdata), ...
        'FaceColor', 'interp', ...
        'EdgeColor', 'none');

    axis equal;
    axis off;
    camlight;
    lighting gouraud;
    colorbar;
    d = gifti(preb_vols{1});

    disp(d.private.metadata)
    md = d.private.metadata;

    idx = strcmp({md.name},'SurfaceID');

    assert(any(idx),'SurfaceID metadata missing');

    disp(md(idx).value)
end
end
