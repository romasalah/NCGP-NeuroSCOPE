% ==========================================================================
% Overall goal (user-provided): Overall goal: Hypothesis 2, converts the resulting TFCE-corrected volumes for hypothesis 2 first and second t-tests and the intersection between the two t-tests. the first t-test is session difference and the second t-test is post-interventional difference between the average between-group distaance and the average wirhin-group distance.
% ==========================================================================
function signodes=NCGP_LDt_TFCE_vol2surf(wf, maskname, curhemi)
% Call → NCGP_paths
paths=NCGP_paths(wf);
sessdiffimg='spmT_0001_sessdiff.nii';
postcontrastimg='spmT_0002_postcontrast.nii';
curspmdir=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
sessdifft=[curspmdir sessdiffimg];
postcontrastt=[curspmdir postcontrastimg];
clear matlabbatch
matlabbatch{1}.spm.util.imcalc.input = {
    [ sessdifft ',1']
    [ postcontrastt ',1']};
matlabbatch{1}.spm.util.imcalc.output = [ curspmdir 'intersection'];
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1>0 & i2>0';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
clear matlabbatch
matlabbatch{1}.spm.util.imcalc.input = {
    [ curspmdir 'intersection.nii,1']
    [ sessdifft ',1']
    };
matlabbatch{1}.spm.util.imcalc.output = [ curspmdir 'intersection_weightBySessdiff'];
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1.*i2';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
clear matlabbatch
matlabbatch{1}.spm.util.imcalc.input = {
    [ curspmdir 'intersection.nii,1']
    [ postcontrastt ',1']
    };
matlabbatch{1}.spm.util.imcalc.output = [ curspmdir 'intersection_weightByPostcontrast'];
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1.*i2';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
% Call → NCGP_vol2surf
NCGP_vol2surf(wf, sessdiffimg, curspmdir, curhemi, 'a');
% Call → NCGP_vol2surf
NCGP_vol2surf(wf, postcontrastimg, curspmdir, curhemi, 'a');
% Call → NCGP_vol2surf
NCGP_vol2surf(wf, 'intersection.nii', curspmdir, curhemi, 'a');
% Call → NCGP_vol2surf
NCGP_vol2surf(wf, 'intersection_weightBySessdiff.nii', curspmdir, curhemi, 'a');
% Call → NCGP_vol2surf
NCGP_vol2surf(wf, 'intersection_weightByPostcontrast.nii', curspmdir, curhemi, 'a');
% Toolbox call → surfing_read
sessdiff_surf=surfing_read([curspmdir strrep(sessdiffimg,'.nii','+orig.niml.dset')]);
% Toolbox call → surfing_read
postcontrast_surf=surfing_read([curspmdir strrep(sessdiffimg,'.nii','+orig.niml.dset')]);
% Toolbox call → surfing_read
intersection_surf=surfing_read([curspmdir 'intersection+orig.niml.dset']);
% Toolbox call → surfing_read
intwbpc_surf=surfing_read([curspmdir 'intersection_weightByPostcontrast+orig.niml.dset']);
signodes.sessdiff=sessdiff_surf.data;
signodes.postcontrast=postcontrast_surf.data;
signodes.intersection=intersection_surf.data;
signodes.intwbpc=intwbpc_surf.data;
end
