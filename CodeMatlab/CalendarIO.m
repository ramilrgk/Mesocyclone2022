%%
%       1. КАЛЕНДАРИ
%
%%%     Условие в построении календаря Golubkin на cal.lat > 1 вызвано тем что
%%% в данных изначальной таблицы различные мезоциклоны отделены друг от
%%% друга пустой строкой. В таблице ей присвоены нули. Таким образом эти
%%% пустые строки можно исключить. 
%%%     Для календаря Kolstad нет необходимости производить отбор,
%%% поэтому календарь по умолчанию называется calSelectColstad. (подробнее
%%% о отборе см. раздел #3)
% 
% Календарь Colstad все случаи
calSelectColstad = cal((cal.source == 1),:);
calSelectColstad.Properties.DimensionNames{1} = 'dateSelect';
% Календарь Golubkin все случаи c треками
calTrackGolubkin = cal((cal.source == 2 & cal.latitude > 1),:);
% Календарь PANGAEA все случаи с треками
calTrackPANG = cal((cal.source == 3),:);

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
%%%     2.2. Полигон домена созданный по границам из #2.1., дискретностью в
%%%          1 градус. Производится вычисление длины стороны домена в 
%%%          единицах ячеек. Домен представляет собой прямоугольник 91 на 24
%%%          Запись в полигон производится по часовой стрелке с точки
%%%          левого верхнего угла "прямоугольника" домена
%%%     2.3. Валидация. inpolygon сверяет список точек на условие вхождение
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

%%%% 2.2. Полигон домена
% Длина стороны домена
lgthBorderLat = (borderLat(1,1)-borderLat(1,2))+1;
lgthBorderLon = (borderLon(1,1)-borderLon(1,2))+1;
% Запись полигона
lgthPolygon = 1;
for i = 1:lgthBorderLon
    polygonLat(1,lgthPolygon) = borderLat(1,1);
    polygonLon(1,lgthPolygon) = borderLon(1,2)+(i-1);
    lgthPolygon = lgthPolygon + 1;
end
lgthPolygon = lgthPolygon - 1;
for i = 1:lgthBorderLat
    polygonLat(1,lgthPolygon) = borderLat(1,1)-(i-1);
    polygonLon(1,lgthPolygon) = borderLon(1,1);
    lgthPolygon = lgthPolygon + 1;
end
lgthPolygon = lgthPolygon - 1;
for i = 1:lgthBorderLon
    polygonLat(1,lgthPolygon) = borderLat(1,2);
    polygonLon(1,lgthPolygon) = borderLon(1,1)-(i-1);
    lgthPolygon = lgthPolygon + 1;
end
lgthPolygon = lgthPolygon - 1;
for i = 1:lgthBorderLat
    polygonLat(1,lgthPolygon) = borderLat(1,2)+(i-1);
    polygonLon(1,lgthPolygon) = borderLon(1,2);
    lgthPolygon = lgthPolygon + 1;
end

%%%% 2.3. Валидация
inColstad = inpolygon(calSelectColstad.longitude,calSelectColstad.latitude,polygonLon,polygonLat);
inGolub = inpolygon(calTrackGolubkin.longitude,calTrackGolubkin.latitude,polygonLon,polygonLat);
inPANG = inpolygon(calTrackPANG.longitude,calTrackPANG.latitude,polygonLon,polygonLat);
% Запись результата в таблицу и переименование
if ismember('valid',calSelectColstad.Properties.VariableNames) == 0 
calSelectColstad = addvars(calSelectColstad,inColstad);
calSelectColstad = renamevars(calSelectColstad,"inColstad","valid");
end
if ismember('valid',calTrackGolubkin.Properties.VariableNames) == 0 
calTrackGolubkin = addvars(calTrackGolubkin,inGolub);
calTrackGolubkin = renamevars(calTrackGolubkin,"inGolub","valid");
end
if ismember('valid',calTrackPANG.Properties.VariableNames) == 0 
calTrackPANG = addvars(calTrackPANG,inPANG);
calTrackPANG = renamevars(calTrackPANG,"inPANG","valid");
end

%%%% Очистка
clear borderLat borderLon 
clear lgthBorderLat lgthBorderLon
% clear polygonLat polygonLon 
clear lgthPolygon
clear inColstad inGolub inPANG i
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
%%%     поэтому календарь по умолчанию называется calSelectColstad и
%%%     создается в разделе #1

%%% 3.1 Golubkin
% Счетчики
countTrackPoint = 1;    %Кол-во точек трека
countValidPoint = 0;    %Кол-во valid точек трека
countRowNewTable = 1;   %Номер строки для отдельного мезоциклона в новой таблице
strValidPoint = '';     %Текстовый счетчик последовательности (non)valid в треке.
                        %Результат последовательность единиц и нулей с
                        %помощью которой можно определить на какой
                        %стадии мезоциклон выходил из области моделирования

for i = 2:1:size(calTrackGolubkin,1)
    
    % Разница между строками по времени, широте и долготе
    timeDiff = datenum(calTrackGolubkin.time(i) - calTrackGolubkin.time(i-1));
    latDiff = abs(calTrackGolubkin.latitude(i) - calTrackGolubkin.latitude(i-1));
    lonDiff = abs(calTrackGolubkin.longitude(i) - calTrackGolubkin.longitude(i-1));
    
    if timeDiff < 1        % 1 = 24 часа
        if and(latDiff < 5, lonDiff < 5)        % 1 = 1 градус сетки
            countTrackPoint = countTrackPoint+1;
            countValidPoint = countValidPoint+calTrackGolubkin.valid(i);
            %%%% Текстовый счетчик последовательности (non)valid в треке
            % Временная текстовая переменная которая хранит значение valid
            % строки i
            strTermValidPoint = num2str(calTrackGolubkin.valid(i));
            % Конкатенация
            strValidPoint = strcat(strValidPoint,strTermValidPoint);
        else
            %%% В эту ветвь (вложенное условие) запись происходит в ситуации
            %%% если в тот-же отрезок времени главного условия, в удалении
            %%% по координатам вложенного условия, есть другой мезоциклон
            
            % Позиция ячейки середины трека
            middleTrack = i-1 - (round(countTrackPoint/2));
            % Время и координаты
            calTermGolubkin(countRowNewTable,1) = datenum(calTrackGolubkin.time(middleTrack));
            calTermGolubkin(countRowNewTable,2) = calTrackGolubkin.latitude(middleTrack);
            calTermGolubkin(countRowNewTable,3) = calTrackGolubkin.longitude(middleTrack);
            % Количество точек в треке (numPoint)
            calTermGolubkin(countRowNewTable,4) = countTrackPoint;
            % Количество valid точек в треке (validPoint)
            calTermGolubkin(countRowNewTable,5) = countValidPoint;
            % Наличие другого циклона в это же время (sameTime)
            calTermGolubkin(countRowNewTable,6) = 1;
            % Количество non-Valid точек в треке
            calTermGolubkin(countRowNewTable,7) = countTrackPoint - countValidPoint;
            % Последовательность (non)valid в треке
            calTextTermGolubkin(countRowNewTable,1) = convertCharsToStrings(strValidPoint);
            % Номера ячеек начала и конца трека
            calTermGolubkin(countRowNewTable,9) = (i-countTrackPoint);
            calTermGolubkin(countRowNewTable,10) = i-1;
            % Время начала и конца трека
            calTermGolubkin(countRowNewTable,11) = datenum(calTrackGolubkin.time(i-countTrackPoint));
            calTermGolubkin(countRowNewTable,12) = datenum(calTrackGolubkin.time(i-1));
            
            % Очистка счетчиков
            countRowNewTable = countRowNewTable+1;
            countTrackPoint = 1;
            countValidPoint = 0; 
            strValidPoint = ''; 
        end
    else
        %%% В эту ветвь (главное условие) запись происходит когда разница
        %%% между соседними строками по времени больше определенного
        %%% значения, что подразумевает собой два разных мезоциклона
        
        % Позиция ячейки середины трека
        middleTrack = i-1 - (round(countTrackPoint/2));
        calTermGolubkin(countRowNewTable,1) = datenum(calTrackGolubkin.time(middleTrack));
        calTermGolubkin(countRowNewTable,2) = calTrackGolubkin.latitude(middleTrack);
        calTermGolubkin(countRowNewTable,3) = calTrackGolubkin.longitude(middleTrack);
        % Количество точек в треке (numPoint)
        calTermGolubkin(countRowNewTable,4) = countTrackPoint;
        % Количество valid точек в треке (validPoint)
        calTermGolubkin(countRowNewTable,5) = countValidPoint;
        % Наличие другого циклона в это же время (sameTime)
        calTermGolubkin(countRowNewTable,6) = 0;
        % Количество non-Valid точек в треке
        calTermGolubkin(countRowNewTable,7) = countTrackPoint - countValidPoint;
        % Последовательность (non)valid в треке
        calTextTermGolubkin(countRowNewTable,8) = convertCharsToStrings(strValidPoint);
        % Номера ячеек начала и конца трека
        calTermGolubkin(countRowNewTable,9) = (i-countTrackPoint);
        calTermGolubkin(countRowNewTable,10) = i-1;
        % Время начала и конца трека
        calTermGolubkin(countRowNewTable,11) = datenum(calTrackGolubkin.time(i-countTrackPoint));
        calTermGolubkin(countRowNewTable,12) = datenum(calTrackGolubkin.time(i-1));
            
        
        % Очистка счетчиков
        countRowNewTable = countRowNewTable+1;
        countTrackPoint = 1;
        countValidPoint = 0; 
        strValidPoint = ''; 
    end 
end

% Создание таблицы
for i=1:size(calTermGolubkin,1)
    dateSelect(i,1) = datetime(calTermGolubkin(i,1),'ConvertFrom','datenum');
    dateStartGolubkin(i,1) = datetime(calTermGolubkin(i,11),'ConvertFrom','datenum');
    dateEndGolubkin(i,1) = datetime(calTermGolubkin(i,12),'ConvertFrom','datenum');
end
calSelectGolubkin = timetable(dateSelect,calTermGolubkin(:,2),...
    calTermGolubkin(:,3),calTermGolubkin(:,4),calTermGolubkin(:,5),...
    calTermGolubkin(:,6),calTermGolubkin(:,7),calTextTermGolubkin(:,1),...
    calTermGolubkin(:,9),calTermGolubkin(:,10),dateStartGolubkin,dateEndGolubkin);
calSelectGolubkin.Properties.VariableNames = {'latitude','longitude',...
    'numPoint','validPoint','sameTime','NvalidPoint','seqValid',...
    'startCell','endCell','dateStart','dateEnd'};

%%%% Очистка
clear countRowNewTable countTrackPoint countValidPoint strValidPoint
clear timeDiff latDiff lonDiff
clear strTermValidPoint i 
clear calTermGolubkin dateSelect dateStartGolubkin dateEndGolubkin
clear middleTrack
clear calTextTermGolubkin

%% 3.2. PANGAEA
% Счетчики
countTrackPoint = 1;    %Кол-во точек трека
countValidPoint = 0;    %Кол-во valid точек трека
countRowNewTable = 1;   %Номер строки для отдельного мезоциклона в новой таблице
strValidPoint = '';     %Текстовый счетчик последовательности (non)valid в треке.
                        %Результат последовательность единиц и нулей с
                        %помощью которой можно определить на какой
                        %стадии мезоциклон выходил из области моделирования

for i = 2:1:size(calTrackPANG,1)
    
    % Разница между строками по времени, широте и долготе
    timeDiff = datenum(calTrackPANG.time(i) - calTrackPANG.time(i-1));
    latDiff = abs(calTrackPANG.latitude(i) - calTrackPANG.latitude(i-1));
    lonDiff = abs(calTrackPANG.longitude(i) - calTrackPANG.longitude(i-1));
    
    if timeDiff < 1        % 1 = 24 часа
        if and(latDiff < 5, lonDiff < 5)        % 1 = 1 градус сетки
            countTrackPoint = countTrackPoint+1;
            countValidPoint = countValidPoint+calTrackPANG.valid(i);
            %%%% Текстовый счетчик последовательности (non)valid в треке
            % Временная текстовая переменная которая хранит значение valid
            % строки i
            strTermValidPoint = num2str(calTrackPANG.valid(i));
            % Конкатенация
            strValidPoint = strcat(strValidPoint,strTermValidPoint);
        else
            %%% В эту ветвь (вложенное условие) запись происходит в ситуации
            %%% если в тот-же отрезок времени главного условия, в удалении
            %%% по координатам вложенного условия, есть другой мезоциклон
            
            % Позиция ячейки середины трека
            middleTrack = i-1 - (round(countTrackPoint/2));
            % Время и координаты
            calTermPANG(countRowNewTable,1) = datenum(calTrackPANG.time(middleTrack));
            calTermPANG(countRowNewTable,2) = calTrackPANG.latitude(middleTrack);
            calTermPANG(countRowNewTable,3) = calTrackPANG.longitude(middleTrack);
            % Количество точек в треке (numPoint)
            calTermPANG(countRowNewTable,4) = countTrackPoint;
            % Количество valid точек в треке (validPoint)
            calTermPANG(countRowNewTable,5) = countValidPoint;
            % Наличие другого циклона в это же время (sameTime)
            calTermPANG(countRowNewTable,6) = 1;
            % Количество non-Valid точек в треке
            calTermPANG(countRowNewTable,7) = countTrackPoint - countValidPoint;
            % Последовательность (non)valid в треке
            calTextTermPANG(countRowNewTable,1) = convertCharsToStrings(strValidPoint);
            % Номера ячеек начала и конца трека
            calTermPANG(countRowNewTable,9) = (i-countTrackPoint);
            calTermPANG(countRowNewTable,10) = i-1;
            % Время начала и конца трека
            calTermPANG(countRowNewTable,11) = datenum(calTrackPANG.time(i-countTrackPoint));
            calTermPANG(countRowNewTable,12) = datenum(calTrackPANG.time(i-1));
        
            
            % Очистка счетчиков
            countRowNewTable = countRowNewTable+1;
            countTrackPoint = 1;
            countValidPoint = 0; 
            strValidPoint = ''; 
        end
    else
        %%% В эту ветвь (главное условие) запись происходит когда разница
        %%% между соседними строками по времени больше определенного
        %%% значения, что подразумевает собой два разных мезоциклона
        
        % Позиция ячейки середины трека
        middleTrack = i-1 - (round(countTrackPoint/2));
        calTermPANG(countRowNewTable,1) = datenum(calTrackPANG.time(middleTrack));
        calTermPANG(countRowNewTable,2) = calTrackPANG.latitude(middleTrack);
        calTermPANG(countRowNewTable,3) = calTrackPANG.longitude(middleTrack);
        % Количество точек в треке (numPoint)
        calTermPANG(countRowNewTable,4) = countTrackPoint;
        % Количество valid точек в треке (validPoint)
        calTermPANG(countRowNewTable,5) = countValidPoint;
        % Наличие другого циклона в это же время (sameTime)
        calTermPANG(countRowNewTable,6) = 0;
        % Количество non-Valid точек в треке
        calTermPANG(countRowNewTable,7) = countTrackPoint - countValidPoint;
        % Последовательность (non)valid в треке
        calTextTermPANG(countRowNewTable,8) = convertCharsToStrings(strValidPoint);
        % Номера ячеек начала и конца трека
        calTermPANG(countRowNewTable,9) = (i-countTrackPoint);
        calTermPANG(countRowNewTable,10) = i-1;
        % Время начала и конца трека
        calTermPANG(countRowNewTable,11) = datenum(calTrackPANG.time(i-countTrackPoint));
        calTermPANG(countRowNewTable,12) = datenum(calTrackPANG.time(i-1));
        
        
        % Очистка счетчиков
        countRowNewTable = countRowNewTable+1;
        countTrackPoint = 1;
        countValidPoint = 0; 
        strValidPoint = ''; 
    end 
end

% Создание таблицы
for i=1:size(calTermPANG,1)
    dateSelect(i,1) = datetime(calTermPANG(i,1),'ConvertFrom','datenum');
    dateStartPANG(i,1) = datetime(calTermPANG(i,11),'ConvertFrom','datenum');
    dateEndPANG(i,1) = datetime(calTermPANG(i,12),'ConvertFrom','datenum');
end
calSelectPANG = timetable(dateSelect,calTermPANG(:,2),...
    calTermPANG(:,3),calTermPANG(:,4),calTermPANG(:,5),...
    calTermPANG(:,6),calTermPANG(:,7),calTextTermPANG(:,1),...
    calTermPANG(:,9),calTermPANG(:,10),dateStartPANG,dateEndPANG);
calSelectPANG.Properties.VariableNames = {'latitude','longitude',...
    'numPoint','validPoint','sameTime','NvalidPoint','seqValid',...
    'startCell','endCell','dateStart','dateEnd'};

%%%% Очистка
clear countRowNewTable countTrackPoint countValidPoint strValidPoint
clear timeDiff latDiff lonDiff
clear strTermValidPoint i 
clear calTermPANG dateSelect dateStartPANG dateEndPANG
clear middleTrack
clear calTextTermPANG

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

%%%% Вывод функции и присваивание вывода таблице calSelect
% Golubkin. 

calDateSelect = cutByTimes(calSelectGolubkin);
calSelectGolubkin = calDateSelect;
% PANGAEA
calDateSelect = cutByTimes(calSelectPANG);
calSelectPANG = calDateSelect;

clear calDateSelect

%% 
%       5. Карта точек мезоциклонов
%
%%%
%%%

%%%% 5.1 Календари с Valid и Non-Valid
calValidColstad = calSelectColstad((calSelectColstad.valid == 1),:);
calValidGolubkin = calSelectGolubkin((calSelectGolubkin.NvalidPoint < 2),:);
calValidPANG = calSelectPANG((calSelectPANG.NvalidPoint < 2),:);

calNonValidColstad = calSelectColstad((calSelectColstad.valid == 0),:);
calNonValidGolubkin = calSelectGolubkin((calSelectGolubkin.NvalidPoint > 2),:);
calNonValidPANG = calSelectPANG((calSelectPANG.NvalidPoint > 2),:);
%% 5.2 Карта
% Папка с дополнениями. Здесь необходим пакет M_map
addpath(genpath('/home/ramil/Program/Matlab/MATLAB Add-Ons'))

%%%% Инициализация карты
clf
m_proj('Azimuthal Equal-Area','lon',-30,'lat',60,'rad',35,'rec','circle','rot',0);
m_grid('xlabeldir','end','ylabeldir','end','tickdir','out',...
    'xaxisLocation','bottom','yaxisLocation','right',...
    'ytick',[90 80 70 60 50],'fontsize',9);
m_coast('patch',[0.94 0.94 0.94],'edgecolor','k');
% m_gshhs_l('patch',[.9 .9 .9]); %high-res coast

%%%% Изображение области моделирования
m_line(polygonLon,polygonLat,'color','k','linewi',1.5);

%%%% Нанесение маркеров мезоциклонов
% Размер маркеров
mksz = 6;

% Valid Pangaea
for i=1:size(calValidPANG,1)
    m_line(calValidPANG.longitude(i),calValidPANG.latitude(i),'marker','x','markersize',mksz,'color','g','LineWidth',1);
end

% Non-Valid Pangaea
for i=1:size(calNonValidPANG,1)
    m_line(calNonValidPANG.longitude(i),calNonValidPANG.latitude(i),'marker','x','markersize',mksz,'color','k','LineWidth',1);
end

% Valid Golubkin
for i=1:size(calValidGolubkin,1)
    m_line(calValidGolubkin.longitude(i),calValidGolubkin.latitude(i),'marker','+','markersize',mksz,'color','b','LineWidth',1);
end

% Non-Valid Golubkin
for i=1:size(calNonValidGolubkin,1)
    m_line(calNonValidGolubkin.longitude(i),calNonValidGolubkin.latitude(i),'marker','+','markersize',mksz,'color','k','LineWidth',1);
end

% Valid Colstad
for i=1:size(calValidColstad,1)
    m_line(calValidColstad.longitude(i),calValidColstad.latitude(i),'marker','s','markersize',mksz,'color','r','LineWidth',1);
end    

% Non-Valid Colstad
for i=1:size(calNonValidColstad,1)
    m_line(calNonValidColstad.longitude(i),calNonValidColstad.latitude(i),'marker','s','markersize',mksz,'color','k','LineWidth',1);
end

title('Граница модельной области и мезоциклоны по календарям', 'FontSize',15);


%%
%       6. Карта треков мезоциклонов
%
%%%
%%%

% Папка с дополнениями. Здесь необходим пакет M_map
addpath(genpath('/home/ramil/Program/Matlab/MATLAB Add-Ons'))

%%%% Инициализация карты
clf
m_proj('Azimuthal Equal-Area','lon',-30,'lat',60,'rad',35,'rec','circle','rot',0);
m_grid('xlabeldir','end','ylabeldir','end','tickdir','out',...
    'xaxisLocation','bottom','yaxisLocation','right',...
    'fontsize',9);
m_coast('patch',[0.94 0.94 0.94],'edgecolor','k');
% m_gshhs_l('patch',[.9 .9 .9]); %high-res coast

%%%% Изображение области моделирования
m_line(polygonLon,polygonLat,'color','k','linewi',1.5);

%%%% Нанесение треков мезоциклонов

% Golubkin

%%
% for i = 1:1:(size(calTrackGolubkin,1)-1)
%     timeDiff(i,1) = datenum(calTrackGolubkin.time(i+1) - calTrackGolubkin.time(i));
%     timeDiffDates(i,1) = datetime((timeDiff(i,1)+1),'ConvertFrom','datenum');
% end

countRow = 1;
for i=1:1:(size(calSelectGolubkin,1))
 a = calSelectGolubkin.startCell(i);
 b = calSelectGolubkin.endCell(i);
    for j = a:1:b
        if j == 1
            continue
        end
        timeDiff(countRow,1) = datenum(calTrackGolubkin.time(j) - calTrackGolubkin.time(j-1));
        timeDiffDates(countRow,1) = datetime((timeDiff(i,1)+1),'ConvertFrom','datenum');
        countRow = countRow + 1;
    end
end
clear timeDiff a b i j
%%
%       ФУНКЦИИ
%%%

% Функция из раздела 4.
function calDateSelect = cutByTimes(x)
% Дата временных границ. В формате %Y,%M,%D,%H,%MI,%S
timeStartBorder = datetime(1993,01,01,00,00,00);
timeEndBorder = datetime(2016,01,01,00,01,00);
% Нижняя (ранняя) граница
calTermTb = timetable2table(x);
calTermStartB = table2timetable(calTermTb,'RowTimes',calTermTb.dateStart);
TR = timerange(timeStartBorder,"2200-01-01");
calTermStartBCut = calTermStartB(TR,:);
% Верхняя (поздняя) граница
calTermTb = timetable2table(calTermStartBCut);
calTermEndB = table2timetable(calTermTb,'RowTimes',calTermTb.dateEnd);
TR = timerange("1900-01-01",timeEndBorder);
calTermEndBCut = calTermEndB(TR,:);
% Возврат к предыдущей сортировке по времени середины трека
calTermTb = timetable2table(calTermEndBCut);
calTermFin = table2timetable(calTermTb,'RowTimes',calTermTb.dateSelect);
calTermFin = removevars(calTermFin,{'Time','Time_1','dateSelect'});
calTermFin.Properties.DimensionNames{1} = 'dateSelect';
calDateSelect = calTermFin;
end
