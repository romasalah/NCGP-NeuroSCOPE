% ==========================================================================
% Overall goal (user-provided): Overall goal: Get the condition name (face identity) from the pre-intervention output files
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Get the condition name (face identity) from the pre-intervention output files
% Note:
% ==========================================================================
% Function signature detected
function allconditions=NCGPH_getcondition(subs)
% Section: for-block starts
for subi=1:length(subs)
    subid=num2str(subs(subi));
    %% Get experimental condition
    prefile=dir([subid 'facesimilarity_pre_output.xlsx']);
% Section: if-block starts
    if isempty(prefile)
        allconditions{subi,1}='Post';
% Section: else-block starts
    else
        allconditions{subi,1}='PrePost';
    end
end
end
