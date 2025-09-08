% ==========================================================================
% Overall goal: Create and write t-statistic visualizations (localizer-masked or whole-brain) for LDt difference tests.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function [sig, sessdiff_nii, postcontrast_nii ]=NCPG_LDt_Diffttest_viz(wf, ttest_stats, vo, fo, maskname, slnames, oldds,maskidx_subsesshemi, MCC)
% Call → NCPG_paths: Project function call
paths=NCPG_paths(wf);
opt.showedges=1;
opt.hold='on';
% Section: for-block starts
for subi = 1: length(wf.subs)
% Section: for-block starts
    for hi = 1:length(wf.hemis)
        curhemi=wf.hemis{hi};
        oldds{subi,hi}.sa=struct();
% Section: for-block starts
        for mci =1:length(MCC)
            empvec=zeros(length(oldds{subi,hi}.samples),1);
            outputfolder=[paths.mp 'LDC' filesep wf.subs{subi} filesep wf.pre filesep wf.glm filesep ];
            mkdir(outputfolder)
            %% get the stats and pvals
% Section: switch-block starts
            switch MCC{mci}
% Section: case-block starts
                case 'none'
                    curtvals_sessdiff=ttest_stats{subi,hi}.tstat_BGdiffbminusWGdiff;
                    curpvals_sessdiff=ttest_stats{subi,hi}.pvalue_BGdiffbminusWGdiff;
                    curtvals_postcontrast=ttest_stats{subi,hi}.tstat_BGpostminusWGpost;
                    curpvals_postcontrast=ttest_stats{subi,hi}.pvalue_BGpostminusWGpost;
% Section: case-block starts
                case 'FDR'
                    curtvals_sessdiff=ttest_stats{subi,hi}.tstat_difftest;
                    curpvals_sessdiff=ttest_stats{subi,hi}.pvalue_difftest;
                    curtvals_postcontrast=ttest_stats{subi,hi}.tstat_postcontrast;
                    curpvals_postcontrast=ttest_stats{subi,hi}.pvalue_postcontrast;
% Section: case-block starts
                case 'TFCE'
                    outputfolder=[outputfolder 'hemi-' curhemi '_mask-' maskname filesep];
% Toolbox call → surfing_read
                    curtvals_sessdiff=surfing_read([outputfolder 'sessdiff_TFCE.nii']);
% Toolbox call → surfing_read
                    curtvals_postcontrast=surfing_read([outputfolder 'sessdiff_TFCE.nii']);
            end
            curtvals_sessdiff((curpvals_sessdiff>0.05 | isnan(curtvals_sessdiff)))=0;
            curtvals_postcontrast((curpvals_postcontrast>0.05 | isnan(curtvals_postcontrast)))=0;
            validnodes= (curtvals_postcontrast~=0 & curtvals_sessdiff~=0);
            validnodes_sessdiffweight= validnodes .* curtvals_sessdiff;
            %% limit t-vals to the mask
% Section: switch-block starts
            switch maskname
% Section: case-block starts
                case 'none'
                    curtvalssd_vec=curtvals_sessdiff;
                    curtvalspc_vec=curtvals_postcontrast;
                    curvalidnodes_vec=validnodes;
                    curWeightedintersect_vec=validnodes_sessdiffweight;
% Section: case-block starts
                case 'localizer'
                    curtvalssd_vec=empvec;
                    curtvalspc_vec=empvec;
                    curvalidnodes_vec=empvec;
                    curWeightedintersect_vec=empvec;
                    curtvalssd_vec(maskidx_subsesshemi{subi,hi})=curtvals_sessdiff;
                    curtvalspc_vec(maskidx_subsesshemi{subi,hi})=curtvals_postcontrast;
                    curvalidnodes_vec(maskidx_subsesshemi{subi,hi})=validnodes;
                    curWeightedintersect_vec(maskidx_subsesshemi{subi,hi})=validnodes_sessdiffweight;
            end
            %% file names
            fnbase= ['sub-' wf.subs{subi} '_task-' wf.task '_hemi-' curhemi '_mask-' maskname '_corr-' MCC{mci}];
            desc_b_sessdiff= [fnbase '_BGdiffbminusWGdiff'];
            desc_b_postcontrast=[fnbase '_BGpostminusWGpost'];
            desc_intersection=[fnbase '_intersection'];
            desc_sessdiffweight=[fnbase '_intersection_weightedBySessionDifference'];
            curimg_sessdiff=[outputfolder desc_b_sessdiff '.niml.dset' ];
            curimg_postcontrast=[outputfolder desc_b_postcontrast '.niml.dset' ];
            curimg_intersection=[outputfolder desc_intersection '.niml.dset' ];
            curimg_sessdiffweight=[outputfolder desc_sessdiffweight '.niml.dset' ];
            %% Change in Between-group LDt minus change in Within-group LDt
            %slnames_num= str2double(strrep(slnames{subi,hi}', 'SL_', ''));
            DispIVSurf(vo{1, hi},fo{1, hi},1:length(vo{1, hi})',curtvalssd_vec,0,opt);
            title(strrep(desc_b_sessdiff,'_','-'));
            savefig(desc_b_sessdiff)
            tmap_ds_sessdiff{subi,hi}=oldds{1,hi};
            tmap_ds_sessdiff{subi,hi}.samples=curtvalssd_vec';
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tmap_ds_sessdiff{subi,hi},curimg_sessdiff);
% Call → NCPG_surf2vol: Project function call
            NCPG_surf2vol(wf, outputfolder, [ desc_b_sessdiff '.niml.dset'], curhemi)
            sessdiff_nii{hi}=[outputfolder desc_b_sessdiff '.nii'];
            %% Session 3 Between-group LDt minus Within-group LDt
            DispIVSurf(vo{1,hi},fo{1, hi},1:length(vo{1, hi})',curtvalspc_vec,0,opt);
            title(strrep(desc_b_postcontrast,'_','-'));
            savefig(desc_b_postcontrast)
            tmap_ds_postcontrast{subi,hi}=oldds{1, hi};
            tmap_ds_postcontrast{subi,hi}.samples=curtvalspc_vec';
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tmap_ds_postcontrast{1, hi},curimg_postcontrast);
% Call → NCPG_surf2vol: Project function call
            NCPG_surf2vol(wf, outputfolder, [ desc_b_postcontrast '.niml.dset'], curhemi)
            postcontrast_nii{hi}=[outputfolder desc_b_postcontrast '.nii'];
            %% intersection result, significant increase in BG than WG + significantly higher BGpost than WGpost
            %% 
            DispIVSurf(vo{1,hi},fo{1, hi},1:length(vo{1, hi})',curvalidnodes_vec,0,opt);
            title(strrep(desc_intersection,'_','-'));
            savefig(desc_intersection);
            tmap_ds_intersection{subi,hi}=oldds{1, hi};
            tmap_ds_intersection{subi,hi}.samples=curvalidnodes_vec';
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tmap_ds_intersection{1, hi},curimg_intersection);
            %% intersection result, significant increase in BG than WG + significantly higher BGpost than WGpost
            DispIVSurf(vo{1,hi},fo{1, hi},1:length(vo{1, hi})',curWeightedintersect_vec,0,opt);
            title(strrep(desc_sessdiffweight,'_','-'));
            savefig(desc_sessdiffweight)
            tmap_sessdiffweight{subi,hi}=oldds{1, hi};
            tmap_sessdiffweight{subi,hi}.samples=curWeightedintersect_vec';
% Toolbox call → cosmo_map2surface
            cosmo_map2surface(tmap_sessdiffweight{1, hi},curimg_sessdiffweight);
            %% Collect results
            sig{mci}{subi,hi}.postcontrast=curtvals_postcontrast;
            sig{mci}{subi,hi}.sessdiff=curtvals_sessdiff;
            sig{mci}{subi,hi}.intersection=validnodes;
            sig{mci}{subi,hi}.intersection_sessdiffweight=validnodes_sessdiffweight;
        end
    end
end
end
