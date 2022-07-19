function YMDtable = AddYearMonthDayToTable(x)
[Year,Month,Day] = ymd(x.Time);
[Hour,~,~] = hms(x.Time);
x = addvars(x,Year,Month,Day,Hour);
YMDtable = x;
end