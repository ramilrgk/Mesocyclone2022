%%
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
%
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
%%
%       6. Интерполяция 
%%%
calTermInterpGolub = InterpolTable(calValidGolub,calTrackGolubkin);
calInterpGolub = InterpolData(calTermInterpGolub);
% [h,m,s] = hms(calInterpGolub.Time);
% calInterpGolub = addvars(calInterpGolub,m);
% calInterpGolub = calInterpGolub((calInterpGolub.m == 30),:);
% calInterpGolub = removevars(calInterpGolub,{'m'});
clear calTermInterpGolub 
% clear h m s

calTermInterpRojo = InterpolTable(calValidRojo,calTrackRojo);
calInterpRojo = InterpolData(calTermInterpRojo);
% [h,m,s] = hms(calInterpRojo.Time);
% calInterpRojo = addvars(calInterpRojo,m);
% calInterpRojo = calInterpRojo((calInterpRojo.m == 30),:);
% calInterpRojo = removevars(calInterpRojo,{'m'});
clear calTermInterpRojo 
% clear h m s

calTermInterpSTARSnorth = InterpolTable(calValidSTARSnorth,calTrackSTARSnorth);
calInterpSTARSnorth = InterpolData(calTermInterpSTARSnorth);
% [h,m,s] = hms(calInterpSTARSnorth.Time);
% calInterpSTARSnorth = addvars(calInterpSTARSnorth,m);
% calInterpSTARSnorth = calInterpSTARSnorth((calInterpSTARSnorth.m == 30),:);
% calInterpSTARSnorth = removevars(calInterpSTARSnorth,{'m'});
clear calTermInterpSTARSnorth 
% clear h m s

calTermInterpSTARSsouth = InterpolTable(calValidSTARSsouth,calTrackSTARSsouth);
calInterpSTARSsouth = InterpolData(calTermInterpSTARSsouth);
% [h,m,s] = hms(calInterpSTARSsouth.Time);
% calInterpSTARSsouth = addvars(calInterpSTARSsouth,m);
% calInterpSTARSsouth = calInterpSTARSsouth((calInterpSTARSsouth.m == 30),:);
% calInterpSTARSsouth = removevars(calInterpSTARSsouth,{'m'});
clear calTermInterpSTARSsouth
% clear h m s

calTermInterpNoer2019 = InterpolTable(calValidNoer2019,calTrackNoer2019);
calInterpNoer2019 = InterpolData(calTermInterpNoer2019);
% [h,m,s] = hms(calInterpNoer2019.Time);
% calInterpNoer2019 = addvars(calInterpNoer2019,m);
% calInterpNoer2019 = calInterpNoer2019((calInterpNoer2019.m == 30),:);
% calInterpNoer2019 = removevars(calInterpNoer2019,{'m'});
clear calTermInterpNoer2019 
% clear h m s

% calTermInterpKolstad = InterpolTable(calValidKolstad,calTrackKolstad);
% calInterpKolstad = InterpolData(calTermInterpKolstad);
% [h,m,s] = hms(calInterpKolstad.Time);
% calInterpKolstad = addvars(calInterpKolstad,m);
% calInterpKolstad = calInterpKolstad((calInterpKolstad.m == 30),:);
% calInterpKolstad = removevars(calInterpKolstad,{'m'});
% clear calTermInterpRojo 
% clear h m s
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
%         TermTab = sortrows(TermTab,'Time','ascend');
        TermIntTab = retime(TermTab,'regular','linear','TimeStep',dt);
        z = [z;TermIntTab];
        TermTab = [];
        TermIntTab = [];
        startCell = i;
    end    
end

% end









%%
%           ФУНКЦИИ
%%%

%%%     timetableCreate. 
%%% Функция создания timetable из таблицы с компонентами 
%%% времени в отдельных столбцах. Предполагается что данные будут
%%% загружены с помощью readtable. Т.е. иметь тип данных "table".
%%% Столбцы времени должны иметь названия Year, Month, Day, Hour, Minute

function x = timetableCreate(x)
% Создание массива нулей. См. Предварительное выделение массивов в
% справочнике Matlab. Общая рекомендация при работе с массивами в циклах
timedateTerm = NaT(size(x,1),1);
% Создание таблицы времен
for i = 1:size(x,1)
    timedateTerm(i) = datetime(x.Year(i),x.Month(i),...
    x.Day(i),x.Hour(i),x.Minute(i),00);
end
% Транспонирование матрицы массива
% timedateTerm = timedateTerm';
% Добавление таблицы с временем в общую таблицу
x = addvars(x,timedateTerm);
% Конвертация в timetable с указанием столбца времени timedateTerm
x = table2timetable(x,'RowTimes',x.timedateTerm);
x = removevars(x,{'timedateTerm'});
end

%%%     createSimplePolygon. 
%%% Функция которая создает полигон в котором координаты сторон
%%% не меняются. Т.е. область ограниченная определенной координатой
%%% с севера, юга, востока и запада. 
%%% Аргументы должны использоваться ровно в таком порядке в котором они
%%% указаны в функции. "in1" и "in2" это массивы границ широт, в которых: 
%%% in1(1,1) - северная граница
%%% in1(1,2) - южная граница
%%% in2(1,1) - восточная граница
%%% in2(1,2) - западная граница
%%% Вывод функции, polygonLat и polygonLon - горизонтальные строки
%%% координат полигона. Необходимость функции связана с использованием
%%% функции inpolygon (внутренняя функция Matlab). Полигон замкнутый, т.е.
%%% последний элемент массивов повторяет первый элемент.
%%% Запись в полигон производится по часовой стрелке с точки левого 
%%% верхнего угла "прямоугольника" домена, через один градус для каждой
%%% координаты

function [polygonLat,polygonLon] = createSimplePolygon(in1,in2)
    % Длина стороны домена
    lgthBorderLat = (in1(1,1)-in1(1,2))+1;
    lgthBorderLon = (in2(1,1)-in2(1,2))+1;
    % Создание массива нулей. Необходимо в целях эффективности. Чтобы при
    % каждой итерации цикла не происходило увеличение массива путем
    % присванивания нового значения в цикле. См. "Предварительное выделение
    % массивов" в справочнике Matlab.
    lgthPolygon = ((lgthBorderLat*2)+(lgthBorderLon*2)-3);
    polygonLat = zeros(1,lgthPolygon);
    polygonLon = zeros(1,lgthPolygon);
    % Запись полигона
    lgthPolygon = 1;
    for i = 1:lgthBorderLon
        polygonLat(1,lgthPolygon) = in1(1,1);
        polygonLon(1,lgthPolygon) = in2(1,2)+(i-1);
        lgthPolygon = lgthPolygon + 1;
    end
    lgthPolygon = lgthPolygon - 1;
    for i = 1:lgthBorderLat
        polygonLat(1,lgthPolygon) = in1(1,1)-(i-1);
        polygonLon(1,lgthPolygon) = in2(1,1);
        lgthPolygon = lgthPolygon + 1;
    end
    lgthPolygon = lgthPolygon - 1;
    for i = 1:lgthBorderLon
        polygonLat(1,lgthPolygon) = in1(1,2);
        polygonLon(1,lgthPolygon) = in2(1,1)-(i-1);
        lgthPolygon = lgthPolygon + 1;
    end
    lgthPolygon = lgthPolygon - 1;
    for i = 1:lgthBorderLat
        polygonLat(1,lgthPolygon) = in1(1,2)+(i-1);
        polygonLon(1,lgthPolygon) = in2(1,2);
        lgthPolygon = lgthPolygon + 1;
    end
end


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



%%% CutByTimes
%%%
%%%

function [x] = CutByTimes(x,timeStart,timeEnd)
% Нижняя (ранняя) граница
x.Properties.RowTimes = x.DateStart;
TR = timerange(timeStart,"2200-01-01");
x = x(TR,:);
% Верхняя (поздняя) граница
x.Properties.RowTimes = x.DateEnd;
TR = timerange("1900-01-01",timeEnd);
x = x(TR,:);
% Возврат к предыдущей сортировке по времени середины трека
x.Properties.RowTimes = x.DateSelect;
end


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

%%%%%%% InterpolData
%%%%%%%
function z = InterpolData(x)
numCase = x.Num(1);
startCell = 1;
dt = minutes(180);
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
