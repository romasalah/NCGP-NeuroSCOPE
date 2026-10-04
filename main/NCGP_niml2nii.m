% ==========================================================================
% Overall goal (user-provided): Overall goal: Converts a NIML surface dataset into a NIFTI volumetric image using fsaverage6 surface volume and freesurfer.
% ==========================================================================
function NCGP_niml2nii(wf)
subs=wf.subs;
sess=wf.sessions;
task=wf.task;
fsout=filesep;
fsin='/';
% Call → NCGP_paths
p=NCGP_paths(wf);
sumasuffix='derivatives/freesurfer/fsaverage6/SUMA/';
% Section: if-block starts
mainpathin='/idata/';
mainpathout=wf.mainpath;
basedir='/mnt/d/Omar/NCGP/data/';
imgbase=[p.imgpathout 'singularity/neurodockerV5*.img'];
imglistdir = dir(imgbase);
imglist={imglistdir(~[imglistdir(:).isdir]).name};
% Section: for-block starts
for i1=1:length(imglist)
    IMG_inside{i1}=[p.imgpathin 'singularity/' imglist{i1}];
    bashbase{i1}=['wsl singularity exec -B ' basedir ':/idata ' IMG_inside{i1} ' '];
end
sumafolder=[mainpathin sumasuffix];
sumafolderout=[mainpathout 'derivatives' filesep 'freesurfer' fsout wf.refsub fsout 'SUMA' fsout];
rtspec='fsaverage6_rh.spec';
ltspec='fsaverage6_lh.spec';
rtpial='rh.pial';
ltpial='lh.pial';
surfvol=[sumafolder 'fsaverage6_SurfVol+orig'];
surfs={'rh.pial.asc', 'lh.pial.asc',...
    'lh.smoothwm.asc', 'rh.smoothwm.asc',...
    'lh.inflated.asc', 'rh.inflated.asc',...'
    'lh.white.asc', 'rh.white.asc'};
T1AFNI=[sumafolder 'T1+orig'];
%% freesurfer to SUMA
subjsurfacepath=[mainpathin 'derivatives/freesurfer/' wf.refsub];
mkdir([subjsurfacepath '/orig']);
%unix([bashbase{1} '@SUMA_make_spec_FS -fspath ' subjsurfacepath ' -sid ' wf.refsub]);
% Section: for-block starts
for si=1:length(surfs)
    inputsurf=[sumafolder surfs{si}];
    outputsurf=strrep(inputsurf,'asc','gii');
    %unix([bashbase{1} 'ConvertSurface -i_fs ' inputsurf ' -o_gii ' outputsurf ' -sv ' surfvol])
end
%% Step 1: Coreg T1 to functional, Convert NIFTI to AFNI and skull strip it
gunzip([sumafolderout 'T1.nii.gz'])
niftiT1=[sumafolder 'T1.nii'];
newcoregT1=[sumafolder 'T1+orig'];
convertnii2afnicmd=[bashbase{i1} ' bash -c "3dcopy ' niftiT1 ' ' newcoregT1 '"'];
unix(convertnii2afnicmd)
%% Convert freesurfer SurfaceVolume
convertnii2afni=[' 3dcopy ' sumafolder 'fsaverage6_SurfVol.nii ' sumafolder 'fsaverage6_SurfVol'];
%unix([bashbase{1} convertnii2afni]);
%%
delete(gcp('nocreate'));
parpool('local',length(IMG_inside))
% Section: parfor-block starts
for subi=1:length(subs)
    % Section: for-block starts
    for sessi=1:length(sess)
        side=wf.hemis;
        % Section: for-block starts
        for i=1:length(wf.hemis)
            curside=side{i};
            % Section: switch-block starts
            switch curside
                % Section: case-block starts
                case 'R'
                    pial=rtpial;
                    spec=rtspec;
                    medialmaskfn=[sumafolderout 'rh.maskmedial.niml.dset'];
                    % Section: case-block starts
                case 'L'
                    pial=ltpial;
                    spec=ltspec;
                    medialmaskfn=[sumafolderout 'lh.maskmedial.niml.dset'];
            end

            specfile=[sumafolder spec];
            pialfn=[sumafolder pial];
            % Toolbox call → surfing_read
            medialmaskdata=surfing_read(medialmaskfn);
            HAdir=[p.pre subs{subi} filesep sess{sessi} filesep 'func' filesep];
            dsetfilelist=dir([HAdir filesep subs{subi} '_' sess{sessi} '_task-' wf.task '*' curside '.func.niml.dset']);
            tempdir=[HAdir filesep 'volumetric' filesep];
            tempdirin=strrep(tempdir,mainpathout,mainpathin);
            tempdirin=strrep(tempdirin,fsout,fsin);

            % Section: for-block starts
            for dseti=1:length(dsetfilelist)
                fname=[dsetfilelist(dseti).name ];
                mainprefix=strrep(fname, '.niml.dset','');
                disp(fname);
                mkdir(tempdir)
                cur1Dfn=[tempdir 'cur1d.1D'];
                cur1Dfnin=strrep(cur1Dfn, tempdir, tempdirin);
                %% Loop between unsmoothed and smoothed .niml.dsets
                % Section: if-block starts
                if contains(wf.smooth, '0') % No Smoothing needed
                    iternum=1;
                    % Section: else-block starts
                else
                    iternum=2;
                end
                % Section: for-block starts
                for issmoothed = 1:iternum
                    % Section: if-block starts
                    if issmoothed==2
                        % Call → NCGP_surfsmooth
                        fname=NCGP_surfsmooth(wf,HAdir, mainprefix, curside, imglist{1});
                        fname=strrep(fname, [filesep filesep],filesep);
                        HAdir=strrep(HAdir, [filesep filesep],filesep);
                        fname=strrep(fname, HAdir, '' );
                    end
                    shortprefix=strrep(fname, '.niml.dset','');
                    % Toolbox call → surfing_read
                    hh=surfing_read([HAdir fname]);
                    allscansdata=hh.data;
                    %%
                    filecell={};
                    filelist=dir([tempdir filesep shortprefix '*.nii']);
                    % Section: for-block starts
                    for i=1:length(filelist)
                        filecell{i}=[filelist(i).folder filesep filelist(i).name];
                    end
                    filecell=filecell(~(contains(filecell,'mask')));
                    % Section: if-block starts
                    if length(filecell)~=size(hh.data,2)
                        %% Convert 3D Surface to Volume
                        % Section: for-block starts
                        for i=1:size(hh.data,2)
                            curdata=zeros(size(medialmaskdata.node_indices));
                            curprefix=[tempdirin shortprefix '_' num2str(i)];
                            curprefixout=strrep(curprefix,tempdirin, tempdir);
                            curprefixout=strrep(curprefixout,fsin, fsout);
                            curprefixnii=[shortprefix '_' num2str(i) '.nii'];
                            % Section: if-block starts
                            if exist([tempdir filesep curprefixnii], 'file')~=2
                                curdata(medialmaskdata.data==1)=allscansdata(:,i);
                                dlmwrite(cur1Dfn,curdata);
                                system([bashbase{subi} '3dSurf2Vol -spec ' specfile ' -surf_A ' pialfn ...
                                    ' -sdata ' cur1Dfnin ' -sv ' surfvol ' -prefix ' curprefix...
                                    ' -map_func ave -grid_parent ' T1AFNI]);
                                system([bashbase{subi} 'sh -c "cd ' tempdirin ' && 3dAFNItoNIFTI ' curprefix '+orig -prefix ' shortprefix '_' num2str(i) '"'])
                                delete([curprefixout '+orig.BRIK.gz']);
                                delete([curprefixout '+orig.HEAD']);
                                gunzip([curprefixout '.nii.gz'])
                                delete([curprefixout '.nii.gz'])
                            end
                        end

                    end
                    %                 %% Convert 3D to 4D
                    %                 system([' cd ' tempdir ';sorted_files=$(ls '  fprefixqry ' | awk -F''func_'' ''{print $2+0, $0}'' | sort -k1,1n | awk ''{print $2}'');' bashbase '3dTcat -prefix output_prefix $(echo $sorted_files) -tr 2.5 -output ' shortprefix ' -verb']);
                    %                 system([bashbase 'cd ' tempdir '; rm  sub*func_*'])
                    %                 system([bashbase 'cd ' tempdir '; 3dAFNItoNIFTI ' shortprefix '+orig -prefix ' shortprefix '.nii'])
                    %                 %% Create mask image
                    % Section: if-block starts
                    if exist([tempdir filesep shortprefix '_mask.nii'], 'file')~=2
                        cur1Dmaskfnout=[tempdir 'cur1d_mask.1D'];
                        cur1Dmaskfn=[tempdirin 'cur1d_mask.1D'];
                        maskvals=ones(size(hh.data,1),1);
                        curdata=zeros(size(medialmaskdata.node_indices));
                        curdata(medialmaskdata.data==1)=maskvals;
                        dlmwrite(cur1Dmaskfnout,curdata)
                        system([bashbase{subi}  'sh -c "cd ' tempdirin ';3dSurf2Vol -spec ' specfile ' -surf_A ' pialfn ...
                            ' -sdata ' cur1Dmaskfn ' -sv ' surfvol ' -prefix ' [shortprefix '_mask']...
                            ' -map_func ave -grid_parent ' T1AFNI '"']);
                        system([bashbase{subi} 'sh -c "cd ' tempdirin '; 3dAFNItoNIFTI ' shortprefix '_mask+orig -prefix ' shortprefix '_mask"'])
                        delete([tempdir shortprefix '_mask+orig.BRIK']);
                        delete([tempdir shortprefix '_mask+orig.HEAD']);
                        gunzip([tempdir shortprefix '_mask.nii.gz']);
                        delete([tempdir shortprefix '_mask.nii.gz']);
                    end
                end
            end
        end
    end
end
delete(gcp('nocreate'));
end
