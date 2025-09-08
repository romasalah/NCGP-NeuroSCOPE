% ==========================================================================
% Overall goal (user-provided): Overall goal: Converts hypothesis 2 results from surface-based NIML datasets to volumetric images.
% Note: Added comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Converts hypothesis 2 results from surface-based NIML datasets to volumetric images.
% Note: 
% ==========================================================================
% Function signature
function [preb_vols,prew_vols,postb_vols,postw_vols]=NCPG_LDt_TFCE_surf2vol(wf, LDCvals,oldds,curhemi,maskname)
% Call → NCPG_paths
paths=NCPG_paths(wf);
outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
mkdir(outputfolder);
empvec=zeros(length(oldds.samples),1);
imgdesc=['mask-' maskname '_hemi-' curhemi '_'];
%% limit t-vals to the mask
curpreb=LDCvals.preb;
curprew=LDCvals.prew;
curpostb=LDCvals.postb;
curpostw=LDCvals.postw;
% Section: for-block starts
for prebi=1:size(curpreb,2)
    curimg_name=['preb_' imgdesc num2str(sprintf('%02d',prebi))];
    cur_data=curpreb(:,prebi);
    cur_data(isnan(cur_data))=0;
    curtmap_ds=oldds;
    curtmap_ds.samples=cur_data';
    curtmap_ds.sa=struct();
    preb_vols{prebi}=[outputfolder curimg_name '.nii'];
% Section: if-block starts
    if exist(preb_vols{prebi},'file')~=2
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(curtmap_ds,[ outputfolder curimg_name '.niml.dset']);
% Call → NCPG_surf2vol
        wf.sfx='a';
        NCPG_surf2vol(wf, outputfolder, [ curimg_name '.niml.dset'], curhemi)
    end
end
% Section: for-block starts
for prewi=1:size(curprew,2)
    curimg_name=['prew_' imgdesc num2str(sprintf('%02d',prewi))];
% Section: switch-block starts
    switch maskname
% Section: case-block starts
        case 'none'
            cur_data=curprew(:,prewi);
% Section: case-block starts
   end
    cur_data(isnan(cur_data))=0;
    curtmap_ds=oldds;
    curtmap_ds.samples=cur_data';
    curtmap_ds.sa=struct();
    prew_vols{prewi}=[outputfolder curimg_name '.nii'];
% Section: if-block starts
    if exist(prew_vols{prewi},'file')~=2
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(curtmap_ds,[ outputfolder curimg_name '.niml.dset']);
% Call → NCPG_surf2vol
        NCPG_surf2vol(wf, outputfolder, [ curimg_name '.niml.dset'], curhemi)
    end
end
% Section: for-block starts
for postbi=1:size(curpostb,2)
    curimg_name=['postb_' imgdesc num2str(sprintf('%02d',postbi))];
% Section: switch-block starts
    switch maskname
% Section: case-block starts
        case 'none'
            cur_data=curpostb(:,postbi);
% Section: case-block starts
 end
    cur_data(isnan(cur_data))=0;
    curtmap_ds=oldds;
    curtmap_ds.samples=cur_data';
    curtmap_ds.sa=struct();
    postb_vols{postbi}=[outputfolder curimg_name '.nii'];

% Section: if-block starts
    if exist(postb_vols{postbi},'file')~=2

% Toolbox call → cosmo_map2surface
        cosmo_map2surface(curtmap_ds,[ outputfolder curimg_name '.niml.dset']);
% Call → NCPG_surf2vol
        NCPG_surf2vol(wf, outputfolder, [ curimg_name '.niml.dset'], curhemi)
    end
end
% Section: for-block starts
for postwi=1:size(curpostw,2)
    curimg_name=['postw_' imgdesc num2str(sprintf('%02d',postwi))];
% Section: switch-block starts
    switch maskname
% Section: case-block starts
        case 'none'
            cur_data=curpostw(:,postwi);
% S
  end
    cur_data(isnan(cur_data))=0;
    curtmap_ds=oldds;
    curtmap_ds.samples=cur_data';
    curtmap_ds.sa=struct();
    postw_vols{postwi}=[outputfolder curimg_name '.nii'];
% Section: if-block starts
    if exist(postw_vols{postwi},'file')~=2
% Toolbox call → cosmo_map2surface
        cosmo_map2surface(curtmap_ds,[ outputfolder curimg_name '.niml.dset']);
% Call → NCPG_surf2vol
        NCPG_surf2vol(wf, outputfolder, [ curimg_name '.niml.dset'], curhemi);
    end
end
end
