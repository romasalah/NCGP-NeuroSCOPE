% ==========================================================================
% Overall goal (user-provided): Overall goal: the 00main function for conducting TFCE. First it converts within-subject and between-subject distance images from surfaces to volume. Then it creates a factorial design using the volumetric images with SPM toolbox. Then estimates the TFCE model. Then the user creates results files. Finally the user converts TFCE results volumes to NIML surface datasets.
% Note: Added comments only; code unchanged.
% ==========================================================================
function signodes_surf=NCGP_LDt_TFCE(wf, LDCvals,oldds,curhemi, maskname)
% Call → NCGP_LDt_TFCE_surf2vol
[preb_vols,prew_vols,postb_vols,postw_vols]=NCGP_LDt_TFCE_surf2vol(wf, LDCvals,oldds,curhemi,maskname);
% Call → NCGP_LDt_Factorial_sessdiff
[spmmat_sd, hemimasks_sd]=NCGP_LDt_Factorial(wf,preb_vols,prew_vols,postb_vols,postw_vols, maskname, curhemi, 'sessdiff');
% Call → NCGP_LDt_Factorial_postcontrast
[spmmat_pc, hemimasks_pc]=NCGP_LDt_Factorial(wf,preb_vols,prew_vols,postb_vols,postw_vols, maskname, curhemi, 'postcontrast');
% Call → NCGP_LDt_TFCE_estimate_sd
paths=NCGP_paths(wf);
outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
exch_blocks= {[outputfolder 'exchangeability_blocks_sessdiff.txt']};
contrast_idx=1;
%NCGP_LDt_TFCE_estimate(wf, 'SPM',hemimasks_sd,spmmat_sd,maskname,curhemi, exch_blocks, 1, oldds);
% Call → NCGP_LDt_TFCE_estimate_pc
%NCGP_LDt_TFCE_estimate(wf, 'SPM',hemimasks_pc,spmmat_pc,maskname,curhemi, {}, 1, oldds);
% Call → NCGP_LDt_TFCE_vol2surf
signodes_surf=NCGP_LDt_TFCE_vol2surf(wf, maskname,curhemi);

end
