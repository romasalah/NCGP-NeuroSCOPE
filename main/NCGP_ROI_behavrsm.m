% ==========================================================================
% Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
function RDMcorr_roibehav=NCGP_ROI_behavrsm(voxcondrun,validrois)
behavPath='/Volumes/EVO8602TB/Omar/NCGP/';
behavmdl_names={'Physical','Personality','social life'};
persons = [1];
mrimidsum=100;
mdlprefix={'pre','post'};
behavid=num2str(persons(1)+mrimidsum);
modelpath='/Volumes/EVO8602TB/NCGP/Data/Models';
%% Load models RDM
theomdl_names={'Group','Gender','GaborJet','Pixel_faces','Pixel_full','GIST_faces','GIST_full','Openface'};
theomodel=NCGP_theomdls(modelpath,theomdl_names);
for si=1:size(voxcondrun,2)
    behavmdls=cell(1,0);
    curbehavmdl_names=cell(1,0);
for modeli=1:length(behavmdl_names)
    fnrdm=[modelpath filesep behavid '_' mdlprefix{si} '_' behavmdl_names{modeli} '_RDM.csv'];
    if exist(fnrdm,'file')==2
    dsmtbl=readtable(fnrdm);
    behavmdls{modeli}=table2array(dsmtbl);
    curbehavmdl_names{modeli}=behavmdl_names{modeli};
    end
end
    allmodels{si}=horzcat(theomodel, behavmdls);
    allmodelnames{si}=horzcat(theomdl_names, curbehavmdl_names);
end
%% Correlate models RDM with brain RDM
for si=1:size(voxcondrun,2)
    for modeli=1:length(allmodels{si})
        target_RDM_vec=cosmo_squareform(allmodels{si}{modeli},'tovector')';
        target_RDM_vecsq=target_RDM_vec.^2;% square predictor
        for mi=1:size(voxcondrun,1)
            voxcondrun_RDM=voxcondrun{mi,si}';
            voxcondrun_RDM_vec=squareform(voxcondrun_RDM,'tovector')';
            voxcondrun_RDM_vec=voxcondrun_RDM_vec(:);target_RDM_vecsq=target_RDM_vecsq(:);
            % Compute Pearson correlation
            [RDMcorr_roibehav{si}(modeli,mi), RDMpval_roibehav{si}(modeli,mi)] = corr(voxcondrun_RDM_vec, target_RDM_vecsq);
        end
    end
end
%% plot model correlation with brain RDM
roinum=size(voxcondrun,1);
for roi=1:roinum
    curroiname{roi}=regexprep(validrois(roi).name,'.*(_-?\d+_-?\d+_-?\d+).*','$1');
    curroiname{roi}=regexprep(curroiname{roi},'(.*0001)(.*)','$2');
    curroiname{roi}=strrep(curroiname{roi},'_roi.mat','');
    curroiname{roi}=strrep(curroiname{roi},'_',' ');
end
if mod(roinum,2)>0
graphnum=roinum+1;
else
    graphnum=roinum;
end
for si=1:size(voxcondrun,2)
    figure('pos',[100 100 1200 800],'Name', ['Session ' num2str(si) ': pearson correlation (Brain RDM vs. others)']);
    for roi=1:roinum
        subplot(graphnum/2,2,roi);
        [corr_sorted,sortidx]=sort(RDMcorr_roibehav{si}(:,roi), 'descend');
        pvals=RDMpval_roibehav{si}(:,roi);
        pvals_sorted = pvals(sortidx);
        names_sorted = {allmodelnames{si}{sortidx}};
        bar(corr_sorted);
        findsig=find(pvals_sorted<0.05);
        yloc=0.1 + corr_sorted;
        for ti=1:length(findsig)
        hold on;
        text(findsig(ti),yloc(findsig(ti)),'*','fontSize',30);
        end
        hold off;
        ylim([-0.15 0.6]);
        ylabel('Correlation')
        xlabel('Model names')
        xticklabels(names_sorted)
        title(curroiname{roi});
    end
end
%% FDR correction
for si =1:size(voxcondrun,2)
    for roi = 1:size(voxcondrun,1)
        clear pMac_vec
        pMap_vec = RDMpval_roibehav{si}(:,roi);
        q=0.05;
        c=1;
        n=length(pMap_vec);
        pMap_vec_sorted=sort(pMap_vec);
        pMap_vec_sorted = pMap_vec_sorted(:);
        pThreshold = pMap_vec_sorted(max(find(pMap_vec_sorted<=(1:n)'/n*q/c)));
        if isempty(pThreshold)
            FDR_thresholds(si,roi) = NaN;
        else
            FDR_thresholds(si,roi) = pThreshold;
        end
    end
end

% Make matrix showing which p values survived FDR
for si=1:size(voxcondrun,2)
corr_F = zeros(size(RDMpval_roibehav{si},1),size(RDMpval_roibehav{si},2), size(voxcondrun,2));
for roi = 1:  size(voxcondrun,1)
    if isnan(FDR_thresholds(si,roi)) == 0
       idx = find(RDMpval_roibehav{si}(:,roi) <= FDR_thresholds(si,roi));
       for c = 1:length(idx)
           model = idx(c);
           corr_F(model,roi,si) = 1;
       end    
    end
end
figure;imagesc(corr_F(:,:,si));
end


end