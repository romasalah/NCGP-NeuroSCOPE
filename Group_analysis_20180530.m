%% 2018/05/30 Maria Tsantani and Lucia Garrido

% Script to do group analysis with three parts:

% Part 1: RSA comparing representational geometries

% Part 2: RSA investigating identity discriminability

% Part 3: Analysis of mean responses


%% Set up stuff

clear all; close all;

DATA.working_folder = pwd;


% File with results for all subjects
RDMs = importdata('RDMs_LDC.mat');

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
DATA.n_subjects = 30;

DATA.output_file='Group_analysis.mat';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. RSA geometry analysis %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for roi = 1 : DATA.n_ROIs
    
    for subject = 1 : DATA.n_subjects
        if ~isempty(RDMs.RDMs.subject(subject).ROI(roi).mean_sessions_Faces) % only adding when this ROI was present
            
            % Get data
            Faces1 = RDMs.RDMs.subject(subject).ROI(roi).session(1).mean_runs_Faces;
            Faces1_vec=squareform(Faces1')';
            
            Faces2 = RDMs.RDMs.subject(subject).ROI(roi).session(2).mean_runs_Faces;
            Faces2_vec=squareform(Faces2')';
            
            Voices1 = RDMs.RDMs.subject(subject).ROI(roi).session(1).mean_runs_Voices;
            Voices1_vec=squareform(Voices1')';
            
            Voices2 = RDMs.RDMs.subject(subject).ROI(roi).session(2).mean_runs_Voices;
            Voices2_vec=squareform(Voices2')';

            % Compute Pearson correlations
            DATA.geometry.ROI(roi).FacesvsFaces.Pearson_persubject(subject,1) = corr(Faces1_vec,Faces2_vec);
            DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_persubject(subject,1) = corr(Voices1_vec,Voices2_vec);
            DATA.geometry.ROI(roi).FacesvsVoices.Pearson_persubject(subject,1) = corr(Faces1_vec,Voices2_vec);
            DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_persubject(subject,1) = corr(Voices1_vec,Faces2_vec);
        
        else
            % Put NaN for everyone who doesn't have ROI
            DATA.geometry.ROI(roi).FacesvsFaces.Pearson_persubject(subject,1) = NaN;
            DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_persubject(subject,1) = NaN;
            DATA.geometry.ROI(roi).FacesvsVoices.Pearson_persubject(subject,1) = NaN;
            DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_persubject(subject,1) = NaN;
            
        end
    end
    
    % Means, sds, and tests across subjects for Pearson correlations
    DATA.geometry.ROI(roi).FacesvsFaces.Pearson_mean_subjects=nanmean(DATA.geometry.ROI(roi).FacesvsFaces.Pearson_persubject);
    DATA.geometry.ROI(roi).FacesvsFaces.Pearson_sd_subjects=nanstd(DATA.geometry.ROI(roi).FacesvsFaces.Pearson_persubject);
    [P,H,STATS]=signrank(DATA.geometry.ROI(roi).FacesvsFaces.Pearson_persubject,0,'alpha',0.05,'method','approximate','tail','right');
    DATA.geometry.ROI(roi).FacesvsFaces.Pearson_signrank.P_values = P;
    DATA.geometry.ROI(roi).FacesvsFaces.Pearson_signrank.zval = STATS.zval;
    DATA.geometry.ROI(roi).FacesvsFaces.Pearson_signrank.signedrank = STATS.signedrank;
    DATA.geometry.All_Pvalues(roi,1)=P; % putting all p-values in same matrix to do FDR
    
    DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_mean_subjects=nanmean(DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_persubject);
    DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_sd_subjects=nanstd(DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_persubject);
    [P,H,STATS]=signrank(DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_persubject,0,'alpha',0.05,'method','approximate','tail','right');
    DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_signrank.P_values = P;
    DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_signrank.zval = STATS.zval;
    DATA.geometry.ROI(roi).VoicesvsVoices.Pearson_signrank.signedrank = STATS.signedrank;
    DATA.geometry.All_Pvalues(roi,2)=P; % putting all p-values in same matrix to do FDR
    
    DATA.geometry.ROI(roi).FacesvsVoices.Pearson_mean_subjects=nanmean(DATA.geometry.ROI(roi).FacesvsVoices.Pearson_persubject);
    DATA.geometry.ROI(roi).FacesvsVoices.Pearson_sd_subjects=nanstd(DATA.geometry.ROI(roi).FacesvsVoices.Pearson_persubject);
    [P,H,STATS]=signrank(DATA.geometry.ROI(roi).FacesvsVoices.Pearson_persubject,0,'alpha',0.05,'method','approximate','tail','right');
    DATA.geometry.ROI(roi).FacesvsVoices.Pearson_signrank.P_values = P;
    DATA.geometry.ROI(roi).FacesvsVoices.Pearson_signrank.zval = STATS.zval;
    DATA.geometry.ROI(roi).FacesvsVoices.Pearson_signrank.signedrank = STATS.signedrank;
    DATA.geometry.All_Pvalues(roi,3)=P; % putting all p-values in same matrix to do FDR
    
    DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_mean_subjects=nanmean(DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_persubject);
    DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_sd_subjects=nanstd(DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_persubject);
    [P,H,STATS]=signrank(DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_persubject,0,'alpha',0.05,'method','approximate','tail','right');
    DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_signrank.P_values = P;
    DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_signrank.zval = STATS.zval;
    DATA.geometry.ROI(roi).VoicesvsFaces.Pearson_signrank.signedrank = STATS.signedrank;
    DATA.geometry.All_Pvalues(roi,4)=P; % putting all p-values in same matrix to do FDR
     
end

% FDR correction
q=0.05;
c=1;
pMap_vec=DATA.geometry.All_Pvalues(:);
n=length(pMap_vec);
pMap_vec_sorted=sort(pMap_vec);
pMap_vec_sorted = pMap_vec_sorted(:);
pThreshold = pMap_vec_sorted(max(find(pMap_vec_sorted<=(1:n)'/n*q/c)));

DATA.geometry.FDR.pthreshold=pThreshold;
DATA.geometry.FDR.pvalues(:,1)=pMap_vec_sorted; % these are the actual p-values
DATA.geometry.FDR.pvalues(:,2)=(1:n)'/n*q/c; % these are the comparison values


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Analysis discriminability %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for roi = 1 : DATA.n_ROIs
    
    % Mean matrix per subject - calculate mean distance
    for subject = 1 : DATA.n_subjects 
        
        if ~isempty(RDMs.RDMs.subject(subject).ROI(roi).mean_sessions_Faces) % only adding when this ROI was present
            a = RDMs.RDMs.subject(subject).ROI(roi).mean_sessions_Faces;
            DATA.discriminability.ROI(roi).Faces.per_subject(subject,1)=mean(squareform(a'));
        
            b = RDMs.RDMs.subject(subject).ROI(roi).mean_sessions_Voices;
            DATA.discriminability.ROI(roi).Voices.per_subject(subject,1)=mean(squareform(b'));
        
            c = RDMs.RDMs.subject(subject).ROI(roi).mean_sessions_FacesVoices;
            DATA.discriminability.ROI(roi).FacesVoices.per_subject(subject,1)=mean(squareform(c'));
        
            d = RDMs.RDMs.subject(subject).ROI(roi).mean_sessions_VoicesFaces;
            DATA.discriminability.ROI(roi).VoicesFaces.per_subject(subject,1)=mean(squareform(d'));
        
        else
            DATA.discriminability.ROI(roi).Faces.per_subject(subject,1)=NaN;
            DATA.discriminability.ROI(roi).Voices.per_subject(subject,1)=NaN;
            DATA.discriminability.ROI(roi).FacesVoices.per_subject(subject,1)=NaN;
            DATA.discriminability.ROI(roi).VoicesFaces.per_subject(subject,1)=NaN;
        end

    end
    
    % Means, sds, and tests across subjects
    DATA.discriminability.ROI(roi).Faces.mean_subjects=nanmean(DATA.discriminability.ROI(roi).Faces.per_subject);
    DATA.discriminability.ROI(roi).Faces.sd_subjects=nanstd(DATA.discriminability.ROI(roi).Faces.per_subject);
    [H,P,CI,STATS]=ttest(DATA.discriminability.ROI(roi).Faces.per_subject,0,0.05,'right');
    DATA.discriminability.ROI(roi).Faces.onesamplettests.P_values = P;
    DATA.discriminability.ROI(roi).Faces.onesamplettests.CI = CI;
    DATA.discriminability.ROI(roi).Faces.onesamplettests.T_values = STATS.tstat;
    DATA.discriminability.ROI(roi).Faces.onesamplettests.df = STATS.df; 
    DATA.discriminability.ROI(roi).Faces.onesamplettests.sd = STATS.sd;
    DATA.discriminability.All_Pvalues(roi,1)=P; % putting all p-values in same matrix to do FDR
    
    DATA.discriminability.ROI(roi).Voices.mean_subjects=nanmean(DATA.discriminability.ROI(roi).Voices.per_subject);
    DATA.discriminability.ROI(roi).Voices.sd_subjects=nanstd(DATA.discriminability.ROI(roi).Voices.per_subject);
    [H,P,CI,STATS]=ttest(DATA.discriminability.ROI(roi).Voices.per_subject,0,0.05,'right');
    DATA.discriminability.ROI(roi).Voices.onesamplettests.P_values = P;
    DATA.discriminability.ROI(roi).Voices.onesamplettests.CI = CI;
    DATA.discriminability.ROI(roi).Voices.onesamplettests.T_values = STATS.tstat;
    DATA.discriminability.ROI(roi).Voices.onesamplettests.df = STATS.df;
    DATA.discriminability.ROI(roi).Voices.onesamplettests.sd = STATS.sd;
    DATA.discriminability.All_Pvalues(roi,2)=P; % putting all p-values in same matrix to do FDR
    
    DATA.discriminability.ROI(roi).FacesVoices.mean_subjects=nanmean(DATA.discriminability.ROI(roi).FacesVoices.per_subject);
    DATA.discriminability.ROI(roi).FacesVoices.sd_subjects=nanstd(DATA.discriminability.ROI(roi).FacesVoices.per_subject);
    [H,P,CI,STATS]=ttest(DATA.discriminability.ROI(roi).FacesVoices.per_subject,0,0.05,'right');
    DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.P_values = P;
    DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.CI = CI;
    DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.T_values = STATS.tstat;
    DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.df = STATS.df;
    DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.sd = STATS.sd;
    DATA.discriminability.All_Pvalues(roi,3)=P; % putting all p-values in same matrix to do FDR
    
    DATA.discriminability.ROI(roi).VoicesFaces.mean_subjects=nanmean(DATA.discriminability.ROI(roi).VoicesFaces.per_subject);
    DATA.discriminability.ROI(roi).VoicesFaces.sd_subjects=nanstd(DATA.discriminability.ROI(roi).VoicesFaces.per_subject);
    [H,P,CI,STATS]=ttest(DATA.discriminability.ROI(roi).VoicesFaces.per_subject,0,0.05,'right');
    DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.P_values = P;
    DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.CI = CI;
    DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.T_values = STATS.tstat;
    DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.df = STATS.df;
    DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.sd = STATS.sd;
    DATA.discriminability.All_Pvalues(roi,4)=P; % putting all p-values in same matrix to do FDR

end

% FDR correction
q=0.05;
c=1;
pMap_vec=DATA.discriminability.All_Pvalues(:); 
n=length(pMap_vec);
pMap_vec_sorted=sort(pMap_vec);
pMap_vec_sorted = pMap_vec_sorted(:);
pThreshold = pMap_vec_sorted(max(find(pMap_vec_sorted<=(1:n)'/n*q/c)));

DATA.discriminability.FDR.pthreshold=pThreshold;
DATA.discriminability.FDR.pvalues(:,1)=pMap_vec_sorted; % these are the actual p-values
DATA.discriminability.FDR.pvalues(:,2)=(1:n)'/n*q/c; % these are the comparison values


% Calculate Cohen's d
%   Divide t value by square root of sample size

for roi = 1:DATA.n_ROIs
    
    clearvars sqrtN tvalF tvalV tvalFV tvalVF
    
    sqrtN = sqrt(DATA.discriminability.ROI(roi).Faces.onesamplettests.df+1);
    tvalF = DATA.discriminability.ROI(roi).Faces.onesamplettests.T_values;    
    DATA.discriminability.ROI(roi).Faces.onesamplettests.effect_size = tvalF/sqrtN;
    tvalV = DATA.discriminability.ROI(roi).Voices.onesamplettests.T_values;    
    DATA.discriminability.ROI(roi).Voices.onesamplettests.effect_size = tvalV/sqrtN;
    tvalFV = DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.T_values;    
    DATA.discriminability.ROI(roi).FacesVoices.onesamplettests.effect_size = tvalFV/sqrtN;
    tvalVF = DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.T_values;    
    DATA.discriminability.ROI(roi).VoicesFaces.onesamplettests.effect_size = tvalVF/sqrtN;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Mean response to faces and voices %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run ttests to determine whether the beta values are significantly different from 0:

for roi = 1:DATA.n_ROIs  
    DATA.mean_response.OneSample.Macrosssubj(roi).faces = mean([RDMs.average_betas.ROI_allvoxels(roi).ROIs.faces]);
    DATA.mean_response.OneSample.SDacrosssubj(roi).faces = std([RDMs.average_betas.ROI_allvoxels(roi).ROIs.faces]);
    [H,P,CI,STATS] = ttest([RDMs.average_betas.ROI_allvoxels(roi).ROIs.faces]); % Faces
    DATA.mean_response.OneSample.pvals(roi).faces = P;
    DATA.mean_response.OneSample.stats(roi).faces = STATS;
    
    DATA.mean_response.OneSample.Macrosssubj(roi).voices = mean([RDMs.average_betas.ROI_allvoxels(roi).ROIs.voices]);
    DATA.mean_response.OneSample.SDacrosssubj(roi).voices = std([RDMs.average_betas.ROI_allvoxels(roi).ROIs.voices]);
    [H,P,CI,STATS] = ttest([RDMs.average_betas.ROI_allvoxels(roi).ROIs.voices]); % Voices
    DATA.mean_response.OneSample.pvals(roi).voices = P;
    DATA.mean_response.OneSample.stats(roi).voices = STATS;
end

% FDR correction
% Put face and voice pvalues in one matrix
temp = [[DATA.mean_response.OneSample.pvals(:).faces]; [DATA.mean_response.OneSample.pvals(:).voices]]';

q=0.05;
c=1;
pMap_vec=temp(:);
n=length(pMap_vec);
pMap_vec_sorted=sort(pMap_vec);
pMap_vec_sorted = pMap_vec_sorted(:);
pThreshold = pMap_vec_sorted(max(find(pMap_vec_sorted<=(1:n)'/n*q/c)));

DATA.mean_response.OneSample.FDR.pthreshold=pThreshold;
DATA.mean_response.OneSample.FDR.pvalues(:,1)=pMap_vec_sorted; % these are the actual p-values
DATA.mean_response.OneSample.FDR.pvalues(:,2)=(1:n)'/n*q/c; % these are the comparison values


% Run ttests to compare responses to faces and voices
for roi = 1:DATA.n_ROIs 
    [H,P,CI,STATS] = ttest([RDMs.average_betas.ROI_allvoxels(roi).ROIs.faces], [RDMs.average_betas.ROI_allvoxels(roi).ROIs.voices]); 
    DATA.mean_response.PairedSample.pval(roi).P = P;
    DATA.mean_response.PairedSample.stats(roi).stats = STATS;
end

% FDR
temp2 = [DATA.mean_response.PairedSample.pval(:).P]';

q=0.05;
c=1;
pMap_vec=temp2(:); 
n=length(pMap_vec);
pMap_vec_sorted=sort(pMap_vec);
pMap_vec_sorted = pMap_vec_sorted(:);
pThreshold = pMap_vec_sorted(max(find(pMap_vec_sorted<=(1:n)'/n*q/c))); %0.0011

DATA.mean_response.PairedSample.FDR.pthreshold=pThreshold;
DATA.mean_response.PairedSample.FDR.pvalues(:,1)=pMap_vec_sorted; % these are the actual p-values
DATA.mean_response.PairedSample.FDR.pvalues(:,2)=(1:n)'/n*q/c; % these are the comparison values

% Save individual subject data
DATA.mean_response.persubject = RDMs.average_betas.ROI_allvoxels;
  

%% Save data
save(DATA.output_file,'DATA');

