function CrossTable = FindCrossYMDH(x,y,i)
    CrossTable = x((x.Year == y.Year(i) & x.Month == y.Month(i) & ...
        x.Day == y.Day(i) & x.Hour == y.Hour(i)),:);
end