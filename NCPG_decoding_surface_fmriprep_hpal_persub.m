% ==========================================================================
% Overall goal (user-provided): Overall goal: Decoding Face Identitiy (1 out of 8 identities) using CosomoMVPA and exports the (accuracy minus chance) maps as a NIML dataset and GIFTI images. This version is modified to use hyperaligned images. It creates 4D surface timeline first and optionally z-scores the data.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Decoding Face Identitiy (1 out of 8 identities) using CosomoMVPA and exports the (accuracy minus chance) maps as a NIML dataset and GIFTI images. This version is modified to use hyperaligned images. It creates 4D surface timeline first and optionally z-scores the data.
% Note:
% ==========================================================================
% Function signature detected
function NCPG_decoding_surface_fmriprep_hpal_persub(wf, runscell, nbrorig_subsesshemi, vo_subsesshemi, fo_subsesshemi)
%fMRI surface-based searchlights with LDA classifier
% use cases:
%   1) single or twin surfaces
%      + FreeSurfer uses twin surfaces (pial and white), and voxels in
%        between or on them are considered to be in the grey matter
%   2) lower resolution output map
%      + in the canonical surface-based searchlight, each node on the input
%        surface(s) is assigned a measure value (accuracy, in this example)
%      + it is also possible to have output in a lower resolution version
%        than the input surfaces; this reduces both the execution time
%        (a Good Thing) and spatial precision (a Bad Thing). Two approaches
%        are illustrated to use a lower resolution surface for output:
%        1) from MapIcosahedron, with a lower value for the number of
%          divisions of the triangles
%        2) using a surface subsampling approach, implemented by
%           surfing_subsample_surface
%
% In all cases a searchlight is run with a 100 voxel searchlight, using a
% disc for which the metric radius varies from node to node. For a fixed
% metric radius of the disc, use a positive value for 'radius' below.
% Distances are measured across the cortical surface using a geodesic
% distance metric.
%% Settings
sessions=wf.sessions;
mainPath = wf.mainpath;
labelnames={'AH1';'AH2';'AH3';'AH4';'NAT1';'NAT2';'NAT3';'NAT4'};
% Section: for-block starts
for si=1:length(wf.sessions)
    cursession=sessions{si};
% Section: for-block starts
    for hi =1:length(wf.hemis)
        vo = vo_subsesshemi{si,hi};
        fo = fo_subsesshemi{si,hi};
        nbrhood = nbrorig_subsesshemi{si,hi};
        curhemi=wf.hemis{hi};
        allacc_res=[];
% Section: for-block starts
        for subi = 1:length(wf.origsubs)
            cursub=wf.origsubs{subi};

            decodingresdir=[mainPath filesep wf.alignment filesep wf.decoding filesep cursub filesep wf.pre filesep wf.glm filesep];
            mkdir(decodingresdir);
            output_path=[decodingresdir  'AH-NAT_' cursession '_surface' '-' upper(wf.classifier) '_' num2str(wf.radius) 'mm' filesep];
            mkdir(output_path);
            beta_loc = [mainPath filesep  wf.alignment filesep wf.glm filesep cursub filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth filesep];
            spmdes=design_from_spm([beta_loc filesep 'SPM.mat']);
            spmdes_lbls=spmdes(1,:);
            spmdes_runidx=cell2mat(spmdes(2,:));
            currunscell=runscell{si,hi}{subi};
            conbetas=[];
% Section: for-block starts
            for runi =1:size(currunscell,1)
                spmdes_currun=horzcat(num2cell([find(spmdes_runidx==runi & ismember(spmdes_lbls, labelnames))]'), horzcat( num2cell(zeros(length(labelnames),1)+runi), horzcat(labelnames, num2cell(1:length(labelnames))')));
                conbetas=vertcat(conbetas, spmdes_currun);
            end
% Section: for-block starts
            for bi =1:length(conbetas)
% Toolbox call → cosmo_surface_dataset
                dssurf{bi} = cosmo_surface_dataset([beta_loc 'beta_' sprintf('%04d', cell2mat(conbetas(bi,1))) '+orig.niml.dset'],'targets',cell2mat(conbetas(bi,4)),'chunks',cell2mat(conbetas(bi,2)));
            end
% Toolbox call → cosmo_stack
            dssurfall=cosmo_stack(dssurf);
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(dssurfall,[beta_loc filesep '4dsurf.niml.dset']);
            chunks=dssurfall.sa.chunks;
            targets=dssurfall.sa.targets;
            save([beta_loc filesep '4dsurf_metadata.mat'],'chunks', 'targets','conbetas');
            betaavg=[beta_loc '4dsurf.niml.dset'];
            %% set Classifier
            % Use the cosmo_cross_validation_measure and set its parameters
            % (classifier and partitions) in a measure_args struct.
            measure = @cosmo_crossvalidation_measure;
            measure_args = struct();
            % Define which classifier to use, using a function handle.
            % Alternatives are @cosmo_classify_{svm,nn,naive_bayes}
            measure_args.classifier = @cosmo_classify_svm;
            %% Load functional data & change decoding to be group level
            dsmeta=load([beta_loc '4dsurf_metadata.mat']);
            %newtargets=1 +(dsmeta.targets>4);
            newtargets=dsmeta.targets;
% Toolbox call → cosmo_surface_dataset
            ds = cosmo_surface_dataset(betaavg, 'chunks', dsmeta.chunks, 'targets', newtargets);
% Toolbox call → cosmo_normalize
            ds_zscored=cosmo_normalize(ds,'zscore');
% Toolbox call → cosmo_normalize
            ds_norm=cosmo_normalize(ds_zscored,'scale_unit');
            % remove zero elements
            fprintf('Dataset has %d samples and %d features\n', size(ds_norm.samples));
% Toolbox call → cosmo_nchoosek_partitioner
            measure_args.partitions = cosmo_nchoosek_partitioner(ds_norm,1);
            measure_args.C = wf.decode.C;
            measure_args.output = wf.decode.output;
            %% Run searchlight
            fprintf('The output surface has %d vertices, %d nodes\n',size(vo,1), size(fo,1));
% Toolbox call → cosmo_warning
            cosmo_warning('off');
% Toolbox call → cosmo_searchlight
            surfsl_res_cursub = cosmo_searchlight(ds_norm,nbrhood,measure,measure_args, 'nproc', 16,'progress',10);
            surfsl_res{subi}=surfsl_res_cursub;
            %% ################  Results  ##########################
            output_ds=fullfile(output_path,'surface_searchlight_results.mat');
            save(output_ds,'surfsl_res_cursub')
            %% Display on the original surfaces
            nvertices=size(vo,1);
            opt.ShowEdge=true;
            DispIVSurf(vo,fo,1:nvertices,surfsl_res_cursub.samples',0,opt);
            %% The surface is stored in NIML, GIFTI
            res_2surfs=surfsl_res{subi}.samples';
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(surfsl_res{subi}, [output_path 'surfslmap.niml.dset'], 'format', 'niml_dset')
            prefix_orig=[cursession '_task-' wf.task '_target-identity_hemi-' curhemi '_space-' wf.refsub '_surface-pial'];
            % GIFTI Original
% Toolbox call → surfing_write
            surfing_write([output_path prefix_orig '_data.gii'],vo,fo, res_2surfs(1:size(vo,1)));
% Toolbox call → surfing_write
            surfing_write([output_path prefix_orig '.gii'],vo,fo,[]);
            %% store voxel counts (how often each voxel is in a neighborhood)
            % take a random sample (the first one) from the input dataset
            % and count how often each voxel was selected.
            % If everything works, then voxels in the grey matter have high
            % voxel counts but voxels outside it low or zero counts.
            % Thus, this can be used as a sanity check that can be visualized
            % easily.
% Toolbox call → cosmo_slice
            % % %             vox_count_ds=cosmo_slice(ds,1);
            % % %             vox_count_ds.samples(:)=0;
            % % %             ncenters=numel(nbrhood.neighbors);
            % % %             for k=1:ncenters
            % % %                 idxs=nbrhood.neighbors{k}; % feature indices in neigborhood
            % % %                 vox_count_ds.samples(idxs)=vox_count_ds.samples(idxs)+1;
            % % %             end
            % % %             vox_count_output_fn=[output_path 'vox_count_'];
            % % %             % store voxel count results
% Toolbox call → cosmo_map2fmri
            % % %             cosmo_map2fmri(vox_count_ds, [vox_count_output_fn '.nii']);
% Toolbox call → cosmo_check_external
            % % %             if cosmo_check_external('afni',false)
% Toolbox call → cosmo_map2fmri
            % % %                 cosmo_map2fmri(vox_count_ds, [vox_count_output_fn '+orig'],'deoblique',true );
            % % %             end
        end
        %% The surface is stored in NIML, GIFTI
        groupdecodingresdir=[mainPath filesep wf.alignment filesep wf.decoding filesep 'group' filesep wf.pre filesep wf.glm filesep];
        mkdir(groupdecodingresdir);
        groupoutput_path=[groupdecodingresdir  'AH-NAT_' cursession '_surface' '-' upper(wf.classifier) '_' num2str(wf.radius) 'mm' filesep];
        mkdir(groupoutput_path);
% Toolbox call → cosmo_stack
        ds_all=cosmo_stack(surfsl_res);
        ds_all.samples=mean(ds_all.samples,1);
        ds_all.sa.labels= ds_all.sa.labels{1};
        slprefix=[cursession '_target-' wf.decode.type '_hemi-' curhemi '_classifier-' upper(wf.classifier) '_zscoredpersub_rescaled'];
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(ds_all, [groupoutput_path filesep slprefix '.niml.dset'], 'format', 'niml_dset');
        wf.smkernel=wf.decode.smkernel;
% Call → NCPG_surfsmooth
        NCPG_surfsmooth(wf, groupoutput_path, slprefix, curhemi);
        opt.ShowEdge=true;
        DispIVSurf(vo,fo,1:nvertices,ds_all.samples',0,opt);
    end
end
end
