% ==========================================================================
% Overall goal: Flatten square RDM/LDt matrices into a long-form table (pairwise rows) for statistical analysis.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function RDM_flat=NCGP_RDM_flatten(RDM)
RDM_flat={};
% Section: for-block starts
for first_cond = 1:7
% Section: for-block starts
for second_cond= first_cond+1:8
RDM_flat{end+1,1}=[num2str(first_cond) '_' num2str(second_cond)];
RDM_flat{end,2}=RDM(first_cond, second_cond);
end
end
