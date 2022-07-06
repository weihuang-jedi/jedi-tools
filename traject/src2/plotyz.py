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

 #filename = 'trajectory.nc'
  filename = 'trajectory_3000m.nc'

  ncfile = netCDF4.Dataset(filename, 'r')
  lon = ncfile.variables['x'][:,:,:]
  lat = ncfile.variables['y'][:,:,:]
  hgt = ncfile.variables['z'][:,:,:]
  ncfile.close()

  nt, nlat, nlon = lon.shape

  print('nt = ', nt)
  print('nlat = ', nlat)
  print('nlon = ', nlon)

  for i in range(0, nlon, 30):
    fig = plt.figure()
    ax = plt.axes()

    for j in range(nlat):
      x = lat[:, j, i]
      z = hgt[:, j, i]
     #ax.plot(x, z)
      ax.plot(x, z, '-o', markersize=2, markevery=x.size)

    plt.axis('tight')
    plt.legend()
    plt.show()

