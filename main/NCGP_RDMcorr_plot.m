% ==========================================================================
% Overall goal: Export correlation maps (localizer-masked and whole-brain) for visualization.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% ==========================================================================
function NCGP_RDMcorr_plot(wf, RDMcorr, vo, fo, taskname, maskname, maskidx, sigFDRidx, oldds,MCCMethod, alpha, htail)
% Section: for-block starts
    for si = 1: length(wf.sessions)
% Section: for-block starts
        for hi = 1:length(wf.hemis)
            cursigFDRidx= sigFDRidx{si,hi};
            curmaskidx=maskidx{si,hi};
            curhemi=wf.hemis{hi};
% Call → NCGP_paths: Project function call
            paths=NCGP_paths(wf);
            outputfolder=[paths.mp 'RDMcorr' filesep 'group' filesep wf.pre filesep wf.glm filesep ];
            mkdir(outputfolder)
            desc=['sub-group_' wf.sessions{si} '_task-' wf.task '_hemi-' curhemi '_run-avg_RDM-'  taskname '_mask-' maskname '_alpha-' num2str(alpha) '_tail-' htail '_corr-' MCCMethod];
            curimg_native=[outputfolder desc '.niml.dset' ];
            curRDMcorr=RDMcorr{si,hi};
            opt.ShowEdge=true;
            opt.ColMapRange=[0 1];
            empnodes=zeros(1,length(vo{si,hi}));
            empnodes(curmaskidx(cursigFDRidx))=curRDMcorr(cursigFDRidx);
            DispIVSurf(vo{si,hi},fo{si,hi},1:length(vo{si,hi}),empnodes',0,opt);
            title(strrep(desc,'_','-'));
            oldds{si,hi}.samples=empnodes;
            oldds{si,hi}.sa=struct();
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(oldds{si,hi},curimg_native);
        end
    end
end
