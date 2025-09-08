% ==========================================================================
% Overall goal (user-provided): Overall goal: Decoding Face Identitiy (1 out of 8 identities) using CosomoMVPA and exports the (accuracy minus chance) maps as a NIML dataset and GIFTI images
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Decoding Face Identitiy (1 out of 8 identities) using CosomoMVPA and exports the (accuracy minus chance) maps as a NIML dataset and GIFTI images
% Note:
% ==========================================================================
% Function signature detected
function NCPG_decoding_surface_fmriprep(wf, edgesnum, glmperrun, runscell)
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
radius=wf.radius;
classifier=wf.classifier;
ngroupsubs=1;
persons = wf.origsubs;
% Call → NCPG_paths
paths=NCPG_paths(wf);
alignedsurf_path=paths.refsuma;
labelnames={'AH1';'AH2';'AH3';'AH4';'NAT1';'NAT2';'NAT3';'NAT4'};
ncond=length(labelnames);
classes=1:ncond;
spm( 'defaults', 'fmri' );
% Toolbox call → spm_jobman
spm_jobman( 'initcfg' );
subsesruns={};
% Section: for-block starts
for si =1:length(wf.sessions)
% Section: for-block starts
    for hi = 1:length(wf.hemis)
% Section: for-block starts
        for  subi=1:length(wf.origsubs)
            cursubruns=runscell{si,hi}{subi};
            subsesruns=vertcat(subsesruns, horzcat(repmat(wf.origsubs(subi),size(cursubruns,1),1), cursubruns));
        end
    end
end
% Section: for-block starts
for subi =1:length(persons)
    sublbl=persons{subi};
    decodingresdir=[mainPath filesep wf.alignment filesep wf.decoding filesep sublbl filesep wf.pre filesep wf.glm filesep];
    mkdir(decodingresdir);
% Section: for-block starts
    for si=1:length(wf.sessions)
        cursession=sessions{si};
% Section: for-block starts
        for hi =1:length(wf.hemis)
            curnrun=size(runscell{si,hi}{subi}, 1);
            curtargets=repmat(repmat(1:ncond,1,curnrun),1,ngroupsubs);
            curchunks=repmat(floor(((1:(ncond*curnrun))-1)/ncond)+1,1,ngroupsubs);
            curhemi=wf.hemis{hi};
            %% Make 4D beta image
            output_path=[decodingresdir  'AH-NAT_' cursession '_surface' '-' upper(classifier) '_' num2str(radius) 'mm' filesep];
            mkdir(output_path);
            st=0;
            betaavg=[output_path '4D.nii'];
% Section: if-block starts
            if glmperrun==1
% Section: for-block starts
                for ri=1:length(runs)
                    modelname=[cursession '_' runs{ri} '_' modeltype];
                    beta_loc = [mainPath wf.alignment filesep wf.glm filesep sublbl filesep wf.pre filesep modelname filesep];
                    regressor_names = design_from_spm(beta_loc);
                    fnst = decoding_describe_data({},labelnames,classes,regressor_names,beta_loc);
                    nbeta(st+1:st+ncond,1)=fnst.files.name;
                    st=st+ncond;
                end
% Section: else-block starts
            else
                beta_loc = [mainPath filesep  wf.alignment filesep wf.glm filesep sublbl filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth filesep];
                regressor_names = design_from_spm(beta_loc);
                fnst = decoding_describe_data({},labelnames,classes,regressor_names,beta_loc);
                nbeta=fnst.files.name;
            end
            clear matlabbatch
            cd(output_path)
            matlabbatch{1}.spm.util.cat.vols = cellstr(nbeta);
            matlabbatch{1}.spm.util.cat.name = betaavg;
            matlabbatch{1}.spm.util.cat.dtype = 4;
            matlabbatch{1}.spm.util.cat.RT = NaN;
% Toolbox call → spm_jobman
            spm_jobman( 'run', matlabbatch );
            %% Set Surfaces
            pial_fn=fullfile(alignedsurf_path, sprintf(['std.%d.' lower(curhemi) 'h.pial.asc'], edgesnum));
            white_fn=fullfile(alignedsurf_path, sprintf(['std.%d.' lower(curhemi) 'h.smoothwm.asc'], edgesnum));
            inflated_fn=fullfile(alignedsurf_path,sprintf(['std.%d.' lower(curhemi) 'h.inflated.asc'], edgesnum));
            %% set Classifier
            % Use the cosmo_cross_validation_measure and set its parameters
            % (classifier and partitions) in a measure_args struct.
            measure = @cosmo_crossvalidation_measure;
            measure_args = struct();
            % Define which classifier to use, using a function handle.
            % Alternatives are @cosmo_classify_{svm,nn,naive_bayes}
            measure_args.classifier = @cosmo_classify_svm;
            %% Load functional data
% Toolbox call → cosmo_fmri_dataset
            ds = cosmo_fmri_dataset(betaavg,'targets',curtargets,'chunks',curchunks);
            % remove zero elements
            zero_msk=all(ds.samples==0,1);
% Toolbox call → cosmo_slice
            ds = cosmo_slice(ds, ~zero_msk, 2);
            fprintf('Dataset has %d samples and %d features\n', size(ds.samples));
% Toolbox call → cosmo_nchoosek_partitioner
            measure_args.partitions = cosmo_nchoosek_partitioner(ds,1);
            measure_args.C=1;
            measure_args.output='accuracy';
            %% Get Neighborhoods and Run searchlight
            % define searchlight surface paramters for each type of analysis
            surf_def={white_fn,pial_fn};
% Toolbox call → cosmo_surficial_neighborhood
            [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(ds,surf_def,'radius',radius);
            fprintf('The output surface has %d vertices, %d nodes\n',size(vo,1), size(fo,1));
% Toolbox call → cosmo_searchlight
            surfsl_res = cosmo_searchlight(ds,nbrhood,measure,measure_args);
            %% ################  Results  ##########################
            output_ds=fullfile([output_path filesep sublbl],'surface_searchlight_results.mat');
            mkdir([output_path filesep sublbl])
            save(output_ds,'surfsl_res')
            %% Read inflated surface
% Toolbox call → surfing_read
            [v_inf,f_inf]=surfing_read(inflated_fn);
% Toolbox call → surfing_read
            %[vinf_rh,finf_rh]=surfing_read([alignedsurf_path 'std.' num2str(edgesnum) '.' lowercurhemi rh.inflated_al.asc']);
% Toolbox call → surfing_read
            %[vinf_lh,finf_lh]=surfing_read([alignedsurf_path 'ico' num2str(edgesnum) '_lh.inflated_al.asc']);
% Toolbox call → surfing_read
            [vo_rh,fo_rh]=surfing_read(pial_fn);
% Toolbox call → surfing_read
            %[vo_lh,fo_lh]=surfing_read([alignedsurf_path 'ico' num2str(edgesnum) '_lh.pial_al.asc']);
            v_inf_out=v_inf;
            f_inf_out=f_inf;
            % visualize the surfaces, if the afni matlab toolbox is present
            nvertices=size(v_inf_out,1);
            opt=struct();
% Section: for-block starts
            for show_edge=[false, true]
                opt.ShowEdge=show_edge;
% Section: if-block starts
                if show_edge
                    t='with edges';
% Section: else-block starts
                else
                    t='without edges';
                end
                header=strrep([' ' t],'_',' ');
                DispIVSurf(vo,fo,1:nvertices,surfsl_res.samples',0,opt);
                title(sprintf('Original %s', header));
                DispIVSurf(v_inf_out,f_inf_out,1:nvertices,...
                    surfsl_res.samples',0,opt);
                title(sprintf('Inflated %s', header));
            end
            %% The surface is stored in ASCII, GIFTI
            res_2surfs=surfsl_res.samples';
            outfnedges=[output_path 'ico' num2str(edgesnum) '_'];
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(surfsl_res, [outfnedges 'surfslmap.niml.dset'], 'format', 'niml_dset')
% Toolbox call → cosmo_map2surface
            %     cosmo_map2surface(res_2surfs(1:size(vinf_rh,1)), [outfnedges 'surfslmap.niml.dset'], 'format', 'niml_dset')
% Toolbox call → cosmo_map2surface
            %     cosmo_map2surface(surfsl_res, [outfnedges 'surfslmap.niml.dset'], 'format', 'niml_dset')

            % GIFTI inflated
            prefix_orig=[cursession '_task-' wf.task '_target-identity_hemi-' curhemi '_space-' wf.refsub '_surface-pial_mesh-std' num2str(edgesnum)];
% Toolbox call → surfing_write
            surfing_write( [ prefix_orig 'inflated_data.gii'],v_inf_out,f_inf_out, res_2surfs);
% Toolbox call → surfing_write
            surfing_write([prefix_orig 'inflated.gii'],f_inf_out,f_inf_out,[]);
            % GIFTI Original
% Toolbox call → surfing_write
            surfing_write([prefix_orig '_data.gii'],vo,fo, res_2surfs(1:size(vo_rh,1)));
% Toolbox call → surfing_write
            surfing_write([prefix_orig '.gii'],vo,fo,[]);
            %         % GIFTI Original - Right hemisphere
% Toolbox call → surfing_write
            %         surfing_write([outfnedges 'rh_data.gii'],vo_rh,fo_rh,res_2surfs(1:size(vo_rh,1)));
% Toolbox call → surfing_write
            %         surfing_write([outfnedges 'rh.gii'],vo_rh,fo_rh,[]);
            %         % GIFTI Original - Left hemisphere
% Toolbox call → surfing_write
            %         surfing_write([outfnedges 'lh_data.gii'],vo_lh,fo_lh,res_2surfs(end-size(vo_lh,1)+1:end));
% Toolbox call → surfing_write
            %         surfing_write([outfnedges 'lh.gii'],vo_lh,fo_lh,[]);
            %% store voxel counts (how often each voxel is in a neighborhood)
            % take a random sample (the first one) from the input dataset
            % and count how often each voxel was selected.
            % If everything works, then voxels in the grey matter have high
            % voxel counts but voxels outside it low or zero counts.
            % Thus, this can be used as a sanity check that can be visualized
            % easily.
% Toolbox call → cosmo_slice
            vox_count_ds=cosmo_slice(ds,1);
            vox_count_ds.samples(:)=0;

            ncenters=numel(nbrhood.neighbors);
% Section: for-block starts
            for k=1:ncenters
                idxs=nbrhood.neighbors{k}; % feature indices in neigborhood
                vox_count_ds.samples(idxs)=vox_count_ds.samples(idxs)+1;
            end

            vox_count_output_fn=[outfnedges 'vox_count_'];

            % store voxel count results
% Toolbox call → cosmo_map2fmri
            cosmo_map2fmri(vox_count_ds, [vox_count_output_fn '.nii']);
% Section: if-block starts
% Toolbox call → cosmo_check_external
            if cosmo_check_external('afni',false)
% Toolbox call → cosmo_map2fmri
                cosmo_map2fmri(vox_count_ds, [vox_count_output_fn '+orig'],'deoblique',true );
            end
        end
    end
end
