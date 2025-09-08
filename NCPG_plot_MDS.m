% ==========================================================================
% Overall goal (user-provided): Overall goal: Create a 2-dimensional plot based on the multidimensional solution and a second plot of a dendrogram.
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Create a 2-dimensional plot based on the multidimensional solution and a second plot of a dendrogram.
% Note:
% ==========================================================================
% Function signature detected
function NCPG_plot_MDS(alltasksmat,alltasksmat_subavg_sqRDM,taskname,gpnames_inout,preorpost)
% Section: for-block starts
for tsi2=1:length(alltasksmat)
    F = cmdscale(alltasksmat_subavg_sqRDM{tsi2});
    figure('Position',[10 10 800 1000]);subplot(2,1,1)
    text(F(:,1)+0.02, F(:,2)+0.02, gpnames_inout, 'FontSize',26);hold on;
    scatter(F(1:4,1), F(1:4,2),'Color','r','LineWidth',8);
    hold on;
    scatter(F(5:8,1), F(5:8,2),'Color','b','LineWidth',8);
    mx = max(abs(F(:)))+0.2;
    xlim([-mx mx]); ylim([-mx mx]);
    set(gca,'fontsize',22,'FontWeight','bold')
    xlabel('Distance (dimension 1)');
    ylabel('Distance (dimension 2)');
    xlim([-0.5 0.6]); ylim([-0.5 0.6]);
    title([taskname{tsi2} ', ' preorpost],'FontSize',30);
    subplot(2,1,2)
    hclus = linkage(alltasksmat_subavg_sqRDM{tsi2});
    dendrogram(hclus, 'labels',gpnames_inout);
end
end
