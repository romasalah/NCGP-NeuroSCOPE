% ==========================================================================
% Overall goal (user-provided): Overall goal: the main function for conducting TFCE. First it converts within-subject and between-subject distance images from surfaces to volume. Then it creates a factorial design using the volumetric images with SPM toolbox. Then estimates the TFCE model. Then the user creates results files. Finally the user converts TFCE results volumes to NIML surface datasets.
% Note: Added comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: the main function for conducting TFCE. First it converts within-subject and between-subject distance images from surfaces to volume. Then it creates a factorial design using the volumetric images with SPM toolbox. Then estimates the TFCE model. Then the user creates results files. Finally the user converts TFCE results volumes to NIML surface datasets.
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
% Function signature
function signodes_surf=NCPG_LDt_TFCE(wf, LDCvals,oldds,curhemi, maskname)
% Call → NCPG_LDt_TFCE_surf2vol
[preb_vols,prew_vols,postb_vols,postw_vols]=NCPG_LDt_TFCE_surf2vol(wf, LDCvals,oldds,curhemi,maskname);
% Call → NCPssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssG_LDt_Factorial
[spmmat, hemimasks]=NCPG_LDt_Factorial(wf,preb_vols,prew_vols,postb_vols,postw_vols, maskname, curhemi);
% Call → NCPG_LDt_TFCE_estimate
NCPG_LDt_TFCE_estimate(wf, 'SPM',hemimasks,spmmat,maskname, oldds);
% Call → NCPG_LDt_TFCE_vol2surf
signodes_surf=NCPG_LDt_TFCE_vol2surf(wf, maskname,curhemi);

end
