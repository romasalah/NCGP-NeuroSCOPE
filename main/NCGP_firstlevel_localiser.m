% ==========================================================================
% Overall goal (user-provided): Overall goal: Uses SPM batch system to calculate a Faces-versus-objects contrast to find selectively face sensitive regions. It uses volumetric preprocessed images coming from fmriprep preprocessing.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Uses SPM batch system to calculate a Faces-versus-objects contrast to find selectively face sensitive regions. It uses volumetric preprocessed images coming from fmriprep preprocessing.
% Note:
% ==========================================================================
% Function signature detected
function [spmmatdir,conimgname,cons]=NCGP_firstlevel_localiser(jobs,wf,HRFderivatives,threshold,mink)
% ----------- Main settings -----------------------------------------------
spmmatdir='';
conimgname='';
conlenbase=[0 2 0 -1 -1 0 0];
runBatch = 1;
% Section: if-block starts
if wf.normalise==1
    prefix='sw';
% Section: else-block starts
else
    prefix='s';
end
TR = 2.5;
persons = wf.subs;
sessions=wf.sessions;
runs=wf.runs;
exreg=zeros(1,6);
fullcon=[];
constvec=zeros(1,length(wf.runs));
% Section: for-block starts
for i=1:length(conlenbase)
    fullcon = [fullcon conlenbase(i) zeros(1, sum(HRFderivatives))];
end
% Section: if-block starts
if length(runs)==4
    cons{1,2} = [fullcon exreg fullcon exreg fullcon exreg fullcon exreg constvec];
% Section: elseif-block starts
elseif length(runs)==2
    cons{1,2} = [fullcon exreg fullcon exreg constvec];
end
cons{1,1} = ['Faces >  Objects_Scenes' ];


Nrun=length(runs);
Nses=length(wf.sessions);
confnames={'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z',...
    'a_comp_cor_00', 'a_comp_cor_01', 'a_comp_cor_02', 'a_comp_cor_03', 'a_comp_cor_04', 'a_comp_cor_05'};

%% Setup finished, get to work
% Section: for-block starts
for tt = 1:length(jobs)
    %reportFile = [codeDir '.txt'];
    doWhat = jobs{tt};
% Section: if-block starts
    if runBatch
        spm( 'defaults', 'fmri' );
% Toolbox call → spm_jobman
        spm_jobman( 'initcfg' );
    end
    
    counter = 0;
% Section: for-block starts
    for person_i = 1 : length( persons )
        % determine person name
        subjName = persons{person_i};
        fprintf('Doing subject: %s\n',subjName)
        counter = counter + 1;
% Section: switch-block starts
        switch doWhat
            
            
% Section: case-block starts
            case 'FFXspecAndEst'
% Call → NCGP_preprocess_normalise
                NCGP_preprocess_normalise(wf,[2 2 3], subjName)
% Call → NCGP_preprocess_smooth
                NCGP_preprocess_smooth(wf, [6 6 6], subjName)
                % ------------ for each run type: ------------------
                clear scanInput sessMultiFile sessMultiregFile matlabbatch sessionData regs
                matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
                matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs  = HRFderivatives;
                matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
                matlabbatch{1}.spm.stats.fmri_spec.mask= {''};
                matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
                matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
                matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
                matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
                
                matname='';
                runcounter=0;
% Section: for-block starts
                for si=1:Nses
                    cursessname=sessions{si};
                    matname=[matname '_' cursessname];
% Section: for-block starts
                    for runi = 1:Nrun
                        matname=[matname '_' runs{runi}];
                        runcounter=runcounter+1;
                        cursessdir=[wf.mainpath filesep 'fmriprep' filesep subjName filesep sessions{si} filesep 'func' filesep];
                        currundir{runcounter} = [ cursessdir filesep runs{runi}];
                        % matlabbatch basics
                        matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).regress = struct('name', {}, 'val', {});
                        matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).hpf = 128;
                        % Get scans
                        %scanListing = dir( [currundir{runcounter} filesep imgType '*.nii'] );
                        scanListing = dir( [currundir{runcounter} filesep prefix subjName '*' wf.task '_' runs{runi} '*_space-T1w_desc-preproc_bold_00*.nii'] );
                        scanInput = cell( length( scanListing ), 1 );
% Section: for-block starts
                        for scanFile = 1 : length( scanListing )
                            scanInput{ scanFile }= [scanListing(1).folder filesep scanListing(scanFile).name ',1'];
                        end
                        %scans{runcounter} = sort( scanInput );
                        scans{runcounter}=scanInput(wf.volskip+1:end);
                        matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).scans = scans{runcounter};
                        % Get realignment parameters
                        multiregFile = dir( [cursessdir  filesep subjName '_' sessions{si} '_task-' wf.task '_' runs{runi}  '*confounds.tsv' ] );
                        sessMultiregFile = [cursessdir filesep multiregFile.name];
                        [confall, header, raw]=tsvread(sessMultiregFile);
                        
                        keep_cols = ismember(header, confnames);
                        minregfn=strrep(sessMultiregFile,'confounds.tsv','confounds_min.txt');
                        conf_selected = confall(wf.volskip+2:end, keep_cols);
                        writematrix(conf_selected, minregfn, 'Delimiter', '\t');
                        matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).multi_reg = {minregfn};
                        % Get Onsets
                        [~,~,onsetstable] = tsvread([cursessdir  filesep subjName '_' sessions{si} '_task-' wf.task '_' runs{runi} '_events.tsv']);
                        onsetstable=array2table(onsetstable(2:end,:),'VariableNames',onsetstable(1,:));
                        condition_names=unique(onsetstable.trial_type);
                        %condition_names=condition_names(~contains(condition_names,'Thumb'));
% Section: for-block starts
                        for ci=1:length(condition_names)
                            conData{si,runi}{ci}.tasks = onsetstable.trial_type(strcmp(onsetstable.trial_type,condition_names{ci}));
                            conData{si,runi}{ci}.onsets= str2double(onsetstable.onset(strcmp(onsetstable.trial_type,condition_names{ci})));
                            conData{si,runi}{ci}.durations = str2double(onsetstable.duration(strcmp(onsetstable.trial_type,condition_names{ci})));
                        end
% Section: for-block starts
                        for c = 1:length(condition_names)
                            matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).cond(c).name = conData{si,runi}{c}.tasks{1};
                            matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).cond(c).onset = conData{si,runi}{c}.onsets;
                            matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).cond(c).duration = conData{si,runi}{c}.durations;
                            matlabbatch{1}.spm.stats.fmri_spec.sess(runcounter).cond(c).tmod = 0;
                        end
                    end
                end
                spmmatdir=[wf.mainpath filesep 'aal' filesep wf.glm filesep wf.pre filesep subjName filesep matname(2:end)];
                mkdir(spmmatdir);
                matlabbatch{1}.spm.stats.fmri_spec.dir = { spmmatdir };
% Section: try-block starts
                try mkdir(spmmatdir); end
                % estimate model
                save([spmmatdir '/matlabbatch'],'matlabbatch')
% Toolbox call → spm_jobman
                spm_jobman( 'run', matlabbatch );
                clear  matlabbatch
                spmmat=[spmmatdir filesep 'SPM.mat'];
                matlabbatch{1}.spm.stats.fmri_est.spmmat = {spmmat};
                loadedspmmat=load(spmmat);
                loadedspmmat.SPM.spm_skip_maskthreshold= 0;
                SPM=loadedspmmat.SPM;
                save(spmmat, 'SPM')
                matlabbatch{1}.spm.stats.fmri_est.write_residuals = 1;
                matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
% Toolbox call → spm_jobman
                spm_jobman( 'run', matlabbatch );
                % ================== CONTRASTS ===========================
% Section: case-block starts
            case 'contrasts'
                % set the contrasts for each subject depending on the conditions available
                % first, determine for each contrast if the necessary conditions
                % have onsets
                spmmatdir = [wf.mainpath filesep wf.alignment filesep wf.glm filesep subjName filesep wf.pre filesep wf.modeltype filesep];
                % create contrast image
                disp(['Running contrast: ' cons{1,1}])
                clear matlabbatch;
                matlabbatch{1}.spm.stats.con.spmmat = { [spmmatdir 'SPM.mat'] };
                matlabbatch{1}.spm.stats.con.delete = 1;
% Section: for-block starts
                for ci=1:size(cons,1)
                    matlabbatch{1}.spm.stats.con.consess{ci}.tcon.name = cons{ci,1};
                    matlabbatch{1}.spm.stats.con.consess{ci}.tcon.convec = cons{ci,2};
                    matlabbatch{1}.spm.stats.con.consess{ci}.tcon.sessrep = 'none';
                end
                matlabbatch{1}.spm.stats.results.spmmat = { [spmmatdir 'SPM.mat'] };
% Toolbox call → spm_jobman
                spm_jobman( 'run', matlabbatch );
                % create threasholded t-map image
% Section: for-block starts
                for ci=1:size(cons,1)
                    clear matlabbatch;
                    conimgname=[ 'spmT_0001_' cons{ci,1} '.nii'];
                    cc=dir([spmmatdir 'spmT*' cons{ci,1} '*.nii']);
% Section: for-block starts
                    for i=1:size(cc,1)
                        delete([cc(1).folder filesep cc(i).name]);
                    end
                    matlabbatch{1}.spm.stats.results.spmmat = { [spmmatdir 'SPM.mat']};
                    matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
                    matlabbatch{1}.spm.stats.results.conspec.contrasts =ci;
                    matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
                    matlabbatch{1}.spm.stats.results.conspec.thresh = threshold;
                    matlabbatch{1}.spm.stats.results.conspec.extent = mink;
                    matlabbatch{1}.spm.stats.results.units = 1;
                    matlabbatch{1}.spm.stats.results.print = true;
                    matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
                    matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
                    matlabbatch{1}.spm.stats.results.units = 1;
                    matlabbatch{1}.spm.stats.results.export{1}.nary.basename = [ cons{ci,1}];
% Toolbox call → spm_jobman
                    spm_jobman( 'run', matlabbatch );
                end
                % each con
        end % doWhat
    end % fuer alle Probanden
end % tasks
end
