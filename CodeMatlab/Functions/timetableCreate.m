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
