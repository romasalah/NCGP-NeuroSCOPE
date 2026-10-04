function NCGP_plot_LDC_allsls(vo,fo,cursli_list,nbrhood_nodes_pre,sigsls,hi,maskname,wf,p,opt)
node_indices=1:length(vo{hi});
nodesvec=1:length(node_indices);
curslmask=zeros(length(node_indices),1);
for sli_idx =1:length(cursli_list)
    sli=cursli_list(sli_idx);
    curslname=sigsls{hi}{sli};
    cursl=nbrhood_nodes_pre{hi}{sli};
    curslmask(cursl)=curslmask(cursl)+1;
end
opt.ColMap = colormap;
opt.ColMap(1,:)=[0.7 0.7 0.7];
DispOpt.ColMapRange=[1 max(curslmask)];
close all;
f1=figure('Position',[0 0 1400 1000]);
DispIVSurf_cmap(vo{hi},fo{hi},nodesvec,curslmask,1,opt);gcf;view(-90,0);
colorbar('off');
p1=gca;
p1.Position = [0.02 0.02 0.98 0.98]; % Adjust the position and size of the axes
p1.PlotBoxAspectRatioMode="auto";
p1.DataAspectRatioMode="auto";
xticklabels({});yticklabels({});zticklabels({});
title('Lateral View');
saveas(f1,[p.LDC 'LDCdiff' filesep 'allsls_hemi-' wf.hemis{hi} '_mask-' maskname '_Lateral.png']);
close(f1);
%%
f2=figure('Position',[0 0 1400 1000]);
DispIVSurf_cmap(vo{hi},fo{hi},nodesvec,curslmask,1,opt);gcf;
view(0,-90);
% colorbar('off');
p2=gca;
p2.Position = [0.02 0.02 0.24 0.9];
p2.PlotBoxAspectRatioMode="auto";
p2.DataAspectRatioMode="auto";
xticklabels({});yticklabels({});zticklabels({});
title('Ventral View');
saveas(f2,[p.LDC 'LDCdiff' filesep 'allsls_hemi-' wf.hemis{hi} '_mask-' maskname '_ventral.png']);
close(f2);
%%
f3=figure('Position',[0 0 1400 1000]);
DispIVSurf_cmap(vo{hi},fo{hi},nodesvec,curslmask,1,opt);gcf;
view(90,0);
colorbar('off');
p3=gca;
p3.Position = [0.02 0.02 0.98 0.98];
p3.PlotBoxAspectRatioMode="auto";
p3.DataAspectRatioMode="auto";
xticklabels({});yticklabels({});zticklabels({});
title('Medial View');
saveas(f3,[p.LDC 'LDCdiff' filesep 'allsls_hemi-' wf.hemis{hi} '_mask-' maskname '_medial.png']);
close(f3);
%%
f4=figure('Position',[0 0 1400 1000]);
DispIVSurf_cmap(vo{hi},fo{hi},nodesvec,curslmask,1,opt);gcf;
view(0,90);
colorbar('off');
p4=gca;
p4.Position = [0.02 0.02 0.24 0.9];
p4.PlotBoxAspectRatioMode="auto";
p4.DataAspectRatioMode="auto";
xticklabels({});yticklabels({});zticklabels({});
title('Dorsal View');
saveas(f4,[p.LDC 'LDCdiff' filesep 'allsls_hemi-' wf.hemis{hi} '_mask-' maskname '_dorsal.png']);
close(f4);