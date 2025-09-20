% Overall goal: Extract condition-wise beta estimates and residuals per searchlight;
% assemble 4D surface datasets. Place in pipeline: Surface-based MVPA workflow
% (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
function [betasfn, nscans_subrun] = NCGP_extract_betasres(wf, betasds, beta_loc_allsubs, beta_loc_group, nbrhood_sl, maskname, presaved_betas_flag )
% Toolbox call → cosmo_surface_dataset
ressds = cosmo_surface_dataset([beta_loc_group '4dsurf_res.niml.dset']);
allres= single(ressds.samples); % Get the whole dataset for this searchlight
%subresscans_start=0;
% reload saved data if found
betasfn=[beta_loc_group 'betas_condbyrun_mask-' maskname '.mat'];
%% Get Residuals number for each subject
nscans_subrun={};
scanid_st=0;
for subi =1:length(wf.origsubs)
    beta_loc=beta_loc_allsubs{subi};
    spmmat=load([beta_loc 'SPM.mat']);
    runlgs=cellfun(@length, {spmmat.SPM.Sess.row});
    scanslimit{subi}=min(runlgs);
    totalsubscans=sum(runlgs);
% Section: for-block starts
    for ri=1:length(runlgs)
        scanid_en=scanid_st+runlgs(ri);
        currunscans{ri}=scanid_st+1:scanid_en;
        nscans_subrun{end+1,1}=wf.origsubs{subi};
        nscans_subrun{end,2}=runlgs(ri);
        nscans_subrun{end,3}=scanslimit{subi};
        nscans_subrun{end,4}=currunscans{ri}(1:scanslimit{subi});
        scanid_st=scanid_en;
    end
end
globalscanslimit=min(cell2mat(nscans_subrun(:,3)));
for ri2=1:size(nscans_subrun,1)
nscans_subrun{ri2, 5} = globalscanslimit;
end
if presaved_betas_flag == 1
if exist(betasfn, 'file') ==2
    warning("Using Saved beta values for each searchlight. Please double check that they are not outdated.")
    %load(betasfn)
    return
end
end
%% loop over the searchlights
betas_condbyrun=cell(length(nbrhood_sl), length(wf.hemis));
%res_condbyrun=cell(length(nbrhood_sl), length(wf.hemis));
hbar = parfor_progressbar(length(nbrhood_sl),'Extracting beta values and residuals from searchlights');  %create the progress bar
% Toolbox call → cosmo_split
dsbycond=cosmo_split(betasds,'targets',1); % Split the dataset by condition
% Section: for-block starts
for ci =1:size(dsbycond,2)
    dsbycond_mat(:,:,ci)=dsbycond{ci}.samples;
end
dsbycond_mat=single(permute(dsbycond_mat, [2 1 3]));
disp('Extracting beta values and residuals from searchlights');
delete(gcp('nocreate'));
parpool('local',2);
parfor roii=1:length(nbrhood_sl)
    hbar.iterate(1);
    cursl=nbrhood_sl{roii};
    for ci=1:size(dsbycond,2)
        betas_condbyrun{roii}(:,:,ci) = dsbycond_mat(cursl,:,ci);
    end
end
close(hbar);
save(betasfn, 'betas_condbyrun', 'allres', '-v7.3');
end