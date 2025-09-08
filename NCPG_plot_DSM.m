% ==========================================================================
% Overall goal (user-provided): Overall goal: Plots the average values of ingroup and outgroup similarity ratings and betweengroup similarity ratings to visually check for outgroup homogeneity
% Note: Added comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Plots the average values of ingroup and outgroup similarity ratings and betweengroup similarity ratings to visually check for outgroup homogeneity 
% Note:
% ==========================================================================
% Function signature
function NCPGH_plot_DSM(alltasksmat,alltasksmat_subavg,alldistavg,taskname,gpnames,preorpost,allingpnames)
colors=repmat({'red','cyan','yellow','green','blue','magenta'},1,10);
% Section: for-block starts
for tsi3=1:length(alltasksmat)
    figure('Position',[100 100 1200, 800]);
% Section: if-block starts
    if ~strcmp(preorpost,'postminuspre')
        subplot(2,1,1);
    end
    imagesc(alltasksmat_subavg{tsi3}(:,:));colorbar;
    title(['All Subjects : ' preorpost ' ' taskname{tsi3}])
    yticks(1:8)
    xticklabels(gpnames)
    yticklabels(gpnames)
% Section: if-block starts
    if ~strcmp(preorpost,'postminuspre')
        subplot(2,1,2);
    end
% Section: for-block starts
    for subi =1:size(alldistavg{tsi3},1)
        plot([alldistavg{tsi3}(subi,:)],'o-','Color',colors{subi});
        hold on;
        text(0.95,alldistavg{tsi3}(subi,1)+0.05,allingpnames{subi})
        hold on;
        text(1.95,alldistavg{tsi3}(subi,2)+0.05,allingpnames{subi})
        hold on;
        text(3.05,alldistavg{tsi3}(subi,3)+0.05,allingpnames{subi})
        hold on;
    end
    plot([mean(alldistavg{tsi3},1)],'o-','Color','black','Linewidth',3);
    title(['All Subjects ' preorpost  ' : ' taskname{tsi3}])
    xticks([0:5])
    xticklabels({'','Ingroup','Outgroup','Between groups',''})
    ylim([1 5])
    xlim([0 4])
% Section: if-block starts
    if strcmp(preorpost,'postminuspre')
        ylim([-1.5 1.5]);
        plot(0:5,zeros(6,1),'LineWidth',3,'Color','black')
    end
end
end
