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

  fig = plt.figure()
  ax = plt.axes()

 #i = int(nlon/2)
  j = int(3*nlat/4)
 #for j in range(nlat):
  for i in range(nlon):
    x = lon[:, j, i]
    z = hgt[:, j, i]
    ax.plot(x, z)

  plt.axis('tight')
  plt.legend()
  plt.show()

