function [spmmat, curhemimask, sessdifft, postcontrastt] = ...
    NCGP_LDt_Factorial( ...
        wf, preb_vols, prew_vols, postb_vols, postw_vols, ...
        maskname, curhemi)

% The four *_vols arguments are retained only to preserve the original
% function call. Input image names are intentionally hardcoded.

paths = NCGP_paths(wf);

outputfolder = [
    paths.mp ...
    'derivatives' filesep ...
    'LDC' filesep ...
    'group' filesep ...
    wf.pre filesep ...
    wf.glm filesep ...
    'hemi-' curhemi '_mask-' maskname filesep
];

mkdir(outputfolder);

spmmat = [outputfolder 'SPM.mat'];

if strcmp(maskname, 'none')
    curhemimask = '';
else
    curhemimaskdir = dir([
        paths.hpal ...
        wf.origsubs{1} filesep ...
        'ses-02' filesep ...
        'func' filesep ...
        'volumetric' filesep ...
        '*faces_run-01*' curhemi '.func_mask.nii'
    ]);

    curhemimask = fullfile( ...
        curhemimaskdir(1).folder, ...
        curhemimaskdir(1).name ...
    );
end


%% ------------------------------------------------------------------------
%  Hardcoded input images
%  Design-row order:
%
%   01-16: preB
%   17-28: preW
%   29-44: postB
%   45-56: postW
% -------------------------------------------------------------------------

preb = arrayfun( ...
    @(i) sprintf( ...
        '%spreb_mask-none_hemi-%s_%02d.nii,1', ...
        outputfolder, curhemi, i), ...
    (1:16)', ...
    'UniformOutput', false);

prew = arrayfun( ...
    @(i) sprintf( ...
        '%sprew_mask-none_hemi-%s_%02d.nii,1', ...
        outputfolder, curhemi, i), ...
    (1:12)', ...
    'UniformOutput', false);

postb = arrayfun( ...
    @(i) sprintf( ...
        '%spostb_mask-none_hemi-%s_%02d.nii,1', ...
        outputfolder, curhemi, i), ...
    (1:16)', ...
    'UniformOutput', false);

postw = arrayfun( ...
    @(i) sprintf( ...
        '%spostw_mask-none_hemi-%s_%02d.nii,1', ...
        outputfolder, curhemi, i), ...
    (1:12)', ...
    'UniformOutput', false);


%% ------------------------------------------------------------------------
%  SPM full-factorial design
% -------------------------------------------------------------------------

spm('defaults', 'fmri');
spm_jobman('initcfg');

clear matlabbatch

matlabbatch{1}.spm.stats.factorial_design.dir = {outputfolder};

matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name = 'Time';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).dept = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).ancova = 0;

matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).name = ...
    'Measurement';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).ancova = 0;

matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = [1 1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans = preb;

matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [1 2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans = prew;

matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [2 1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans = postb;

matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).levels = [2 2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).scans = postw;

matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 0;

matlabbatch{1}.spm.stats.factorial_design.cov = ...
    struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});

matlabbatch{1}.spm.stats.factorial_design.multi_cov = ...
    struct('files', {}, 'iCFI', {}, 'iCC', {});

matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {curhemimask};

matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

spm_jobman('run', matlabbatch);


%% ------------------------------------------------------------------------
%  Estimate the model
% -------------------------------------------------------------------------

clear matlabbatch

matlabbatch{1}.spm.stats.fmri_est.spmmat = {spmmat};
matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;

spm_jobman('run', matlabbatch);


%% ------------------------------------------------------------------------
%  Define both unthresholded contrasts
%
%  Column order:
%   1 = preB
%   2 = preW
%   3 = postB
%   4 = postW
% -------------------------------------------------------------------------

clear matlabbatch

matlabbatch{1}.spm.stats.con.spmmat = {spmmat};

matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'sessdiff';
matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = ...
    [-1 1 1 -1];
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'postcontrast';
matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = ...
    [0 0 1 -1];
matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

matlabbatch{1}.spm.stats.con.delete = 1;

spm_jobman('run', matlabbatch);

sessdifft = [outputfolder 'spmT_0001.nii'];
postcontrastt = [outputfolder 'spmT_0002.nii'];

NCGP_vol2surf(wf, sessdifft, outputfolder, curhemi, 'a');
NCGP_vol2surf(wf, postcontrastt, outputfolder, curhemi, 'a');


%% ------------------------------------------------------------------------
%  Explicit TFCE exchangeability blocks
% -------------------------------------------------------------------------

sessdiff_blocks_file = [
    outputfolder ...
    'exchangeability_blocks_sessdiff.txt'
];

postcontrast_blocks_file = [
    outputfolder ...
    'exchangeability_blocks_postcontrast.txt'
];

% Rows 01-16: preB units 01-16
% Rows 17-28: preW units 01-12, represented by labels 17-28
% Rows 29-44: postB units 01-16
% Rows 45-56: postW units 01-12, represented by labels 17-28
%
% Each label occurs exactly twice:
%   Between unit 01: preB_01 and postB_01
%   ...
%   Within unit 01: preW_01 and postW_01

sessdiff_blocks = [
    (1:16)'
    (17:28)'
    (1:16)'
    (17:28)'
];

writematrix( ...
    sessdiff_blocks, ...
    sessdiff_blocks_file, ...
    'Delimiter', 'tab');


% For postcontrast:
%   Pre rows receive singleton blocks and therefore remain fixed.
%   All 28 post rows receive label 1 and may be exchanged with each other.
%
% This tests postB versus postW without exchanging post observations
% with pre-intervention observations.

postcontrast_blocks = [
    (2:29)'
    ones(28, 1)
];

writematrix( ...
    postcontrast_blocks, ...
    postcontrast_blocks_file, ...
    'Delimiter', 'tab');


%% ------------------------------------------------------------------------
%  TFCE: sessdiff
% -------------------------------------------------------------------------

clear matlabbatch

matlabbatch{1}.spm.tools.tfce_estimate.data = {spmmat};
matlabbatch{1}.spm.tools.tfce_estimate.nproc = 0;
matlabbatch{1}.spm.tools.tfce_estimate.mask = {''};

matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr = ...
    'sessdiff';
matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts = 1;
matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm = 10000;

matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method = 2;
matlabbatch{1}.spm.tools.tfce_estimate.use_sequential_stopping = 0;
matlabbatch{1}.spm.tools.tfce_estimate.tbss = 0;

matlabbatch{1}.spm.tools.tfce_estimate.exch_blocks = ...
    {sessdiff_blocks_file};

spm_jobman('run', matlabbatch);


%% ------------------------------------------------------------------------
%  TFCE: postcontrast
% -------------------------------------------------------------------------

clear matlabbatch

matlabbatch{1}.spm.tools.tfce_estimate.data = {spmmat};
matlabbatch{1}.spm.tools.tfce_estimate.nproc = 0;
matlabbatch{1}.spm.tools.tfce_estimate.mask = {''};

matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr = ...
    'postcontrast';
matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts = 2;
matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm = 10000;

matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method = 2;
matlabbatch{1}.spm.tools.tfce_estimate.use_sequential_stopping = 0;
matlabbatch{1}.spm.tools.tfce_estimate.tbss = 0;

matlabbatch{1}.spm.tools.tfce_estimate.exch_blocks = ...
    {postcontrast_blocks_file};

spm_jobman('run', matlabbatch);

end