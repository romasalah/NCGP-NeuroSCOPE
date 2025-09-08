% ==========================================================================
% Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
function [intragroupsim_pre_avg,intragroupsim_post_avg,intergpsim_pre_avg,intergpsim_post_avg]=NCPG_plotMCR(allingpsim_pre,alloutgpsim_pre,allbtgpsim_pre,allingpsim_post,alloutgpsim_post,allbtgpsim_post,allingpnames,tasknames, plotflag)
for tsi=1:3
    if plotflag==1
        figure;
    end
    for subi =1:length(allingpnames)
        intragroupsim_pre=[allingpsim_pre{tsi}(:,subi),alloutgpsim_pre{tsi}(:,subi)];
        intragroupsim_post=[allingpsim_post{tsi}(:,subi),alloutgpsim_post{tsi}(:,subi)];
        intragroupsim_pre_avg{tsi}(subi)=mean(intragroupsim_pre(:));
        intragroupsim_post_avg{tsi}(subi)=mean(intragroupsim_post(:));
        intergpsim_pre_avg{tsi}(subi)=mean(allbtgpsim_pre{tsi}(:,subi),"all");
        intergpsim_post_avg{tsi}(subi)=mean(allbtgpsim_post{tsi}(:,subi),"all");
        MCRpre(subi)=1-(intergpsim_pre_avg{tsi}(subi)/intragroupsim_pre_avg{tsi}(subi));
        MCRpost(subi)=1-(intergpsim_post_avg{tsi}(subi)/intragroupsim_post_avg{tsi}(subi));
        if plotflag==1
            plot([ MCRpre(subi) MCRpost(subi)],'o-');
            hold on;
            text(0.95,MCRpre(subi)+0.01,allingpnames{subi})
            hold on;
            text(2.05,MCRpost(subi)+0.01,allingpnames{subi})
            hold on;
        end
    end
    if plotflag==1
        plot([mean(MCRpre) mean(MCRpost)],'o-','color','black','LineWidth',3)
        title(['Meta contrast ratio '  ' : ' tasknames{tsi} ])
        xticks([0:4])
        xticklabels({'','MCR_pre','MCR_post',''})
        ylim([-0.5 1.2])
        xlim([0 3])
    end
end
end