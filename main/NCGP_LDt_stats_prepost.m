% ==========================================================================
% Overall goal: Searchlight-level statistical testing of LDt changes (between-group vs within-group) with multiple-comparison control.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function [statresults,signodes_surf]=NCGP_LDt_stats_prepost(wf, maskname, ldt_avgruns)
signodes_surf=[];
% Section: for-block starts
bg_idx_rows=[1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4]';
bg_idx_cols=[5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8]';
bg_idx=[bg_idx_rows, bg_idx_cols];
wg_idx_rows=[1,1,1,2,2,3,5,5,5,6,6,7]';
wg_idx_cols=[2,3,4,3,4,4,6,7,8,7,8,8]';
wg_idx=[wg_idx_rows, wg_idx_cols];

for hi=1:length(wf.hemis)
    curhemi=wf.hemis{hi};
    % Call → NCGP_paths: Project function call
    paths=NCGP_paths(wf);
    outputfolder=[paths.mp 'LDC' filesep wf.subs{1} filesep wf.pre filesep wf.glm filesep ];
    for sesi = 1:2
        clear allwg
        clear allbg
        curldt=ldt_avgruns{sesi,1};
        for sli = 1:size(curldt,1)
            cursl_RDM = curldt{sli,1};
            cursl_wg=[];
            cursl_bg=[];
            for wgi= 1:size(wg_idx,1)
                cursl_wg(end+1)=cursl_RDM(wg_idx(wgi,1), wg_idx(wgi,2));
            end
            for bgi= 1:size(bg_idx, 1)
                cursl_bg(end+1)=cursl_RDM(bg_idx(bgi,1), bg_idx(bgi,2));
            end
            allwg(sli,:)=cursl_wg;
            allbg(sli,:)=cursl_bg;
        end
        if sesi == 1
            statresults{hi}.preb=allbg;
            statresults{hi}.prew=allwg;
        elseif sesi==2
            statresults{hi}.postb=allbg;
            statresults{hi}.postw=allwg;
        end 

    end
    % Call → NCGP_LDt_TFCE: Project function call
    oldds{hi}={};
    signodes_surf{hi}=NCGP_LDt_TFCE_prepost(wf, statresults{hi},oldds{hi},curhemi,maskname);

end
end