% ==========================================================================
% Overall goal: Build directory config and execution order for the overall analysis workflow.
% Place in pipeline: Surface-based MVPA workflow (hyperalignment → GLMs → surface stacks → searchlights → LDt → group stats/corr maps).
% Note: Added comments only; code logic unchanged.
% ==========================================================================
function wf=NCPG_create_workflow(wfname, hemis, exp, alignment)
% Section: if-block starts
if strcmpi(alignment,'aal')
    hemis={'LR'};
end
% Section: switch-block starts
switch exp
% Section: case-block starts
    case 'BehavNCGP'
        sublist={};
        %         subsnum=[2:3, 5:16, 18:26]';
        %         for i=1:length(subsnum)
        %         sublist{i}=num2str(sprintf('%03d',subsnum(i)));
        %         end
        subsnum2=[204:208, 210:213, 215,216, 219:224]';
% Section: for-block starts
        for i2=1:length(subsnum2)
            sublist{end+1}=num2str(subsnum2(i2));
        end
% Call → NCPG_osdir: Project function call
        wf.mainpath=NCPG_osdir('BehavNCGP');
    case 'NCGP'
        subsnum=[4:8, 10:13, 15,16, 19:24];
        subsnum=[16, 19:22];

        subs=string(subsnum);
        sublist={};
% Section: for-block starts
        for i=1:length(subs)
% Section: if-block starts
            if length(subs{i})==1
                sublist{end+1}=['sub-00' subs{i}];
% Section: elseif-block starts
            elseif length(subs{i})==2
                sublist{end+1}=['sub-0' subs{i}];
            end
        end
end
wf.exp=exp;
wf.subs=sublist;

% Section: switch-block starts
switch wfname
% Section: case-block starts
    case 'faces'
        wf.glmresiduals=1;
        wf.hemis=hemis;
        wf.pre='fmriprep';wf.decoding='Cosmo_surfdecoding';wf.stats='perm_stats';wf.glm='SPM_GLM';wf.mcc='TFCE_MCC';
        wf.radius=10; wf.classifier='libsvm';
% Call → NCPG_osdir: Project function call
        wf.mainpath=NCPG_osdir(wf.exp);
        wf.t1folder=[wf.mainpath wf.pre filesep 'fsaverage6' filesep 'T1' filesep];
        wf.runs={'run-01','run-02','run-03','run-04','run-05','run-06'};
        wf.sessions={'ses-02','ses-03'};
        %wf.sessions={'ses-02'};
        wf.task='faces';
        wf.TR=2.5;
        wf.modeltype='regperidentity';
        wf.alignment=alignment;
        wf.refsub='fsaverage6';
        wf.volskip=0;
        wf.hemis=hemis;
        wf.RDMcorr.Method = 'spearman';
        wf.RDMcorr.htail = 'right';
        wf.RDMcorr.alpha = 0.05;
        wf.smooth='S0';
        wf.decode.output='accuracy';
        wf.decode.C=1;
        wf.decode.alpha=0.05;
        wf.decode.tail=1;
        wf.decode.nbootstraps=10000;
        wf.decode.npermute=100;
        wf.decode.smkernel=6;
        wf.decode.type='individuals';
        wf.modelblackresponse=0;
% Section: case-block starts
    case 'localizer'
        wf.hemis=hemis;
        wf.glmresiduals=0;
        wf.pre='fmriprep';
        wf.glm='SPM_GLM';
        wf.mcc='none';
% Call → NCPG_osdir: Project function call
        wf.mainpath=NCPG_osdir(wf.exp);
        wf.task='localizer';
        wf.modeltype='regperidentity';
        wf.volskip=0;
        wf.smooth='S6';
        wf.threshold=0.001;
        wf.mink=50;
        wf.refsub='fsaverage6';
        wf.group=1;
        wf.smkernel=6;
        wf.alignment=alignment;
        wf.normalise=1;
        wf.convec=[0 2 0 -1 -1 0 0 zeros(1,6)];
        wf.HRF.deriv=[0 0];
% Section: switch-block starts
        switch exp
% Section: case-block starts
            case 'NCGP'
                wf.sessions={'ses-01','ses-02', 'ses-03'};
                wf.runs={'run-01','run-02', 'run-03','run-04'};
                wf.TR=2.5;
        end
end
