function [LLMdes_RSMrun, LLMdes_RSMrun_FDR]=NCGP_searchlightRDM2LLM(wf,slRSMcell,sigFDR_idx, node_indices_masked, taskname,maskname)
% ==========================================================================
% Overall goal: Package searchlight correlation/LDt values into tabular form for LLM ingestion.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
LLMdes_RSMrun=[];
LLMdes_RSMrun_FDR=[];
    cursub='group';
% Section: for-block starts
    for si=1:length(wf.sessions)
        cursession=wf.sessions{si};
% Section: for-block starts
        for hi=1:length(wf.hemis)
            curhemi=wf.hemis{hi};
            curslRSM=slRSMcell{si,hi};
            %curslRSM=permute(curslRSM, [2,3,1]);
            empchar=cellstr(num2str(ones(size(curslRSM,1),1)));
            empslchar=strrep(cellstr(num2str([1:size(curslRSM,1)]')), ' ', '0');
            slchar=cellfun(@(x) ['SL-' x], empslchar, 'UniformOutput',false);
            subchar=strrep(empchar, '1', cursub);
            seschar=strrep(empchar, '1', cursession);
            hemichar=strrep(empchar, '1', curhemi);
            taskchar=strrep(empchar, '1', taskname);
% Section: for-block starts
            for ri=1:size(curslRSM, 2)
                runchar=strrep(empchar, '1', ['run-' num2str(ri)]);
                curFFX=[subchar seschar hemichar taskchar runchar slchar  num2cell(curslRSM(:,ri))];
                LLMdes_RSMrun=[LLMdes_RSMrun; curFFX];
            end
            curslRSM_FDR=curslRSM(sigFDR_idx{si,hi}, :);
            sigidx=(sigFDR_idx{si,hi});
% Section: if-block starts
            if ~isempty(curslRSM_FDR)
% Section: for-block starts
            for ri=1:size(curslRSM_FDR, 2)
                runchar=strrep(empchar, '1', ['run-' num2str(ri)]);
                curFFX=[subchar(sigidx) seschar(sigidx) hemichar(sigidx) taskchar(sigidx) runchar(sigidx) slchar(sigidx)  num2cell(curslRSM_FDR(:,ri))];
                LLMdes_RSMrun_FDR=[LLMdes_RSMrun_FDR; curFFX];
            end
            end
        
    end
end
% Call → NCGP_paths: Project function call
paths=NCGP_paths(wf);
outputfolder=[paths.mp 'RDMcorr' filesep cursub filesep wf.pre filesep wf.glm filesep ];
fnprefix=[outputfolder 'sub-group_task-' wf.task '_RDM-'  taskname '_mask-' maskname '_corr-none_LLM.xlsx'];
LLMdes_RSMrun_tbl=array2table(LLMdes_RSMrun, 'VariableNames',{'Subject', 'Session', 'Hemisphere', 'Task', 'Run', 'ROI', 'RDMCorr'});
writetable(LLMdes_RSMrun_tbl ,fnprefix);
% Section: if-block starts
if ~isempty(curslRSM_FDR)
fnprefix_FDR=[outputfolder 'sub-group_task-' wf.task '_RDM-'  taskname '_mask-' maskname '_corr-FDR_LLM.xlsx'];
LLMdes_RSMrun_FDR_tbl=array2table(LLMdes_RSMrun_FDR, 'VariableNames',{'Subject', 'Session', 'Hemisphere', 'Task', 'Run', 'ROI', 'RDMCorr'});
writetable(LLMdes_RSMrun_FDR_tbl ,fnprefix_FDR);
end
end
