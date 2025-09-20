% ==========================================================================
% Overall goal: Export LDt (or RDM-like) matrices across sessions/hemispheres into files for later stats/LLM usage.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function full_FFXtbl=NCGP_RDM_export(wf, LDt, searchlights, vo, fo, maskname, masknodes)
    cursub='group';
% Section: for-block starts
    for si = 1:length(wf.sessions)
        cursess=wf.sessions{si};
% Section: for-block starts
        for hi = 1:length(wf.hemis)
            allFFX_hemi{si, hi}={};
            full_FFXtbl{si, hi}=cell(0,6);
            curhemi= wf.hemis{hi};
            cursubsesshemi_sl= searchlights{si, hi};
            cursubsesshemi_vo= vo{si, hi};
            cursubsesshemi_fo= fo{si, hi};
% Section: if-block starts
            if ~isempty(masknodes)
                curmasknodes=masknodes{si, hi};
% Section: else-block starts
            else
                curmasknodes=1:length(cursubsesshemi_vo);
            end
            LDt_sub_sess=LDt{si}(:,hi);
% Section: for-block starts
            for li=1:size(LDt_sub_sess,1)
% Call → NCGP_RDM_flatten: Flatten square RDM/LDt matrices into a long-form table (pairwise rows) for statistical analysis.
                curldt=NCGP_RDM_flatten(LDt_sub_sess{li,hi});
                cursl=curmasknodes(li);
                roifx= strrep(cellstr(num2str(zeros(28,1) + cursl)), num2str(cursl), ['SL_' num2str(sprintf('%06d', cursl))]);
                sessfx= strrep(cellstr(num2str(zeros(28,1))), '0', cursess);
                hemifx= strrep(cellstr(num2str(zeros(28,1))), '0', curhemi);
                subfx= strrep(cellstr(num2str(zeros(28,1))), '0', cursub);
                infofx=[subfx roifx sessfx hemifx];
                curFFXtbl= horzcat(infofx, curldt);
                full_FFXtbl{si, hi}=[full_FFXtbl{si, hi}; curFFXtbl];
            end
% Call → NCGP_paths: Project function call
            paths=NCGP_paths(wf);
            outputfolder=[paths.mp 'LDC' filesep cursub filesep wf.pre filesep wf.glm filesep ];
            mkdir(outputfolder)
            fnprefix=[outputfolder 'sub-' cursub '_' wf.sessions{si} '_task-' wf.task '_hemi-' curhemi '_mask-' maskname ];
            curmatfn=[ fnprefix '_LLM.mat' ];
            save(curmatfn,'full_FFXtbl');
            writetable(array2table(full_FFXtbl{si, hi}, 'VariableNames',{'Subject', 'Searchlight', 'Session', 'Hemisphere', 'Contrast', 'LDCvalue'}), [fnprefix '_LLM.csv']);
            allFFX_hemi{si, hi}= full_FFXtbl{si, hi};
        end
    end
    fields={'Subject', 'Searchlight', 'Session', 'Hemisphere', 'Contrast', 'LDCvalue'};
% Section: for-block starts
    for hi = 1:length(wf.hemis)
        curhemi= wf.hemis{hi};
        allFFXcat_hemi{hi}=cell(0,6);
        %array2table(allFFXcat_hemi{subi}{hi},'VariableNames',fields)
% Section: for-block starts
        for si = 1:length(wf.sessions)
            allFFXcat_hemi{hi} = [allFFXcat_hemi{hi}; allFFX_hemi{si, hi}];
        end
        fnprefix=[outputfolder 'sub-' cursub '_task-' wf.task '_hemi-' curhemi '_mask-' maskname '_ses-all' ];
        curmatfn=[ fnprefix '_prepost_LLM.mat' ];
        save(curmatfn,'allFFXcat_hemi');
        writetable(array2table(allFFXcat_hemi{hi}, 'VariableNames',fields), [fnprefix '_prepost_LLM.csv']);
        outputfolder=[paths.mp 'LDC' filesep cursub filesep wf.pre filesep wf.glm filesep ];
        fnprefix=[outputfolder 'sub-' cursub '_task-' wf.task '_hemi-' curhemi '_mask-' maskname  '_ses-all' ];
        llmdesfn=[fnprefix '_prepost_LLM.csv'];
        preposttbl=readtable(llmdesfn);
        con=preposttbl.Contrast;
        cons=str2double(cellstr(split(con, '_')));
        wg1=sum(cons<5,2)==2;
        wg2=sum(cons>4,2)==2;
        allwg=wg1+wg2;
        wgbg=strrep(cellstr(num2str(allwg)), '1', 'Within-group');
        wgbg=strrep(wgbg, '0', 'Between-group');
        preposttbl.Contrast=wgbg;
        writetable(preposttbl,[fnprefix '_prepost_LLM_crctd.csv']);
    end
end
