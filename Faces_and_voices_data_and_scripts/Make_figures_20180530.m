%% 2018/05/30 Maria Tsantani and Lucia Garrido

% Script to create figures for 00main analyses


%% Set up stuff

clear all; close all;

DATA.working_folder = pwd;

% File with results for all subjects
GROUP = importdata('Group_analysis.mat');

fig = 0;
identities = {'AC','AS','B0','DR','GN','JR','BK','BW','CC','EW','KM','SO'};

DATA.roi_names_forFig = {'rFFA','rOFA','rpSTS','OFC','FP','rTP aIT','lTP aIT','Prec./P.Cing.','rSTS/STG','rTVA','lSTS/STG','lTVA'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figure for geometry analysis%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars bar_plot error_bars signif_corr

% Preparation
alpha_plot = GROUP.geometry.FDR.pthreshold; 
signif_p = zeros(length(DATA.roi_names_forFig),4);
for roi = 1: GROUP.n_ROIs
    f_corr = GROUP.geometry.ROI(roi).FacesvsFaces.Pearson_mean_subjects;
    v_corr = GROUP.geometry.ROI(roi).VoicesvsVoices.Pearson_mean_subjects;
    fv_corr = GROUP.geometry.ROI(roi).FacesvsVoices.Pearson_mean_subjects;
    vf_corr = GROUP.geometry.ROI(roi).VoicesvsFaces.Pearson_mean_subjects;
    f_stdE = GROUP.geometry.ROI(roi).FacesvsFaces.Pearson_sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1); % Compute standard error
    v_stdE = GROUP.geometry.ROI(roi).VoicesvsVoices.Pearson_sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1);
    fv_stdE = GROUP.geometry.ROI(roi).FacesvsVoices.Pearson_sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1); 
    vf_stdE = GROUP.geometry.ROI(roi).VoicesvsFaces.Pearson_sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1);  
    
    bar_plot(roi,:) = [f_corr, v_corr, fv_corr, vf_corr];
    error_bars(roi,:) = [f_stdE, v_stdE, fv_stdE, vf_stdE];

    if GROUP.geometry.ROI(roi).FacesvsFaces.Pearson_signrank.P_values <= alpha_plot
    signif_p(roi,1) = 1;
    end
    if GROUP.geometry.ROI(roi).VoicesvsVoices.Pearson_signrank.P_values <= alpha_plot
    signif_p(roi,2) = 1;
    end
    if GROUP.geometry.ROI(roi).FacesvsVoices.Pearson_signrank.P_values <= alpha_plot
    signif_p(roi,3) = 1;
    end
    if GROUP.geometry.ROI(roi).VoicesvsFaces.Pearson_signrank.P_values <= alpha_plot
    signif_p(roi,4) = 1;
    end
 
end

% Face-selective ROIs
fig = fig+1;    
figure(fig)
set(fig,'position',[-58 200 2000 1500]);
roi_first = 1;
roi_last = 3;
clear rois_nms
for nms = roi_first:roi_last
    rois_nms{1,nms} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,1);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);    % The bars will now touch each other
set(b(1),'FaceColor',[160 80 80]/255);
set(b(2),'FaceColor',[80 80 160]/255);
set(b(3),'FaceColor',[145 81 164]/255);
set(b(4),'FaceColor',[120 81 164]/255);
axis([0.5 length(rois_nms)+0.5 -0.55 0.7]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[-0.4 -0.2 0 0.2 0.4 0.6],'yticklabel',[-0.4 -0.2 0 0.2 0.4 0.6],'linewidth',1,'fontsize',23);
title('Face-selective ROIs', 'fontsize',30)
ylabel('Mean RDM correlation', 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1); % number of ROIs
numbars = size(bar_plot(roi_first:roi_last,:), 2); % number of bars-contrasts
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 0.6, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        if i == 1
            plot(x(j), GROUP.geometry.ROI(j).FacesvsFaces.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 2
            plot(x(j), GROUP.geometry.ROI(j).VoicesvsVoices.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 3
            plot(x(j), GROUP.geometry.ROI(j).FacesvsVoices.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 4
            plot(x(j), GROUP.geometry.ROI(j).VoicesvsFaces.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);           
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i), error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);
      
      % Added this because the caps on the error bars were too short
        hb = get(ha,'children'); 
        Xdata = get(hb(2),'Xdata');
        temp = 4:3:length(Xdata);
        temp(3:3:end) = [];
        % xleft and xright contain the indices of the left and right
        %  endpoints of the horizontal lines
        xleft = temp; xright = temp+1;
        % Increase line length by units
        Xdata(xleft) = Xdata(xleft) + .06;
        Xdata(xright) = Xdata(xright) - .06;
        set(hb(2),'Xdata',Xdata)
end
box off;


% Voice-selective ROIs
clear rois_nms
c = 0;
roi_first = length(DATA.roi_names_forFig)-3;
roi_last = length(DATA.roi_names_forFig);
clear rois_nms
for nms = roi_first:roi_last
    c = c+1;
    rois_nms{1,c} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,2);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);    % The bars will now touch each other
set(b(1),'FaceColor',[160 80 80]/255);
set(b(2),'FaceColor',[80 80 160]/255);
set(b(3),'FaceColor',[145 81 164]/255);
set(b(4),'FaceColor',[120 81 164]/255);
axis([0.5 length(rois_nms)+0.5 -0.55 0.7]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[-0.4 -0.2 0 0.2 0.4 0.6],'yticklabel',[-0.4 -0.2 0 0.2 0.4 0.6],'linewidth',1,'fontsize',23);
title('Voice-selective ROIs', 'fontsize',30)
ylabel('Mean RDM correlation', 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1);
numbars = size(bar_plot(roi_first:roi_last,:), 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 0.6, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last; % This  is the index for the ROIs within the entire ROI set
        if i == 1
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).FacesvsFaces.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 2
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).VoicesvsVoices.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 3
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).FacesvsVoices.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 4
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).VoicesvsFaces.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);           
        end
    end
end
% Add error bars
for i = 1:numbars
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
    ha = errorbar(x, bar_plot(roi_first:roi_last,i),error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);      
     % Added this because the caps on the error bars were too short
    hb = get(ha,'children'); 
    Xdata = get(hb(2),'Xdata');
    temp = 4:3:length(Xdata);
    temp(3:3:end) = [];
    xleft = temp; xright = temp+1;
    Xdata(xleft) = Xdata(xleft) + .08;
    Xdata(xright) = Xdata(xright) - .08;
    set(hb(2),'Xdata',Xdata)
end
box off;


% Multimodal ROIs 
clear rois_nms
c = 0;
roi_first = 4;
roi_last = length(DATA.roi_names_forFig)-4;
clear rois_nms
for nms = roi_first:roi_last
    c = c+1;
    rois_nms{1,c} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,[3 3.5]);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);
set(b(1),'FaceColor',[160 80 80]/255);
set(b(2),'FaceColor',[80 80 160]/255);
set(b(3),'FaceColor',[145 81 164]/255);
set(b(4),'FaceColor',[120 81 164]/255);
axis([0.5 length(rois_nms)+0.5 -0.55 0.7]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[-0.4 -0.2 0 0.2 0.4 0.6],'yticklabel',[-0.4 -0.2 0 0.2 0.4 0.6],'linewidth',1,'fontsize',23);
l = legend('Face-Face RDMs', 'Voice-Voice RDMs','Face-Voice RDMs', 'Voice-Face RDMs', 'Location', 'South','Orientation','horizontal');
set(l, 'fontsize',26)
title('Person-selective ROIs', 'fontsize',30)
ylabel('Mean RDM correlation', 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1);
numbars = size(bar_plot(roi_first:roi_last,:), 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 0.6, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last; % This  is the index for the ROIs within the entire ROI set
        if i == 1
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).FacesvsFaces.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 2
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).VoicesvsVoices.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 3
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).FacesvsVoices.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 4
            plot(x(j), GROUP.geometry.ROI(rois_idx(j)).VoicesvsFaces.Pearson_persubject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);           
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i),error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);
    % Added this because the caps on the error bars were too long
    hb = get(ha,'children'); 
    Xdata = get(hb(2),'Xdata');
    temp = 4:3:length(Xdata);
    temp(3:3:end) = [];
    xleft = temp; xright = temp+1;
    Xdata(xleft) = Xdata(xleft) + .08;
    Xdata(xright) = Xdata(xright) - .08;
    set(hb(2),'Xdata',Xdata)
end
box off;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figure for analysis of discriminability%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars bar_plot error_bars signif_corr

% Preparation
alpha_plot = GROUP.discriminability.FDR.pthreshold; 
signif_p = zeros(length(DATA.roi_names_forFig),4);
for roi = 1: GROUP.n_ROIs
    f_corr = GROUP.discriminability.ROI(roi).Faces.mean_subjects;
    v_corr = GROUP.discriminability.ROI(roi).Voices.mean_subjects;
    fv_corr = GROUP.discriminability.ROI(roi).FacesVoices.mean_subjects;
    vf_corr = GROUP.discriminability.ROI(roi).VoicesFaces.mean_subjects;
    f_stdE = GROUP.discriminability.ROI(roi).Faces.sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1); % Compute standard error
    v_stdE = GROUP.discriminability.ROI(roi).Voices.sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1);
    fv_stdE = GROUP.discriminability.ROI(roi).FacesVoices.sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1); 
    vf_stdE = GROUP.discriminability.ROI(roi).VoicesFaces.sd_subjects/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1);  

    bar_plot(roi,:) = [f_corr, v_corr, fv_corr, vf_corr];
    error_bars(roi,:) = [f_stdE, v_stdE, fv_stdE, vf_stdE];

    if GROUP.discriminability.ROI(roi).Faces.onesamplettests.P_values <= alpha_plot
    signif_p(roi,1) = 1;
    end
    if GROUP.discriminability.ROI(roi).Voices.onesamplettests.P_values <= alpha_plot
    signif_p(roi,2) = 1;
    end
    if GROUP.discriminability.ROI(roi).FacesVoices.onesamplettests.P_values <= alpha_plot
    signif_p(roi,3) = 1;
    end
    if GROUP.discriminability.ROI(roi).VoicesFaces.onesamplettests.P_values <= alpha_plot
    signif_p(roi,4) = 1;
    end 
end

% Face-selective ROIs
fig = fig+1;    
figure(fig)
set(fig,'position',[-58 200 2000 1500]);
roi_first = 1;
roi_last = 3;
clear rois_nms
for nms = roi_first:roi_last
    rois_nms{1,nms} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,1);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);
set(b(1),'FaceColor',[153 50 76]/255);
set(b(2),'FaceColor',[102 50 102]/255);
set(b(3),'FaceColor',[50 153 153]/255);
set(b(4),'FaceColor',[50 102 102]/255);
axis([0.5 length(rois_nms)+0.5 -3 4.2]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[-2 -1 0 1 2 3],'yticklabel',[-2 -1 0 1 2 3],'linewidth',1,'fontsize',23);
title('Face-selective ROIs', 'fontsize',30)
ylabel('Mean LDC', 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1); % number of ROIs
numbars = size(bar_plot(roi_first:roi_last,:), 2); % number of bars-contrasts
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 3.7, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        if i == 1
            plot(x(j), GROUP.discriminability.ROI(j).Faces.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 2
            plot(x(j), GROUP.discriminability.ROI(j).Voices.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 3
            plot(x(j), GROUP.discriminability.ROI(j).FacesVoices.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 4
            plot(x(j), GROUP.discriminability.ROI(j).VoicesFaces.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);           
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i), error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);
      
      % Added this because the caps on the error bars were too short
        hb = get(ha,'children'); 
        Xdata = get(hb(2),'Xdata');
        temp = 4:3:length(Xdata);
        temp(3:3:end) = [];
        xleft = temp; xright = temp+1;
        Xdata(xleft) = Xdata(xleft) + .06;
        Xdata(xright) = Xdata(xright) - .06;
        set(hb(2),'Xdata',Xdata)
end
box off;


% Voice-selective ROIs
clear rois_nms
c = 0;
roi_first = length(DATA.roi_names_forFig)-3;
roi_last = length(DATA.roi_names_forFig);
clear rois_nms
for nms = roi_first:roi_last
    c = c+1;
    rois_nms{1,c} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,2);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1); 
set(b(1),'FaceColor',[153 50 76]/255);
set(b(2),'FaceColor',[102 50 102]/255);
set(b(3),'FaceColor',[50 153 153]/255);
set(b(4),'FaceColor',[50 102 102]/255);
axis([0.5 length(rois_nms)+0.5 -3 4.2]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[-2 -1 0 1 2 3],'yticklabel',[-2 -1 0 1 2 3],'linewidth',1,'fontsize',23);
title('Voice-selective ROIs', 'fontsize',30)
ylabel('Mean LDC', 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1);
numbars = size(bar_plot(roi_first:roi_last,:), 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 3.7, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if i == 1
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).Faces.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 2
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).Voices.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 3
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).FacesVoices.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 4
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).VoicesFaces.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);           
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i),error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);      
         % Added this because the caps on the error bars were too short
        hb = get(ha,'children'); 
        Xdata = get(hb(2),'Xdata');
        temp = 4:3:length(Xdata);
        temp(3:3:end) = [];
        xleft = temp; xright = temp+1;
        Xdata(xleft) = Xdata(xleft) + .08;
        Xdata(xright) = Xdata(xright) - .08;
        set(hb(2),'Xdata',Xdata)
end
box off;


% Multimodal ROIs 
clear rois_nms
c = 0;
roi_first = 4;
roi_last = length(DATA.roi_names_forFig)-4;
clear rois_nms
for nms = roi_first:roi_last
    c = c+1;
    rois_nms{1,c} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,[3 3.5]);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);    % The bars will now touch each other
set(b(1),'FaceColor',[153 50 76]/255);
set(b(2),'FaceColor',[102 50 102]/255);
set(b(3),'FaceColor',[50 153 153]/255);
set(b(4),'FaceColor',[50 102 102]/255);
axis([0.5 length(rois_nms)+0.5 -3 4.2]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[-2 -1 0 1 2 3],'yticklabel',[-2 -1 0 1 2 3],'linewidth',1,'fontsize',23);
l = legend('Face RDMs', 'Voice RDMs','Crossmodal RDMs (F-V)', 'Crossmodal RDMs (V-F)', 'Location', 'South','Orientation','horizontal');
set(l, 'fontsize',26)
title('Person-selective ROIs', 'fontsize',30)
ylabel('Mean LDC', 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1);
numbars = size(bar_plot(roi_first:roi_last,:), 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 3.7, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last; % This  is the index for the ROIs within the entire ROI set
        if i == 1
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).Faces.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 2
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).Voices.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 3
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).FacesVoices.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);
        elseif i == 4
            plot(x(j), GROUP.discriminability.ROI(rois_idx(j)).VoicesFaces.per_subject, 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',7);           
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i),error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);

    % Added this because the caps on the error bars were too long
    hb = get(ha,'children'); 
    Xdata = get(hb(2),'Xdata');
    temp = 4:3:length(Xdata);
    temp(3:3:end) = [];
    xleft = temp; xright = temp+1;
    Xdata(xleft) = Xdata(xleft) + .08;
    Xdata(xright) = Xdata(xright) - .08;
    set(hb(2),'Xdata',Xdata)

end
box off;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figure for mean response analysis%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars bar_plot error_bars signif_corr

% Preparation
alpha_plot = GROUP.mean_response.OneSample.FDR.pthreshold;
signif_p = zeros(length(DATA.roi_names_forFig),2);
for roi = 1: GROUP.n_ROIs   
    mean_faces = GROUP.mean_response.OneSample.Macrosssubj(roi).faces;
    stE_faces = GROUP.mean_response.OneSample.SDacrosssubj(roi).faces/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1);
    mean_voices = GROUP.mean_response.OneSample.Macrosssubj(roi).voices;
    stE_voices = GROUP.mean_response.OneSample.SDacrosssubj(roi).voices/sqrt(GROUP.discriminability.ROI(roi).Faces.onesamplettests.df+1);

    bar_plot(roi,:) = [mean_faces, mean_voices];
    error_bars(roi,:) = [stE_faces,stE_voices]; 

    if GROUP.mean_response.OneSample.pvals(roi).faces <= alpha_plot
    signif_p(roi,1) = 1;
    end
    if GROUP.mean_response.OneSample.pvals(roi).voices <= alpha_plot
    signif_p(roi,2) = 1;
    end
end

% Face-selective ROIs
fig = fig+1;    
figure(fig)
set(fig,'position',[-58 200 1200 1000]);
clear rois_nms
roi_first = 1;
roi_last = 3;
for nms = roi_first:roi_last
    rois_nms{1,nms} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,1);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);    % The bars will now touch each other
set(b(1),'FaceColor',[50,50,139]/255); 
set(b(2),'FaceColor',[80,105,225]/255);
axis([0.5 length(rois_nms)+0.5 -2 20]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[0 5 10 15],'yticklabel',[0 5 10 15],'linewidth',1,'fontsize',23);
title('Face-selective ROIs', 'fontsize',30)
ylabel({'Regional mean response' '(beta estimates)'}, 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1); % number of ROIs
numbars = size(bar_plot(roi_first:roi_last,:), 2); % number of bars-contrasts
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 18.5, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        if i == 1
            plot(x(j), [GROUP.mean_response.persubject(j).ROIs.faces], 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',9);
        elseif i == 2
            plot(x(j),  [GROUP.mean_response.persubject(j).ROIs.voices], 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',9);         
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i), error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);      
      % Added this because the caps on the error bars were too short
        hb = get(ha,'children'); 
        Xdata = get(hb(2),'Xdata');
        temp = 4:3:length(Xdata);
        temp(3:3:end) = [];
        xleft = temp; xright = temp+1;
        Xdata(xleft) = Xdata(xleft) + .08;
        Xdata(xright) = Xdata(xright) - .08;
        set(hb(2),'Xdata',Xdata)
end


% Voice-selective ROIs
clear rois_nms
c = 0;
roi_first = length(DATA.roi_names_forFig)-3;
roi_last = length(DATA.roi_names_forFig);
clear rois_nms
for nms = roi_first:roi_last
    c = c+1;
    rois_nms{1,c} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,2);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);    % The bars will now touch each other
set(b(1),'FaceColor',[50,50,139]/255);
set(b(2),'FaceColor',[80,105,225]/255);
axis([0.5 length(rois_nms)+0.5 -2 20]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[0 5 10 15],'yticklabel',[0 5 10 15],'linewidth',1,'fontsize',23);
title('Voice-selective ROIs', 'fontsize',30)
ylabel({'Regional mean response' '(beta estimates)'}, 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1);
numbars = size(bar_plot(roi_first:roi_last,:), 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 18.5, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if i == 1
            plot(x(j), [GROUP.mean_response.persubject(rois_idx(j)).ROIs.faces], 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',9);
        elseif i == 2
            plot(x(j), [GROUP.mean_response.persubject(rois_idx(j)).ROIs.voices], 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',9);          
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i),error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);
      
         % Added this because the caps on the error bars were too short
        hb = get(ha,'children'); 
        Xdata = get(hb(2),'Xdata');
        temp = 4:3:length(Xdata);
        temp(3:3:end) = [];
        xleft = temp; xright = temp+1;
        Xdata(xleft) = Xdata(xleft) + .1;
        Xdata(xright) = Xdata(xright) - .1;
        set(hb(2),'Xdata',Xdata)
end


% Multimodal ROIs 
clear rois_nms
c = 0;
roi_first = 4;
roi_last = length(DATA.roi_names_forFig)-4;
clear rois_nms
for nms = roi_first:roi_last
    c = c+1;
    rois_nms{1,c} = DATA.roi_names_forFig{nms};
end
ax = subplot(2,2,[3 3.5]);
b = bar(bar_plot(roi_first:roi_last,:));
set(b,'BarWidth',1);    % The bars will now touch each other
set(b(1),'FaceColor',[50,50,139]/255);
set(b(2),'FaceColor',[80,105,225]/255);
axis([0.5 length(rois_nms)+0.5 -2 20]);
set(ax,'xtick', [1:length(rois_nms)],'xticklabel',rois_nms,'ytick',[0 5 10 15],'yticklabel',[0 5 10 15],'linewidth',1,'fontsize',23);
l = legend('Face identities', 'Voice identities', 'Location', 'South','Orientation','horizontal');
set(l, 'fontsize',26)
title('Person-selective ROIs', 'fontsize',30)
ylabel({'Regional mean response' '(beta estimates)'}, 'fontsize',23)
hold on;
numgroups = size(bar_plot(roi_first:roi_last,:), 1);
numbars = size(bar_plot(roi_first:roi_last,:), 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
% Add stars for significant pvals 
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if signif_p(rois_idx(j),i) == 1
           plot(x(j), 18.5, '*', 'color', [0 0 0],'linewidth',1,'markersize',10);
        end
    end
end
% Add single-subject data
for i = 1:numbars % for each contrast (e.g the first bar in each group-faces in each ROI)
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups % for each ROI
        rois_idx = roi_first:roi_last;
        if i == 1
            plot(x(j), [GROUP.mean_response.persubject(rois_idx(j)).ROIs.faces], 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',9);
        elseif i == 2
            plot(x(j), [GROUP.mean_response.persubject(rois_idx(j)).ROIs.voices], 'o', 'color', [153 153 153]/255,'linewidth',1,'markersize',9);         
        end
    end
end
% Add error bars
for i = 1:numbars
      x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar      
      ha = errorbar(x, bar_plot(roi_first:roi_last,i),error_bars(roi_first:roi_last,i), 'k', 'linestyle', 'none','linewidth',2);
    % Added this because the caps on the error bars were too long
    hb = get(ha,'children'); 
    Xdata = get(hb(2),'Xdata');
    temp = 4:3:length(Xdata);
    temp(3:3:end) = [];
    xleft = temp; xright = temp+1;
    Xdata(xleft) = Xdata(xleft) + .1;
    Xdata(xright) = Xdata(xright) - .1;
    set(hb(2),'Xdata',Xdata)
end

