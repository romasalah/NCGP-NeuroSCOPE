% Paired participant-level SPM model, surface TFCE, and H2 conjunction.
function signodes_surf = NCGP_LDt_TFCE_prepost_persub(wf,LDCvals,oldds,curhemi,maskname)
[C1_files,C2_files,maskfile]=NCGP_LDt_TFCE_prepostsurf_persub(wf,LDCvals,curhemi,maskname);
[spmmat,blocksFile]=NCGP_LDt_Factorial_persub(wf,C1_files,C2_files,maskfile,maskname,curhemi);

% Swapping within blocks tests C1-C2 only. Marginal H2 tests are sign-flipped.
NCGP_LDt_TFCE_estimate_persub(wf,spmmat,maskfile,blocksFile,C1_files,C2_files,curhemi);
signodes_surf=NCGP_LDt_TFCE_vol2surf_persub(wf,maskname,curhemi,spmmat,maskfile);
end
