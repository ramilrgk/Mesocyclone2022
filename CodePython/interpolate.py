# -*- coding: utf-8 -*-
"""
Created on Tue Aug 16 17:30:10 2016

@author: polina
"""

import datetime
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
import numpy as np
import os

print 'Insert file name without out_ and .txt'

myfile=pd.read_csv('/home/polina/Documents/Antarctic/Manual tracking/post/out_'+\
raw_input()+'.txt',delim_whitespace=True,header=None,names=['id','data','lon','lat','diam'])

print 'Insert file name without out_ and .txt again'
outfile = '/home/polina/Documents/Antarctic/'+raw_input()+'int.txt'

# get the lenght of file to read data
lenght = len(myfile['data'])
# get first and last dates of data
fdate = datetime.datetime.strptime(str(myfile['data'][0]),'%Y%m%d%H')
edate = datetime.datetime.strptime(str(myfile['data'][lenght-1]),'%Y%m%d%H')
frstdate = fdate.strftime('%H:%M, %d %B %Y')
enddate = edate.strftime('%d %B %Y')

# start loop by lat/lon for calculating density
#frequency = np.zeros((181,28))
#ii = np.arange(-180,182,2)
#jj = np.arange(-34,-90,-2)
print 'Now insert the divider for 3-hourly original time step'
nt = int(raw_input())

outf = []
out = open((outfile),'w')
for ind, group in myfile.groupby(['id']):
    ind = group.id.values
    data = group.data.values
    lats = group.lat.values
    lons = group.lon.values
    diam = group.diam.values
    lons1 = np.ndarray(len(lons))
    lons2 = np.ndarray(len(lons))
    x = np.zeros((len(lats)*nt))
    y = np.zeros((len(lons)*nt))
    d = np.zeros((len(lons)*nt))
    for k in range(len(lats)-1):
        for l in range(nt):
            if (lons[k+1] - lons[k]) > 200.:
                lons1[k] = lons[k]+360.
                y[l] = lons[k] + ((lons[k+1] - lons1[k])/nt)*float(l)
            elif (lons[k+1] - lons[k]) < -200.:
                lons2[k] = lons[k+1]+360.
                y[l] = lons[k] + ((lons2[k] - lons[k])/nt)*float(l)
            else:
                y[l] = lons[k] + ((lons[k+1] - lons[k])/nt)*float(l)
            if y[l] >= 360.:
                y[l] = y[l]-360.
            x[l] = lats[k] + ((lats[k+1] - lats[k])/nt)*float(l)
            d[l] = diam[k] + ((diam[k+1] - diam[k])/nt)*float(l)
            out.write(str(ind[0])+'\t'+str(data[k])+'\t'+\
            '{0:.2f}\t{1:.2f}\t{2:.2f}\n'.format(float(y[l]),float(x[l]),float(d[l])))
out.close()