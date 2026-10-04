% ==========================================================================
% Overall goal (user-provided): Overall goal: Uses SPM batch system to calculate a Faces-versus-objects contrast to find selectively face sensitive regions. It uses volumetric preprocessed images coming from fmriprep preprocessing.
% ==========================================================================
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
p=NCGP_paths(wf);
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
confnames={'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z',...
    'a_comp_cor_00', 'a_comp_cor_01', 'a_comp_cor_02', 'a_comp_cor_03', 'a_comp_cor_04', 'a_comp_cor_05'};
%% Setup finished, get to work
% Section: for-block starts
    % Section: if-block starts
 for  hi =1:length(wf.hemis)
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
        % ================== CONTRASTS ===========================
        % Section: case-block starts
        % set the contrasts for each subject depending on the conditions available
        % first, determine for each contrast if the necessary conditions
        % have onsets
        spmmatdir = [p.mp filesep 'derivatives' filesep wf.glm filesep 'group' filesep wf.pre filesep 'task-' wf.task '_hemi-' wf.hemis{hi} '_smooth-' wf.smooth filesep];
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
    end 
 end
end