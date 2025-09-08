% ==========================================================================
% Overall goal (user-provided): Overall goal: Corrects fieldmap image names from "run-0X_magnitude" to "magnitudeX"
% Note: Comments only; code unchanged.
% ==========================================================================
% ==========================================================================
% Overall goal: Corrects fieldmap image names from "run-0X_magnitude" to "magnitudeX"
% Note: Comments added only at the top; code unchanged.
% ==========================================================================
rootdir='E:\Omar\NCPG\bidsify';
bidsroot='E:\Omar\NCPG\bidsify\BIDS';
ptlist=[19];
subprefix='NCGP0';
sesslist={'S1','S2','S3'};
% Section: for-block starts
for subi=1:length(ptlist)
    cursubstr0=ptlist(subi);
% Section: if-block starts
    if length(num2str(cursubstr0))==2
        zerext='';
% Section: else-block starts
    else
        zerext='0';
    end
    cursubstr=[zerext num2str(ptlist(subi))];
    cursubfull=[subprefix cursubstr];
    cursubfolder = [rootdir filesep cursubfull filesep 'MRI' filesep];
    scanstbl=[cursubfolder filesep 'scans.xlsx'];
    sctbl=readtable(scanstbl);
    curmax=[];
% Section: for-block starts
    for si=1:length(sesslist)
        curfmapfolder=[bidsroot filesep 'sub-0' cursubstr...
            filesep 'ses-0' num2str(si) filesep 'fmap'];
        magold1=[curfmapfolder filesep 'sub-0' cursubstr...
            '_ses-0' num2str(si) '_run-01_magnitude.nii.gz'];
        magold1json=strrep(magold1, '.nii.gz', '.json');
        
        magold2 = strrep(magold1,'run-01','run-02');
        magold2json=strrep(magold2, '.nii.gz', '.json');

        magnew1=strrep(magold1, 'run-01_magnitude', 'magnitude1');
        magnew2=strrep(magold2, 'run-02_magnitude', 'magnitude2');
        magnew1json=strrep(magold1json, 'run-01_magnitude', 'magnitude1');
        magnew2json=strrep(magold2json, 'run-02_magnitude', 'magnitude2');
        
% Section: try-block starts
        try
        copyfile(magold1, magnew1)
        copyfile(magold2, magnew2)
        end
        copyfile(magold1json, magnew1json)
        copyfile(magold2json, magnew2json)
        
        delete(magold1)
        delete(magold2)
        delete(magold1json)
        delete(magold2json)
        
    end
end
