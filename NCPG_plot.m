% ==========================================================================
% Overall goal (user-provided): Overall goal: Iterate over tasks (Physical appearance, social life, personality) and reverse scores (1 - rescaled original score). then creates a diagonal matrix (using left to right flip then 90 degree rotation). Finally plots a Multidimensional scale solution.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Iterate over tasks (Physical appearance, social life, personality) and reverse scores (1 - rescaled original score). then creates a diagonal matrix (using left to right flip then 90 degree rotation). Finally plots a Multidimensional scale solution.
% ==========================================================================
% Function signature detected
function alltasksmat_subavg_sqRDM=NCPGH_plot(alltasksmat, allingpsim, alloutgpsim,allbtgpsim,allingpsim_distavg, alloutgpsim_distavg, allbtgpsim_distavg,allingpnames, taskname, gpnames,gpnames_inout,preorpost)
% Section: for-block starts
for tsi2=1:length(alltasksmat)
    alltasksmat_subavg{tsi2}=mean(alltasksmat{tsi2},3);
%     allingpsim_subavg{tsi2}=mean(allingpsim{tsi2},2);
%     alloutgpsim_subavg{tsi2}=mean(alloutgpsim{tsi2},2);
%     allbtgpsim_subavg{tsi2}=mean(allbtgpsim{tsi2},2);
    alltasksmat_subavg_sqRDM{tsi2}= 1-rescale((rot90(fliplr(alltasksmat_subavg{tsi2}),1) + alltasksmat_subavg{tsi2} + diag(zeros(1,8)+7)));
    alldistavg{tsi2}=[allingpsim_distavg{tsi2}' alloutgpsim_distavg{tsi2}' allbtgpsim_distavg{tsi2}'];
end
%% plot MDS
taskname=strrep(taskname,'Physical', 'Facial features');
preorpost=[preorpost '-intervention'];
% Call → NCPG_plot_MDS
NCPG_plot_MDS(alltasksmat,alltasksmat_subavg_sqRDM,taskname,gpnames_inout,preorpost);
%% plot DSM
% Call → NCPG_plot_DSM
NCPG_plot_DSM(alltasksmat,alltasksmat_subavg,alldistavg,taskname,gpnames,preorpost,allingpnames);

end
