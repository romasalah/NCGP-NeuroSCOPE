% Overall goal: Hardcodes a factorial design made of 16 between subject distance
% images and 12 within subject distance images for before and after the intervention
% (so 12 x 2 + 16 x 2 images). The factorial design is used later to estimate a TFCE model
function [spmmat, curhemimask, sessdifft, postcontrastt]=NCGP_LDt_Factorial(wf,preb_vols,prew_vols,postb_vols,postw_vols,maskname,curhemi, conname )
% Call → NCGP_paths
paths=NCGP_paths(wf);
inputfolder= [paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname '_' conname filesep];
try; mkdir(outputfolder); end
switch conname
    case 'sessdiff'
        % Exchangeability blocks for the sessdiff contrast.
        %
        % Block 1  = preB_01 + postB_01
        % Block 2  = preB_02 + postB_02
        % ...
        % Block 16 = preB_16 + postB_16
        %
        % Block 17 = preW_01 + postW_01
        % ...
        % Block 28 = preW_12 + postW_12

        sessdiff_blocks = [ ...
            1:16, ...   % preB
            17:28, ...   % preW
            1:16, ...   % postB
            17:28  ...   % postW
            ]';

        sessdiff_blocks_file = [outputfolder 'exchangeability_blocks_sessdiff.txt'];

        writematrix(sessdiff_blocks, sessdiff_blocks_file);
    case 'postcontrast'
end
curhemimaskdir=dir([paths.hpal wf.origsubs{1} filesep 'ses-02' filesep 'func' filesep 'volumetric' filesep '*faces_run-01*' curhemi '.func_mask.nii']);
if strcmp(maskname,'none')
    curhemimask='';
else
    curhemimask=[curhemimaskdir.folder filesep curhemimaskdir.name];
end
curpreb_vols=strrep(preb_vols,'.nii','.gii');
curprew_vols=strrep(prew_vols,'.nii','.gii');
curpostb_vols=strrep(postb_vols,'.nii','.gii');
curpostw_vols=strrep(postw_vols,'.nii','.gii');
%%
spm( 'defaults', 'fmri' );
% Toolbox call → spm_jobman
spm_jobman( 'initcfg' );
clear matlabbatch
matlabbatch{1}.spm.stats.factorial_design.dir = {outputfolder};
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name = 'Time';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).dept = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).name = 'Measurement';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = [1
    1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans = {[ inputfolder 'preb_mask-none_hemi-' curhemi '_01.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_02.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_03.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_04.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_05.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_06.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_07.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_08.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_09.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_10.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_11.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_12.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_13.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_14.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_15.gii']
    [ inputfolder 'preb_mask-none_hemi-' curhemi '_16.gii']
    };
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [2
    1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans = {[ inputfolder 'postb_mask-none_hemi-' curhemi '_01.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_02.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_03.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_04.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_05.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_06.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_07.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_08.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_09.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_10.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_11.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_12.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_13.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_14.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_15.gii']
    [ inputfolder 'postb_mask-none_hemi-' curhemi '_16.gii']
    };
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [1
    2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans = {[ inputfolder 'prew_mask-none_hemi-' curhemi '_01.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_02.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_03.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_04.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_05.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_06.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_07.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_08.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_09.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_10.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_11.gii']
    [ inputfolder 'prew_mask-none_hemi-' curhemi '_12.gii']
    };
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).levels = [2
    2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).scans = {[ inputfolder 'postw_mask-none_hemi-' curhemi '_01.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_02.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_03.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_04.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_05.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_06.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_07.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_08.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_09.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_10.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_11.gii']
    [ inputfolder 'postw_mask-none_hemi-' curhemi '_12.gii']
    };
%%

matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 0;

matlabbatch{1}.spm.stats.factorial_design.cov = ...
    struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});

matlabbatch{1}.spm.stats.factorial_design.multi_cov = ...
    struct('files', {}, 'iCFI', {}, 'iCC', {});

% No threshold masking
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;

% Do NOT treat zero as missing
matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;

% No explicit mask
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};

% Do not calculate global values
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
% No grand mean scaling
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;

% No global normalization
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
switch conname
    case 'sessdiff'
        % Contrast is defined below after model estimation.
        matlabbatch{3}.spm.stats.con.spmmat(1) = {[outputfolder 'SPM.mat']};
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'sessdiff';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [-1 1 1 -1];
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.delete = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {[outputfolder 'SPM.mat']};
        matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
        matlabbatch{4}.spm.stats.results.conspec.thresh = 0.05;
        matlabbatch{4}.spm.stats.results.conspec.extent = 0;
        matlabbatch{4}.spm.stats.results.units = 1;
        matlabbatch{4}.spm.stats.results.export{1}.tspm.basename = 'sessdiff';
        matlabbatch{4}.spm.stats.results.conspec.mask.image.name = {''};
        if ~strcmp(maskname,'none')
            matlabbatch{4}.spm.stats.results.conspec.threshdesc = maskname;
            matlabbatch{4}.spm.stats.results.conspec.mask.image.name = {curhemimask};
            matlabbatch{4}.spm.stats.results.conspec.mask.image.mtype = 0;
        end
        save([outputfolder 'matlabbatch.mat'],'matlabbatch');
        % Toolbox call → spm_jobman
        spm_jobman( 'run', matlabbatch );
        % sessdifft=[outputfolder 'con_0001_sessdiff.nii'];
        % Call → NCGP_vol2surf
        %NCGP_vol2surf(wf, sessdifft, outputfolder, curhemi, 'a');
    case 'postcontrast'
        %clear matlabbatch
        matlabbatch{3}.spm.stats.con.spmmat(1) = {[outputfolder 'SPM.mat']};
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'postcontrast';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 0 1 -1];
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.delete = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {[outputfolder 'SPM.mat']};
        matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
        matlabbatch{4}.spm.stats.results.conspec.thresh = 0.05;
        matlabbatch{4}.spm.stats.results.conspec.extent = 0;
        matlabbatch{4}.spm.stats.results.units = 1;
        matlabbatch{4}.spm.stats.results.export{1}.tspm.basename = 'postcontrast';
        matlabbatch{4}.spm.stats.results.conspec.mask.image.name = {''};
        if ~strcmp(maskname,'none')
            matlabbatch{4}.spm.stats.results.conspec.threshdesc = maskname;
            matlabbatch{4}.spm.stats.results.conspec.mask.image.name = {curhemimask};
            matlabbatch{4}.spm.stats.results.conspec.mask.image.mtype = 0;
        end
        % Toolbox call → spm_jobman
        spm_jobman( 'run', matlabbatch );
        % postcontrastt=[outputfolder 'con_0002_postcontrast.nii'];
        % Call → NCGP_vol2surf
       % NCGP_vol2surf(wf, postcontrastt, outputfolder, curhemi, 'a');
end
        spmmat=[outputfolder 'SPM.mat'];
end
