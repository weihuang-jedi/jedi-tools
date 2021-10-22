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
  var = nc.variables['T'][0,63,:,:]
  nc.close()

 #var = 0.01*var

 #print('var = ', var)
 #print('var.ndim = ', var.ndim)
 #print('var.shape = ', var.shape)

#------------------------------------------------------------------------------
  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
  clevs = np.arange(220.0, 311.0, 1.0)
  cblevs = np.arange(220.0, 320.0, 10.0)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)
 #gp.set_cmapname(cmapname='rainbow')

#------------------------------------------------------------------------------
  gp.set_label('Temperature at Level 63')

  imgname = 't_level_63'
  title = 'Temperature at Level 63'

  gp.set_imagename(imgname)
  gp.set_title(title)
  gp.plot(var)

#------------------------------------------------------------------------------
  filename = '/work/noaa/gsienkf/weihuang/jedi/vis_tools/weiinterp/weights.nc'

  nc = Dataset(filename)
 #lon = nc.variables['lon'][:]
 #lat = nc.variables['lat'][:]
  var = nc.variables['pos'][:,:]
  nc.close()

#------------------------------------------------------------------------------
  cblevs = np.arange(1.0, 8.0, 1.0)
  clevs = np.arange(1.0, 8.0, 1.0)
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

