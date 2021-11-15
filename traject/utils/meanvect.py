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

#sys.path.append('../plot-utils')
from plottools import PlotTools

#=========================================================================
class PlotFV3Model():
  def __init__(self, debug=0, output=0, filename=None):
    self.debug = debug
    self.output = output
    self.filename = filename

    if(self.debug):
      print('self.filename = ', self.filename)

  def get_var(self, varname, ndim=3):
    ncfile = netCDF4.Dataset(self.filename, 'r')
    lat = ncfile.variables['lat_0'][:]
    lon = ncfile.variables['lon_0'][:]
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
 #filename = 'output/gfs_4_20211016_1200_000.nc'
  filename = 'output/gfs_4_20210416_1200_000.nc'

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
  pom = PlotFV3Model(debug=debug, output=output, filename=filename)

  lat, lon, u3d = pom.get_var('UGRD_P0_L100_GLL0')
  lat, lon, v3d = pom.get_var('VGRD_P0_L100_GLL0')
  lat, lon, w3d = pom.get_var('VVEL_P0_L100_GLL0')

 #print('lon = ', lon)
 #print('lat = ', lat)
 #print('u3d = ', u3d)
 #print('v3d = ', v3d)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  pt.set_label('Vector')

  imageprefix = 'fv3_vector'
  titleprefix = 'FV3 vector at'

#------------------------------------------------------------------------------
  pt.set_cmapname('rainbow')

  nlev, nlat, nlon = v3d.shape

  print('v3d.shape = ', v3d.shape)

  levs = [40, 39, 38, 5, 4]
  for lev in levs:
    u = u3d[lev,:,:]
    v = v3d[lev,:,:]
    imgname = '%s_lev_%d.png' %(imageprefix, lev)
    title = '%s level %d' %(titleprefix, lev)
    pt.set_imagename(imgname)
    pt.set_title(title)
   #pt.simple_vector(u, v, intv=10)
    pt.simple_stream(u, v)
   #pt.simple_barbs(u, v, intv=10)

#------------------------------------------------------------------------------
  clevs = np.arange(-0.5, 0.51, 0.01)
  cblevs = np.arange(-0.5, 0.6, 0.1)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)

  ver = np.arange(0.0, float(nlev), 1.0)
  ver = -ver[::-1]

  print('u3d.shape = ', u3d.shape)

  vmean = np.mean(v3d[:,:,150*2:210*2], axis=2)
  wmean = np.mean(w3d[:,:,150*2:210*2], axis=2)

  v = vmean[::-1,:]
  w = wmean[::-1,:]

  title = '%s zonal mean between 150-210' %(titleprefix)
  imgname = '%s_zonal_mean_150-210.png' %(imageprefix)

  pt.set_title(title)
  pt.set_imagename(imgname)
 #pt.plot_section_vector(v, w, lat, ver, intv=5)
  pt.plot_section_stream(v, w, lat, ver)

  for i in [180, 240, 300, 360, 540]:
    v = v3d[::-1,:,i]
    w = w3d[::-1,:,i]

    title = '%s at longitude %d' %(titleprefix, i/2)
    imgname = '%s_at_longitude_%d.png' %(imageprefix, i/2)

    pt.set_title(title)
    pt.set_imagename(imgname)
   #pt.plot_section_vector(v, w, lat, ver, intv=5)
    pt.plot_section_stream(v, w, lat, ver)

