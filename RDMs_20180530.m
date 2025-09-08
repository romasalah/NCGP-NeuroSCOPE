%% 2018/05/30 Maria Tsantani and Lucia Garrido

% This script requires 'Function_covdiag.m', which was adapted from the RSA
% toolbox (Nili et al., 2014, Plos Computational Biology)

%   This script has two main parts:

%   Part 1
%       It creates RDMs from individual GLM data using the LDC
%       Aim is to see how the hyperplanes defined by contrasting two conditions in one partition 
%       (w - I'll call these weight vectors from partition 1) can be used to discriminate the same 
%       two conditions in partition 2. 

%   Part 2
%       It computes main effects analyses in each ROI, in terms of mean
%       responses to faces and voices in each ROI


%% Subject loop

clear all;
clc;

p_nums = {'P01','P02'};

DATA.ROIs_names = {'F_rFFA.nii','F_rOFA.nii','F_rpSTS.nii','M_OFC.nii','M_FPo.nii','M_rTPo_AIT.nii','M_lTPo_AIT.nii',...
        'M_Prec.nii','V_rTVA.nii','T_rTVA_loc.nii','V_lTVA.nii','T_lTVA_loc.nii'}';

DATA.condition_names.faces = {'1AC_F','2AS_F','3BO_F','4DR_F','5GN_F',...
                '6JR_F','7BK_F','8BW_F','9CC_F','10EW_F','11KM_F','12SO_F'};
DATA.condition_names.voices = {'1AC_V','2AS_V','3BO_V','4DR_V','5GN_V',...
                '6JR_V','7BK_V','8BW_V','9CC_V','10EW_V','11KM_V','12SO_V'};
            

DATA.N_conditions_per_modality = 12;
DATA.N_sessions = 2;
DATA.N_runs_per_session = 3;
DATA.n_ROIs = 12;
DATA.n_subjects = 2;

DATA.name_output = 'RDMs_LDC.mat'; 


for p = 1:length(p_nums)
    
    p
    
    clear GLM; 

    % Save participant code    
    Subject = p_nums{p};

    % Path to ROIs
    DATA.working_folder = pwd;
    DATA.GLM_folder = strcat(DATA.working_folder,'/Participant_GLMs/');

    % Load GLM file per participant
    DATA.GLM_files(p).path = strcat(DATA.GLM_folder,Subject,'_GLM.mat');
    GLM = importdata(DATA.GLM_files(p).path);


    %% PART 1
    %% Compute LDC per ROI per session per partition
    for roi = 1 : length(GLM.ROIs(:)) % For each ROI
        if ~isempty(GLM.ROIs(roi).ROI) % if the participant has that ROI
            for session = 1:GLM.N_sessions % for each session
                for run = 1 : GLM.N_runs_per_session % and each run   

                    for wcond1 = 1 : size(GLM.betas.ROI(roi).session(session).run(run).betas_faces,1) % for each condition (12 faces and 12 voices)
                        for wcond2 = (wcond1+1) : size(GLM.betas.ROI(roi).session(session).run(run).betas_faces,1) % and for each other condition

                            % Conditions from partition 1 to make the hyperplane (partition 1 means the two concatenated runs)
                            %Faces
                            F_P1_cond1 = GLM.betas.ROI(roi).session(session).run(run).betas_faces_other_runs(wcond1,:); 
                            F_P1_cond2 = GLM.betas.ROI(roi).session(session).run(run).betas_faces_other_runs(wcond2,:);
                            %Voices
                            V_P1_cond1 = GLM.betas.ROI(roi).session(session).run(run).betas_voices_other_runs(wcond1,:);
                            V_P1_cond2 = GLM.betas.ROI(roi).session(session).run(run).betas_voices_other_runs(wcond2,:);

                            % Use the residuals from partition 1 to compute the noise-covariance matrix for the ROI and run
                            residuals_P1 = GLM.residuals.ROI(roi).session(session).run(run).other_runs;
                            % Shrink the estimate to a diagonal version
                            [sigma,shrinkage,sample] = Function_covdiag(residuals_P1); % Function_covdiag is from the RSA toolbox

                            % Test conditions from partition 2 (partition 2 means single run)
                            %Faces
                            F_P2_cond1 = GLM.betas.ROI(roi).session(session).run(run).betas_faces(wcond1,:);                                                                                                                 
                            F_P2_cond2 = GLM.betas.ROI(roi).session(session).run(run).betas_faces(wcond2,:);
                            %Voices
                            V_P2_cond1 = GLM.betas.ROI(roi).session(session).run(run).betas_voices(wcond1,:);                                                                                                                      
                            V_P2_cond2 = GLM.betas.ROI(roi).session(session).run(run).betas_voices(wcond2,:);

                            %%% LDC based on Johan Carlin's code:
                            %%% http://www.johancarlin.com/pilab-tutorial-2-linear-discriminant-contrast.html 
                            % Faces
                            F_w1 = (F_P1_cond1-F_P1_cond2)* inv(sigma);
                            F_w1u = F_w1/sqrt(sum(F_w1.^2)); 
                            F_m = (F_P2_cond1-F_P2_cond2) * F_w1u';
                            DATA.RDMs.subject(p).ROI(roi).session(session).run(run).Faces_LDC(wcond1,wcond2) = F_m;

                            % Faces vs Voices, i.e., use w vector above to
                            % descriminate two voice conditions
                            FV_m = (V_P2_cond1-V_P2_cond2) * F_w1u';
                            DATA.RDMs.subject(p).ROI(roi).session(session).run(run).FacesVoices_LDC(wcond1,wcond2) = FV_m;

                            % Voices
                            V_w1=(V_P1_cond1-V_P1_cond2)* inv(sigma);
                            V_w1u=V_w1/sqrt(sum(V_w1.^2));
                            V_m = (V_P2_cond1-V_P2_cond2) * V_w1u';
                            DATA.RDMs.subject(p).ROI(roi).session(session).run(run).Voices_LDC(wcond1,wcond2) = V_m;

                            % Voices vs Faces, i.e., use w vector above to
                            % descriminate two face conditions
                            VF_m = (F_P2_cond1-F_P2_cond2) * V_w1u';
                            DATA.RDMs.subject(p).ROI(roi).session(session).run(run).VoicesFaces_LDC(wcond1,wcond2) = VF_m;

                        end %for wcond2
                    end %for wcond1
                    
                    % Add a 12th row of zeros to RDMs
                    DATA.RDMs.subject(p).ROI(roi).session(session).run(run).Faces_LDC(12,:) = 0;
                    DATA.RDMs.subject(p).ROI(roi).session(session).run(run).FacesVoices_LDC(12,:) = 0;
                    DATA.RDMs.subject(p).ROI(roi).session(session).run(run).Voices_LDC(12,:) = 0;
                    DATA.RDMs.subject(p).ROI(roi).session(session).run(run).VoicesFaces_LDC(12,:) = 0;

                end %for run
            end %for session
        end % if ROI present
    end %for roi


    %% Calculate mean matrices across all partitions and sessions

    for roi = 1 : length(GLM.ROIs(:)) % For each ROI
        if ~isempty(GLM.ROIs(roi).ROI) % if the participant has that ROI
            F_Cat_matrix_session = [];  FV_Cat_matrix_session = []; V_Cat_matrix_session = [];  VF_Cat_matrix_session = [];

            for session = 1 : GLM.N_sessions
                F_Cat_matrix_run = [];  FV_Cat_matrix_run = []; V_Cat_matrix_run = [];  VF_Cat_matrix_run = [];

                for run = 1 : GLM.N_runs_per_session
                    F_Cat_matrix_run = cat(3,F_Cat_matrix_run,DATA.RDMs.subject(p).ROI(roi).session(session).run(run).Faces_LDC);
                    FV_Cat_matrix_run = cat(3,FV_Cat_matrix_run,DATA.RDMs.subject(p).ROI(roi).session(session).run(run).FacesVoices_LDC);
                    V_Cat_matrix_run = cat(3,V_Cat_matrix_run,DATA.RDMs.subject(p).ROI(roi).session(session).run(run).Voices_LDC);
                    VF_Cat_matrix_run = cat(3,VF_Cat_matrix_run,DATA.RDMs.subject(p).ROI(roi).session(session).run(run).VoicesFaces_LDC);
                end

                DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_Faces = mean(F_Cat_matrix_run,3);
                F_Cat_matrix_session = cat(3,F_Cat_matrix_session,DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_Faces);

                DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_FacesVoices = mean(FV_Cat_matrix_run,3);
                FV_Cat_matrix_session = cat(3,FV_Cat_matrix_session,DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_FacesVoices);

                DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_Voices = mean(V_Cat_matrix_run,3);
                V_Cat_matrix_session = cat(3,V_Cat_matrix_session,DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_Voices);

                DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_VoicesFaces = mean(VF_Cat_matrix_run,3);
                VF_Cat_matrix_session = cat(3,VF_Cat_matrix_session,DATA.RDMs.subject(p).ROI(roi).session(session).mean_runs_VoicesFaces);
            end

            % Average of all sessions    
            DATA.RDMs.subject(p).ROI(roi).mean_sessions_Faces = mean(F_Cat_matrix_session,3);
            DATA.RDMs.subject(p).ROI(roi).mean_sessions_FacesVoices = mean(FV_Cat_matrix_session,3);
            DATA.RDMs.subject(p).ROI(roi).mean_sessions_Voices = mean(V_Cat_matrix_session,3);
            DATA.RDMs.subject(p).ROI(roi).mean_sessions_VoicesFaces = mean(VF_Cat_matrix_session,3);
        end
    end

%% PART 2
%%  Average betas for faces and for voices in each ROI - for main effects analysis


    for roi = 1 : length(GLM.ROIs(:)) % For each ROI
        if ~isempty(GLM.ROIs(roi).ROI) % if the participant has that ROI
            for session = 1 : GLM.N_sessions % For each session
                for run = 1 : GLM.N_runs_per_session % and for each run
                    % Average betas in each voxel across all face and all voice
                    % conditions in each run
                    DATA.average_betas.subject(p).ROI(roi).session(session).faces_allruns(:,run) = ...
                        mean(GLM.betas.ROI(roi).session(session).run(run).betas_faces)'; % mean across all face conditions
                    DATA.average_betas.subject(p).ROI(roi).session(session).voices_allruns(:,run) = ...
                        mean(GLM.betas.ROI(roi).session(session).run(run).betas_voices)'; % mean across all voice conditions                    
                end        
                % Average betas across all runs
                DATA.average_betas.subject(p).ROI(roi).session(session).faces_avrg_runs = ...
                    mean(DATA.average_betas.subject(p).ROI(roi).session(session).faces_allruns, 2);
                DATA.average_betas.subject(p).ROI(roi).session(session).voices_avrg_runs = ...
                    mean(DATA.average_betas.subject(p).ROI(roi).session(session).voices_allruns, 2);
            end        
            % Average across sessions
            DATA.average_betas.subject(p).ROI(roi).faces_avrg = ...
                mean([DATA.average_betas.subject(p).ROI(roi).session(1).faces_allruns, ...
                DATA.average_betas.subject(p).ROI(roi).session(2).faces_allruns],2);
            DATA.average_betas.subject(p).ROI(roi).voices_avrg = ...
                mean([DATA.average_betas.subject(p).ROI(roi).session(1).voices_allruns, ...
                DATA.average_betas.subject(p).ROI(roi).session(2).voices_allruns],2);
           
            % Average across all voxels in the ROI
            DATA.average_betas.ROI_allvoxels(roi).ROIs(p).faces = mean(DATA.average_betas.subject(p).ROI(roi).faces_avrg); % Faces
            DATA.average_betas.ROI_allvoxels(roi).ROIs(p).voices = mean(DATA.average_betas.subject(p).ROI(roi).voices_avrg); % Voices
        end
    end


end % end of participant loop


%% Save data file

save(DATA.name_output,'DATA');

