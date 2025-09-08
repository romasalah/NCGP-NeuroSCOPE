% ==========================================================================
% Overall goal (user-provided): Overall goal: unzips and unpacks a 4D NIFTI image after fmriprep preprocessing
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: unzips and unpacks a 4D NIFTI image after fmriprep preprocessing
% Note:
% ==========================================================================
% Function signature detected
function NCPG_unpack4D(wf,cursub)
mainFolder=[wf.mainpath filesep];
subs=wf.subs;
sessions=wf.sessions;
runs=wf.runs;
task=wf.task;
%% unpack images
% Section: for-block starts
for si =1:length(sessions)
    cursesfolder= [mainFolder filesep wf.pre filesep cursub filesep sessions{si} filesep 'func'];
% Section: for-block starts
    for ri =1:length(runs)
        currundir=[cursesfolder filesep 'task-' wf.task '_' runs{ri}];
        mkdir(currundir)
        flist=dir([cursesfolder filesep cursub '_' sessions{si} '_task-' task '_' runs{ri} '*preproc.nii.gz']);
% Section: if-block starts
        if ~isempty(flist)
        flist=[flist(1).folder filesep flist(1).name];
        unzippedfn=strrep(flist,'.gz','');
        gunzip(flist);
        clear matlabbatch
        matlabbatch{1}.spm.util.split.vol = {unzippedfn};
        matlabbatch{1}.spm.util.split.outdir = {currundir};
% Toolbox call → spm_jobman
        spm_jobman( 'run', matlabbatch );
% Section: else-block starts
        else
            disp([cursub ', ' sessions{si}  ' doesn''t have ' task ' runs' ]);
        end
    end
end
end
