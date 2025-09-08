% ==========================================================================
% Overall goal (user-provided): Overall goal: False Discovery Rate correction over searchlights/vertices (e.g., Benjamini–Hochberg).
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: False Discovery Rate correction over searchlights/vertices (e.g., Benjamini–Hochberg).
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
% Function signature detected
function qval = NCPG_FDR(p, FDRmethod)
% Section: switch-block starts
% Section: switch-block starts
switch FDRmethod
% Section: case-block starts
% Section: case-block starts
    case 'BHFDR'
        qval=mafdr(p,'BHFDR',true, 'showplot', true);
% Section: case-block starts
% Section: case-block starts
    case 'polynomial'
        qval=mafdr(p,'Method','polynomial', 'showplot', true);
% Section: case-block starts
% Section: case-block starts
    case 'bootstrap'
        qval=mafdr(p, 'showplot', true);
% Section: case-block starts
% Section: case-block starts
    case 'storey'
        qval=mafdr(p,'Showplot',true);
end
end