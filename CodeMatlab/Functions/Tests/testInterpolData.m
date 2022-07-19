 %%
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
         TermIntTab = retime(TermTab,'regular','linear','TimeStep',dt);
         z = [z;TermIntTab];
         TermTab = [];
         TermIntTab = [];
         startCell = i;
     end    
 end
 clear numCase startCell dt TermTab TermIntTab
 
 
 %%
 % numCase = x.Num(67);
 % startCell = 67;
 % dt = minutes(30);
 % z = timetable;
 % 
 % for i = 67:size(x,1)
 %     if x.Num(i) == numCase
 %         continue
 %     else
 %         endCell = i-1;
 %         numCase = x.Num(i);
 %         TermTab = x(startCell:endCell,:);
 %         TermIntTab = retime(TermTab,'regular','linear','TimeStep',dt);
 %         z = [z;TermIntTab];
 %         TermTab = [];
 %         TermIntTab = [];
 %         startCell = i;
 %     end    
 % end
 % clear numCase startCell dt TermTab TermIntTab
 % 
 % 
 
 % function z = InterpolData(x)
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
         TermIntTab = retime(TermTab,'regular','linear','TimeStep',dt);
         z = [z;TermIntTab];
         TermTab = [];
         TermIntTab = [];
         startCell = i;
     end    
 end
 
 % end
 
 % filepath = '/fdf/dfdf'
 tableYDZ = ncread(filepath,'z200');
 termTab = zeros(144,73,39);
 sumTab = zeros(144,73);
 
 for i = 1:91
    termTab = tableYDZ(:,:,:,i);
    for j = 1:39
         sumTab = sumTab + termTab(:,:,j); 
    end
    filename = sprintf("sumTab_%d.dat",i);
    dlmwrite(filename,sumTab);
    termTab = zeros(144,73,39);
    sumTab = zeros(144,73);
 end
 
 