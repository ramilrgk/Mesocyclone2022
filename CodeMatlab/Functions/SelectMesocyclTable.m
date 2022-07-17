%%% SelectMesocyclTable
%%%
%%%
function SelectTable = SelectMesocyclTable(x)

if ismember('ObsCase',x.Properties.VariableNames) == 0
numCase = 1;        % Cчетчик отдельного мезоциклона
numObs = 1;         % Счетчик количества точек в отдельном кейсе
ObsCase = zeros(size(x,1),1);
    for i = 1:size(x,1)
            if x.Num(i) == numCase
                ObsCase(i,1) = numObs;
                numObs = numObs + 1;
            else
                numCase = x.Num(i);
                numObs = 1;
                ObsCase(i,1) = numObs;
                numObs = numObs + 1;
            end
    end
    % Запись номеров точек (ObsCase) в траектории в таблицу
    x = addvars(x,ObsCase);
    x = movevars(x,'ObsCase','After','Num');    
end

numCase = 1;
numStart = 1;    %Номер строки первой точки в треке
numRowTable = 1; %Номер строки для отдельного мезоциклона в новой таблице
numValidPoint = 0; %Cчетчик точек входящих в домен

strValidPoint = ''; %Текстовый счетчик последовательности (non)valid в треке.
                    %Результат последовательность единиц и нулей с
                    %помощью которой можно определить на какой
                    %стадии мезоциклон выходил из области моделирования

for i = 1:size(x,1)    
    if x.Num(i) == numCase
        numValidPoint = numValidPoint + x.Valid(i);
        
        strTermValidPoint = num2str(x.Valid(i));
        strValidPoint = strcat(strValidPoint,strTermValidPoint);
    else
        numCase = x.Num(i);
        middleTrack = i-1 - floor(x.ObsCase(i-1)/2);
        StartCell(numRowTable,1) = numStart;
        EndCell(numRowTable,1) = i-1;
        termDateStart(numRowTable,1) = datenum(x.Time(numStart));
        termDateEnd(numRowTable,1) = datenum(x.Time(i-1));
        termDateSelect(numRowTable,1) = datenum(x.Time(middleTrack));
        SelectTable(numRowTable,:) = x(middleTrack,:);
        NumPoint(numRowTable,1) = x.ObsCase(i-1);
        ValidPoint(numRowTable,1) = numValidPoint;
        NoValidPoint(numRowTable,1) = x.ObsCase(i-1) - numValidPoint;
        SeqValid(numRowTable,1) = convertCharsToStrings(strValidPoint);
        PercentValid(numRowTable,1) = numValidPoint / x.ObsCase(i-1);
        
        numValidPoint = 0;
        numValidPoint = numValidPoint + x.Valid(i);

        numRowTable = numRowTable + 1;
        numStart = i;
        strValidPoint = ''; 
    end
end

% Создание таблиц времени
for i=1:size(termDateSelect,1)
    DateSelect(i,1) = datetime(termDateSelect(i,1),'ConvertFrom','datenum');
    DateStart(i,1) = datetime(termDateStart(i,1),'ConvertFrom','datenum');
    DateEnd(i,1) = datetime(termDateEnd(i,1),'ConvertFrom','datenum');
end

SelectTable = addvars(SelectTable,StartCell,EndCell,DateSelect,DateStart,...
    DateEnd,NumPoint,ValidPoint,NoValidPoint,SeqValid,PercentValid);
SelectTable.Properties.RowTimes = DateSelect;

% Перестановка столбцов
SelectTable = movevars(SelectTable,'NumPoint','After','Longitude');
SelectTable = movevars(SelectTable,'ValidPoint','After','NumPoint');
SelectTable = movevars(SelectTable,'NoValidPoint','After','ValidPoint');
SelectTable = movevars(SelectTable,'SeqValid','After','NoValidPoint');


    if ismember('Year',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Year'});
    end
    if ismember('Month',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Month'});
    end
    if ismember('Day',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Day'});
    end
    if ismember('Hour',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Hour'});
    end
    if ismember('Minute',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Minute'});
    end
    if ismember('Valid',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Valid'});
    end
    if ismember('Row',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Row'});
    end
    if ismember('ObsCase',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'ObsCase'});
    end
    if ismember('Obs',SelectTable.Properties.VariableNames) == 1
        SelectTable = removevars(SelectTable,{'Obs'});
    end
end
