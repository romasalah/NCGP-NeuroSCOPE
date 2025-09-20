% ==========================================================================
% Overall goal (user-provided): Overall goal: Runs a permutation test either on a signularity container or directly through python. the code calls the permutation test file run_permtest_bootstrap.py and waits for it to finish.
% Note: Comments only; code unchanged.
% ==========================================================================
function NCGP_decoding_surface_fdr(wf)
mainPath = wf.mainpath;
sessions=wf.sessions;
nbootstraps=wf.decode.nbootstraps;
tail=wf.decode.tail;
alpha=wf.decode.alpha;
% Call → NCGP_paths
p=NCGP_paths(wf);
sublbl = 'group';
nproc=1;
% Call → NCGP_osdir
[~,pcnum]=NCGP_osdir(0);
% Section: if-block starts
if pcnum==1
    pypath=['/opt/local/Library/Frameworks/Python.framework/Versions/2.7/bin/python2.7'];
    fdrscript=[pypath ' /Volumes/EVO8602TB/NCGP/AnalysisScripts/run_permtest_bootstrap.py'];
    insideslash='\';
% Section: else-block starts
else
    mainpathin='/idata/';
    mainpathout=wf.mainpath;
    basedir='/mnt/c/Users/CENs-Admin/Documents/Omar/NCGP/';
    IMG=[basedir 'singularity/neurodockerv4e.img'];
    bashbase=['wsl singularity exec -B ' basedir ':/idata ' IMG ' '];
    pypath=['/opt/conda2/envs/neuro27/bin/python'];
    fdrscript=[bashbase pypath ' /idata/scripts/run_permtest_bootstrap.py'];
    insideslash='/';
end
mcc_results_path=[mainPath wf.alignment filesep wf.mcc filesep sublbl filesep wf.pre filesep wf.glm filesep wf.decoding filesep wf.stats];
mkdir(mcc_results_path);
% Section: for-block starts
for hi= 1:length(wf.hemis)
% Section: for-block starts
    for si=1:length(sessions)
        cursession=sessions{si};
        decoding_opts=['AH-NAT_' cursession '_surface' '-' upper(wf.classifier) '_' num2str(wf.radius) 'mm'];
        decoding_basedir=[wf.mainpath filesep wf.alignment filesep wf.decoding filesep sublbl filesep wf.pre filesep wf.glm];
        perm_basedir= [wf.mainpath filesep wf.alignment filesep wf.stats filesep sublbl filesep wf.pre filesep wf.glm filesep wf.decoding];
        output_path=[wf.mainpath filesep wf.alignment filesep wf.mcc filesep sublbl filesep wf.pre filesep wf.glm filesep wf.decoding filesep wf.stats filesep decoding_opts filesep];
        mkdir(output_path);
        decflist=dir([decoding_basedir filesep decoding_opts filesep '*.niml.dset']);
        permflist=dir([perm_basedir filesep decoding_opts filesep '*.niml.dset']);
        %     if ~isempty(permflist)
        inputfn= [decflist.folder filesep decflist.name];
        perm=[permflist.folder filesep permflist.name];
        pycmd=[fdrscript ' --input '   strrep(strrep(inputfn,mainpathout, mainpathin),'\',insideslash) ' --permuted '  strrep(strrep(perm,mainpathout, mainpathin),'\',insideslash)  ...
            ' --nbootstraps ' num2str(nbootstraps) ' --alpha ' num2str(alpha) ...
            ' --tail ' num2str(tail) ' --prefix '  strrep(strrep(output_path,mainpathout, mainpathin),'\',insideslash) ' --nproc ' num2str(nproc)];
        system(pycmd)
        %     dsetfiles=dir([output_path '*.niml.dset']);
        %
        %     for di= 1:length(dsetfiles)
        %         curdset=[dsetfiles(di).folder filesep dsetfiles(di).name];
        %         prefix=strrep(curdset,'.niml.dset','');
        %         system([bashbase 'ConvertDset -input ' curdset ' -o_gii_asci -prefix ' prefix])
        %         newfn=[prefix '.gii.dset'];
        %         copyfile(newfn, strrep(newfn,'.dset',''))
        %         delete(newfn)
        %
        % %         for sfi =1: length(g)
        % %         surftype= strrep(g{sfi},'.asc','');
        % %         surftype= strrep(surftype,'.','_');
        % %         curgii= strrep(curdset, '.niml.dset', [surftype '.gii']);
        % % %         back2orig=[ bashbase 'SurfToSurf -i_fs ' surflist{sfi,1} ' -i_fs ' surflist{sfi,2} ' -o_gii ' curgii ' -closest_possible 2 -dset ' inputfn];
        % % %         system(back2orig)
        % % %         copyfile(strrep(curgii,'gii','niml.M2M') ,strrep(curgii,'gii','niml.dset') )
        % %         end
        %
        %     end
% Call → NCGP_dset_split
        %NCGP_dset_split([stats_results_path filesep decoding_opts],'')
    end
end
end
