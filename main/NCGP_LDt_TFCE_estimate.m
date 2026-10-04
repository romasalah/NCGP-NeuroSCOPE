% ==========================================================================
% Overall goal (user-provided): Overall goal: Estimates threshold free cluster enhancement model using 10 thousand permutations. Options are SPM TFCE toolbox or MATLAB TFCE toolbox
% ==========================================================================
function g=NCGP_LDt_TFCE_estimate(wf,TFCEmethod, hemimasks,spmmats,maskname, curhemi, exch_blocks, contrast_idx, ds)
paths=NCGP_paths(wf);
outputfolder=[paths.mp 'derivatives' filesep 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep 'hemi-' curhemi '_mask-' maskname filesep];
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
            matlabbatch{1}.spm.tools.tfce_estimate.nproc = 20;
            matlabbatch{1}.spm.tools.tfce_estimate.mask = {''};
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr = '';
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm = 10000;
            matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method = 0;
            matlabbatch{1}.spm.tools.tfce_estimate.tbss = 0;
            matlabbatch{1}.spm.tools.tfce_estimate.exch_blocks = exch_blocks;
            matlabbatch{1}.spm.tools.tfce_estimate.singlrthreaded = 0;
            % Toolbox call → spm_jobman
            spm_jobman( 'run', matlabbatch );
        end
end
end
