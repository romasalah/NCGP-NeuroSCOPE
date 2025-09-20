% ==========================================================================
% Overall goal (user-provided): Overall goal: Main Function for testing hypothesis 3. The function calculates the Spearman correlation coefficient Rho between LDt value for each searchlight and each one of the three behavioural dissimilarity matrices for (Physical appearance, personality, and social life).
% ==========================================================================
function  [ds_rsm_behav, allRSMs_masked_subsesshemi]=NCGP_surface_searchlight_rsm(wf, ds, nbrhood_nodes, nbr_subsesshemi_mask, taskname, vo, fo)
%% Settings
sessions=wf.sessions;
mainPath = wf.mainpath;
persons = wf.subs;
% Call → NCGP_paths
paths=NCGP_paths(wf);
allhemis=wf.hemis;
% Section: for-block starts
for subi =1:length(persons)
    sublbl=persons{subi};
    decodingresdir=[mainPath filesep wf.alignment filesep wf.decoding filesep sublbl filesep wf.pre filesep wf.glm filesep];
    mkdir(decodingresdir);
% Section: for-block starts
    for si=1:length(sessions)
        cursession=sessions{si};
% Section: for-block starts
        for hi =1:length(allhemis)
            curhemi=allhemis{hi};
            %% Load models RDM
            curmodelname='';
            target_dsm=wf.curRDM;
            target_dsmt=target_dsm' + target_dsm;
            % set measure
            measure=@cosmo_target_dsm_corr_measure;
            measure_args=struct();
            measure_args.target_dsm=target_dsmt;
            measure_args.metric= 'correlation';
            measure_args.center_data= true;
            % run searchlight
          curds=ds{subi,si}{hi};
          curnbrhood=nbrhood_nodes{subi,si}{hi};
% Toolbox call → cosmo_split
          minds=cosmo_split(curds, 'chunks');
% Toolbox call → surfing_read
          maskdset=surfing_read([strrep(wf.maskhemis{hi},'.nii','+orig.niml.dset')]);
          mask_idx=find(maskdset.data);
          currsmbehav={};
% Section: for-block starts
          for runi=1:length(minds)
% Toolbox call → cosmo_searchlight
          currsmbehav{runi}=cosmo_searchlight(minds{runi},curnbrhood,measure,measure_args);
% Toolbox call → cosmo_slice
          currsmbehav_masked{runi}=cosmo_slice(currsmbehav{runi},mask_idx,2);
          allRSMs(:,:,runi)=currsmbehav{runi}.samples;
          allRSMs_masked(:,:,runi)=currsmbehav_masked{runi}.samples;
          end
% Toolbox call → cosmo_stack
        ds_rsm_behav{subi,si}{hi}=cosmo_stack(currsmbehav);
        allRSMs_masked_subsesshemi{subi,si}{hi}=allRSMs_masked;

        outputfolder=[paths.mp 'RDMcorr' filesep wf.subs{subi} filesep wf.pre filesep wf.glm filesep ];
        mkdir(outputfolder)
        fnprefix=[outputfolder 'sub-' wf.subs{subi} '_' wf.sessions{si} '_task-' wf.task '_hemi-' curhemi '_run-avg_RDM-'  taskname];
        curimg_native=[ fnprefix '.niml.dset' ];
        curmatfn=[ fnprefix '_masked.mat' ];
        curmatfullfn=[ fnprefix '_full_masked.mat' ];
        save(curmatfn,'allRSMs_masked');
        save(curmatfullfn,'allRSMs');
        allRSMsavg=mean(allRSMs_masked,3);        
        opt.ShowEdge=true;
        empnodes=zeros(1,length(vo{subi,si}{hi}));
        empnodes(mask_idx)=allRSMsavg;
        DispIVSurf(vo{subi,si}{hi},fo{subi,si}{hi},1:length(vo{subi,si}{hi})',empnodes',0,opt);
        title([wf.sessions{si} ' hemi-' curhemi ' run-avg RDM-'  taskname]);
        
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(ds_rsm_behav{subi,si}{hi},curimg_native);
    end
end
end
end
