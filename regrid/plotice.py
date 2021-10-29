#=========================================================================
import os
import sys
import types
import getopt
import netCDF4
import matplotlib

import numpy as np
import matplotlib.pyplot

from matplotlib import cm
from mpl_toolkits.basemap import Basemap

sys.path.append('../plot-utils')
from plottools import PlotTools

#=========================================================================
class PlotIceModel():
  def __init__(self, debug=0, output=0, filename=None):
    self.debug = debug
    self.output = output
    self.filename = filename

    if(self.debug):
      print('self.filename = ', self.filename)

  def get_var(self, varname, ndim=3):
    ncfile = netCDF4.Dataset(self.filename, 'r')
    lat = ncfile.variables['lat'][:]
    lon = ncfile.variables['lon'][:]
    if(ndim == 3):
      var = ncfile.variables[varname][:, :, :]
    else:
      var = ncfile.variables[varname][:, :]
    ncfile.close()

    if(self.debug):
      msg = ('analy range for variable %s: (%s, %s).' % (varname, var.min(), var.max()))
      print(msg)

    return lat, lon, var

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  filename = 'output/iced.2016-01-10-43200_360x181.nc'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'filename='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--filename'):
      filename = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('filename = ', filename)

#------------------------------------------------------------------------------
  pim = PlotIceModel(debug=debug, output=output, filename=filename)

 #varname = 'vsnon'
  varname = 'vicen'
  lat, lon, var = pim.get_var(varname)

 #print('lon = ', lon)
 #print('lat = ', lat)
 #print('var = ', var)

  ncat, nlat, nlon = var.shape
  print('var.shape = ', var.shape)

  imageprefix = 'ice_%s' %(varname)
  titleprefix = 'Ice %s at' %(varname)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)

  pt.set_label(varname)
 #clevs = np.arange(-2.0, 32.1, 0.5)
 #cblevs = np.arange(-2.0, 34.0, 2.0)
 #clevs = np.arange(0.0, 0.0071, 0.0001)
 #cblevs = np.arange(0.0, 0.008, 0.001)
  clevs = np.arange(0.0, 0.101, 0.001)
  cblevs = np.arange(0.0, 0.11, 0.01)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)
  pt.set_precision(precision=2)
  pt.set_cmapname('rainbow')

#------------------------------------------------------------------------------
  for lev in range(ncat):
    pvar = var[lev,:,:]
    imgname = '%s_lev_%d.png' %(imageprefix, lev)
    title = '%s level %d' %(titleprefix, lev)
    pt.set_imagename(imgname)
    pt.set_title(title)
   #pt.plot(pvar)
   #pt.simple_plot(pvar)
   #pt.plot4hemisphere(pvar, hemisphere='N')
   #pt.plot4hemisphere(pvar, hemisphere='S')
    pt.panel2hemispheres(pvar)

  sys.exit(-1)

#------------------------------------------------------------------------------
  clevs = np.arange(-0.5, 0.51, 0.01)
  cblevs = np.arange(-0.5, 0.6, 0.1)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)

 #lons = [40, 105, 170, 270, 300]
  lons = [60]

  for lon in lons:
    pvar = var[:,:,lon]
    title = '%s longitude %d' %(titleprefix, lon)
    pt.set_title(title)

    imgname = '%s_lon_%d_level.png' %(imageprefix, lon)
    pt.set_imagename(imgname)
    pt.plot_meridional_section(pvar)

#------------------------------------------------------------------------------
 #lats = [-30, 0, 45, 70]
  lats = [50, 55]

  for lat in lats:
    pvar = var[:,90+lat,:]
    pt.set_title(title)
    title = '%s latitude %d' %(titleprefix, lat)

    imgname = '%s_lat_%d_level.png' %(imageprefix, lat)
    pt.set_imagename(imgname)
    pt.plot_zonal_section(pvar)

