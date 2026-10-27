% ==========================================================================
% Overall goal: Construct subject-specific surface searchlight neighborhoods (fsaverage6) and optional localizer mask indices.
% ==========================================================================
function [ds_subsesshemi, fullnbr_frombetas_cell_sesshemi, vo_subsesshemi, fo_subsesshemi, out2in,...
    betasfn, allnbrhood_frombetas_cell, nscans_subrun, allnbr_frombetas_sesshemi]=NCGP_surficial_neighborhood_persub(wf, faces_runs, presaved_betas_flag)
%% Settings
baselabelnames={'AH1';'AH2';'AH3';'AH4';'NAT1';'NAT2';'NAT3';'NAT4'};
baseclasses=1:8;
ncond=length(baselabelnames);
mainPath = wf.mainpath;
radius=wf.radius;
persons = wf.origsubs;
% Call → NCGP_paths: Project function call
paths=NCGP_paths(wf);
alignedsurf_path=paths.refsuma;
allsubs_runinfo={};
conbetas={};
allhemis=wf.hemis;
% Section: for-block starts
for si = 1:length(wf.sessions)
    cursession=wf.sessions{si};
    % Section: for-block starts
    for hi = 1: length(wf.hemis)
        curhemi=allhemis{hi};
        chunksnum=0;
        allsubs_runinfo{si,hi}={};
        conbetas{si,hi}={};
        for subi =1:length(wf.origsubs)
            subruns=faces_runs{si,hi}{subi};
            for ri =1:length(subruns)
                chunksnum=chunksnum+1;
                cursub=wf.origsubs{subi};
                cursess=faces_runs{si,hi}{subi}{ri,1};
                currun=faces_runs{si,hi}{subi}{ri,2};
                for ci =1:ncond
                    allsubs_runinfo{si,hi}{end+1,1}=cursub;
                    allsubs_runinfo{si,hi}{end,2}=cursess;
                    allsubs_runinfo{si,hi}{end,3}=chunksnum;
                    allsubs_runinfo{si,hi}{end,4}=currun;
                    allsubs_runinfo{si,hi}{end,5}=ci;
                    allsubs_runinfo{si,hi}{end,6}=baselabelnames{ci};
                end
            end
        end
        curruninfo{si,hi}= array2table(allsubs_runinfo{si,hi}, 'VariableNames',{'Subject','Session','Chunk','Run','Label','Condition'});
        curruninfo{si,hi}=sortrows(curruninfo{si,hi}, [1,5, 3]);
        chunks=cell2mat(curruninfo{si,hi}.Chunk);
        classes=cell2mat(curruninfo{si,hi}.Label);
        lastchunkinsub=0;
        % Section: for-block starts
        for subi =1:length(persons)
            cursub=persons{subi};
            cursubruns=faces_runs{si,hi}{subi};
            cursubruns_num=size(cursubruns,1);
            %% Load the GLM
            onsets='face';
            if wf.modelblackresponse==1
                onsets='faceblackresponse';
            end
            beta_loc{si,hi}{subi} = [mainPath 'derivatives' filesep wf.glm filesep persons{subi} filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth '_onsets-' onsets filesep];
            regressor_names = design_from_spm(beta_loc{si,hi}{subi});
            fnst = decoding_describe_data({},baselabelnames,baseclasses,regressor_names,beta_loc{si,hi}{subi});
            conbetas{si,hi}=vertcat(conbetas{si,hi}, ...
                [fnst.files.name num2cell(fnst.files.chunk+lastchunkinsub)...
                num2cell(fnst.files.label) ]);
            lastchunkinsub=lastchunkinsub+cursubruns_num;
        end
        %         %% Convert betas from volumes to 4D surface and save it
        pial_fn=fullfile(alignedsurf_path, [ lower(curhemi) 'h.pial.asc']);
        group_spmdir = [mainPath 'derivatives' filesep wf.glm filesep 'group' filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth filesep];
        mkdir(group_spmdir)
        curds_nii=conbetas{si, hi};
        dssurf={};
        % Section: for-block starts
        for bi =1:size(curds_nii,1)
            betadsetname=strrep(curds_nii{bi,1},'.nii', '+orig.niml.dset');
            % Section: if-block starts
            if ~exist(betadsetname,'file')
                % Call → NCGP_vol2surf: Sample volumetric data to surface nodes (fsaverage6), creating per-vertex data from 3D images.
                curfoldernameloc= strfind(curds_nii{bi,1},'beta_');
                curfoldername=curds_nii{bi,1}(1:curfoldernameloc-1);
                NCGP_vol2surf(wf, strrep(curds_nii{bi,1},curfoldername,''), curfoldername, curhemi,'a');
            end
            % Toolbox call → cosmo_surface_dataset
            dssurf{bi} = cosmo_surface_dataset(betadsetname,'targets',curds_nii{bi,3},'chunks',curds_nii{bi,2});
        end
        % Toolbox call → cosmo_stack
        dssurfall=cosmo_stack(dssurf);
        dssurf_betasfn=[group_spmdir filesep '4dsurf.niml.dset'];
        % Toolbox call → cosmo_map2surface
        cosmo_map2surface(dssurfall,dssurf_betasfn);
        chunks=dssurfall.sa.chunks;
        targets=dssurfall.sa.targets;
        metadatafn=[group_spmdir filesep '4dsurf_metadata.mat'];
        delete(metadatafn);
        save(metadatafn,'chunks', 'targets','conbetas');
        %% Convert Residuals to surfaces
        imgsuffixes={'a','b','c','d','e','f'};
        imgsuffixes=repmat(imgsuffixes,1,4);
        delete(gcp('nocreate'))
        parpool(4);
        % Section: for-block starts
        for parsub =1:length(persons)
            cursfx=imgsuffixes{1};
            curbetalocs=beta_loc{si,hi}{parsub};
            resdir=dir([curbetalocs 'Res_*.nii.gz']);
            % Section: for-block starts
            for ri =1:length(resdir)
                curresnii=resdir(ri).name;
                resdsetname=strrep(curresnii,'.nii.gz', '+orig.niml.dset');
                % Section: if-block starts
                if ~exist([curbetalocs resdsetname],'file')
                    % Call → NCGP_vol2surf: Sample volumetric data to surface nodes (fsaverage6), creating per-vertex data from 3D images.
                    NCGP_vol2surf_gz(wf, curresnii, curbetalocs, curhemi, cursfx);
                end
            end
        end
        allressurfs = {};

        for subi = 1:length(persons)
            curbetalocs = beta_loc{si,hi}{subi};
            resdir = dir([curbetalocs 'Res_*.nii.gz']);
            % Reset the array for each participant
            resdset_list = cell(length(resdir),1);
            for ri = 1:length(resdir)
                curresnii = resdir(ri).name;
                resdsetname = strrep( ...
                    curresnii,'.nii.gz','+orig.niml.dset');
                resdset_list{ri} = cosmo_surface_dataset( ...
                    [curbetalocs resdsetname]);
                assert(size(resdset_list{ri}.samples,1) == 1, ...
                    'Expected one residual sample per file.');
            end
            allressurfs = vertcat( ...
                allressurfs, resdset_list);
        end
        % Toolbox call → cosmo_stack
        ressurfall=cosmo_stack(allressurfs);
        fdsurf_res=[group_spmdir '4dsurf_res.niml.dset'];
        delete(fdsurf_res);
        % Toolbox call → cosmo_map2surface
        cosmo_map2surface(ressurfall,fdsurf_res);
        %% define searchlights for each feature (voxel).
        disp(['Defining Neighborhoods']);
        % Toolbox call → cosmo_surface_dataset
        betasds = cosmo_surface_dataset(dssurf_betasfn,'targets',classes,'chunks',chunks);
        
        % Toolbox call → cosmo_surficial_neighborhood
        [allnbrhood_frombetas,vo,fo,out2in]=cosmo_surficial_neighborhood(betasds,{pial_fn},'radius',radius);
        % Toolbox call → cosmo_convert_neighborhood
        allnbrhood_frombetas_cell=cosmo_convert_neighborhood(allnbrhood_frombetas, 'cell');
        % Call → NCGP_surface_neighborhood_plot: Project function call
        %NCGP_surface_neighborhood_plot(nbrhood_sl,pial_fn)
        %% extract betas and residuals for each searchlight
        % Call → NCGP_extract_betasres: Extract condition-wise beta estimates and residuals per searchlight; assemble 4D surface datasets.
        [betasfn{si, hi}, nscans_subrun{si, hi}] = NCGP_extract_betasres(wf, betasds, beta_loc{si,hi}, group_spmdir,allnbrhood_frombetas_cell, 'none',presaved_betas_flag );
        % Call → NCGP_betas_export_4D: Project function call
        %NCGP_betas_export_4D(betasfn{si,hi})
        %% store the results
        allnbr_frombetas_sesshemi{si, hi}=allnbrhood_frombetas;
        fullnbr_frombetas_cell_sesshemi{si, hi}=allnbrhood_frombetas_cell;
        vo_subsesshemi{si,hi}=vo;
        fo_subsesshemi{si,hi}=fo;
        ds_subsesshemi{si,hi}=betasds;
    end
end
end
