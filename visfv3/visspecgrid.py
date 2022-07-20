#=========================================================================
import os
import sys
import types
import getopt

import numpy as np
import matplotlib
import matplotlib.pyplot

from netCDF4 import Dataset
from matplotlib import cm
from mpl_toolkits.basemap import Basemap

from genplot import GeneratePlot as genplot

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)

#------------------------------------------------------------------------------
  filename = '/work/noaa/gsienkf/weihuang/jedi/vis_tools/weiinterp/latlon_grid.nc'

  nc = Dataset(filename)
  lon = nc.variables['lon'][:]
  lat = nc.variables['lat'][:]
  var = nc.variables['pos'][:,:]

  print('var.ndim = ', var.ndim)
  print('var.shape = ', var.shape)

  nlat, nlon = var.shape

  print('nlon = ', nlon)
 #print('lon = ', lon)
  print('nlat = ', nlat)
 #print('lat = ', lat)

#------------------------------------------------------------------------------
  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
  clevs = np.arange(1.0, 7, 1.0)
  cblevs = np.arange(1.0, 7.0, 1.0)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)
  gp.set_cmapname(cmapname='rainbow')

#------------------------------------------------------------------------------
  gp.set_label('Position in Tile')

  imgname = 'pos_in_tile'
  title = 'Position in Tile'

  gp.set_imagename(imgname)
  gp.set_title(title)
  gp.plot(var)

