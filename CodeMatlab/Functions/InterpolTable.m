%%%
%%% InterpolTable
%%%

function z = InterpolTable(x,y)
countRow = 1;

for i = 1:size(x,1)
startCell = x.StartCell(i);
endCell = x.EndCell(i);
       for j = startCell:endCell
            termTime(countRow,1) = datenum(y.Time(j));
            Num(countRow,1) = y.Num(j);
            Latitude(countRow,1) = y.Latitude(j);
            Longitude(countRow,1) = y.Longitude(j);
            Diam(countRow,1) = y.Diam(j);

            countRow = countRow + 1;
       end
    for i=1:size(termTime,1)
        TimeInt(i,1) = datetime(termTime(i,1),'ConvertFrom','datenum');
    end
end    

for i=1:size(termTime,1)
    TimeInt(i,1) = datetime(termTime(i,1),'ConvertFrom','datenum');
end

z = timetable;
z = addvars(z,TimeInt,Num,Latitude,Longitude,Diam);
z.Properties.RowTimes = TimeInt;

if ismember('TimeInt',z.Properties.VariableNames) == 1
        z = removevars(z,{'TimeInt'});
end

end
