%%%%%%% InterpolData
%%%%%%%
function z = InterpolData(x)
numCase = x.Num(1);
startCell = 1;
dt = minutes(30);
z = timetable;

for i = 1:size(x,1)
    if x.Num(i) == numCase
        continue
    else
        endCell = i-1;
        numCase = x.Num(i);
        TermTab = x(startCell:endCell,:);
%         TermTab = sortrows(TermTab,'Time','ascend');
        TermIntTab = retime(TermTab,'regular','linear','TimeStep',dt);
        z = [z;TermIntTab];
        TermTab = [];
        TermIntTab = [];
        startCell = i;
    end    
end

end

%     zTerm = timetable;
%     zTerm = addvars(zTerm,TimeInt,Num,Latitude,Longitude,Diam);
%     zTerm.Properties.RowTimes = TimeInt;
% 
%     if ismember('TimeInt',zTerm.Properties.VariableNames) == 1
%             zTerm = removevars(zTerm,{'TimeInt'});
%     end
% InterpZ = retime(zTerm,'regular','linear','TimeStep',dt); 
% sizeInterpZ = size(InterpZ,1);
% if i == 1
%     countEnZ = sizeInterpZ;
% else
%     countEnZ = countEnZ + sizeInterpZ;
% end
% z(countStZ:countEnZ,:) = InterpZ;
% 
% countStZ = countStZ + sizeInterpZ;
% 
% clear zTerm InterpZ
