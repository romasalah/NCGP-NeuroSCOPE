% ==========================================================================
% Overall goal (user-provided): Overall goal: Creates a Face > objects or scenes contrast using volumetric images and creates a cluster image
% ==========================================================================
function [conimgname, conimg_clustNum]=NCGP_localiser_contrast(wf,spmdir, threshold, mink, runscell)
runs=wf.runs;
%%  ---------- contrasts --------------------------------------
spm('defaults','fMRI');
motionregs=zeros(1,12);
wf.contrast='Faces_morethan_Objects';
cons{1,1} = wf.contrast;
conimgname=[ 'spmT_0001_' cons{1,1} '.nii'];
conimg_clustNum=[ cons{1,1} '_ClustNum.nii'];
% Section: if-block starts
if exist([spmdir filesep conimgname],'file')==2
    disp(['Contrast Image Found ' spmdir filesep conimgname ' , Skipping...']);
    return
% Section: else-block starts
else
% Section: switch-block starts
switch wf.exp
% Section: case-block starts
    case 'NCGP'
        %         cons{1,1} = ['Faces_morethan_Others' ];
        %         consbase=[-1 4 0 0 -1 -1 -1 zeros(1,12)];
        convals{1}={'Face','Object'};
        convals{2}=[1, -1];
end
convals{2}=cellstr(num2str(convals{2}'));
c={};
% Section: for-block starts
for subi = 1:length(wf.subs)
% Section: for-block starts
    for runi = 1:length(runscell{subi})
        c{end+1}=[ runscell{subi}{runi,1} '_' runscell{subi}{runi,2}];
    end
end
spmmat=load([spmdir filesep 'SPM.mat']);
Sessdata=spmmat.SPM.Sess(:);
condnum=cellfun(@(x) {x(:).name},{Sessdata.U},'UniformOutput',false);
curcond={};
curcond_conc={};
% Section: for-block starts
for runi= 1 : length(condnum)
    curcond{runi}={};
    curcond{runi}=cellfun(@(x) vertcat(curcond{runi},cellstr(x{1})), condnum{runi}', 'UniformOutput' , false);
    curcond{runi}=cellfun(@(x) x{1},curcond{runi},'UniformOutput',false);
    curcond_deriv{runi}={};
% Section: for-block starts
    for ci=1:length(curcond{runi})
% Section: if-block starts
        if sum(wf.HRF.deriv)==2
        curcond_deriv{runi}=vertcat(curcond_deriv{runi}, vertcat(curcond{runi}{ci},{'0';'0'}));
% Section: elseif-block starts
        elseif sum(wf.HRF.deriv)==0
        curcond_deriv{runi}=vertcat(curcond_deriv{runi}, curcond{runi}{ci});
        end
    end
    curcond_conc= vertcat(curcond_conc,vertcat(curcond_deriv{runi},cellstr(num2str(motionregs'))));
end
% Section: for-block starts
for condrepi =1:length(convals{1})
    curcond_conc=strrep(curcond_conc,convals{1}{condrepi}, convals{2}{condrepi});
end
weights_const = zeros(1,length(condnum));
allcon_nans=[str2double(curcond_conc)' weights_const];
allcon_nans(isnan(allcon_nans))=0;
cons{1,2}=allcon_nans;
%% create contrast image
clear matlabbatch;
matlabbatch{1}.spm.stats.con.spmmat = { [spmdir filesep 'SPM.mat'] };
matlabbatch{1}.spm.stats.con.delete = 1;
matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = cons{1,1};
matlabbatch{1}.spm.stats.con.consess{1}.tcon.convec = cons{1,2};
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{1}.spm.stats.results.spmmat = { [spmdir filesep 'SPM.mat'] };
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
%% create threasholded t-map image
clear matlabbatch;
conimgname=[ 'spmT_0001_' cons{1,1} '.nii'];
cc=dir([spmdir filesep 'spmT*' cons{1,1} '*.nii']);
% Section: for-block starts
for i=1:size(cc,1)
    delete([cc(1).folder filesep cc(i).name]);
end
matlabbatch{1}.spm.stats.results.spmmat = { [spmdir filesep 'SPM.mat']};
matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
matlabbatch{1}.spm.stats.results.conspec.contrasts =1;
matlabbatch{1}.spm.stats.results.conspec.threshdesc = wf.mcc;
matlabbatch{1}.spm.stats.results.conspec.thresh = threshold;
matlabbatch{1}.spm.stats.results.conspec.extent = mink;
matlabbatch{1}.spm.stats.results.units = 1;
matlabbatch{1}.spm.stats.results.print = true;
matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
matlabbatch{1}.spm.stats.results.conspec.mask.image.name = {[spmdir filesep 'mask.nii']};
matlabbatch{1}.spm.stats.results.conspec.mask.image.mtype = 0;
matlabbatch{1}.spm.stats.results.units = 1;
matlabbatch{1}.spm.stats.results.export{1}.tspm.basename = [ cons{1,1}];
matlabbatch{1}.spm.stats.results.export{2}.nary.basename = [ cons{1,1} '_ClustNum'];
% Toolbox call → spm_jobman
spm_jobman( 'run', matlabbatch );
end
end
