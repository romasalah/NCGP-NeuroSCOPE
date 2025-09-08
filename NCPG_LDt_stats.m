% ==========================================================================
% Overall goal: Searchlight-level statistical testing of LDt changes (between-group vs within-group) with multiple-comparison control.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [slnames, statresults,signodes_surf]=NCPG_LDt_stats(wf, maskname, stattype, oldds)
signodes_surf=[];
% Section: for-block starts
for subi=1:length(wf.subs)
% Section: for-block starts
    for hi=1:length(wf.hemis)
        curhemi=wf.hemis{hi};
% Call → NCPG_paths: Project function call
        paths=NCPG_paths(wf);
        outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep wf.subs{subi} filesep wf.pre filesep wf.glm filesep ];
        fnprefix=[outputfolder 'sub-' wf.subs{subi} '_task-' wf.task '_hemi-' curhemi '_mask-' maskname  '_ses-all' ];
        llmdesfn=[fnprefix '_prepost_LLM_crctd.csv'];
        preposttbl=readtable(llmdesfn);
        % Specify the model
% Section: switch-block starts
        switch stattype
% Section: case-block starts
            case 'LLM'
                formula = 'LDCvalue ~ Session + Contrast + Session*Contrast';
                allsls=unique(preposttbl.Searchlight);
% Section: for-block starts
                for sli = 1:length(allsls)
                    cursl=allsls{sli};
                    curtbl=preposttbl(contains(preposttbl.Searchlight,cursl),:);
                    % Fit the linear mixed model
                    lme_sl{sli} = fitlme(curtbl, formula);
                end
                % Identify significant interactions (assuming alpha level of 0.05)
                significant_interactions = find(p_values < 0.05);
                disp('Searchlight levels with significant interaction between comparison_type and session:');
                disp(lme_sl{sli});
% Section: case-block starts
            case 'rmANOVA'
                allsls=unique(preposttbl.Searchlight);
                bres{subi,hi}=[];
                wres{subi,hi}=[];
                slnames{subi,hi}={};
                f = waitbar(0, ['Running repeated measures ANOVA for Searchlight No. 0 out of ' num2str(length(allsls))]);
% Section: for-block starts
                for sli = 1:length(allsls)
                    waitbar(sli/length(allsls), f, ['Running repeated measures ANOVA for Searchlight No. ' num2str(sli) ' out of ' num2str(length(allsls))]);
                    cursl=allsls{sli};
                    curtbl=preposttbl(strcmp(preposttbl.Searchlight,cursl),:);
                    prew=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-02'));
                    postw=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-03'));
                    preb=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-02'));
                    postb=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-03'));
                    anovatbl{sli}=array2table([preb postb [prew; nan(4,1)] [postw; nan(4,1)]], 'VariableNames',{'pre_b',  'post_b', 'pre_w',  'post_w'});
                    TimePoint = {'pre', 'post', 'pre', 'post'}';
                    MeasurementType = {'b', 'b', 'w', 'w'}';
                    WithinStructure = table(TimePoint, MeasurementType);
% Section: if-block starts
                    if sum(ismissing(anovatbl{sli}), 'all') == sum(numel(anovatbl{sli}))
                        bres{subi,hi}(sli,:)=0;
                        wres{subi,hi}(sli,:)=0;
                        slnames{subi,hi}{sli}=cursl;
                        continue
                    end
                    rmanova_sl{sli}=fitrm(anovatbl{sli},'pre_b-post_w ~ 1','WithinDesign',WithinStructure);
                    contrasttbl{sli}=coeftest(rmanova_sl{sli},1, [-1 1 1 -1]'); % Contrast: post_b - pre_b - post_w + pre_w
                    Pillaipval(sli,1)=contrasttbl{sli}.pValue(1);
                    contrast_posthoc= multcompare(rmanova_sl{sli},'TimePoint','By','MeasurementType');
                    contrast_posthoc=contrast_posthoc(contains(contrast_posthoc.TimePoint_1, 'post'),:);
                    contrast_posthoc_bidx=contains(contrast_posthoc.MeasurementType, 'b');
                    contrast_posthoc_widx=contains(contrast_posthoc.MeasurementType, 'w');
                    bres{subi,hi}(sli,:)=[contrast_posthoc.Difference(contrast_posthoc_bidx) contrast_posthoc.pValue(contrast_posthoc_bidx)];
                    wres{subi,hi}(sli,:)=[contrast_posthoc.Difference(contrast_posthoc_widx) contrast_posthoc.pValue(contrast_posthoc_widx)];
                    slnames{subi,hi}{sli}=cursl;
                end
                %% FDR correction of post-hoc tests
                breswres_p=[bres{subi,hi}(:,2); wres{subi,hi}(:,2)];
% Call → NCPG_FDR: False Discovery Rate correction over searchlights/vertices (e.g., Benjamini–Hochberg).
                breswres_pFDR{subi,hi} = NCPG_FDR(breswres_p,'BHFDR');
                bres_pFDR{subi,hi}=breswres_pFDR{subi,hi}(1:size(bres{subi,hi},1));
                wres_pFDR{subi,hi}=breswres_pFDR{subi,hi}(size(bres{subi,hi},1)+1:end);
                %                 nonsigloc=( bres_pFDR{subi,hi}>=0.05 |  wres_pFDR{subi,hi}>=0.05);
                %                 oppositeDirectionLoc=( bres{subi,hi}(:,1)<0 |  wres{subi,hi}(:,1)>0);
                %                 excludedloc=(nonsigloc | oppositeDirectionLoc);
                nonsigloc=Pillaipval>=0.05;
                bressig= bres{subi,hi};
                bressig(nonsigloc,:)=0;
                wressig=wres{subi,hi};
                wressig(nonsigloc, :)=0;
                figure;plot(bressig(:,1));hold on;plot(wressig(:,1));legend({'Significant difference in between-subject Discriminability (LDt)','Significant difference in Within-subject Discriminability (LDt)'});
                statresults{subi,hi}.bres=bres{subi,hi};
                statresults{subi,hi}.wres=wres{subi,hi};
                statresults{subi,hi}.bressig=bressig;
                statresults{subi,hi}.wressig=wressig;
                statresults{subi,hi}.breswres_p=breswres_p;
                statresults{subi,hi}.breswres_pFDR=breswres_pFDR{subi,hi};
                statresults{subi,hi}.bres_pFDR=bres_pFDR{subi,hi};
                statresults{subi,hi}.wres_pFDR=wres_pFDR{subi,hi};
                statresults{subi,hi}.Pillaipval=Pillaipval;
                statresults{subi,hi}.contrastres=contrasttbl;

% Section: case-block starts
            case 'diff t-test'
                allsls=unique(preposttbl.Searchlight);
                slnames{subi,hi}={};
                f = waitbar(0, ['Running repeated measures ANOVA for Searchlight No. 0 out of ' num2str(length(allsls))]);
% Section: for-block starts
                for sli = 1:length(allsls)
                    waitbar(sli/length(allsls), f, ['Running repeated measures ANOVA for Searchlight No. ' num2str(sli) ' out of ' num2str(length(allsls))]);
                    cursl=allsls{sli};
                    curtbl=preposttbl(strcmp(preposttbl.Searchlight,cursl),:);
                    prew(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-02'));
                    postw(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-03'));
                    preb(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-02'));
                    postb(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-03'));
                    bg_diff(:,sli)=postb(sli,:)-preb(sli,:);
                    wg_diff(:,sli)=postw(sli,:)-prew(sli,:);
                    %% Should we use a parameteric test, is the varirance of wgdiff and bgdiff equal?
                    [h1(sli,1), pval(sli,1), ~, stats{sli,1}]=ttest2( bg_diff(:,sli), wg_diff(:,sli),'Tail','right');
                    tval(sli,1) = stats{sli,1}.tstat;
                    %% Test if Between-group LDt post is higher than Within-group LDt post
                    [h12(sli,1), pval2(sli,1), ~, stats2{sli,1}]=ttest2( postb(sli,:), postw(sli,:),'Tail','right');
                    tval2(sli,1) = stats2{sli,1}.tstat;
                    %% Plot
                    %                     if h1(sli) == 1 && h12(sli) == 1
                    %                         figure;
                    %                         subplot(2,1,1);
                    %                         plot( bg_diff(:,sli));hold on;plot( wg_diff(:,sli));legend({'Between-group Difference','Within-group Difference'})
                    %                         subplot(2,1,2);
                    %                         plot( postb);hold on;plot(postw);legend({'Between-group LDt, Session 3','Within-group LDt, Session 3'})
                    %                     end
                    slnames{subi,hi}{sli}=cursl;
                end

                %% FDR correction of the two t-tests
                p_all=[pval; pval2];
% Call → NCPG_FDR: False Discovery Rate correction over searchlights/vertices (e.g., Benjamini–Hochberg).
                p_FDR_all = NCPG_FDR(p_all,'BHFDR');
                p_difftest_FDR=p_FDR_all(1:size(pval,1));
                p_postcontrast_FDR=p_FDR_all(size(pval,1)+1:end);
                nonsigloc_difftest=p_difftest_FDR>=0.05;
                tval_difftest_FDR= tval;
                tval_difftest_FDR(nonsigloc_difftest,:)=0;
                nonsigloc_postcontrast=p_postcontrast_FDR>=0.05;
                tval_postcontrast_FDR= tval2;
                tval_postcontrast_FDR(nonsigloc_postcontrast,:)=0;
                figure;plot(tval_difftest_FDR);hold on;plot(tval_postcontrast_FDR);legend({'Significant difference in between-subject Discriminability (LDt)','Significant difference in Within-subject Discriminability (LDt)'});
                %% Collect results
                statresults{subi,hi}.tstat_BGdiffbminusWGdiff=tval;
                statresults{subi,hi}.pvalue_BGdiffbminusWGdiff=pval;
                statresults{subi,hi}.tstat_BGpostminusWGpost=tval2;
                statresults{subi,hi}.pvalue_BGpostminusWGpost=pval2;
                statresults{subi,hi}.tstat_difftest=tval_difftest_FDR;
                statresults{subi,hi}.pvalue_difftest=p_difftest_FDR;
                statresults{subi,hi}.tstat_postcontrast=tval_postcontrast_FDR;
                statresults{subi,hi}.pvalue_postcontrast=p_postcontrast_FDR;
                statresults{subi,hi}.preb=preb;
                statresults{subi,hi}.postb=postb;
                statresults{subi,hi}.prew=prew;
                statresults{subi,hi}.postw=postw;
                delete(f);
% Section: case-block starts
            case 'TFCE'
                allsls=unique(preposttbl.Searchlight);
                hbar =parfor_progressbar(length(allsls),'Extracting LDC values');
                sls_currentsesshemi=cell(length(allsls),1);
% Section: parfor-block starts
                parfor(sli = 1:length(allsls),16)
                    cursl=allsls{sli};
                    sls_currentsesshemi{sli}=cursl;
                    curtbl=preposttbl(strcmp(preposttbl.Searchlight,cursl),:);
                    prew(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-02'));
                    postw(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-03'));
                    preb(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-02'));
                    postb(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-03'));
                    hbar.iterate(1);
                end
                close(hbar);
                slnames{hi}=sls_currentsesshemi;
                statresults{hi}.preb=preb;
                statresults{hi}.prew=prew;
                statresults{hi}.postb=postb;
                statresults{hi}.postw=postw;
% Call → NCPG_LDt_TFCE: Project function call
                signodes_surf{hi}=NCPG_LDt_TFCE(wf, statresults{hi},oldds{hi},curhemi,maskname);
        end
    end
end
end
