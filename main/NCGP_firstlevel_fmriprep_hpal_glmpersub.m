% ==========================================================================
% Overall goal (user-provided): Overall goal: Run first-level GLM per subject (whole-brain/surface) using fMRIPrep outputs.
% ==========================================================================
function firstleveldir=NCGP_firstlevel_fmriprep_hpal_glmpersub(wf, HRFderivatives, runscell)
%% FFX batch code for SocialDecision experiments Summer 2017
% O. S. Ahmed based on J Schultz based on code by Paul Jung
% ----------- Main settings -----------------------------------------------
TR = wf.TR;
sessions=wf.sessions;
runs=wf.runs;
if strcmp(wf.task,'faces')
    Nses=length(sessions);
elseif strcmp(wf.task,'localizer')
    Nses=1;
end
mainFolder=wf.mainpath;
subs=wf.subs;
confnames1={'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z',...
    'a_comp_cor_00', 'a_comp_cor_01', 'a_comp_cor_02', 'a_comp_cor_03', 'a_comp_cor_04', 'a_comp_cor_05'};
confnames2={'X', 'Y', 'Z', 'RotX', 'RotY', 'RotZ',...
    'aCompCor00', 'aCompCor01', 'aCompCor02', 'aCompCor03', 'aCompCor04', 'aCompCor05'};
confnameopts={confnames1, confnames2};
hemis=wf.hemis;
runscell_sesshemi=cell(Nses,length(wf.hemis));
p=NCGP_paths(wf);
% Section: if-block starts
if strcmp(wf.task,'faces')
    % Section: for-block starts
    for si=1:length(wf.sessions)
        
        % Section: for-block starts
        for hi=1:length(wf.hemis)
            % Section: for-block starts
            for subi=1:length(subs)
                cursubcell=runscell{si,hi}{subi};
                runscell_sesshemi{si,hi}{subi}=cursubcell;
            end
        end
    end
end
%% Setup finished, get to work
% Section: for-block starts
for si=1:Nses
    cursession=sessions{si};
    % Section: for-block starts
    % Section: for-block starts
    for hi=1:length(hemis)
        curhemi=hemis{hi};
        scanInput={};
        sessMultiFile={};
        sessMultiregFile={};
        
        sessionData={};
        regs={};
        % Section: for-block starts
        % Section: for-block starts
        parfor (subi=1:length(subs), 4)
            confnames=confnameopts{1};
            matlabbatch={};
            curcellruns = [];
            cursession = '';
            maskfn = '';
            % Section: if-block starts
            % Section: if-block starts
            if strcmp(wf.task,'faces')
                curcellruns=runscell_sesshemi{si,hi}{subi};
                % Section: elseif-block starts
                % Section: elseif-block starts
            elseif strcmp(wf.task,'localizer')
                curcellruns=runscell_sesshemi{subi};
            end
            concrunnames='';
            allruns_subs=0;
            % Section: for-block starts
            % Section: for-block starts
            for runi = 1:length(curcellruns)
                cursession= curcellruns{runi,1};
                cursessdir= [p.pre filesep subs{subi} filesep cursession filesep 'func' filesep];
                currundir=[cursessdir filesep 'volumetric'];
                % Get scans
                fprintf('fMRI data folder: %s\n',currundir)
                runprefix=[subs{subi} '_' cursession '_task-' wf.task '_' curcellruns{runi,2}];
                fqry=[currundir filesep  runprefix '*' curhemi '.func_'];
                scanListing = dir( [fqry '*.nii'] );
                maskfndir=dir( [currundir filesep  runprefix '*' curhemi '.func_mask.nii'] );
                % Section: if-block starts
                % Section: if-block starts
                if isempty(scanListing)
                    warning(['Skipping: No scans for subject ' subs{subi} ' in run No. ' num2str(runi) ' in session No. ' num2str(si)]);
                    continue
                end
                maskfn=[currundir filesep maskfndir(1).name];
                nonmaskidx=~contains({scanListing.name}, maskfndir(1).name);
                scanListing=scanListing(nonmaskidx);
                scanInput = cell( length( scanListing ), 1 );
                for scanFile = 1 : length( scanListing )
                    curfiledir= dir([fqry num2str(scanFile) '.nii']);
                    scanInput{ scanFile }= [curfiledir(1).folder filesep curfiledir(1).name ',1'];
                    %scanInput{ scanFile }= [scanListing(1).folder filesep scanListing(scanFile).name];
                end
                %scans = sort( scanInput );
                concrunnames=[concrunnames strrep(curcellruns{runi,2},'run-','')];
                allruns_subs=allruns_subs+1;
                scans=scanInput(wf.volskip+1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).scans = scans;

                % Get realignment parameters
                % Section: switch-block starts
                % Section: switch-block starts

                        multiregFile = dir( [p.pre  filesep subs{subi} filesep cursession filesep 'func' filesep subs{subi} '_' cursession '_task-' wf.task '_' curcellruns{runi,2}  '*confounds.tsv' ] );
                        sessMultiregFile = [multiregFile.folder filesep multiregFile.name];
                        minregfn=strrep(sessMultiregFile,'confounds.tsv','confounds_min.txt');
                
                [confall, header, raw]=tsvread(sessMultiregFile);
                keep_cols = ismember(header, confnameopts{1});
                if sum(keep_cols)==0
                    confnames=confnameopts{2};
                    keep_cols = ismember(header, confnames);
                end
                conf_selected = confall(wf.volskip+2:end, keep_cols);
                assert(size(conf_selected,1) == numel(scans), ...
                    'Mismatch between nuisance rows and fMRI scans.');

                assert(all(isfinite(conf_selected(:))), ...
                    'Nuisance regressors contain NaN or Inf.');
                conf_selected=array2table(conf_selected, 'VariableNames', confnames);
                writetable(conf_selected, minregfn, 'WriteVariableNames', false, 'Delimiter', '\t');
                % Get Onsets
                % Section: switch-block starts
                % Section: switch-block starts
            
                        onsetstable = readtable([multiregFile.folder filesep runprefix '_events.xlsx']);
            
                condition_names=unique(onsetstable.trial_type);
                conData={};
                % Section: for-block starts
                % Section: for-block starts
                for ci=1:length(condition_names)
                    conData{ci}.tasks = onsetstable.trial_type(strcmp(onsetstable.trial_type,condition_names{ci}));
                    temp_onsets= onsetstable.onset(strcmp(onsetstable.trial_type,condition_names{ci}));
                   
                    if isa(onsetstable.onset(1),'char') | isa(onsetstable.onset(1),'cell')
                        temp_onsets=str2double(temp_onsets);
                    end
                    temp_durations=onsetstable.duration(strcmp(onsetstable.trial_type,condition_names{ci}));
                 
                    if isa(onsetstable.duration(1),'char') | isa(onsetstable.duration(1),'cell')
                        temp_durations=str2double(temp_durations);
                    end
                    conData{ci}.onsets=temp_onsets;
                    conData{ci}.durations = temp_durations;
                end
                % add session-specific infos
            
                for c = 1:length(condition_names)
                    matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).cond(c).name = conData{c}.tasks{1};
                    matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).cond(c).onset = conData{c}.onsets;
                    matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).cond(c).duration = conData{c}.durations;
                    matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).cond(c).tmod = 0;
                end
                matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).multi_reg = {minregfn};
                matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).regress = struct('name', {}, 'val', {});
                matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).hpf = 128;
            end

            matlabbatch{1}.spm.stats.fmri_spec.mask = {[maskfn  ',1']};
            matlabbatch{1}.spm.stats.fmri_spec.mthresh = 1;
            matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
            matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs  = HRFderivatives;
            matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
            outputsub=subs{subi};
            onsets='face';
            
            if wf.modelblackresponse==1
                onsets='faceblackresponse';
            end
            spmmatdir=[mainFolder filesep 'derivatives' filesep wf.glm filesep  outputsub filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth '_onsets-' onsets filesep ];
            mkdir(spmmatdir)
            matlabbatch{1}.spm.stats.fmri_spec.dir= { spmmatdir };

            matlabbatch{2}.spm.stats.fmri_est.spmmat = {[spmmatdir filesep 'SPM.mat']};
            matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
            matlabbatch{2}.spm.stats.fmri_est.write_residuals =wf.glmresiduals;
            matlabbatch{2}.spm_skip_maskthreshold=1;
           
            try mkdir(spmmatdir); end
            %save([spmmatdir '/matlabbatch'],'matlabbatch')
            
            spm_jobman( 'run', matlabbatch );
            compress_spm_residuals(spmmatdir, false, 0)
        end
    end
    % estimate model
end
end