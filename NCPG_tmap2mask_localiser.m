% ==========================================================================
% Overall goal: Failed to guess the function goal from project context. (Per request, leaving file body unannotated.)
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
function [allnii,roismat,wholeroismat,newmaskbin]=NCPG_tmap2mask_localiser(localiserspmmatdir,conimgname,loc_sessions,loc_runs,runsprefix)
mainPath = '/Volumes/EVO8602TB/NCPG/Data/';
q = dir([mainPath]);
subjNames = cellstr(char(q(3:end).name));

% ------------- Cycle through subjects ------------------------------------
for person = 1 : length( subjNames )
    %% delete old ROIs
    pwd=cd;
    cd(localiserspmmatdir)
    system(['rm ' runsprefix '*_roi*.mat']);
    system(['rm ' runsprefix '*_roi.nii']);
    cd(pwd);
    subjName = subjNames{ person };
    if strcmp(subjName(1), '.')
        continue
    end
    df=dir([mainPath subjName filesep loc_sessions{1} filesep loc_runs{1} filesep 'meanurf*.nii']);
    referenceloc=[df(1).folder filesep df(1).name];
    %% ############################################################################################################
    %############################ Localizer Space ####################### Localizer Space #############################
    %###################################################################################################################
    %% Remove negative blobs
    oldmaskname=[localiserspmmatdir filesep conimgname]; % the old unregistered mask
    clustermtimg=load_untouch_nii(oldmaskname);
    pmtimg=load_untouch_nii([localiserspmmatdir filesep 'spmT_0001.nii']);
    nonpos_belowthresh_loc=find(pmtimg.img<=0 & clustermtimg.img==0);
    clustermtimg.img(nonpos_belowthresh_loc)=0;
    oldmaskname_pos_unsmoothed=[localiserspmmatdir strrep(conimgname,'.nii','') '_pos.nii'];
    save_untouch_nii(clustermtimg,oldmaskname_pos_unsmoothed);
    %% ############################################################################################################
    %############################ Session Space ####################### Session Space #############################
    %###################################################################################################################
    %% extract ROIs from SPM image
    mars_img2rois(oldmaskname_pos_unsmoothed,localiserspmmatdir,[runsprefix '_' strrep(conimgname,'.nii','')],'c');
    roismat=dir([localiserspmmatdir filesep runsprefix '_' strrep(conimgname,'.nii','') '*_roi.mat']);
    allnii={};
    sp = mars_space(referenceloc); % get image space
    %% export ROIs to separate images
    for i=1:size(roismat,1)
        curroi= [roismat(i).folder filesep roismat(i).name];
        allnii{i}=strrep(roismat(i).name,'.mat','.nii');
        allrois{i}=curroi;
        mars_rois2img(curroi, [localiserspmmatdir filesep allnii{i}],sp);
    end
    %% combine ROIs to one image and binarize it and get a big ROI
    combinedroisname=[localiserspmmatdir filesep runsprefix '_' strrep(conimgname,'.nii','') '_newcombinedrois.nii'];
    combinedrois_binname=[localiserspmmatdir filesep runsprefix '_' strrep(conimgname,'.nii','') '_newcombinedrois_bin.nii'];
    %% output
    wholeroismat=[runsprefix '_' strrep(conimgname,'.nii','') '_bin_1_roi.mat'];
    wholeroismat=dir([localiserspmmatdir wholeroismat]);
end
end