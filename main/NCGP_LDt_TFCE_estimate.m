% ==========================================================================
% Overall goal (user-provided): Overall goal: Estimates threshold free cluster enhancement model using 10 thousand permutations. Options are SPM TFCE toolbox or MATLAB TFCE toolbox
% ==========================================================================
function g=NCGP_LDt_TFCE(wf,TFCEmethod, hemimasks,spmmats,maskname, ds)
% Section: switch-block starts
switch TFCEmethod
% Section: case-block starts
    case 'matlabTFCE'
        nsim=1000;
% Section: for-block starts
        for hi = 1:length(wf.hemis)
            cur_diffsess=sessdiff_nii{hi};
            cur_postcontrast=postcontrast_nii{hi};
            %% independent sample ttest, one-sided
            fp = NaN(nsim,1);
            img1_all=load_untouch_nii(cur_diffsess);
            img2_all=load_untouch_nii(cur_postcontrast);
            all_nonemp=union(find(img1_all.img),find(img2_all.img));
            % Convert the linear indices to subscripts (x, y, z coordinates)
            [x, y, z] = ind2sub(size(img1_all.img), all_nonemp);
            coordinates = [x, y, z];
            imsz=length(all_nonemp);
            img1=img1_all.img;
            img2=img2_all.img;
            img1=ones(imsz,imsz,imsz,2);
            img2=img1;
            img2(:,:,:,1)=img2_all.img;
% Section: for-block starts
            for i = 1:nsim
                [pcorr_pos] = matlab_tfce('independent',1,img1,img2);
                fp(i) = sum(pcorr_pos(:)<.05)+sum(pcorr_neg(:)<.05);
            end
            sum(fp>0)/nsim % false positive rate
        end
% Section: case-block starts
    case 'SPM'
% Section: for-block starts
        for hi =1:length(wf.hemis)
        spm( 'defaults', 'fmri' );
% Toolbox call → spm_jobman
        spm_jobman( 'initcfg' );
        clear matlabbatch
        matlabbatch{1}.spm.tools.tfce_estimate.data = {spmmats};
        matlabbatch{1}.spm.tools.tfce_estimate.nproc = 10;
        matlabbatch{1}.spm.tools.tfce_estimate.mask = {[hemimasks ',1']};
        matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr = '';
        matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts = [1 2];
        matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm = 10000;
        matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method = 2;
        matlabbatch{1}.spm.tools.tfce_estimate.tbss = 0;
        matlabbatch{1}.spm.tools.tfce_estimate.E_weight = 0.5;
        matlabbatch{1}.spm.tools.tfce_estimate.singlethreaded = 0;
% Toolbox call → spm_jobman
        spm_jobman( 'run', matlabbatch );
        
        end

end
end
