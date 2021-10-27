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

from genplot import GeneratePlot as genplot
#from readGSIobs import ReadGSIobs

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
  addobs = 0
  filename = 'output/iced.2016-01-10-43200_360x181.nc'

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
  pim = PlotIceModel(debug=debug, output=output, filename=filename)

 #varname = 'vsnon'
  varname = 'vicen'
  lat, lon, var = pim.get_var(varname)

 #print('lon = ', lon)
 #print('lat = ', lat)
 #print('var = ', var)

#------------------------------------------------------------------------------
  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
 #if(addobs):
 #  filename = 'jeff-runs/PSonly/diag_conv_ps_ges.2021010900_ensmean.nc4'
 #  rgo = ReadGSIobs(debug=debug, filename=filename)
 #  obslat, obslon = rgo.get_latlon()

 #  gp.set_obs_latlon(obslat=obslat, obslon=obslon)

#------------------------------------------------------------------------------
  gp.set_label(varname)

  imageprefix = 'ice_%s' %(varname)
  titleprefix = 'Ice %s at' %(varname)

#------------------------------------------------------------------------------
 #clevs = np.arange(-2.0, 32.1, 0.5)
 #cblevs = np.arange(-2.0, 34.0, 2.0)
  clevs = np.arange(0.0, 0.0071, 0.0001)
  cblevs = np.arange(0.0, 0.008, 0.001)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)
  gp.set_precision(precision=3)
  gp.set_cmapname('rainbow')

  ncat, nlat, nlon = var.shape

  print('var.shape = ', var.shape)

  for lev in range(ncat):
    pvar = var[lev,:,:]
    imgname = '%s_lev_%d.png' %(imageprefix, lev)
    title = '%s level %d' %(titleprefix, lev)
    gp.set_imagename(imgname)
    gp.set_title(title)
    gp.simple_plot(pvar)
   #gp.plot(pvar)

  sys.exit(-1)

#------------------------------------------------------------------------------
  clevs = np.arange(-0.5, 0.51, 0.01)
  cblevs = np.arange(-0.5, 0.6, 0.1)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)

 #lons = [40, 105, 170, 270, 300]
  lons = [60]

  for lon in lons:
    pvar = var[:,:,lon]
    title = '%s longitude %d' %(titleprefix, lon)
    gp.set_title(title)

    imgname = '%s_lon_%d_level.png' %(imageprefix, lon)
    gp.set_imagename(imgname)
    gp.plot_meridional_section(pvar)

#------------------------------------------------------------------------------
 #lats = [-30, 0, 45, 70]
  lats = [50, 55]

  for lat in lats:
    pvar = var[:,90+lat,:]
    gp.set_title(title)
    title = '%s latitude %d' %(titleprefix, lat)

    imgname = '%s_lat_%d_level.png' %(imageprefix, lat)
    gp.set_imagename(imgname)
    gp.plot_zonal_section(pvar)

