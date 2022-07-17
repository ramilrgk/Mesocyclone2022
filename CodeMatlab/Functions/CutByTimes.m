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
