% Папка с функциями
addpath("/home/ramil/Documents/Work/IO_Practice/CodeMatlab/Functions/");
addpath("/home/ramil/Program/Matlab/MATLAB Add-Ons/timeline/");


%       1. КАЛЕНДАРИ
%
%%%     Условие в построении календаря Golubkin на cal.lat > 1 вызвано тем что
%%% в данных изначальной таблицы различные мезоциклоны отделены друг от
%%% друга пустой строкой. В таблице ей присвоены нули. Таким образом эти
%%% пустые строки можно исключить. 
%%%     Для календаря Kolstad нет необходимости производить отбор,
%%% поэтому календарь по умолчанию называется calSelectKolstad. (подробнее
%%% о отборе см. раздел #3)

% Загрузка файлов календарей
load('~/Documents/Work/IO_Practice/Data/CalendarVar.mat');
% Календарь Golubkin все случаи c треками
calTrackGolubkin = readtable("~/Documents/Work/IO_Practice/Data/atmosphere-12-00224-s001.xlsx");
% Календарь Rojo все случаи с треками
calTrackRojo = readtable("~/Documents/Work/IO_Practice/Data/Rojo-etal_2019.xlsx");

% Календарь Kolstad все случаи
calKolstad = cal((cal.Source == 1),:);
calKolstad = removevars(calKolstad,{'Valid'});
calKolstad.Properties.DimensionNames{1} = 'DateSelect';

% Функция создания таблицы времени (см. ФУНКЦИИ)
calTrackGolubkin = timetableCreate(calTrackGolubkin);
calTrackGolubkin = calTrackGolubkin((calTrackGolubkin.Num > 0),:);
calTrackRojo = timetableCreate(calTrackRojo);

% Календарь Kolstad от Полины Сергеевной. *from NAAD4*
calTrackKolstad = readtable('~/Documents/Work/IO_Practice/Data/Kolstad_from_NAAD4.txt');
calTrackKolstad = renamevars(calTrackKolstad,["Var1","Var2","Var3","Var4",...
    "Var5","Var6","Var7","Var8","Var9"],...
    ["Num","Year","Month","Day","Hour","Minute","Longitude","Latitude","Diam"]);
calTrackKolstad = timetableCreate(calTrackKolstad);
% calTrackKolstad = removevars(calTrackKolstad,{'Year','Month','Day','Hour','Minute'});

numCase = 1;
GroupCase = 1;
countCycl = 1;

for i = 1:size(calTrackRojo,1)
    if calTrackRojo.Num(i) == numCase
        if calTrackRojo.Group(i) == GroupCase
            NumCyclone(i,1) = countCycl;
        else
            GroupCase = calTrackRojo.Group(i);
            countCycl = countCycl+1;
            NumCyclone(i,1) = countCycl;
        end
    else
        numCase = calTrackRojo.Num(i);
        countCycl = countCycl+1;
        NumCyclone(i,1) = countCycl;
        GroupCase = calTrackRojo.Group(i);
    end    
end
calTrackRojo = addvars(calTrackRojo, NumCyclone);
calTrackRojo = renamevars(calTrackRojo,"Num","NumByGroup");
calTrackRojo = renamevars(calTrackRojo,"NumCyclone","Num");
calTrackRojo = movevars(calTrackRojo,'Num','Before','Group');
clear i countCycl GroupCase numCase NumCyclone time

%%%% Календарь STARS
calTrackSTARSsouth = readtable('~/Documents/Work/IO_Practice/Data/PolarLow_tracks_South_2002_2011');
calTrackSTARSnorth = readtable('~/Documents/Work/IO_Practice/Data/PolarLow_tracks_North_2002_2011');


rowNum = 1;
for i=1:size(calTrackSTARSnorth,1)
    if i == 1
        calTermTrackSTARSnorth(rowNum,:) = calTrackSTARSnorth(i,:);
        rowNum = rowNum + 1;
        continue
    end
    
    if calTrackSTARSnorth.Num(i) == calTrackSTARSnorth.Num(i-1)
        if calTrackSTARSnorth.Day(i) == calTrackSTARSnorth.Day(i-1)
            if calTrackSTARSnorth.Hour(i) == calTrackSTARSnorth.Hour(i-1)
                if calTrackSTARSnorth.Latitude(i) == calTrackSTARSnorth.Latitude(i-1)
                    continue
                end
            end 
        end
    end
    calTermTrackSTARSnorth(rowNum,:) = calTrackSTARSnorth(i,:);
    rowNum = rowNum + 1;
end
clear i rowNum

calTrackSTARSnorth = calTermTrackSTARSnorth;
calTrackSTARSnorth = timetableCreate(calTrackSTARSnorth);

calTrackSTARSsouth = readtable('~/Documents/Work/IO_Practice/Data/PolarLow_tracks_South_2002_2011');
calTrackSTARSsouth = timetableCreate(calTrackSTARSsouth);

clear calTermTrackSTARSnorth


calTrackNoer2019 = readtable('~/Documents/Work/IO_Practice/Data/IO_ERA5_pl_list2019.csv');
Minute = zeros(size(calTrackNoer2019,1),1);
calTrackNoer2019 = addvars(calTrackNoer2019,Minute);
clear Minute

calTrackNoer2019 = timetableCreate(calTrackNoer2019);













%% 
%       2. ВАЛИДАЦИЯ ТОЧЕК КАЛЕНДАРЯ
%
%%%     ВАЛ.Т.К. представляет собой проверку на предмет вхождения в
%%%     область моделирования (домен). Чтобы это сделать необходимо
%%%     построить полигон из координат границ домена. После чего применить
%%%     к точкам календаря функцию "inpolygon". Выводом которой является
%%%     логическая переменная "in". 
%%%
%%%     2.1. Границы (широта и долгота) домена
%%%     2.2. Валидация. inpolygon сверяет список точек на условие вхождение
%%%     в полигон из #2.2. В записи результата условия необходимы для того
%%%     чтобы уже существующий столбец valid не размножался при каждом 
%%%     запуске секции кода 

%%%% 2.1. Границы домена 
% Широта
borderLat(1,1) = 70;    % С
borderLat(1,2) = 47;    % Ю
% Долгота
borderLon(1,1) = 18;    % В
borderLon(1,2) = -72;   % З

% Здесь используется моя функция создающая полигон ддомена. См. раздел ФУНКЦИИ
[polygonLat,polygonLon] = createSimplePolygon(borderLat,borderLon);
%%
%%%% 2.2. Валидация
inKolstad = inpolygon(calKolstad.Longitude,calKolstad.Latitude,polygonLon,polygonLat);
inGolub = inpolygon(calTrackGolubkin.Longitude,calTrackGolubkin.Latitude,polygonLon,polygonLat);
inRojo = inpolygon(calTrackRojo.Longitude,calTrackRojo.Latitude,polygonLon,polygonLat);
inKolstadTrack = inpolygon(calTrackKolstad.Longitude,calTrackKolstad.Latitude,polygonLon,polygonLat);
inSTARSTrackNorth = inpolygon(calTrackSTARSnorth.Longitude,calTrackSTARSnorth.Latitude,polygonLon,polygonLat);
inSTARSTrackSouth = inpolygon(calTrackSTARSsouth.Longitude,calTrackSTARSsouth.Latitude,polygonLon,polygonLat);
inNoer2019 = inpolygon(calTrackNoer2019.Longitude,calTrackNoer2019.Latitude,polygonLon,polygonLat);
% Запись результата в таблицу и переименование
if ismember('Valid',calKolstad.Properties.VariableNames) == 0 
calKolstad = addvars(calKolstad,inKolstad);
calKolstad = renamevars(calKolstad,"inKolstad","Valid");
end
if ismember('Valid',calTrackGolubkin.Properties.VariableNames) == 0 
calTrackGolubkin = addvars(calTrackGolubkin,inGolub);
calTrackGolubkin = renamevars(calTrackGolubkin,"inGolub","Valid");
end
if ismember('Valid',calTrackRojo.Properties.VariableNames) == 0 
calTrackRojo = addvars(calTrackRojo,inRojo);
calTrackRojo = renamevars(calTrackRojo,"inRojo","Valid");
end
if ismember('Valid',calTrackKolstad.Properties.VariableNames) == 0 
    calTrackKolstad = addvars(calTrackKolstad,inKolstadTrack);
    calTrackKolstad = renamevars(calTrackKolstad,"inKolstadTrack","Valid");
end
if ismember('Valid',calTrackSTARSnorth.Properties.VariableNames) == 0 
    calTrackSTARSnorth = addvars(calTrackSTARSnorth,inSTARSTrackNorth);
    calTrackSTARSnorth = renamevars(calTrackSTARSnorth,"inSTARSTrackNorth","Valid");
end
if ismember('Valid',calTrackSTARSsouth.Properties.VariableNames) == 0 
    calTrackSTARSsouth = addvars(calTrackSTARSsouth,inSTARSTrackSouth);
    calTrackSTARSsouth = renamevars(calTrackSTARSsouth,"inSTARSTrackSouth","Valid");
end
if ismember('Valid',calTrackNoer2019.Properties.VariableNames) == 0 
calTrackNoer2019 = addvars(calTrackNoer2019,inNoer2019);
calTrackNoer2019 = renamevars(calTrackNoer2019,"inNoer2019","Valid");
end

clear inKolstad inGolub inRojo i inKolstadTrack inSTARSTrackNorth...
    inSTARSTrackSouth inNoer2019














%%
%       3. ОТБОР ТОЧЕК 
% 
%%%     Под отбором имеется ввиду следующее: в календаре Golubkin и
%%%   PANGAEA данные представлены в ввиде множества точек относящихся к одному
%%%   мезоциклону, составляющих собой его траекторию (трек). Отбор
%%%   позволяет вычленить одну конкретную точку (координаты и время). 
%%%     В данном отборе в качестве конкретной точки, "представляющую"
%%%   весь трек, выбирается точка середины трека. 
%%%     Для удобства обращения с треком созданы столбцы startCell и endCell,
%%%   представляющие собой номер ячеек первой и последней точки трека.
%%%     Для календаря Kolstad нет необходимости производить отбор,
%%%     поэтому календарь по умолчанию называется calSelectKolstad и
%%%     создается в разделе #1

calSelectGolub = SelectMesocyclTable(calTrackGolubkin);
calSelectRojo = SelectMesocyclTable(calTrackRojo);
calSelectKolstad = SelectMesocyclTable(calTrackKolstad);
calSelectSTARSnorth = SelectMesocyclTable(calTrackSTARSnorth);
calSelectSTARSsouth = SelectMesocyclTable(calTrackSTARSsouth);
calSelectNoer2019 = SelectMesocyclTable(calTrackNoer2019);














%%
%       4. Отбор случаев по времени
%
%%%     ВАЖНОЕ ЗАМЕЧАНИЕ! ЕСЛИ ЭТОТ УЧАСТОК НЕ ЗАПУСКАТЬ ВООБЩЕ, ТО ЭТО
%%%     НИКАК НЕ ПОВЛИЯЕТ НА ДАЛЬНЕЙШУЮ РАБОТУ! ВСЕ БУДЕТ РАБОТАТЬ 
%%%     ДЛЯ ВСЕХ СЛУЧАЕВ ПО КАЛЕНДАРЯМ МЕЗОЦИКЛОНОВ НЕ ОГРАНИЧЕННЫХ ВО 
%%%     ВРЕМЕНИ
%%%
%%%         Данный отбор необходим в ситуации когда при дальнейшей
%%%     работе с календарем необходимо отрезать часть случаев. Например 
%%%     если модельный архив охватывает только какой-то конкретный 
%%%     диапазон времени, меньший чем доступен по календарю. 
%%%     Необходимость данного раздела продиктована следующим
%%%     обстоятельством: в календарях calSelect{name} в качестве даты
%%%     используется средняя точка. При отборе случаев мезоциклонов
%%%     требуется отбросить треки, часть которых выходит за временные
%%%     пределы. Соответственно здесь реализована проверка точек треков на
%%%     дату начала и конца треков. Если трек выходит за пределы - он
%%%     отсекается. 
%%%         calDateSelect - название функции. Функция записана в конце
%%%         файла. ДАТЫ ВРЕМЕННЫХ ГРАНИЦ УКАЗЫВАЮТСЯ ВНУТРИ НЕЕ!!!

% Дата временных границ. В формате %Y,%M,%D,%H,%MI,%S
timeStart = datetime(1993,01,01,00,00,00);
timeEnd = datetime(2016,01,01,00,01,00);

calSelectGolub = CutByTimes(calSelectGolub,timeStart,timeEnd);
calSelectRojo = CutByTimes(calSelectRojo,timeStart,timeEnd);
calSelectSTARSnorth = CutByTimes(calSelectSTARSnorth,timeStart,timeEnd);
calSelectSTARSsouth = CutByTimes(calSelectSTARSsouth,timeStart,timeEnd);
calSelectNoer2019 = CutByTimes(calSelectNoer2019,timeStart,timeEnd);
clear timeStart timeEnd

















%% 
%       5. Карты 
%
%%%
%%%
% Папка с дополнениями. Здесь необходим пакет M_map
addpath(genpath('/home/ramil/Program/Matlab/MATLAB Add-Ons'))

%%%% 5.1 Календари с Valid и Non-Valid
% calValidKolstad = calKolstad((calKolstad.Valid == 1),:);
calValidGolub = calSelectGolub((calSelectGolub.PercentValid >= 0.5),:);
calValidRojo = calSelectRojo((calSelectRojo.PercentValid >= 0.5),:);
calValidKolstad = calSelectKolstad;
calValidSTARSnorth = calSelectSTARSnorth((...
    calSelectSTARSnorth.PercentValid >= 0.5),:);
calValidSTARSsouth = calSelectSTARSsouth((...
    calSelectSTARSsouth.PercentValid >= 0.5),:);
calValidNoer2019 = calSelectNoer2019((calSelectNoer2019.PercentValid >= 0.5),:);
    
% calNonValidKolstad = calKolstad((calKolstad.Valid == 0),:);
% calNonValidGolub = calSelectGolub((calSelectGolub.PercentValid < 0.5),:);
% calNonValidRojo = calSelectRojo((calSelectRojo.PercentValid < 0.5),:);











%% 5.2 Карта точек мезоциклонов

%%%% Инициализация карты
clf
m_proj('Azimuthal Equal-Area','lon',-30,'lat',60,'rad',35,'rec','circle','rot',0);
% m_proj('Azimuthal Equal-Area','lon',-20,'lat',75,'rad',29,'rec','circle','rot',-90);
m_grid('xlabeldir','end','ylabeldir','end','tickdir','out',...
    'xaxisLocation','middle','yaxisLocation','left',...
    'ytick',[90 75 60 45 30],'fontsize',9);
m_coast('patch',[0.94 0.94 0.94],'edgecolor','k');
% m_gshhs_l('patch',[.9 .9 .9]); %high-res coast

%%%% Изображение области моделирования
m_line(polygonLon,polygonLat,'color','k','linewi',1.5);

%%%% Нанесение маркеров мезоциклонов
% Размер маркеров
mksz = 6;

% Valid Pangaea
for i=1:size(calValidRojo,1)
    m_line(calValidRojo.Longitude(i),calValidRojo.Latitude(i),...
        'marker','x','markersize',mksz,'color','r','LineWidth',1);
end

% % Non-Valid Pangaea
% for i=1:size(calNonValidRojo,1)
%     m_line(calNonValidRojo.Longitude(i),calNonValidRojo.Latitude(i),...
%         'marker','x','markersize',mksz,'color','k','LineWidth',1);
% end

% Valid Golub
for i=1:size(calValidGolub,1)
    m_line(calValidGolub.Longitude(i),calValidGolub.Latitude(i),...
        'marker','+','markersize',mksz,'color','b','LineWidth',1);
end

% % Non-Valid Golub
% for i=1:size(calNonValidGolub,1)
%     m_line(calNonValidGolub.Longitude(i),calNonValidGolub.Latitude(i),...
%         'marker','+','markersize',mksz,'color','k','LineWidth',1);
% end

% Valid Kolstad
for i=1:size(calValidKolstad,1)
    m_line(calValidKolstad.Longitude(i),calValidKolstad.Latitude(i),...
        'marker','s','markersize',mksz,'color','m','LineWidth',1);
end    

% % Non-Valid Kolstad
% for i=1:size(calNonValidKolstad,1)
%     m_line(calNonValidKolstad.Longitude(i),calNonValidKolstad.Latitude(i),...
%         'marker','s','markersize',mksz,'color','k','LineWidth',1);
% end

for i=1:size(calValidSTARSnorth,1)
    m_line(calValidSTARSnorth.Longitude(i),calValidSTARSnorth.Latitude(i),...
        'marker','d','markersize',mksz,'color','g','LineWidth',1);
end

for i=1:size(calValidSTARSsouth,1)
    m_line(calValidSTARSsouth.Longitude(i),calValidSTARSsouth.Latitude(i),...
        'marker','d','markersize',mksz,'color','g','LineWidth',1);
end

title('Граница модельной области и мезоциклоны по календарям', 'FontSize',15);



















%% 5.3. Карта треков мезоциклонов


%%%% Инициализация карты
clf
m_proj('Azimuthal Equal-Area','lon',-30,'lat',60,'rad',35,'rec','circle','rot',0);
m_grid('xlabeldir','end','ylabeldir','end','tickdir','out',...
    'xaxisLocation','middle','yaxisLocation','left',...
    'ytick',[90 75 60 45 30],'fontsize',9);
m_coast('patch',[0.94 0.94 0.94],'edgecolor','k');
% m_gshhs_l('patch',[.9 .9 .9]); %high-res coast

%%%% Изображение области моделирования
m_line(polygonLon,polygonLat,'color','k','linewi',1.5);

for i=1:size(calValidGolub,1)
TrackLon = calTrackGolubkin.Longitude((calValidGolub.StartCell(i)):(calValidGolub.EndCell(i)));
TrackLat = calTrackGolubkin.Latitude((calValidGolub.StartCell(i)):(calValidGolub.EndCell(i)));
TrackLon = TrackLon';
TrackLat = TrackLat';
m_line(TrackLon,TrackLat,'color','b','linewi',0.5);

DotLon = calTrackGolubkin.Longitude(calValidGolub.EndCell(i));
DotLat = calTrackGolubkin.Latitude(calValidGolub.EndCell(i));
m_line(DotLon,DotLat,...
    'marker','.','markersize',10,'color','b','LineWidth',1);

TrackLon = [];
TrackLat = [];
DotLon = [];
DotLat = [];
end


for i=1:size(calValidRojo,1)
TrackLon = calTrackRojo.Longitude((calValidRojo.StartCell(i)):(calValidRojo.EndCell(i)));
TrackLat = calTrackRojo.Latitude((calValidRojo.StartCell(i)):(calValidRojo.EndCell(i)));
TrackLon = TrackLon';
TrackLat = TrackLat';
m_line(TrackLon,TrackLat,'color','r','linewi',0.5);

DotLon = calTrackRojo.Longitude(calValidRojo.EndCell(i));
DotLat = calTrackRojo.Latitude(calValidRojo.EndCell(i));
m_line(DotLon,DotLat,...
    'marker','.','markersize',10,'color','r','LineWidth',1);

TrackLon = [];
TrackLat = [];
DotLon = [];
DotLat = [];
end

for i=1:size(calValidSTARSnorth,1)
TrackLon = calTrackSTARSnorth.Longitude((calValidSTARSnorth.StartCell(i)):(calValidSTARSnorth.EndCell(i)));
TrackLat = calTrackSTARSnorth.Latitude((calValidSTARSnorth.StartCell(i)):(calValidSTARSnorth.EndCell(i)));
TrackLon = TrackLon';
TrackLat = TrackLat';
m_line(TrackLon,TrackLat,'color','g','linewi',0.5);

DotLon = calTrackSTARSnorth.Longitude(calValidSTARSnorth.EndCell(i));
DotLat = calTrackSTARSnorth.Latitude(calValidSTARSnorth.EndCell(i));
m_line(DotLon,DotLat,...
    'marker','.','markersize',10,'color','g','LineWidth',1);

TrackLon = [];
TrackLat = [];
DotLon = [];
DotLat = [];
end

for i=1:size(calValidSTARSsouth,1)
TrackLon = calTrackSTARSsouth.Longitude((calValidSTARSsouth.StartCell(i)):(calValidSTARSsouth.EndCell(i)));
TrackLat = calTrackSTARSsouth.Latitude((calValidSTARSsouth.StartCell(i)):(calValidSTARSsouth.EndCell(i)));
TrackLon = TrackLon';
TrackLat = TrackLat';
m_line(TrackLon,TrackLat,'color','g','linewi',0.5);

DotLon = calTrackSTARSsouth.Longitude(calValidSTARSsouth.EndCell(i));
DotLat = calTrackSTARSsouth.Latitude(calValidSTARSsouth.EndCell(i));
m_line(DotLon,DotLat,...
    'marker','.','markersize',10,'color','g','LineWidth',1);

TrackLon = [];
TrackLat = [];
DotLon = [];
DotLat = [];
end

title('Треки мезоциклонов по календарям Golubkin, Rojo и STARS', 'FontSize',15);

clear DotLat DotLon mksz i TrackLat TrackLon
















%% 6. Интерполяция 
%%%
calTermInterpGolub = InterpolTable(calValidGolub,calTrackGolubkin);
calInterpGolub = InterpolData(calTermInterpGolub);
[h,m,s] = hms(calInterpGolub.Time);
calInterpGolub = addvars(calInterpGolub,m);
calInterpGolub = calInterpGolub((calInterpGolub.m == 30),:);
calInterpGolub = removevars(calInterpGolub,{'m'});
clear calTermInterpGolub h m s

calTermInterpRojo = InterpolTable(calValidRojo,calTrackRojo);
calInterpRojo = InterpolData(calTermInterpRojo);
[h,m,s] = hms(calInterpRojo.Time);
calInterpRojo = addvars(calInterpRojo,m);
calInterpRojo = calInterpRojo((calInterpRojo.m == 30),:);
calInterpRojo = removevars(calInterpRojo,{'m'});
clear calTermInterpRojo 
clear h m s

calTermInterpSTARSnorth = InterpolTable(calValidSTARSnorth,calTrackSTARSnorth);
calInterpSTARSnorth = InterpolData(calTermInterpSTARSnorth);
[h,m,s] = hms(calInterpSTARSnorth.Time);
calInterpSTARSnorth = addvars(calInterpSTARSnorth,m);
calInterpSTARSnorth = calInterpSTARSnorth((calInterpSTARSnorth.m == 30),:);
calInterpSTARSnorth = removevars(calInterpSTARSnorth,{'m'});
clear calTermInterpSTARSnorth h m s

calTermInterpSTARSsouth = InterpolTable(calValidSTARSsouth,calTrackSTARSsouth);
calInterpSTARSsouth = InterpolData(calTermInterpSTARSsouth);
[h,m,s] = hms(calInterpSTARSsouth.Time);
calInterpSTARSsouth = addvars(calInterpSTARSsouth,m);
calInterpSTARSsouth = calInterpSTARSsouth((calInterpSTARSsouth.m == 30),:);
calInterpSTARSsouth = removevars(calInterpSTARSsouth,{'m'});
clear calTermInterpSTARSsouth h m s

calTermInterpNoer2019 = InterpolTable(calValidNoer2019,calTrackNoer2019);
calInterpNoer2019 = InterpolData(calTermInterpNoer2019);
[h,m,s] = hms(calInterpNoer2019.Time);
calInterpNoer2019 = addvars(calInterpNoer2019,m);
calInterpNoer2019 = calInterpNoer2019((calInterpNoer2019.m == 30),:);
calInterpNoer2019 = removevars(calInterpNoer2019,{'m'});
clear calTermInterpNoer2019 
clear h m s

% calTermInterpKolstad = InterpolTable(calValidKolstad,calTrackKolstad);
% calInterpKolstad = InterpolData(calTermInterpKolstad);
% [h,m,s] = hms(calInterpKolstad.Time);
% calInterpKolstad = addvars(calInterpKolstad,m);
% calInterpKolstad = calInterpKolstad((calInterpKolstad.m == 30),:);
% calInterpKolstad = removevars(calInterpKolstad,{'m'});
% clear calTermInterpRojo 
% clear h m s







%% 7. Нахождение пересекающихся случаев

calInterpGolub = AddYearMonthDayToTable(calInterpGolub);
calInterpNoer2019 = AddYearMonthDayToTable(calInterpNoer2019);
calInterpRojo = AddYearMonthDayToTable(calInterpRojo);
calInterpSTARSnorth = AddYearMonthDayToTable(calInterpSTARSnorth);
calInterpSTARSsouth = AddYearMonthDayToTable(calInterpSTARSsouth);

%%
clear CrossTableRojo

for i = 1:size(calInterpRojo,1)
    termSTARSsouth = FindCrossYMDH(calInterpSTARSsouth,calInterpRojo,i);
    if size(termSTARSsouth,1) > 0
        for j = 1:size(termSTARSsouth,1)
           diffLat = abs(calInterpRojo.Latitude(i) - termSTARSsouth.Latitude(j));
           diffLon = abs(calInterpRojo.Longitude(i) - termSTARSsouth.Longitude(j));
           if diffLat < 1.5
           if diffLon < 1.5
                NumSTARSsouth(i,1) = termSTARSsouth.Num(j);
           end   
           end  
        end    
    end    
    

    termSTARSnorth = FindCrossYMDH(calInterpSTARSnorth,calInterpRojo,i);
    if size(termSTARSnorth,1) > 0
        for j = 1:size(termSTARSnorth,1)
           diffLat = abs(calInterpRojo.Latitude(i) - termSTARSnorth.Latitude(j));
           diffLon = abs(calInterpRojo.Longitude(i) - termSTARSnorth.Longitude(j));
           if diffLat < 1.5
           if diffLon < 1.5
                NumSTARSnorth(i,1) = termSTARSnorth.Num(j);
           end   
           end  
        end    
    end  

    termNoer2019 = FindCrossYMDH(calInterpNoer2019,calInterpRojo,i);
    if size(termNoer2019,1) > 0
        for j = 1:size(termNoer2019,1)
           diffLat = abs(calInterpRojo.Latitude(i) - termNoer2019.Latitude(j));
           diffLon = abs(calInterpRojo.Longitude(i) - termNoer2019.Longitude(j));
           if diffLat < 1.5
           if diffLon < 1.5
                NumNoer2019(i,1) = termNoer2019.Num(j);
           end   
           end  
        end    
    end  
 
    termGolub = FindCrossYMDH(calInterpGolub,calInterpRojo,i);
    if size(termGolub,1) > 0
        for j = 1:size(termGolub,1)
           diffLat = abs(calInterpRojo.Latitude(i) - termGolub.Latitude(j));
           diffLon = abs(calInterpRojo.Longitude(i) - termGolub.Longitude(j));
           if diffLat < 1.5
           if diffLon < 1.5
                NumGolub(i,1) = termGolub.Num(j);
           end   
           end  
        end    
    end  
 

end     

NumGolub(size(calInterpRojo,1),1) = 0;
NumNoer2019(size(calInterpRojo,1),1) = 0;
NumSTARSnorth(size(calInterpRojo,1),1) = 0;
NumSTARSsouth(size(calInterpRojo,1),1) = 0;

CrossTableRojo = calInterpRojo;
CrossTableRojo = addvars(CrossTableRojo,NumGolub,NumNoer2019,NumSTARSnorth,NumSTARSsouth);
CrossTableRojo = removevars(CrossTableRojo, {'Diam','Year','Month','Day','Hour'});
CrossTableRojo = movevars(CrossTableRojo, 'NumGolub', 'Before', 'Latitude');
CrossTableRojo = movevars(CrossTableRojo, 'NumNoer2019', 'Before', 'Latitude');
CrossTableRojo = movevars(CrossTableRojo, 'NumSTARSnorth', 'Before', 'Latitude');
CrossTableRojo = movevars(CrossTableRojo, 'NumSTARSsouth', 'Before', 'Latitude');
CrossTableRojo.Properties.VariableNames{1} = 'NumRojo';


clear termGolub termNoer2019 termSTARSnorth termSTARSsouth
clear NumGolub NumNoer2019 NumSTARSnorth NumSTARSsouth i j



%%
UniqueRojoSTARSnorth = calInterpSTARSnorth; 
for i = 1:size(CrossTableRojo,1)
    UniqueRojoSTARSnorth = UniqueRojoSTARSnorth((UniqueRojoSTARSnorth.Num ~= ...
        CrossTableRojo.NumSTARSnorth(i)),:);
end    

UniqueRojoSTARSsouth = calInterpSTARSsouth; 
for i = 1:size(CrossTableRojo,1)
    UniqueRojoSTARSsouth = UniqueRojoSTARSsouth((UniqueRojoSTARSsouth.Num ~= ...
        CrossTableRojo.NumSTARSsouth(i)),:);
end    

UniqueRojoNoer2019 = calInterpNoer2019; 
for i = 1:size(CrossTableRojo,1)
    UniqueRojoNoer2019 = UniqueRojoNoer2019((UniqueRojoNoer2019.Num ~= ...
        CrossTableRojo.NumNoer2019(i)),:);
end    

UniqueRojoGolub = calInterpGolub; 
for i = 1:size(CrossTableRojo,1)
    UniqueRojoGolub = UniqueRojoGolub((UniqueRojoGolub.Num ~= ...
        CrossTableRojo.NumGolub(i)),:);
end  



%% 
for i = 1:size(UniqueRojoNoer2019,1)
    termSTARSsouth = FindCrossYMDH(UniqueRojoSTARSsouth,UniqueRojoNoer2019,i);
    if size(termSTARSsouth,1) > 0
        for j = 1:size(termSTARSsouth,1)
           diffLat = abs(UniqueRojoNoer2019.Latitude(i) - termSTARSsouth.Latitude(j));
           diffLon = abs(UniqueRojoNoer2019.Longitude(i) - termSTARSsouth.Longitude(j));
           if diffLat < 2
           if diffLon < 2
                NumSTARSsouth(i,1) = termSTARSsouth.Num(j);
           end   
           end  
        end    
    end   

    termSTARSnorth = FindCrossYMDH(UniqueRojoSTARSnorth,UniqueRojoNoer2019,i);
    if size(termSTARSnorth,1) > 0
        for j = 1:size(termSTARSnorth,1)
           diffLat = abs(UniqueRojoNoer2019.Latitude(i) - termSTARSnorth.Latitude(j));
           diffLon = abs(UniqueRojoNoer2019.Longitude(i) - termSTARSnorth.Longitude(j));
           if diffLat < 2
           if diffLon < 2
                NumSTARSnorth(i,1) = termSTARSnorth.Num(j);
           end   
           end  
        end    
    end   
    
    termGolub = FindCrossYMDH(UniqueRojoGolub,UniqueRojoNoer2019,i);
    if size(termGolub,1) > 0
        for j = 1:size(termGolub,1)
           diffLat = abs(UniqueRojoNoer2019.Latitude(i) - termGolub.Latitude(j));
           diffLon = abs(UniqueRojoNoer2019.Longitude(i) - termGolub.Longitude(j));
           if diffLat < 2
           if diffLon < 2
                NumGolub(i,1) = termGolub.Num(j);
           end   
           end  
        end    
    end   
  
end    

NumGolub(size(UniqueRojoNoer2019,1),1) = 0;
NumSTARSnorth(size(UniqueRojoNoer2019,1),1) = 0;
NumSTARSsouth(size(UniqueRojoNoer2019,1),1) = 0;

CrossTableNoer2019 = UniqueRojoNoer2019;
CrossTableNoer2019 = removevars(CrossTableNoer2019, {'Diam','Year','Month','Day','Hour'});
CrossTableNoer2019 = addvars(CrossTableNoer2019,NumGolub,NumSTARSnorth,NumSTARSsouth);
CrossTableNoer2019.Properties.VariableNames{1} = 'NumNoer2019';

clear termGolub termSTARSnorth termSTARSsouth
clear NumGolub NumSTARSnorth NumSTARSsouth i j



%%
UniqueNoer2019STARSnorth = UniqueRojoSTARSnorth; 
for i = 1:size(CrossTableNoer2019,1)
    UniqueNoer2019STARSnorth = UniqueNoer2019STARSnorth((UniqueNoer2019STARSnorth.Num ~= ...
        CrossTableNoer2019.NumSTARSnorth(i)),:);
end    

UniqueNoer2019STARSsouth = UniqueRojoSTARSsouth; 
for i = 1:size(CrossTableNoer2019,1)
    UniqueNoer2019STARSsouth = UniqueNoer2019STARSsouth((UniqueNoer2019STARSsouth.Num ~= ...
        CrossTableNoer2019.NumSTARSsouth(i)),:);
end    

UniqueNoer2019Golub = UniqueRojoGolub; 
for i = 1:size(CrossTableNoer2019,1)
    UniqueNoer2019Golub = UniqueNoer2019Golub((UniqueNoer2019Golub.Num ~= ...
        CrossTableNoer2019.NumGolub(i)),:);
end  



%% 
termUniqueValidGolub = calValidGolub;
for i = 1:size(UniqueNoer2019Golub,1)
    termUniqueValidGolub = termUniqueValidGolub((termUniqueValidGolub.Num ~= ...
        UniqueNoer2019Golub.Num(i)),:);  
end

UniqueValidGolub = calValidGolub;
for i = 1:size(termUniqueValidGolub,1)
    UniqueValidGolub = UniqueValidGolub((UniqueValidGolub.Num ~= ...
        termUniqueValidGolub.Num(i)),:);
end

%%%%%%%%%%%%
termUniqueValidSTARSnorth = calValidSTARSnorth;
for i = 1:size(UniqueNoer2019STARSnorth,1)
    termUniqueValidSTARSnorth = termUniqueValidSTARSnorth((termUniqueValidSTARSnorth.Num ~= ...
        UniqueNoer2019STARSnorth.Num(i)),:);  
end  

UniqueValidSTARSnorth = calValidSTARSnorth;
for i = 1:size(termUniqueValidSTARSnorth,1)
    UniqueValidSTARSnorth = UniqueValidSTARSnorth((UniqueValidSTARSnorth.Num ~= ...
        termUniqueValidSTARSnorth.Num(i)),:);
end
%%%%%%%%%%%%
termUniqueValidSTARSsouth = calValidSTARSsouth;
for i = 1:size(UniqueNoer2019STARSsouth,1)
    termUniqueValidSTARSsouth = termUniqueValidSTARSsouth((termUniqueValidSTARSsouth.Num ~= ...
        UniqueNoer2019STARSsouth.Num(i)),:);  
end  

UniqueValidSTARSsouth = calValidSTARSsouth;
for i = 1:size(termUniqueValidSTARSsouth,1)
    UniqueValidSTARSsouth = UniqueValidSTARSsouth((UniqueValidSTARSsouth.Num ~= ...
        termUniqueValidSTARSsouth.Num(i)),:);
end
%%%%%%%%%%%%
termUniqueValidNoer2019 = calValidNoer2019;
for i = 1:size(CrossTableNoer2019,1)
    termUniqueValidNoer2019 = termUniqueValidNoer2019((termUniqueValidNoer2019.Num ~= ...
        CrossTableNoer2019.NumNoer2019(i)),:);  
end  

UniqueValidNoer2019 = calValidNoer2019;
for i = 1:size(termUniqueValidNoer2019,1)
    UniqueValidNoer2019 = UniqueValidNoer2019((UniqueValidNoer2019.Num ~= ...
        termUniqueValidNoer2019.Num(i)),:);
end
%%%%%%%%%%%%
termUniqueValidRojo = calValidRojo;
for i = 1:size(CrossTableRojo,1)
    termUniqueValidRojo = termUniqueValidRojo((termUniqueValidRojo.Num ~= ...
        CrossTableRojo.NumRojo(i)),:);  
end  

UniqueValidRojo = calValidRojo;
for i = 1:size(termUniqueValidRojo,1)
    UniqueValidRojo = UniqueValidRojo((UniqueValidRojo.Num ~= ...
        termUniqueValidRojo.Num(i)),:);
end
%%%%%%%%%%%%
clear termUniqueValidGolub termUniqueValidNoer2019 termUniqueValidRojo ...
    termUniqueValidSTARSnorth termUniqueValidSTARSsouth
%% Добавить столбцы с годами и месяцами
UniqueValidGolub = AddYearMonthDayToTable(UniqueValidGolub);
UniqueValidNoer2019 = AddYearMonthDayToTable(UniqueValidNoer2019);
UniqueValidSTARSnorth = AddYearMonthDayToTable(UniqueValidSTARSnorth);
UniqueValidSTARSsouth = AddYearMonthDayToTable(UniqueValidSTARSsouth);
UniqueValidRojo = AddYearMonthDayToTable(UniqueValidRojo);

%% Гистограмма год-месяц
YearMonth(:,1) = [UniqueValidGolub.Year' UniqueValidNoer2019.Year' ...
    UniqueValidRojo.Year' UniqueValidSTARSnorth.Year' ...
    UniqueValidSTARSsouth.Year']';
YearMonth(:,2) = [UniqueValidGolub.Month' UniqueValidNoer2019.Month' ...
    UniqueValidRojo.Month' UniqueValidSTARSnorth.Month' ...
    UniqueValidSTARSsouth.Month']';

clf
histogram2(YearMonth(:,1),YearMonth(:,2),'DisplayStyle',"tile")
mycolormap = customcolormap(linspace(0,1,11), {'#a60126','#d7302a','#f36e43','#faac5d','#fedf8d','#fcffbf','#d7f08b','#a5d96b','#68bd60','#1a984e','#006936'});
% mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});
% C=parula(10)
% colormap(mycolormap(C));
% colormap(flipud(C))
% colorbar
colormap(mycolormap);
colorbar;
title('Гистограмма наблюдений мезоциклонов по календарям STARS, Rojo, Golubkin и Noer', 'FontSize',13);

yticks([1 2 3 4 5 6 7 8 9 10 11 12])
yticklabels({'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'});
xticks([2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 ...
    2012 2013 2014 2015]);



%%