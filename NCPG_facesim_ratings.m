% Overall goal: takes similarity ratings of personality, social life and physical apperance
% from before and after the intervention and calculates the difference
function [alltasksmat,allingpsim_vals,alloutgpsim_vals,allbtgpsim_vals,allingpsim_distavg,alloutgpsim_distavg,allbtgpsim_distavg]=NCPGH_facesim_ratings(subs,allfacesimtbl,allgpnames,timedata)
switch timedata
    case 'pre'
        corrlist0=zeros(8,8,length(subs));
        for subi=1:length(subs)
            subid=num2str(subs(subi));
            facesimtbl=allfacesimtbl{subi};
            gpnames=allgpnames{subi};
            fsim=table2cell(facesimtbl(:,4:6));
            alltaskssim={fsim};
            curtasktb=alltaskssim{1};
            c=0;
            d=0;
            e=0;
            for ir=1:8
                for ic=1:8
                    if ic<ir
                        irname=gpnames{ir};
                        icname=gpnames{ic};
                        currow=find((contains(curtasktb(:,1),irname) & contains(curtasktb(:,2),icname)) | (contains(curtasktb(:,1),icname) & contains(curtasktb(:,2),irname)));                      ;
                        length([curtasktb{currow,3}]);
                        corrlist0(ir,ic,subi)=mean([curtasktb{currow,3}]);
                    end
                end
            end
            alltasksmat{1}=corrlist0;
        end
    case 'post'
        corrlist0=zeros(8,8,length(subs));
        for subi=1:length(subs)
            subid=num2str(subs(subi));
            facesimtbl=allfacesimtbl{subi};
            gpnames=allgpnames{subi};
            fsim=table2cell(facesimtbl(:,5:7));
            trsim1=table2cell(facesimtbl(:,[8:10]));
            trsim2=table2cell(facesimtbl(:,[8:9,11]));
            alltaskssim={fsim, trsim1, trsim2};
            for tsi= find(~cellfun(@isempty,alltaskssim))
                curtasktb=alltaskssim{tsi};
                c=0;
                d=0;
                e=0;
                for ir=1:8
                    for ic=1:8
                        if ic<ir
                            irname=gpnames{ir};
                            icname=gpnames{ic};
                            currow=find((contains(curtasktb(:,1),irname) & contains(curtasktb(:,2),icname)) | (contains(curtasktb(:,1),icname) & contains(curtasktb(:,2),irname)));                      ;
                            corrlist0(ir,ic,subi)=mean([curtasktb{currow,3}]);
                        end
                    end
                end
                alltasksmat{tsi}=corrlist0;
            end
        end
    case 'postminuspre'
        corrlist0=zeros(8,8,length(subs));
        allingpsim=cell(1,1);
        alloutgpsim=cell(1,1);
        allbtgpsim=cell(1,1);
        for subi=1:length(subs)
            subid=num2str(subs(subi));
            gpnames=allgpnames{subi};
            facesimtblpre=allfacesimtbl.pre{subi};
            facesimtblpost=allfacesimtbl.post{subi};
            fsimpost=table2cell(sortrows(facesimtblpost(:,5:7),[1 2]));
            fsimpre=table2cell(sortrows(facesimtblpre(:,5:7),[1 2]));
            fsimprepost0=cell2mat(fsimpost(:,3)) -  cell2mat(fsimpre(:,3));
            fsimprepost=fsimpre;
            fsimprepost(:,3)=num2cell(fsimprepost0);
            alltaskssim={fsimprepost};
            curtasktb=fsimprepost;
            c=0;
            d=0;
            e=0;
            for ir=1:8
                for ic=1:8
                    if ic<ir
                        irname=gpnames{ir};
                        icname=gpnames{ic};
                        currow=find((contains(curtasktb(:,1),irname) & contains(curtasktb(:,2),icname)) | (contains(curtasktb(:,1),icname) & contains(curtasktb(:,2),irname)));
                        corrlist0(ir,ic,subi)=mean([curtasktb{currow,3}]) - mean([curtasktb{currow,3}]);
                    end
                end
            end
            alltasksmat{1}=corrlist0;
        end
end
for tsi=1:length(alltaskssim)
    allingpsim_vals{tsi}=[];
    alloutgpsim_vals{tsi}=[];
    allbtgpsim_vals{tsi}=[];
    for subi =1:size(alltasksmat{tsi},3)
        cursb_fromRDM=alltasksmat{tsi}(:,:,subi);
        ingpsim_vals{tsi}{subi}=[cursb_fromRDM(2:4,1); cursb_fromRDM(3:4,2); cursb_fromRDM(4,3);];
        outgpsim_vals{tsi}{subi}=[cursb_fromRDM(6:8,5); cursb_fromRDM(7:8,6); cursb_fromRDM(8,7);];
        btgpsim_vals{tsi}{subi}=[cursb_fromRDM(5:8,1:4)];
        allingpsim_vals{tsi}=[allingpsim_vals{tsi} ingpsim_vals{tsi}{subi}];
        alloutgpsim_vals{tsi}=[alloutgpsim_vals{tsi} outgpsim_vals{tsi}{subi}];
        allbtgpsim_vals{tsi}=[allbtgpsim_vals{tsi} btgpsim_vals{tsi}{subi}(:)];
    end
    allingpsim_distavg{tsi}=mean(allingpsim_vals{tsi},1);
    alloutgpsim_distavg{tsi}=mean(alloutgpsim_vals{tsi},1);
    allbtgpsim_distavg{tsi}=mean(allbtgpsim_vals{tsi},1);
end
end