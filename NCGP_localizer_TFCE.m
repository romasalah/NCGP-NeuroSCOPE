                allsls=unique(preposttbl.Searchlight);
                hbar =parfor_progressbar(length(allsls),'Extracting LDC values');
                sls_currentsesshemi=cell(length(allsls),1);
% Section: parfor-block starts
                parfor(sli = 1:length(allsls),16)
                    cursl=allsls{sli};
                    sls_currentsesshemi{sli}=cursl;
                    curtbl=preposttbl(strcmp(preposttbl.Searchlight,cursl),:);
                    prew(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-02'));
                    postw(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Within-group') & strcmp(curtbl.Session, 'ses-03'));
                    preb(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-02'));
                    postb(sli,:)=curtbl.LDCvalue(strcmp(curtbl.Contrast, 'Between-group') & strcmp(curtbl.Session, 'ses-03'));
                    hbar.iterate(1);
                end
                close(hbar);
                slnames{hi}=sls_currentsesshemi;
                statresults{hi}.preb=preb;
                statresults{hi}.prew=prew;
                statresults{hi}.postb=postb;
                statresults{hi}.postw=postw;
% Call → NCGP_LDt_TFCE: Project function call
                signodes_surf{hi}=NCGP_LDt_TFCE(wf, statresults{hi},oldds{hi},curhemi,maskname);