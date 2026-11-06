% Surface TFCE for a participant-level one-sample GLM.
% The modified tfce_estimate_stat.m sign-flips each subject map independently.
function NCGP_LDt_TFCE_estimate_persub( ...
    wf,TFCEmethod,hemimask,spmmat,maskname,curhemi,exch_blocks)
assert(strcmp(TFCEmethod,'SPM'),'Only SPM surface TFCE is supported.');
assert(isfile(spmmat),'SPM.mat missing: %s',spmmat);
assert(isfile(hemimask),'Common analysis surface mask missing.');
assert(isempty(exch_blocks), ...
    'One-sample TFCE uses subject-wise sign flips, not exchangeability blocks.');

spm('defaults','fmri');
spm_jobman('initcfg');
clear matlabbatch
matlabbatch{1}.spm.tools.tfce_estimate.data={spmmat};
matlabbatch{1}.spm.tools.tfce_estimate.nproc=20;
matlabbatch{1}.spm.tools.tfce_estimate.mask={''};
matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr='';
matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm=10000;
matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method=0;
matlabbatch{1}.spm.tools.tfce_estimate.tbss=0;
matlabbatch{1}.spm.tools.tfce_estimate.exch_blocks={};
matlabbatch{1}.spm.tools.tfce_estimate.singlrthreaded=0;
spm_jobman('run',matlabbatch);

assert(isfile(fullfile(fileparts(spmmat),'TFCE_log_pFWE_0001.gii')), ...
    'TFCE did not create the expected surface FWE map: %s',spmmat);
fprintf('TFCE completed for hemisphere %s, %s.\n',curhemi,spmmat);
end
