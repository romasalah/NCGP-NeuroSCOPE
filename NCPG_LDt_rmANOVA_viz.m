% ==========================================================================
% Overall goal (user-provided): Overall goal: Converts volumetric images resulting from hypothesis 2 to NIML surfaces using CosmoMVPA map2surface funtion.
% Note: Added comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Converts volumetric images resulting from hypothesis 2 to NIML surfaces using CosmoMVPA map2surface funtion.
% Note:
% ==========================================================================
% Function signature
function NCPG_LDt_rmANOVA_viz(wf, stats_struct, vo, fo, maskname, slnames, oldds)
% Section: for-block starts
for subi = 1: length(wf.subs)
% Section: for-block starts
    for hi = 1:length(wf.hemis)
        curbres=stats_struct{subi,hi}.bressig;
        curwres=stats_struct{subi,hi}.wressig;

        slnames_num= str2double(strrep(slnames{subi,hi}', 'SL_', ''));
        curhemi=wf.hemis{hi};
% Call → NCPG_paths
        paths=NCPG_paths(wf);
        outputfolder=[paths.mp 'LDC' filesep wf.subs{subi} filesep wf.pre filesep wf.glm filesep ];
        mkdir(outputfolder)
        descbase=['sub-' wf.subs{subi} '_task-' wf.task '_hemi-' curhemi '_mask-' maskname '_corr-FDR_LDCdiff'];
        %% Between-subject
        desc_b=[descbase '_betweensubject'];
        curimg_b=[outputfolder desc_b '.niml.dset' ];
        opt.ShowEdge=true;
        empnodes_b=zeros(1,length(vo{subi,1}{hi}));
        empnodes_b(slnames_num)=curbres(:,1);
        DispIVSurf(vo{subi,1}{hi},fo{subi,1}{hi},1:length(vo{subi,1}{hi})',empnodes_b',0,opt);
        title(strrep(desc_b,'_','-'));
        savefig(desc_b)
        ds_b{subi,1}{hi}=oldds{subi,1}{hi};
        ds_b{subi,1}{hi}.samples=empnodes_b;
        ds_b{subi,1}{hi}.sa=struct();
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(ds_b{subi,1}{hi},curimg_b);
        %% Within-subject
        desc_w=[descbase '_withinsubject'];
        curimg_w=[outputfolder desc_w '.niml.dset' ];
        empnodes_w=zeros(1,length(vo{subi,1}{hi}));
        empnodes_w(slnames_num)=curwres(:,1);
        DispIVSurf(vo{subi,1}{hi},fo{subi,1}{hi},1:length(vo{subi,1}{hi})',empnodes_w',0,opt);
        title(strrep(desc_w,'_','-'));
        savefig(desc_w)
        ds_w{subi,1}{hi}=oldds{subi,1}{hi};
        ds_w{subi,1}{hi}.samples=empnodes_b;
        ds_w{subi,1}{hi}.sa=struct();
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(ds_w{subi,1}{hi},curimg_w);
    end
end
end
