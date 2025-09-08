% ==========================================================================
% Overall goal (user-provided): Overall goal: Divides the brain surface into searchlights using CosmoMVPA functions. First it creates a 4D beta image, then convert it to NIML surface dataset then loads the surface dataset.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Divides the brain surface into searchlights using CosmoMVPA functions. First it creates a 4D beta image, then convert it to NIML surface dataset then loads the surface dataset.
% Note:
% ==========================================================================
% Function signature detected
function [ds_subsesshemi, fullnbr_subsesshemi, nbr_subsesshemi, vo_subsesshemi, fo_subsesshemi, out2in,...
    maskidx_subsesshemi, betasfn, betasfn_masked]=NCPG_surficial_neighborhood(wf, faces_runs)
%% Settings

%scans = sort( scanInput );

sessions=wf.sessions;
runs=wf.runs;
nrun=length(runs);
mainPath = wf.mainpath;
radius=wf.radius;
classifier=wf.classifier;
modeltype=wf.modeltype;
ngroupsubs=length(wf.origsubs);
nrunsub=ngroupsubs*nrun;
persons = wf.origsubs;
% Call → NCPG_paths
paths=NCPG_paths(wf);
alignedsurf_path=paths.refsuma;
baselabelnames={'AH1';'AH2';'AH3';'AH4';'NAT1';'NAT2';'NAT3';'NAT4'};
ncond=length(baselabelnames);
addedval=0;
chunks=[];

% Section: for-block starts
for subi=1:ngroupsubs
    curchunks=floor(((1:(ncond*nrun))-1)/ncond)+1 + addedval; % Chunks(repetitions) = runs repeated over (conditions* runs * subjects)
    addedval=nrun*(subi);
    chunks=[chunks curchunks];
end
labelnames=repmat(baselabelnames,nrunsub,1);
baseclasses=1:8;
classes=repmat(baseclasses,1,nrunsub); % Classes(targets) = conditions repeated over (conditions * runs* subjects)
spm( 'defaults', 'fmri' );
% Toolbox call → spm_jobman
spm_jobman( 'initcfg' );
allhemis=wf.hemis;
% Section: for-block starts
for subi =1:length(persons)
    sublbl=persons{subi};
    decodingresdir=[mainPath filesep wf.alignment filesep wf.decoding filesep sublbl filesep wf.pre filesep wf.glm filesep];
    mkdir(decodingresdir);
% Section: for-block starts
    for si=1:length(sessions)
        cursession=sessions{si};
% Section: for-block starts
        for hi =1:length(allhemis)
            %% Load the GLM
            curhemi=allhemis{hi};
            output_path=[decodingresdir  'AH-NAT_' cursession '_surface' '-' upper(classifier) '_' num2str(radius) 'mm' filesep];
            mkdir(output_path);
            concrunnames='';
% Section: for-block starts
            for origruni = 1:length(wf.runs)
                concrunnames=[concrunnames strrep(wf.runs{origruni},'run-','')];
            end

            beta_loc = [mainPath  wf.alignment filesep wf.glm filesep persons{subi} filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_run-' concrunnames filesep];
            regressor_names = design_from_spm(beta_loc);
            fnst = decoding_describe_data({},baselabelnames,baseclasses,regressor_names,beta_loc);
            nbeta=fnst.files.name;
            %             %% Make 4D beta image
            %             betaavg=[output_path '4D.nii'];
            %             if ~exist(betaavg, 'file')
            %                 clear matlabbatch
            %                 cd(output_path)
            %                 delete(betaavg)
            %                 matlabbatch{1}.spm.util.cat.vols = cellstr(nbeta);
            %                 matlabbatch{1}.spm.util.cat.name = betaavg;
            %                 matlabbatch{1}.spm.util.cat.dtype = 4;
            %                 matlabbatch{1}.spm.util.cat.RT = NaN;
% Toolbox call → spm_jobman
            %                 spm_jobman( 'run', matlabbatch );
            %             end
            %% Convert betas from volumes to 4D surface and save it
            pial_fn=fullfile(alignedsurf_path, [ lower(curhemi) 'h.pial.asc']);
% Toolbox call → surfing_read
            nodeloc_pial=surfing_read(pial_fn);
% Section: for-block starts
            for bi =1:length(nbeta)
                betadsetname=strrep(nbeta{bi},'.nii', '+orig.niml.dset');
% Section: if-block starts
                if ~exist(betadsetname,'file')
% Call → NCPG_vol2surf
                    NCPG_vol2surf(wf, strrep(nbeta{bi},beta_loc,''), beta_loc, curhemi);
                end
% Toolbox call → cosmo_surface_dataset
                dssurf{bi} = cosmo_surface_dataset(betadsetname,'targets',classes(bi),'chunks',chunks(bi),'labels',labelnames{bi});
            end
% Toolbox call → cosmo_stack
            dssurfall=cosmo_stack(dssurf);
            dssurfall.sa.labels=labelnames;
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(dssurfall,[beta_loc '4dsurf.niml.dset']);
            %% Convert Residuals to surfaces
            %             disp(['Compressing Residual images']);
            %             resdirnii=dir([beta_loc 'Res_*.nii']);
            %             if ~isempty(resdirnii)
            %             parfor ni =1:length(resdirnii)
            %                curresnii_0=[resdirnii(1).folder filesep resdirnii(ni).name];
            %                gzip(curresnii_0);
            %                delete(curresnii_0);
            %             end
            %             end
            disp(['Reading Residual images']);
            resdirgz=dir([beta_loc 'Res_*.niml']);
% Section: if-block starts
            if ~isempty(resdirgz)
% Section: for-block starts
            for ri =1:length(resdirgz)
                curresniigz=resdirgz(ri).name;
                gunzip([beta_loc curresniigz]);
            end
            end
            resdir=dir([beta_loc 'Res_*.nii']);
% Section: for-block starts
            for ri =1:length(resdir)
                curresnii=resdir(ri).name;
                %gunzip([beta_loc curresniigz]);
                resdsetname=strrep(curresnii,'.nii', '+orig.niml.dset');
% Section: if-block starts
                if ~exist([beta_loc resdsetname],'file')
% Call → NCPG_vol2surf
                    NCPG_vol2surf(wf, curresnii, beta_loc, curhemi);
                end
% Toolbox call → cosmo_surface_dataset
                resdset_list{ri} = cosmo_surface_dataset([beta_loc resdsetname]);
            end
% Toolbox call → cosmo_stack
            ressurfall=cosmo_stack(resdset_list);
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(ressurfall,[beta_loc '4dsurf_res.niml.dset']);
            %% define searchlights for each feature (voxel).
            disp(['Defining Neighborhoods']);
% Toolbox call → cosmo_surface_dataset
            betasds = cosmo_surface_dataset([beta_loc '4dsurf.niml.dset'],'targets',classes,'chunks',chunks);
% Toolbox call → cosmo_surficial_neighborhood
            [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(betasds,{pial_fn},'radius',radius);
% Toolbox call → cosmo_convert_neighborhood
            allnbrhoods=cosmo_convert_neighborhood(nbrhood, 'cell');
% Toolbox call → surfing_read
            maskdset=surfing_read([strrep(wf.maskhemis{hi},'.nii','+orig.niml.dset')]);
            mask_idx=find(maskdset.data);
            nbrhood_sl=allnbrhoods(mask_idx);
% Call → NCPG_surface_neighborhood_plot
            NCPG_surface_neighborhood_plot(nbrhood_sl,pial_fn)
            %% extract betas and residuals for each searchlight
% Call → NCPG_extract_betasres
            betasfn_masked{subi,si}{hi} = NCPG_extract_betasres(wf, betasds, beta_loc, nbrhood_sl , 'localizer');
            betasfn=betasfn_masked;
% Call → NCPG_extract_betasres
            %betasfn{subi,si}{hi} = NCPG_extract_betasres(wf, betasds, beta_loc, allnbrhoods, 'none' );
            %% store the results
            nbr_subsesshemi{subi,si}{hi}=nbrhood_sl;
            fullnbr_subsesshemi{subi,si}{hi}=nbrhood;
            vo_subsesshemi{subi,si}{hi}=vo;
            fo_subsesshemi{subi,si}{hi}=fo;
            ds_subsesshemi{subi,si}{hi}=betasds;
            %             betas_subsesshemi_roirun{subi,si}{hi}=betas_condbyrun;
            %             res_subsesshemi_roirun{subi,si}{hi}=res_condbyrun;
            %             betas_subsesshemi_roirun_masked{subi,si}{hi}=betas_condbyrun_masked;
            %             res_subsesshemi_roirun_masked{subi,si}{hi}=res_condbyrun_masked;
            betas_subsesshemi_roirun{subi,si}{hi}=betasfn;
            res_subsesshemi_roirun{subi,si}{hi}=betasfn;
            betas_subsesshemi_roirun_masked{subi,si}{hi}=betasfn;
            res_subsesshemi_roirun_masked{subi,si}{hi}=betasfn;
            maskidx_subsesshemi{subi,si}{hi}=mask_idx;
        end
    end
end
end
