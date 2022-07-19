linenames = {'Golubkin', 'Noer', 'Rojo', 'STARSnorth', "STARSsouth"}
starttimes = {calTrackGolubkin.Time(1) calTrackNoer2019.Time(1) calTrackRojo.Time(1) calTrackSTARSnorth.Time(1) calTrackSTARSsouth.Time(1)}
endtimes = {calTrackGolubkin.Time(1266) calTrackNoer2019.Time(1531) calTrackRojo.Time(3850) calTrackSTARSnorth.Time(1723) calTrackSTARSsouth.Time(661)}
a = timeline(linenames,starttimes,endtimes,'lineSpacing',.99999,'facecolor',[0.25 0.62 1])
datetick('keeplimits');
title('Временной охват календарей Golubkin, Rojo и STARS')