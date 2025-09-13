% Overall goal: False Discovery Rate correction over searchlights/vertices
% (e.g., Benjamini–Hochberg).
% Place in pipeline: Surface-based MVPA workflow
% (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
function qval = NCPG_FDR(p, FDRmethod)
switch FDRmethod
    case 'BHFDR'
        qval=mafdr(p,'BHFDR',true, 'showplot', true);
    case 'polynomial'
        qval=mafdr(p,'Method','polynomial', 'showplot', true);
    case 'bootstrap'
        qval=mafdr(p, 'showplot', true);
    case 'storey'
        qval=mafdr(p,'Showplot',true);
end
end