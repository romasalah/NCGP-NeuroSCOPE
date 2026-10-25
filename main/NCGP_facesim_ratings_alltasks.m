% Overall goal: takes similarity ratings of personality, social life and
% physical apperance from before and after the intervention and calculates the difference
function [alltasksmat,allingpsim_vals,alloutgpsim_vals,allbtgpsim_vals,allingpsim_distavg,alloutgpsim_distavg,allbtgpsim_distavg]=NCGP_facesim_ratings_alltasks(subs,allfacesimtbl,allgpnames,timedata,exp)
alltaskssim={};
p1p2_col=4:5;
facial_col=6;
personality_col=7;
sociallife_col=8;
for subi=1:length(subs)
    facesimtbl=allfacesimtbl{subi};
    if size(facesimtbl,2)==8
        curfacial=table2cell(facesimtbl(:,[p1p2_col, facial_col]));
        curpersonality=table2cell(facesimtbl(:,[p1p2_col,personality_col]));
        cursociallife=table2cell(facesimtbl(:,[p1p2_col,sociallife_col]));
    end
    alltaskssim{1}{subi}=curfacial;
    alltaskssim{2}{subi}=curpersonality;
    alltaskssim{3}{subi}=cursociallife;
end
fixedgpnames= {'AH1', 'AH2', 'AH3', 'AH4', 'NAT1', 'NAT2', 'NAT3', 'NAT4'};
for tsi= 1:3
    corrlist0=[];   
    for subi=1:length(subs)
        corrlist0(:,:,subi)=zeros(8,8);
        curtasktb=alltaskssim{tsi}{subi};
        for p1=1:8 
            for p2=1:8 
                if p2<p1
                    p1name=fixedgpnames{p1};
                    p2name=fixedgpnames{p2};
                    currow=find((contains(curtasktb(:,1),p1name) & contains(curtasktb(:,2),p2name)) | (contains(curtasktb(:,1),p2name) & contains(curtasktb(:,2),p1name)));                      ;
                    corrlist0(p1,p2,subi)=mean([curtasktb{currow,3}]);
                end
            end
        end
    end
    alltasksmat{tsi}=corrlist0;
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
