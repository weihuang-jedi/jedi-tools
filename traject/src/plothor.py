import os
import sys
import getopt
import math
import numpy as np
import netCDF4
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0

  m = Basemap(llcrnrlon=0, llcrnrlat=-90,
              urcrnrlon=360, urcrnrlat=90,
              resolution='c', projection='cyl',
              lat_0 = 0, lon_0 = 180)

  m.drawcoastlines(linewidth=0.72, color='gray')
  m.drawcountries(zorder=0, color='gray')

  filename = 'trajectory.nc'
  ncfile = netCDF4.Dataset(filename, 'r')
  lon = ncfile.variables['x'][:,:,:]
  lat = ncfile.variables['y'][:,:,:]
  hgt = ncfile.variables['z'][:,:,:]
  ncfile.close()

  nt, nlat, nlon = lon.shape

  print('nt = ', nt)
  print('nlat = ', nlat)
  print('nlon = ', nlon)

  latc = int(nlat/2)
  lonc = int(nlon/2)

  x = lon[:, latc, lonc]
  y = lat[:, latc, lonc]

  print('x = ', x)
  print('y = ', y)

  for j in range(0, nlat, 10):
    for i in range(0, nlon, 10):
      x = lon[:, j, i]
      y = lat[:, j, i]
      m.plot(x, y)

  plt.legend()
  plt.show()

