% ==========================================================================
% Overall goal (user-provided): Overall goal: Creates a full structure of premade paths for further retrieval
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Creates a full structure of premade paths for further retrieval
% Note:
% ==========================================================================
% Function signature detected
function p = NCPG_paths(wf)
% Section: if-block starts
if ~strcmp(wf.mainpath(end),filesep)
    wf.mainpath=[wf.mainpath filesep];
end
% Section: if-block starts
if ~isfield(wf,'sfx')
    wf.sfx='';
end
% Section: if-block starts
if isempty(wf.sfx)
    imgsfx='';
    % Section: else-block starts
else
    imgsfx=wf.sfx;
end
p.mp=wf.mainpath;
p.pre=[p.mp filesep 'derivatives' filesep wf.pre filesep];
p.hpal=[p.mp filesep 'derivatives' filesep 'hpalfunc' filesep];
p.fs=[p.mp 'derivatives' filesep 'freesurfer' filesep];
p.refsuma=[p.fs wf.refsub filesep 'SUMA'];
p.glm=[p.mp wf.alignment filesep wf.glm filesep];
p.LDC= [p.mp 'LDC' filesep 'group' filesep wf.pre filesep wf.glm filesep ];
% Section: for-block starts
for i=1:length(wf.subs)
    p.presub{i}=[p.pre wf.subs{i}];
    p.glmsub{i}=[p.glm wf.subs{i}];
end

p.wslbasedir='/mnt/f/NCGP/data/';
p.mainpathin='/idata/';
p.mainpathout=wf.mainpath;
p.imgpathout='F:\NCGP\data\';
p.imgpathin='/mnt/f/NCGP/data/';
IMG=[p.imgpathin 'singularity/neurodockerV5' imgsfx '.img'];
p.bashbase=['wsl singularity exec -B ' p.wslbasedir ':/idata ' IMG ' '];
end
