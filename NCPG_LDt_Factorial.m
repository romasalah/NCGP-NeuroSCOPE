% ==========================================================================
% Overall goal (user-provided): Overall goal: Hardcodes a factorial design made of 16 between subject distance images and 12 within subject distance images for before and after the intervention (so 12 x 2 + 16 x 2 images). The factorial design is used later to estimate a TFCE model
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Hardcodes a factorial design made of 16 between subject distance images and 12 within subject distance images for before and after the intervention (so 12 x 2 + 16 x 2 images). The factorial design is used later to estimate a TFCE model
% Note:
% ==========================================================================
% Function signature detected
function [spmmat, curhemimask, sessdifft, postcontrastt]=NCPG_LDt_Factorial(wf,preb_vols,prew_vols,postb_vols,postw_vols,maskname,curhemi )
% Call → NCPG_paths
paths=NCPG_paths(wf);
outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
curhemimaskdir=dir([paths.hpal wf.origsubs{1} filesep 'ses-02' filesep 'func' filesep 'volumetric' filesep '*faces_run-01*' curhemi '.func_mask.nii']);
curhemimask=[curhemimaskdir.folder filesep curhemimaskdir.name];
curpreb_vols=strrep(preb_vols,'.nii','.nii,1');
curprew_vols=strrep(prew_vols,'.nii','.nii,1');
curpostb_vols=strrep(postb_vols,'.nii','.nii,1');
curpostw_vols=strrep(postw_vols,'.nii','.nii,1');
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
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans = {[ outputfolder 'preb_mask-none_hemi-' curhemi '_01.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_02.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_03.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_04.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_05.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_06.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_07.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_08.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_09.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_10.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_11.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_12.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_13.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_14.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_15.nii,1']
    [ outputfolder 'preb_mask-none_hemi-' curhemi '_16.nii,1']
    };
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [2
    1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans = {[ outputfolder 'postb_mask-none_hemi-' curhemi '_01.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_02.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_03.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_04.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_05.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_06.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_07.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_08.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_09.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_10.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_11.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_12.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_13.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_14.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_15.nii,1']
    [ outputfolder 'postb_mask-none_hemi-' curhemi '_16.nii,1']
    };
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [1
    2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans = {[ outputfolder 'prew_mask-none_hemi-' curhemi '_01.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_02.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_03.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_04.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_05.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_06.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_07.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_08.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_09.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_10.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_11.nii,1']
    [ outputfolder 'prew_mask-none_hemi-' curhemi '_12.nii,1']
    };
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).levels = [2
    2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).scans = {[ outputfolder 'postw_mask-none_hemi-' curhemi '_01.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_02.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_03.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_04.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_05.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_06.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_07.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_08.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_09.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_10.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_11.nii,1']
    [ outputfolder 'postw_mask-none_hemi-' curhemi '_12.nii,1']
    };
%%
matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 0;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {curhemimask};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = {[outputfolder 'SPM.mat']};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'sessdiff';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [-1 1 1 -1];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;
matlabbatch{4}.spm.stats.results.spmmat = {[outputfolder 'SPM.mat']};
matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
matlabbatch{4}.spm.stats.results.conspec.threshdesc = maskname;
matlabbatch{4}.spm.stats.results.conspec.thresh = 0.05;
matlabbatch{4}.spm.stats.results.conspec.extent = 0;
matlabbatch{4}.spm.stats.results.conspec.mask.image.name = {curhemimask};
matlabbatch{4}.spm.stats.results.conspec.mask.image.mtype = 0;
matlabbatch{4}.spm.stats.results.units = 1;
matlabbatch{4}.spm.stats.results.export{1}.tspm.basename = 'sessdiff';
save([outputfolder 'matlabbatch.mat'],'matlabbatch');
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
clear matlabbatch
matlabbatch{1}.spm.stats.con.spmmat(1) = {[outputfolder 'SPM.mat']};
matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'postcontrast';
matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 0 1 -1];
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{2}.spm.stats.results.spmmat = {[outputfolder 'SPM.mat']};
matlabbatch{2}.spm.stats.results.conspec.contrasts = 2;
matlabbatch{2}.spm.stats.results.conspec.threshdesc = maskname;
matlabbatch{2}.spm.stats.results.conspec.thresh = 0.05;
matlabbatch{2}.spm.stats.results.conspec.extent = 0;
matlabbatch{2}.spm.stats.results.conspec.mask.image.name = {curhemimask};
matlabbatch{2}.spm.stats.results.conspec.mask.image.mtype = 0;
matlabbatch{2}.spm.stats.results.units = 1;
matlabbatch{2}.spm.stats.results.export{1}.tspm.basename = 'postcontrast';
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
sessdifft=[outputfolder 'spmT_0001_sessdiff.nii'];
postcontrastt=[outputfolder 'spmT_0002_postcontrast.nii'];
% Call → NCPG_vol2surf
NCPG_vol2surf(wf, sessdifft, outputfolder, curhemi, 'a');
% Call → NCPG_vol2surf
NCPG_vol2surf(wf, postcontrastt, outputfolder, curhemi, 'a');
spmmat=[outputfolder 'SPM.mat'];
end
