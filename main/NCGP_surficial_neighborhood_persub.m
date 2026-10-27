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
        pial_fn=fullfile(alignedsurf_path, [lower(curhemi) 'h.pial.asc']);
        group_spmdir=fullfile(mainPath, 'derivatives', wf.glm, 'group', ...
            wf.pre, ['task-' wf.task '_' cursession '_hemi-' curhemi ...
            '_smooth-' wf.smooth]);
        if ~exist(group_spmdir, 'dir')
            mkdir(group_spmdir);
        end
        onsets='face';
        if wf.modelblackresponse==1
            onsets='faceblackresponse';
        end

        % Skip surface conversion, neighborhoods and extraction when all
        % cached inputs still correspond to the current GLMs and settings.
        cachefn=fullfile(group_spmdir, sprintf( ...
            'searchlight_cache_radius-%g_onsets-%s.mat', radius, onsets));
        cacheMeta=NCGP_surface_cache_metadata(wf, faces_runs{si,hi}, ...
            cursession, curhemi, pial_fn, onsets);
        if presaved_betas_flag && exist(cachefn,'file')==2
            try
                previous=load(cachefn, 'cacheMeta');
                if isfield(previous,'cacheMeta') && ...
                        isequaln(previous.cacheMeta, cacheMeta)
                    C=load(cachefn, 'saved_ds', 'saved_neighborhood', ...
                        'saved_cell', 'saved_vo', 'saved_fo', ...
                        'saved_out2in', 'saved_betasfn', 'saved_nscans');
                    if exist(C.saved_betasfn,'file')==2
                        ds_subsesshemi{si,hi}=C.saved_ds;
                        allnbr_frombetas_sesshemi{si,hi}=C.saved_neighborhood;
                        fullnbr_frombetas_cell_sesshemi{si,hi}=C.saved_cell;
                        vo_subsesshemi{si,hi}=C.saved_vo;
                        fo_subsesshemi{si,hi}=C.saved_fo;
                        out2in=C.saved_out2in;
                        allnbrhood_frombetas_cell=C.saved_cell;
                        betasfn{si,hi}=C.saved_betasfn;
                        nscans_subrun{si,hi}=C.saved_nscans;
                        fprintf('Loaded cached searchlights: %s / %s\n', ...
                            cursession, curhemi);
                        continue;
                    end
                end
                fprintf('Searchlight cache outdated: %s / %s\n', ...
                    cursession, curhemi);
            catch cacheErr
                warning('NCGP:InvalidSurfaceCache', ...
                    'Could not load %s (%s). Rebuilding.', ...
                    cachefn, cacheErr.message);
            end
        end
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
            beta_loc{si,hi}{subi} = [mainPath 'derivatives' filesep wf.glm filesep persons{subi} filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth '_onsets-' onsets filesep];
            regressor_names = design_from_spm(beta_loc{si,hi}{subi});
            fnst = decoding_describe_data({},baselabelnames,baseclasses,regressor_names,beta_loc{si,hi}{subi});
            conbetas{si,hi}=vertcat(conbetas{si,hi}, ...
                [fnst.files.name num2cell(fnst.files.chunk+lastchunkinsub)...
                num2cell(fnst.files.label) ]);
            lastchunkinsub=lastchunkinsub+cursubruns_num;
        end
        %         %% Convert betas from volumes to 4D surface and save it
        curds_nii=conbetas{si, hi};
        dssurf={};
        % Section: for-block starts
        for bi =1:size(curds_nii,1)
            betadsetname=strrep(curds_nii{bi,1},'.nii', '+orig.niml.dset');
            % Section: if-block starts
            if NCGP_surface_needs_update(curds_nii{bi,1}, betadsetname)
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
                if NCGP_surface_needs_update( ...
                        fullfile(curbetalocs,curresnii), ...
                        fullfile(curbetalocs,resdsetname))
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
        fdsurf_res=fullfile(group_spmdir, '4dsurf_res.niml.dset');
        delete(fdsurf_res);
        % Toolbox call → cosmo_map2surface
        cosmo_map2surface(ressurfall,fdsurf_res);
        %% define searchlights for each feature (voxel).
        disp(['Defining Neighborhoods']);
        % Toolbox call → cosmo_surface_dataset
        % Use the labels and run chunks of the actual beta images, not a
        % theoretical number of runs (which fails when a run is missing).
        betasds = cosmo_surface_dataset(dssurf_betasfn, ...
            'targets', cell2mat(curds_nii(:,3)), ...
            'chunks', cell2mat(curds_nii(:,2)));
        assert(size(betasds.samples,1)==size(curds_nii,1), ...
            'Stacked surface beta count differs from the extracted beta list.');
        
        % Toolbox call → cosmo_surficial_neighborhood
        [allnbrhood_frombetas,vo,fo,out2in]=cosmo_surficial_neighborhood(betasds,{pial_fn},'radius',radius);
        % Toolbox call → cosmo_convert_neighborhood
        allnbrhood_frombetas_cell=cosmo_convert_neighborhood(allnbrhood_frombetas, 'cell');
        % Call → NCGP_surface_neighborhood_plot: Project function call
        %NCGP_surface_neighborhood_plot(nbrhood_sl,pial_fn)
        %% extract betas and residuals for each searchlight
        % Call → NCGP_extract_betasres: Extract condition-wise beta estimates and residuals per searchlight; assemble 4D surface datasets.
        % If whole-stage cache is invalid, recompute extracted searchlight
        % data too. The extractor's existing MAT cache does not check radius
        % or run configuration and could otherwise return stale values.
        [betasfn{si, hi}, nscans_subrun{si, hi}] = ...
            NCGP_extract_betasres(wf, betasds, beta_loc{si,hi}, ...
            [group_spmdir filesep], allnbrhood_frombetas_cell, 'none', 0);
        % Call → NCGP_betas_export_4D: Project function call
        %NCGP_betas_export_4D(betasfn{si,hi})
        %% store the results
        allnbr_frombetas_sesshemi{si, hi}=allnbrhood_frombetas;
        fullnbr_frombetas_cell_sesshemi{si, hi}=allnbrhood_frombetas_cell;
        vo_subsesshemi{si,hi}=vo;
        fo_subsesshemi{si,hi}=fo;
        ds_subsesshemi{si,hi}=betasds;

        % Large extracted matrices already reside in saved_betasfn;
        % cache all other outputs needed by downstream LDC functions.
        saved_ds=betasds;
        saved_neighborhood=allnbrhood_frombetas;
        saved_cell=allnbrhood_frombetas_cell;
        saved_vo=vo;
        saved_fo=fo;
        saved_out2in=out2in;
        saved_betasfn=betasfn{si,hi};
        saved_nscans=nscans_subrun{si,hi};
        tempfn=[tempname(group_spmdir) '.mat'];
        try
            save(tempfn, 'cacheMeta', 'saved_ds', 'saved_neighborhood', ...
                'saved_cell', 'saved_vo', 'saved_fo', 'saved_out2in', ...
                'saved_betasfn', 'saved_nscans', '-v7.3');
            [ok,msg]=movefile(tempfn, cachefn, 'f');
            if ~ok
                error('NCGP:CacheMoveFailed', '%s', msg);
            end
            fprintf('Saved searchlight cache: %s\n', cachefn);
        catch cacheErr
            if exist(tempfn,'file')==2
                delete(tempfn);
            end
            warning('NCGP:CacheSaveFailed', ...
                'Could not save searchlight cache: %s', cacheErr.message);
        end
    end
end
end

function meta=NCGP_surface_cache_metadata(wf, runlist, session, hemi, pial_fn, onsets)
% Lightweight source fingerprints for invalidating stale saved arrays.
meta.version=1;
meta.session=session;
meta.hemi=hemi;
meta.radius=wf.radius;
meta.subjects=wf.origsubs;
meta.runlist=runlist;
meta.task=wf.task;
meta.pre=wf.pre;
meta.glm=wf.glm;
meta.smooth=wf.smooth;
meta.onsets=onsets;
[geo_folder,geo_name,geo_ext]=fileparts(pial_fn);
meta.pial=NCGP_surface_cache_filesignature(geo_folder, ...
    {[geo_name geo_ext]});
meta.glms=cell(numel(wf.origsubs),1);
for subi=1:numel(wf.origsubs)
    folder=fullfile(wf.mainpath, 'derivatives', wf.glm, ...
        wf.origsubs{subi}, wf.pre, ...
        ['task-' wf.task '_' session '_hemi-' hemi ...
        '_smooth-' wf.smooth '_onsets-' onsets]);
    meta.glms{subi}.folder=folder;
    meta.glms{subi}.spm=NCGP_surface_cache_filesignature(folder, ...
        {'SPM.mat'});
    meta.glms{subi}.beta=NCGP_surface_cache_filesignature(folder, ...
        {'beta_*.nii', 'beta_*.nii.gz'});
    meta.glms{subi}.res=NCGP_surface_cache_filesignature(folder, ...
        {'Res_*.nii', 'Res_*.nii.gz'});
end
end

function signature=NCGP_surface_cache_filesignature(folder, patterns)
% Compare file names, lengths and modification times without reading voxels.
files=dir(fullfile(folder,patterns{1}));
for pi=2:numel(patterns)
    files=[files; dir(fullfile(folder,patterns{pi}))]; %#ok<AGROW>
end
[~,order]=sort({files.name});
files=files(order);
signature.names={files.name};
signature.bytes=[files.bytes];
signature.datenum=[files.datenum];
end

function needsUpdate=NCGP_surface_needs_update(sourcefn, surfacefn)
% A surface needs rebuilding when its source NIfTI was replaced.
if exist(surfacefn,'file')~=2
    needsUpdate=true;
    return;
end
src=dir(sourcefn);
surf=dir(surfacefn);
needsUpdate=~isempty(src) && ~isempty(surf) && ...
    src.datenum>surf.datenum;
end
