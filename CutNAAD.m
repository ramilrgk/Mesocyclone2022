clear
load('Data/CutNAAD.mat');
clear polygonLat polygonLon borderLat borderLon cal calTermInterpGolub ...
    calTermInterpRojo 
%%

cutNAAD_Rojo = createCutNAADtable(calInterpRojo);
cutNAAD_Golub = createCutNAADtable(calInterpGolub);
cutNAAD_STARSnorth = createCutNAADtable(calInterpSTARSnorth);
cutNAAD_STARSsouth = createCutNAADtable(calInterpSTARSsouth);
cutNAAD_Noer2019 = createCutNAADtable(calInterpNoer2019);

%%
cd OutputTable/CutNAADtab/
writematrix(cutNAAD_Rojo,'NAADcutRojo.txt','Delimiter',' ');
writematrix(cutNAAD_Golub,'NAADcutGolub.txt','Delimiter',' ');
writematrix(cutNAAD_STARSnorth,'NAADcutSTARSnorth.txt','Delimiter',' ');
writematrix(cutNAAD_STARSsouth,'NAADcutSTARSsouth.txt','Delimiter',' ');
writematrix(cutNAAD_Noer2019,'NAADcutNoer2019.txt','Delimiter',' ');
cd ../../



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Functions                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tableFin = createCutNAADtable(x)
    [y,~,~] = ymd(x.Time);
    [h,~,~] = hms(x.Time);

    x = addvars(x,h);
    x = addvars(x,y);
    dayofyear = day(x.Time,'dayofyear') - 1;
    x = addvars(x,dayofyear);

    numObs = (x.dayofyear * 8) + (x.h / 3);
    x = addvars(x,numObs);
    x = removevars(x,{'h','dayofyear'});
    clear h m s y month d 


%%%%
    numCase = x.Num(1);
    numObs = 0;
    RowNum = 1;

    for i = 1:size(x,1)
        if x.Num(i) == numCase
            numObs = numObs + 1;
        else
            numCase = x.Num(i);
            table(RowNum,1) = x.y(i-numObs);
            table(RowNum,2) = x.numObs(i-1)+8;
            table(RowNum,3) = x.numObs(i-numObs)-8;
            RowNum = RowNum + 1;
            numObs = 0;
        end        
    end
%%%%
    RowNum = 1;
    for i = 1:size(table,1)

        maxNumObs = maxNumObsCreate(table(i,1));
        if table(i,3) < 0
            maxNumObsPrev = maxNumObsCreate((table(i,1)-1));

            tableFin(RowNum,1) = table(i,1);
            tableFin(RowNum,2) = table(i,2);
            tableFin(RowNum,3) = 0;
            RowNum = RowNum + 1;
            tableFin(RowNum,1) = table(i,1) - 1;
            tableFin(RowNum,2) = maxNumObsPrev;
            tableFin(RowNum,3) = maxNumObsPrev + table(i,3);
            RowNum = RowNum + 1;
        elseif table(i,2) > maxNumObs
            tableFin(RowNum,1) = table(i,1);
            tableFin(RowNum,2) = maxNumObs;
            tableFin(RowNum,3) = table(i,3);
            RowNum = RowNum + 1;
            tableFin(RowNum,1) = table(i,1) + 1;
            tableFin(RowNum,2) = table(i,2) - maxNumObs;
            tableFin(RowNum,3) = 0;
            RowNum = RowNum + 1;
        else
            tableFin(RowNum,1) = table(i,1);
            tableFin(RowNum,2) = table(i,2);
            tableFin(RowNum,3) = table(i,3);
            RowNum = RowNum + 1;
        end
    end    

end

function maxNumObs = maxNumObsCreate(x)
    if x == 2016
        numDayYear = 366;
    elseif x == 2012
        numDayYear = 366;
    elseif x == 2008
        numDayYear = 366;
    elseif x == 2004
        numDayYear = 366;
    elseif x == 2000
        numDayYear = 366;
    elseif x == 1996
        numDayYear = 366;
    elseif x == 1992
        numDayYear = 366;
    else
        numDayYear = 365;
    end
maxNumObs = (numDayYear * 8) - 1;
end