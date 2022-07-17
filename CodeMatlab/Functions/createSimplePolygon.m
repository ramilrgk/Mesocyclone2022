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
