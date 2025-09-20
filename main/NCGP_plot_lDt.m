% ==========================================================================
% Overall goal (user-provided): Overall goal: Iterates over searchlights and plots LDt value for each searchlight
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Iterates over searchlights and plots LDt value for each searchlight
% ==========================================================================
% Function signature detected
function NCGP_plot_lDt(wf,nbrhood_nodes,ldt_cv)
%% ######### Plot LDt RDMs ##########
% Call → NCGP_paths
p=NCGP_paths(wf);
pialfn=[p.refsuma filesep 'rh.pial.asc'];
lbls={'AH1','AH2','AH3','AH4','NAT1','NAT2','NAT3','NAT4'};
% for i=1:length(ldt_cv)
%     for ri=1:12
% Toolbox call → cosmo_pdist
%         curpd=cosmo_pdist(currun_condbyvox{i,1}(:,:,ri)');
% Toolbox call → cosmo_squareform
%         allsqs(:,:,ri)=cosmo_squareform(curpd);
%     end
%     sqm=mean(allsqs,3);
% Call → NCGP_surface_neighborhood_plot
%     NCGP_surface_neighborhood_plot(nbrhood_nodes.neighbors,pialfn)
%     figf=figure('Position',[10 200 400 300]);imagesc(sqm);colorbar();title(num2str(i));yticklabels(lbls);xticklabels(lbls);pause(2);
% end
% Toolbox call → surfing_read
[vo,fo]=surfing_read(pialfn);
node_indices=1:length(vo);
nodesvec=1:length(node_indices);
opt.ShowEdge=0;
opt.DispMode='Add';
opt.Hold=' on';
% Section: for-block starts
for si =1:length(wf.sessions)
% Section: for-block starts
    for hi = 1:length(wf.hemis)
        curhemi=wf.hemis{hi};
        allsls=nbrhood_nodes{si, hi};
% Section: for-block starts
        for sli=1:length(allsls)
            cursl=allsls{sli};
            curslmask=zeros(length(node_indices),1);
            curslmask(cursl)=1;
            DispIVSurf(vo,fo,nodesvec,curslmask,1,opt);gcf;view(-90,0);
            title(['Searchlight No. ' num2str(sli)])
            figf=figure('Position',[10 200 400 300]);subplot(2,1,1);imagesc(ldt_cv{si,hi}{sli});colorbar();title(num2str(sli));yticklabels(lbls);xticklabels(lbls);
            pause(3);
            close all
        end
    end
end
end
