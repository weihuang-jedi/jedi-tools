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
class PlotOceanModel():
  def __init__(self, debug=0, output=0, filename=None):
    self.debug = debug
    self.output = output
    self.filename = filename

    if(self.debug):
      print('self.filename = ', self.filename)

  def get_var(self, varname, ndim=3, time=0):
    ncfile = netCDF4.Dataset(self.filename, 'r')
    lat = ncfile.variables['lat'][:]
    lon = ncfile.variables['lon'][:]
    if(ndim == 3):
      var = ncfile.variables[varname][time, :, :, :]
    else:
      var = ncfile.variables[varname][time, :, :]
    ncfile.close()

    if(self.debug):
      msg = ('analy range for variable %s: (%s, %s).' % (varname, var.min(), var.max()))
      print(msg)

    return lat, lon, var

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  addobs = 0
  filename = 'output/MOM.res.2016-01-11-03-00-00_360x181.nc'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'addobs=', 'filename='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--addobs'):
      addobs = int(a)
    elif o in ('--filename'):
      filename = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('addobs = ', addobs)
  print('filename = ', filename)

#------------------------------------------------------------------------------
  pom = PlotOceanModel(debug=debug, output=output, filename=filename)

  varname = 'Temp'
 #varname = 'Salt'
  lat, lon, var = pom.get_var(varname)

  print('lon = ', lon)
  print('lat = ', lat)
 #print('var = ', var)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
 #if(addobs):
 #  filename = 'jeff-runs/PSonly/diag_conv_ps_ges.2021010900_ensmean.nc4'
 #  rgo = ReadGSIobs(debug=debug, filename=filename)
 #  obslat, obslon = rgo.get_latlon()

 #  pt.set_obs_latlon(obslat=obslat, obslon=obslon)

#------------------------------------------------------------------------------
  pt.set_label('Temperature (K)')

  imageprefix = 'ocean_%s' %(varname)
  titleprefix = 'Ocean %s at' %(varname)

#------------------------------------------------------------------------------
  clevs = np.arange(-2.0, 32.1, 0.5)
  cblevs = np.arange(-2.0, 34.0, 2.0)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)
  pt.set_precision(precision=0)
  pt.set_cmapname('rainbow')

  nlev, nlat, nlon = var.shape

  print('var.shape = ', var.shape)

  for lev in range(nlev):
    pvar = var[lev,:,:]
    imgname = '%s_lev_%d.png' %(imageprefix, lev)
    title = '%s level %d' %(titleprefix, lev)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot(pvar)

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

