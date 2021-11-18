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

    self.open()

  def open(self):
    self.ncfile = netCDF4.Dataset(self.filename, 'r')
    self.lon = self.ncfile.variables['lon'][:]
    self.lat = self.ncfile.variables['lat'][:]
    self.alt = self.ncfile.variables['alt'][:]

  def get_latlon(self):
    return self.lon, self.lat, self.alt

  def get_var(self, varname, ndim=3):
    if(ndim == 3):
      var = self.ncfile.variables[varname][:, :, :]
    else:
      var = self.ncfile.variables[varname][:, :]

    if(self.debug):
      msg = ('analy range for variable %s: (%s, %s).' % (varname, var.min(), var.max()))
      print(msg)

    return var

  def close(self):
    self.ncfile.close()

  def get_q(self, RH, T, p):
    es = 611.2*np.exp(17.67*(T-273.15)/(T-29.65))
    rvs = 0.622*es/(p - es)
    rv = RH/100. * rvs
    qv = rv/(1 + rv)
    return qv

  def get_pdfq(self, temp, qv, p):
   #r = 286.9
   #rho = p/(r*temp)
   #rho_ref = rho * (1 + 1.609 * qv) / (1 + qv)
    pq = 0.609 * p * qv / (1.0 + qv)

    return pq

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
 #filename = 'output/gfs_4_20211016_1200_000.nc'
  filename = 'verticalheight.nc'

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

  lon, lat, alt = pom.get_latlon()

 #print('lon = ', lon)
 #print('lat = ', lat)
 #print('alt = ', alt)

  u3d = pom.get_var('U')
  v3d = pom.get_var('V')
  p3d = pom.get_var('P')
  t3d = pom.get_var('T')
  rh3d = pom.get_var('RH')
  qv3d = pom.get_q(rh3d, t3d, p3d)
  pq3d = pom.get_pdfq(t3d, qv3d, p3d)

  rho3d = 1000.0*(p3d/(287.0*t3d))

 #print('u3d = ', u3d)
 #print('v3d = ', v3d)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  pt.set_label('Vector')

  imageprefix = 'gfs_vector'
  titleprefix = 'GFS vector at'

#------------------------------------------------------------------------------
  pt.set_cmapname('rainbow')

  nalt, nlat, nlon = t3d.shape

  print('v3d.shape = ', v3d.shape)

  alts = [0, 2, 6, 10, 50]
  for n in alts:
    u = u3d[n,:,:]
    v = v3d[n,:,:]
    t = t3d[n,:,:]
    p = p3d[n,:,:]
    qv = qv3d[n,:,:]
    pq = pq3d[n,:,:]
    rho = rho3d[n,:,:]
    imgname = '%s_%dm.png' %(imageprefix, int(alt[n]))
    title = '%s %dm' %(titleprefix, int(alt[n]))
    pt.set_imagename(imgname)
    pt.set_title(title)

   #pt.simple_plot(t)
   #pt.simple_plot(p)
   #pt.simple_plot(qv)
   #pt.simple_plot(pq)
   #pt.simple_plot(rho)
   #pt.simple_contour_quiver(u, v, rho, intv=10)
   #pt.plot4hemisphere(rho, hemisphere='N', projection='npstere')
   #pt.simple_panel2hemispheres(rho)
   #pt.simple_panel2hemispheres(t)
    pt.simple_panel2hemispheres_streamline_over_contour(u, v, rho)

   #pt.simple_vector(u, v, intv=10)
   #pt.simple_stream(u, v)
   #pt.simple_barbs(u, v, intv=10)

