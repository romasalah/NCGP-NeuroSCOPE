% ==========================================================================
% Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
function  NCGP_tfce(sessions)
persons = [1];
labelnames={'AH1';'AH2';'AH3';'AH4';'NAT1';'NAT2';'NAT3';'NAT4'};
t1folder='/Volumes/EVO8602TB/NCGP/Data/NCGP_001/T1/';
ncond=length(labelnames);
personName = ['NCGP_00' num2str( persons(1) ) filesep ];

for si=1:length(sessions)
    %% Step 1. Load surface
    subfolder=['/Volumes/EVO8602TB/NCGP/Data/Decoding/AH-NAT_' sessions{si} '_surface-LIBSVM_10mm/'];
    surf_fn = [subfolder filesep 'original.gii'];
    [vertices, faces] = surfing_read(surf_fn);
    nvertices = size(vertices, 1);
    npermute=100;
    %% Step 2. Load original and permuted data
    % store masks to reuse later
    orig_fn = load([subfolder filesep 'NCGP_001/surface_searchlight_results.mat']);
    ds = orig_fn.surface_searchlight_results;
    ds.samples=ds.samples-1/8;
    perm_fn = load([subfolder filesep num2str(npermute) '_permutedmaps.mat']);
    ff=perm_fn.surface_searchlight_results;
    perms=ff{1};
    for i=2:npermute
        perms.samples=[perms.samples; ff{i}.samples];
        perms.sa.labels=[perms.sa.labels; ff{1}.sa.labels];
    end
    ss=perms.samples;
    ssmin=ss-1/8;
    nonzeros=ssmin(:,(sum(ssmin,1)>0.1));
    allperms_hightail=prctile(ssmin, 95, 1);
    parfor mcsi=1:1000
        curperm = randperm(npermute,70);
        curssmin=ssmin(curperm,:);
        hightail(mcsi,:)=prctile(curssmin, 95, 1);
    end
    meanhightail=mean(hightail,1);
    tt2=ds.samples>meanhightail;
    ds.samples(~tt2)=0;
    ds.samples=abs(ds.samples);
%     %% Step 4. Put everything together and run TFCE
%     nbr = cosmo_cluster_neighborhood(orig_data{1}, 'vertices', double(vertices), 'faces', double(faces));
%     opt = struct();
%     opt.cluster_stat = 'tfce';
%     opt.niter = niter;
%     opt.h0_mean = 1/8;
%     opt.seed = 42;
%     opt.null = ff;
%     opt.nproc = 1;
%     opt.dh=0.1;
%     opt.feature_stat='auto';
%     fprintf('Using the following options\n');
%     cosmo_disp(opt);
%     %NCGP_tfce_suppfunc(ds, opt,orig_data, nbr)
    
    %% Step 5. Store results
    mainPath = '/Volumes/EVO8602TB/NCGP/Data/';
    decodings_results_path=[mainPath filesep 'Decoding'];
    mkdir(decodings_results_path);
    output_path=[decodings_results_path filesep 'AH-NAT_' sessions{si} '_surface-LIBSVM_10mm_tfce/'];
    
    output_ds=fullfile([output_path filesep personName],'surface_searchlight_results.mat');
    surf_output_fn=fullfile(output_path,['original']);
    mkdir([output_path filesep personName])
    save(output_ds,'ds')
    % visualize the surfaces, if the afni matlab toolbox is present
    opt=struct();
    for show_edge=[false, true]
        opt.ShowEdge=show_edge;
        if show_edge
            t='with edges';
        else
            t='without edges';
        end
        header=strrep([' ' t],'_',' ');
        DispIVSurf(vertices,faces,1:nvertices,ds.samples',0,opt);
        title(sprintf('Original %s', header));
    end
    % GIFTI
    [rhv, rhf]=surfing_read([t1folder 'ico64_rh.pial_al.asc']);
    [lhv, lhf]=surfing_read([t1folder 'ico64_lh.pial_al.asc']);
    rhvsz=size(rhv,1);
    surfing_write([surf_output_fn '_data.gii'],vertices,faces,ds.samples');
    surfing_write([surf_output_fn '.gii'],vertices,faces,[]);
    surfing_write([surf_output_fn '_rh_data.gii'],rhv,rhf,ds.samples(1:rhvsz)');
    surfing_write([surf_output_fn '_rh.gii'],rhv,rhf,[]);
    surfing_write([surf_output_fn '_lh_data.gii'],lhv,lhf,ds.samples(rhvsz+1:end)');
    surfing_write([surf_output_fn '_lh.gii'],lhv,lhf,[]);
    
end
end