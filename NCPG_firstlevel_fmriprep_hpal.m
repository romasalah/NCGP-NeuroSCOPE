% ==========================================================================
% Overall goal: Run first-level GLM on fMRIPrep outputs with hyperalignment confounds/settings (6 DOF + aCompCor).
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function firstleveldir=NCPG_firstlevel_fmriprep_hpal(wf, HRFderivatives, runscell_sesshemi)
%% FFX batch code for SocialDecision experiments Summer 2017
% O. S. Ahmed based on J Schultz based on code by Paul Jung
% ----------- Main settings -----------------------------------------------
TR = wf.TR;
sessions=wf.sessions;
    Nses=length(sessions);
mainFolder=wf.mainpath;
subs=wf.subs;
confnames1={'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z',...
    'a_comp_cor_00', 'a_comp_cor_01', 'a_comp_cor_02', 'a_comp_cor_03', 'a_comp_cor_04', 'a_comp_cor_05'};
confnames2={'X', 'Y', 'Z', 'RotX', 'RotY', 'RotZ',...
    'aCompCor00', 'aCompCor01', 'aCompCor02', 'aCompCor03', 'aCompCor04', 'aCompCor05'};
confnameopts={confnames1, confnames2};
confnames=confnameopts{1};
hemis=wf.hemis;
%% Setup finished, get to work
% Section: for-block starts
for si=1:Nses
    cursession=sessions{si};
% Section: for-block starts
    for hi=1:length(hemis)
        curhemi=hemis{hi};
        allruns_subs=0;
        scanInput={};
        sessMultiregFile={};
        matlabbatch={};
        regs={};
% Section: for-block starts
        for subi=1:length(subs)
            curcellruns=runscell_sesshemi{si,hi}{subi};
            concrunnames='';
% Section: for-block starts
            for runi = 1:length(curcellruns)
                cursession= curcellruns{runi,1};
                currun= curcellruns{runi,2};
                cursessdir= [mainFolder filesep wf.pre filesep subs{subi} filesep cursession filesep 'func' filesep];
                currundir=[cursessdir filesep 'temp'];
                % Get scans
                fprintf('fMRI data folder: %s\n',currundir)
                runprefix=[subs{subi} '_' cursession '_task-' wf.task '_' currun];
                fqry=[currundir filesep  runprefix '*' curhemi '.func_'];
                scanListing = dir( [fqry '*.nii'] );
                maskfndir_unsmoothed=dir( [currundir filesep  runprefix '*' curhemi '.func_mask.nii'] );
                maskfn_unsmoothed=[currundir filesep maskfndir_unsmoothed(1).name];
% Section: if-block starts
                if isempty(scanListing)
                    warning(['Skipping: No scans for subject ' subs{subi} ' in run No. ' num2str(runi) ' in session No. ' num2str(si)]);
                    continue
                end
% Section: if-block starts
                if ~isempty(maskfndir_unsmoothed)
                    nonmaskidx=~contains({scanListing.name}, 'mask');
                    scanListing=scanListing(nonmaskidx);
                end
                scanInput = cell( length( scanListing ), 1 );
% Section: for-block starts
                for scanFile = 1 : length( scanListing )
                    curfiledir= dir([fqry num2str(scanFile) '.nii']);
                    scanInput{ scanFile }= [curfiledir(1).folder filesep curfiledir(1).name ',1'];
                    %scanInput{ scanFile }= [scanListing(1).folder filesep scanListing(scanFile).name];
                end
                %scans = sort( scanInput );
                concrunnames=[concrunnames strrep(currun,'run-','')];
                allruns_subs=allruns_subs+1;
                scans=scanInput(wf.volskip+1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(allruns_subs).scans = scans;

                % Get realignment parameters
% Section: switch-block starts
                switch wf.exp
% Section: case-block starts
                    case 'NCGP'
                        multiregFile = dir( [cursessdir  filesep subs{subi} '_' cursession '_task-' wf.task '_' currun  '*confounds.tsv' ] );
                        sessMultiregFile = [cursessdir filesep multiregFile.name];
                        minregfn=strrep(sessMultiregFile,'confounds.tsv','confounds_min.txt');
% Section: case-block starts
                    case 'Castello'
                        multiregFile = dir( [cursessdir  filesep subs{subi} '_' cursession '_task-' wf.task '_' currun '*confounds.tsv' ] );
                        sessMultiregFile = [cursessdir filesep multiregFile.name];
                        minregfn=strrep(sessMultiregFile,'confounds.tsv','confounds_min.txt');
% Section: case-block starts
                    case 'Castellonew'
                        multiregFile = dir( [cursessdir  filesep subs{subi} '_' cursession '_task-' wf.task '_' currun  '*confounds.tsv' ] );
                        sessMultiregFile = [cursessdir filesep multiregFile.name];
                        minregfn=strrep(sessMultiregFile,'confounds.tsv','confounds_min.txt');
                end
                [confall, header, raw]=tsvread(sessMultiregFile);
                keep_cols = ismember(header, confnameopts{1});
% Section: if-block starts
                if sum(keep_cols)==0
                    confnames=confnameopts{2};
                    keep_cols = ismember(header, confnames);
                end
                conf_selected = confall(2:end, keep_cols);
                conf_selected=array2table(conf_selected, 'VariableNames', confnames);
                writetable(conf_selected, minregfn, 'WriteVariableNames', false, 'Delimiter', '\t');
                % Get Onsets
% Section: switch-block starts
                switch wf.exp
% Section: case-block starts
                    case 'NCGP'
                        onsetstable = readtable([cursessdir filesep runprefix '_events.xlsx']);
% Section: case-block starts
                    case 'Castello'
                        datasessdir= [mainFolder filesep 'data' filesep subs{subi} filesep cursession filesep 'func' filesep];
                        [~, header, onsetstableraw] = tsvread([datasessdir filesep runprefix '_events.tsv']);
                        onsetstable=array2table(onsetstableraw(2:end,:), "VariableNames",header);
                        %onsetstable.trial_type=onsetstable.stim_type;
% Section: case-block starts
                    case 'Castellonew'
                        datasessdir= [mainFolder filesep 'data' filesep subs{subi} filesep cursession filesep 'func' filesep];
                        [~, header, onsetstableraw] = tsvread([datasessdir filesep runprefix '_events.tsv']);
                        onsetstable=array2table(onsetstableraw(2:end,:), "VariableNames",{'onset', 'duration', 'trial_type'});
                        %onsetstable.trial_type=onsetstable.stim_type;
                end
                condition_names=unique(onsetstable.trial_type);
                conData={};
% Section: for-block starts
                for ci=1:length(condition_names)
                    conData{ci}.tasks = onsetstable.trial_type(strcmp(onsetstable.trial_type,condition_names{ci}));
                    temp_onsets= onsetstable.onset(strcmp(onsetstable.trial_type,condition_names{ci}));
% Section: if-block starts
                    if isa(onsetstable.onset(1),'char') | isa(onsetstable.onset(1),'cell')
                        temp_onsets=str2double(temp_onsets);
                    end
                    temp_durations=onsetstable.duration(strcmp(onsetstable.trial_type,condition_names{ci}));
% Section: if-block starts
                    if isa(onsetstable.duration(1),'char') | isa(onsetstable.duration(1),'cell')
                        temp_durations=str2double(temp_durations);
                    end
                    conData{ci}.onsets=temp_onsets;
                    conData{ci}.durations = temp_durations;
                end
                % add session-specific infos
% Section: for-block starts
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
            matlabbatch{1}.spm.stats.fmri_spec.mask = {[maskfn_unsmoothed  ',1']};
            matlabbatch{1}.spm.stats.fmri_spec.mthresh = 1;
            matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
            matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs  = HRFderivatives;
            matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
            spmmatdir=[mainFolder filesep  wf.alignment filesep wf.glm filesep  subs{subi} filesep wf.pre filesep  'task-' wf.task '_' cursession '_hemi-' curhemi '_smooth-' wf.smooth filesep];
            mkdir(spmmatdir)
            matlabbatch{1}.spm.stats.fmri_spec.dir= { spmmatdir };
            matlabbatch{2}.spm.stats.fmri_est.spmmat = {[spmmatdir filesep 'SPM.mat']};
            matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
            matlabbatch{2}.spm.stats.fmri_est.write_residuals =wf.glmresiduals;
            matlabbatch{2}.spm_skip_maskthreshold=1;
% Section: try-block starts
            try mkdir(spmmatdir); end
            %save([spmmatdir '/matlabbatch'],'matlabbatch')
% Toolbox call → spm_jobman
            spm_jobman( 'run', matlabbatch );
        end
    end
    % estimate model
end
end
