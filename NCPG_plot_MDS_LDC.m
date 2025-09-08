% ==========================================================================
% Overall goal: Plot MDS (or similar) from LDt/LDC distances for visualization/QA.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function NCPG_plot_MDS_LDC(wf, ldt_avg,nbrhood_nodes, TFCE_stats, stats, slnames,maskname,MCC)
lbls={'AH1','AH2','AH3','AH4','NAT1','NAT2','NAT3','NAT4'};
%% ######### Plot LDt RDMs ##########
% Call → NCPG_paths: Project function call
p=NCPG_paths(wf);
opt.ShowEdge=1;
mb=[0.7:-0.08:0]';
mr=[0.7:0.035:1]';
opt.ColMap =[mr mb mb];
opt.ColMapRange=[];
%opt.DispMode='Add';
opt.Hold=' on';

% Section: for-block starts
for hi= 1:length(wf.hemis)
    minpploc_pre={};
    minval_pre={};
    minval_pre_abs={};
    minpploc_post={};
    minval_post={};
    minval_post_abs={};
    sig_intersect=find(TFCE_stats{hi}.intersection);
% Section: if-block starts
    if ~isempty(sig_intersect)
        sig_sessdiff=TFCE_stats{hi}.sessdiff(sig_intersect);
        [sigsessord, sig_sessdiff_ord{hi}]=sort(sig_sessdiff,'descend');
        preb{hi}=stats{1,hi}.preb(sig_intersect, :);
        sigsls{hi}=slnames{hi}(sig_intersect);
        prew{hi}=stats{1,hi}.prew(sig_intersect, :);
        postb{hi}=stats{1,hi}.postb(sig_intersect, :);
        postw{hi}=stats{1,hi}.postw(sig_intersect, :);
% Section: switch-block starts
        switch MCC
% Section: case-block starts
            case 'none'
                postcontrast{hi}=stats{1,hi}.tstat_BGpostminusWGpost(sig_intersect, :);
                sessdiff{hi}=stats{1, hi}.tstat_BGdiffbminusWGdiff(sig_intersect, :);
% Section: case-block starts
            case 'TFCE'
                postcontrast{hi}=TFCE_stats{1,hi}.postcontrast(sig_intersect, :);
                sessdiff{hi}=TFCE_stats{1, hi}.sessdiff(sig_intersect, :);
% Section: case-block starts
            case 'FDR'
                postcontrast{hi}=stats{1,hi}.tstat_difftest(sig_intersect, :);
                sessdiff{hi}=stats{1, hi}.tstat_postcontrast(sig_intersect, :);
        end
        ldc_avg_pre{hi}=ldt_avg{hi,1}(sig_intersect);
        ldt_avg_post{hi}=ldt_avg{hi, 2}(sig_intersect);
        nbrhood_nodes_pre{hi}=nbrhood_nodes{1,hi}(sig_intersect);
        nbrhood_nodes_post{hi}=nbrhood_nodes{2,hi}(sig_intersect);
        pialfn{hi}=[p.refsuma filesep lower(wf.hemis{hi}) 'h.pial.asc'];
% Toolbox call → surfing_read
        [vo{hi},fo{hi}]=surfing_read(pialfn{hi});
        curmat_pre=[];
        curmat_post=[];
% Section: for-block starts
        for sli =1:length(ldc_avg_pre{hi})
            curmat_pre=ldc_avg_pre{hi}{sli};
            curmat_post=ldt_avg_post{hi}{sli};
            ldt_avg3_pre{hi}(:,:,sli)=curmat_pre+curmat_pre';
            ldt_avg3_post{hi}(:,:,sli)=curmat_post+curmat_post';
        end
        minpploc_pre{hi}=find(ldt_avg3_pre{hi}(:)==min(ldt_avg3_pre{hi}(:)));
        minval_pre{hi}=ldt_avg3_pre{hi}(minpploc_pre{hi});
        minval_pre{hi}=minval_pre{hi}(1);
        minval_pre_abs{hi}=abs(minval_pre{hi});
        minpploc_post{hi}=find(ldt_avg3_post{hi}(:)==min(ldt_avg3_post{hi}(:)));
        minval_post{hi}=ldt_avg3_post{hi}(minpploc_post{hi});
        minval_post{hi}=minval_post{hi}(1);
        minval_post_abs{hi}=abs(minval_post{hi});
    end

end
%% Start plotting
mkdir([p.LDC 'LDCdiff']);
close all;
% Section: for-block starts
for hi= 1:length(wf.hemis)
% Section: for-block starts
    for mci = 1:length(MCC)
% Section: if-block starts
        if ~isempty(sig_intersect)
            cursli_list=sig_sessdiff_ord{hi};
% Section: for-block starts
            for sli_idx =1:length(cursli_list)
                sli=cursli_list(sli_idx);
                curslname=sigsls{hi}{sli};
                ldtavg_offset_pre=ldt_avg3_pre{hi}(:,:,sli)+ minval_pre_abs{hi} - diag(zeros(1,8) + minval_pre_abs{hi});
                ldtavg_offset_post=ldt_avg3_post{hi}(:,:,sli)+ minval_post_abs{hi} - diag(zeros(1,8) + minval_post_abs{hi});
                cursl=nbrhood_nodes_pre{hi}{sli};
                node_indices=1:length(vo{hi});
                nodesvec=1:length(node_indices);
                curslmask=zeros(length(node_indices),1);
                curslmask(cursl)=1;
                fighandle=figure('Position',[0 0 1400 1000]);
                subplot(2,4,1);
                [~,curfig]=DispIVSurf(vo{hi},fo{hi},nodesvec,curslmask,1,opt);gcf;view(90,0);
                colorbar('off');
                p1=gca;
                p1.Position = [0.02 0.52 0.3 0.3]; % Adjust the position and size of the axes
                p1.PlotBoxAspectRatioMode="auto";
                p1.DataAspectRatioMode="auto";
                xticklabels({});yticklabels({});zticklabels({});
                title(['Searchlight ' curslname ' Lateral view']);
                subplot(2,4,2);
                DispIVSurf(vo{hi},fo{hi},nodesvec,curslmask,curfig.Fig,opt);view(-90,0);
                colorbar('off');
                p2=gca;
                p2.Position = [0.3 0.52 0.2 0.2]; % Adjust the position and size of the axes
                p2.PlotBoxAspectRatioMode="auto";
                p2.DataAspectRatioMode="auto";
                xticklabels({});yticklabels({});zticklabels({});
                title(['Searchlight ' curslname ' Medial view']);
                subplot(2,4,3);
                DispIVSurf(vo{hi},fo{hi},nodesvec,curslmask,curfig.Fig,opt);view(0,-90);
                colorbar('off');
                p3=gca;
                p3.Position = [0.6 0.52 0.12 0.45]; % Adjust the position and size of the axes
                p3.PlotBoxAspectRatioMode="auto";
                p3.DataAspectRatioMode="auto";
                xticklabels({});yticklabels({});zticklabels({});
                title(['Searchlight ' curslname ' Ventral view']);
                subplot(2,4,4);
                DispIVSurf(vo{hi},fo{hi},nodesvec,curslmask,curfig.Fig,opt);view(0,90);
                colorbar('off');
                p4=gca;
                p4.Position = [0.85 0.52 0.12 0.45]; % Adjust the position and size of the axes
                p4.PlotBoxAspectRatioMode="auto";
                p4.DataAspectRatioMode="auto";
                xticklabels({});yticklabels({});zticklabels({});
                title(['Searchlight ' curslname ' Dorsal view']);
                p2.Position = [0.36 0.52 0.3 0.3]; % Adjust the position and size of the axes
                p3.Position = [0.7 0.52 0.12 0.45]; % Adjust the position and size of the axes
                F_pre = cmdscale(ldtavg_offset_pre);
                F_post = cmdscale(ldtavg_offset_post);
                mx_pre = max(abs(F_pre(:)))+5;
                mx_post = max(abs(F_post(:)))+5;
                mx_max=max(mx_pre, mx_post);
                subplot(2,4,5);
                text(F_pre(:,1)+1, F_pre(:,2)+0.02, lbls, 'FontSize',12);hold on;
                scatter(F_pre(1:4,1), F_pre(1:4,2),'Color','r','LineWidth',8);
                hold on;
                scatter(F_pre(5:8,1), F_pre(5:8,2),'Color','b','LineWidth',8);
                xlim([-mx_max mx_max]); ylim([-mx_max mx_max]);
                set(gca,'fontsize',12,'FontWeight','bold');
                p5=gca;
                p5.Position=[0.04 0.05 0.27 0.4];
                xlabel('Distance (dimension 1)');
                ylabel('Distance (dimension 2)');
                title('Pre-intervention, Discriminability scores');
                %xlim([-0.5 0.6]); ylim([-0.5 0.6]);
                %title([taskname{tsi2} ', ' preorpost],'FontSize',30);
                %post
                subplot(2,4,6);
                text(F_post(:,1)+1, F_post(:,2)+0.02, lbls, 'FontSize',12);hold on;
                scatter(F_post(1:4,1), F_post(1:4,2),'Color','r','LineWidth',8);
                hold on;
                scatter(F_post(5:8,1), F_post(5:8,2),'Color','b','LineWidth',8);
                xlim([-mx_max mx_max]); ylim([-mx_max mx_max]);
                set(gca,'fontsize',12,'FontWeight','bold')
                xlabel('Distance (dimension 1)');
                ylabel('Distance (dimension 2)');
                p6=gca;
                p6.Position=[0.37 0.05 0.27 0.4];
                title('Post-intervention, Discriminability scores');
                subplot(2,4,8);
                xoffset=[1:2]+0.1;
                scatter(ones(1, length(preb{hi}(sli,:)))+0.1, preb{hi}(sli,:),'ro','LineWidth',2);hold on;
                scatter(ones(1, length(postb{hi}(sli,:)))+1.1, postb{hi}(sli,:),'ro','LineWidth',2);hold on;
                plot(xoffset,[mean(preb{hi}(sli,:)) mean(postb{hi}(sli,:))], 'r', 'LineWidth',5);hold on;
                scatter(ones(1, length(prew{hi}(sli,:))), prew{hi}(sli,:),'bo','LineWidth',2);hold on;
                scatter(ones(1, length(postw{hi}(sli,:)))+1, postw{hi}(sli,:),'bo','LineWidth',2);hold on;
                plot([mean(prew{hi}(sli,:)) mean(postw{hi}(sli,:))], 'b', 'LineWidth',5);hold on;
                text(0.5,21,['Session Difference t-stat = ' num2str(round(sessdiff{hi}(sli),2))],'fontsize',12)
                text(0.5,19,['Session 3 (between - within) t-stat = ' num2str(round(postcontrast{hi}(sli),2))],'fontsize',12)
                set(gca,'fontsize',12,'FontWeight','bold')
                ylabel('Discrminability Scores');
                xlabel('Session');
                xticks(1:2)
                xticklabels({ 'Pre', 'Post'});
                p8=gca;
                p8.Position=[0.7 0.05 0.27 0.4];
                title('Pre & Post-intervention, Discriminability scores');
                xlim([0 3]);ylim([-25 30]);
                legend({'','Between-group discriminability','','Within-group discriminability'},'Location','north');
                saveas(fighandle,[p.LDC 'LDCdiff' filesep curslname '_hemi-' wf.hemis{hi} '_mask-' maskname '.png']);
                pause(1)
                close all
            end
        end
    end
end
end
