import getopt
import os, sys
import time
import datetime

import numpy as np
import matplotlib.pyplot as plt

from mpl_toolkits.basemap import Basemap
from itertools import chain
from netCDF4 import Dataset

#from netCDF4 import date2index
#from datetime import datetime

def draw_map(m, scale=0.2):
    # draw a shaded-relief image
    m.shadedrelief(scale=scale)
    
    # lats and longs are returned as a dictionary
    lats = m.drawparallels(np.linspace(-90, 90, 13))
    lons = m.drawmeridians(np.linspace(-180, 180, 13))

    # keys contain the plt.Line2D instances
    lat_lines = chain(*(tup[1][0] for tup in lats.items()))
    lon_lines = chain(*(tup[1][0] for tup in lons.items()))
    all_lines = chain(lat_lines, lon_lines)
    
    # cycle through these lines and set the desired style
    for line in all_lines:
        line.set(linestyle='-', alpha=0.3, color='w')

#fig = plt.figure(figsize=(8, 6), edgecolor='w')
#m = Basemap(projection='cyl', resolution=None,
#            llcrnrlat=-90, urcrnrlat=90,
#            llcrnrlon=-180, urcrnrlon=180, )
#draw_map(m)
#plt.show()

datadir = '/work/noaa/gsienkf/weihuang/jedi/run/intelcase/observations'
datafile = datadir + '/hofx_scatwind_obs_2019120300_0000.nc4'

data = Dataset(datafile)

lat = data.variables['latitude@MetaData'][:]
lon = data.variables['longitude@MetaData'][:]
#lon, lat = np.meshgrid(lon, lat)

u = data.variables['eastward_wind@ObsValue'][:]
v = data.variables['northward_wind@ObsValue'][:]

# 1. Draw the map background
fig = plt.figure(figsize=(15, 6))
#res = 'h'
res = 'l'
m = Basemap(projection='cyl', resolution=res,
            llcrnrlat=-90, urcrnrlat=90,
            llcrnrlon=-180, urcrnrlon=180)

m.fillcontinents(color="#FFDDCC", lake_color='#DDEEFF')
m.drawmapboundary(fill_color="#DDEEFF")
m.drawcoastlines()

#draw_map(m)

# 2. scatter city data, with color reflecting population
# and size reflecting area
m.scatter(lon, lat, latlon=True,
          c=np.sign(u), s=abs(u),
          cmap='bwr', alpha=0.5)

# 3. create colorbar and legend
plt.colorbar(label='u')
plt.clim(-2.5, 2.5)

# make legend with dummy points
#for a in [100, 300, 500]:
#    plt.scatter([], [], c='k', alpha=0.5, s=a,
#                label=str(a) + ' km$^2$')
#plt.legend(scatterpoints=1, frameon=False,
#           labelspacing=1, loc='lower left');

plt.show()

