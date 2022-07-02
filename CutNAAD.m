clear
load('Data/CutNAAD.mat');
clear polygonLat polygonLon
%%
clear x 
x = calInterpRojo;
[y,month,d] = ymd(x.Time);
[h,m,s] = hms(x.Time);

x = addvars(x,h);
x = addvars(x,y);
dayofyear = day(x.Time,'dayofyear') - 1;
x = addvars(x,dayofyear);

numObs = (x.dayofyear * 8) + (x.h / 3);
x = addvars(x,numObs);
x = removevars(x,{'h','dayofyear'});
clear h m s y month d 


%%
numCase = 1;
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
%%%
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