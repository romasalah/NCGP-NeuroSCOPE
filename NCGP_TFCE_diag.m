clear g1 g2 g3 g4 Tperm

spmT_gii = gifti('spmT_0001.gii');
T_gii = gifti('T_0001.gii');
Tlogp_gii = gifti('T_log_p_0001.gii');
TFCElogp_gii = gifti('TFCE_log_p_0001.gii');

spmT     = double(spmT_gii.cdata);
T        = double(T_gii.cdata);
Tlogp    = double(Tlogp_gii.cdata);
TFCElogp = double(TFCElogp_gii.cdata);

spmT     = spmT(:);
T        = T(:);
Tlogp    = Tlogp(:);
TFCElogp = TFCElogp(:);

corr(spmT, T, 'rows', 'complete')
pthr = -log10(0.05);

raw_sig  = Tlogp > pthr;
tfce_sig = TFCElogp > pthr;

fprintf('Raw permutation significant: %d\n', sum(raw_sig));
fprintf('TFCE significant:            %d\n', sum(tfce_sig));

fprintf('Significant in BOTH:         %d\n', sum(raw_sig & tfce_sig));
fprintf('Raw ONLY:                    %d\n', sum(raw_sig & ~tfce_sig));
fprintf('TFCE ONLY:                   %d\n', sum(~raw_sig & tfce_sig));
retained = raw_sig & tfce_sig;
lost     = raw_sig & ~tfce_sig;

fprintf('Retained mean T: %.3f\n', mean(T(retained)));
fprintf('Lost mean T:     %.3f\n', mean(T(lost)));

fprintf('Retained median T: %.3f\n', median(T(retained)));
fprintf('Lost median T:     %.3f\n', median(T(lost)));
load('SPM.mat');

G = SPM.xVol.G;

if ~isa(G,'gifti')
    G = gifti(G);
end

disp(size(G.vertices))
disp(size(G.faces))
disp(min(G.faces(:)))
disp(max(G.faces(:)))


gT_FWE    = gifti('T_log_pFWE_0001.gii');
gTFCE_FWE = gifti('TFCE_log_pFWE_0001.gii');

T_FWE    = double(gT_FWE.cdata);
TFCE_FWE = double(gTFCE_FWE.cdata);

T_FWE    = T_FWE(:);
TFCE_FWE = TFCE_FWE(:);
pthr = -log10(0.05);

T_FWE_sig    = T_FWE > pthr;
TFCE_FWE_sig = TFCE_FWE > pthr;

fprintf('Raw T FWE significant: %d\n', sum(T_FWE_sig));
fprintf('TFCE FWE significant:  %d\n', sum(TFCE_FWE_sig));

fprintf('BOTH:                   %d\n', sum(T_FWE_sig & TFCE_FWE_sig));
fprintf('Raw T ONLY:             %d\n', sum(T_FWE_sig & ~TFCE_FWE_sig));
fprintf('TFCE ONLY:              %d\n', sum(~T_FWE_sig & TFCE_FWE_sig));