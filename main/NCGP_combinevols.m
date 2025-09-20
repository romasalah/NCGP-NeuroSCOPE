% ==========================================================================
% Overall goal (user-provided): Overall goal: Uses SPM Batch to combines right and left volumes containing only surface based voxels into one volume only with surface voxels.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Uses SPM Batch to combines right and left volumes containing only surface based voxels into one volume only with surface voxels.
% Note: 
% ==========================================================================
% Function signature detected
function NCGP_combinevols(wf)
subs=wf.subs;
sessions=wf.sessions;
runs=wf.runs;
% Section: for-block starts
for subi=1:length(subs)
% Section: for-block starts
    for si=1:length(sessions)
        dsetfolder= [wf.mainpath filesep wf.pre filesep subs{subi} filesep sessions{si} filesep 'func' filesep 'temp' filesep];
        cursesfolder= [wf.mainpath filesep wf.pre filesep subs{subi} filesep sessions{si} filesep 'func' filesep];

% Section: for-block starts
        for runi =1:length(runs)
            runprefix=[subs{subi} '_' sessions{si} '_task-' wf.task '_' runs{runi}];
            filelist= dir([dsetfolder filesep runprefix '*.R.*.nii']);
% Section: for-block starts
            for i=1:length(filelist)
                rtfn=[filelist(i).folder filesep filelist(i).name];
                ltfn=strrep(rtfn, 'R', 'L');
                clear matlabbatch
                matlabbatch{1}.spm.util.imcalc.input =cellstr( vertcat([rtfn ',1'], [ltfn ',1']));
                matlabbatch{1}.spm.util.imcalc.output = strrep(rtfn,'R','B');
                matlabbatch{1}.spm.util.imcalc.outdir = {filelist(i).folder};
                matlabbatch{1}.spm.util.imcalc.expression = 'i1+i2';
                matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
                matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
                matlabbatch{1}.spm.util.imcalc.options.mask = 0;
                matlabbatch{1}.spm.util.imcalc.options.interp = 1;
% Toolbox call → spm_jobman
                spm_jobman( 'run', matlabbatch );
                delete(rtfn);
                delete(ltfn);
            end
                rtmaskdir= dir([cursesfolder filesep runprefix '*.R.func_mask.nii']);
                rtmaskfn=[cursesfolder filesep rtmaskdir(1).name];
                ltmaskfn=strrep(rtmaskfn, 'R', 'L');
                clear matlabbatch
                matlabbatch{1}.spm.util.imcalc.input =cellstr( vertcat([rtmaskfn ',1'], [ltmaskfn ',1']));
                matlabbatch{1}.spm.util.imcalc.output = strrep(rtmaskfn,'R','B');
                matlabbatch{1}.spm.util.imcalc.outdir = {cursesfolder};
                matlabbatch{1}.spm.util.imcalc.expression = 'i1+i2';
                matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
                matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
                matlabbatch{1}.spm.util.imcalc.options.mask = 0;
                matlabbatch{1}.spm.util.imcalc.options.interp = 1;
% Toolbox call → spm_jobman
                spm_jobman( 'run', matlabbatch );
        end
    end
end
end
