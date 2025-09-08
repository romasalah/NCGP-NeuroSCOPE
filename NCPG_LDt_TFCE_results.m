% ==========================================================================
% Overall goal (user-provided): Overall goal: Tries to calculate the results of a TFCE model previously estimated using TFCE toolbox for SPM.
% Note: Added comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Tries to calculate the results of a TFCE model previously estimated using TFCE toolbox for SPM.
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
% Function signature
function out=NCPG_LDt_TFCE_results(spmfolder, hemimasks)
%-Apply to all contrasts if Inf is entered
%----------------------------------------------------------------------
cd(spmfolder)
load('SPM.mat');
Ic =1; %contrast index;
xCon = SPM.xCon(1);
[~,nam,xt] = fileparts(xCon(Ic).Vspm.fname);
% Toolbox call → spm_data_hdr_read
xCon(Ic).Vspm = spm_data_hdr_read(fullfile(spmfolder,[nam xt]));
SPM.Ic = Ic; SPM.xCon = xCon;
SPM.swd = spmfolder;
% check for existing TFCE results for this contrast
% Section: if-block starts
if  (exist(fullfile(spmfolder,sprintf('%s_log_p_%04d.nii',xCon(Ic).STAT,Ic))) || ...
        exist(fullfile(spmfolder,sprintf('%s_log_p_%04d.gii',xCon(Ic).STAT,Ic))))
    SPM.statType = 'TFCE';
    SPM.thresDesc = 'none';
    SPM.title     = '';
    SPM.k         = 0;
    SPM.u        = 0.05;
    SPM.invResult=0;
    [~,xSPM] = tfce_getSPM(SPM);
    xSPM.statType = 'TFCE';
end
%-Create xSPM variable
%----------------------------------------------------------------------
xSPM.swd       = spmfolder;
xSPM.Ic        = Ic;
xSPM.Im        = [];
xSPM.pm    = [];
xSPM.thresDesc = 'none';
xSPM.title     = '';
xSPM.k         = 0;
xSPM.units = {'mm' 'mm' 'mm'};

%-Compute a specified and thresholded SPM
%----------------------------------------------------------------------
% Toolbox call → spm_getSPM
[SPM, xSPM] = spm_getSPM(xSPM);
% Toolbox call → spm_list
TabDat = spm_list('Table',xSPM);
hReg = [];
out.xSPMvar(Ic)   = xSPM;
out.TabDatvar(Ic) = TabDat;
out.filtered{Ic}  = {};
Z = xSPM.Z;
% Toolbox call → spm_write_filtered
V = spm_write_filtered(Z,xSPM.XYZ,xSPM.DIM,xSPM.M,...
    '','test.nii');
F = V.fname;
out.filtered{Ic} = F;
end
