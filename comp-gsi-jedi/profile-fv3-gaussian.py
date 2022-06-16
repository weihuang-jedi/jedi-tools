#=========================================================================
import os
import sys
import types
import getopt
import netCDF4
import matplotlib

import numpy as np
import matplotlib.pyplot as plt

from matplotlib import cm
from mpl_toolkits.basemap import Basemap

from scipy_regridder import RegridFV3 as regridder

#=========================================================================
class ReadFile():
  def __init__(self, debug=0, filename='unknown'):
    self.debug = debug
    self.filename = filename

    if(self.debug):
      print('debug = ', debug)
      print('filename = ', filename)

  def set_filename(self, filename='unknown'):
    self.filename = filename

    if(self.debug):
      print('debug = ', debug)
      print('filename = ', filename)

  def get_var(self, varname):
    print('varname =', varname)

    ncfile = netCDF4.Dataset(self.filename, 'r')
    lat = ncfile.variables['lat'][:, :]
    lon = ncfile.variables['lon'][:, :]
    var = ncfile.variables[varname][:, :, :, :]
    ncfile.close()

    return lon, lat, var

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

#=======================================================================================================================
  gsi_data_dir = '/work2/noaa/gsienkf/weihuang/C96_psonly_delp/2020011006'
  gsi_bkg_name = '%s/sfg_2020011006_fhr06_ensmean' %(gsi_data_dir)
  gsi_anl_name = '%s/sanl_2020011006_fhr06_ensmean' %(gsi_data_dir)

  jedi_data_dir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/surf/run_80.40t1n_24p'
  jedi_filename = '%s/analysis/increment/xainc.20200110_030000z.nc4' %(jedi_data_dir)

#=======================================================================================================================
  reader = ReadFile(debug=debug, filename=gsi_bkg_name)
  lon, lat, bkg = reader.get_var('tmp')

  reader.set_filename(filename=gsi_anl_name)
  lon, lat, anl = reader.get_var('tmp')

  gsi_incr = anl - bkg

  print('anl.shape = ', anl.shape)
  ntime, nlev, nlat, nlon = anl.shape

  ncf = netCDF4.Dataset(jedi_filename)
  jlat = ncf.variables['lat'][:]
  jlon = ncf.variables['lon'][:]
  jedi_incr = ncf.variables['t'][:, :, :, :]
  ncf.close()

  print('jedi_incr.shape = ', jedi_incr.shape)

  lon1d = lon.flatten()
  lat1d = lat.flatten()
 #gsi1d = gsi_incr.flatten()
 #jedi1d = jedi_incr.flatten()

#=======================================================================================================================
 #rg = regridder(debug=debug, datafiles=[], gridspecfiles=[])
 #gsi_var = rg.interp2latlon_data(lon1d, lat1d, gsi_incr, nlon=nlon, nlat=nlat, method='linear')
 #jedi_var = rg.interp2latlon_data(lon1d, lat1d, jedi_incr, nlon=nlon, nlat=nlat, method='linear')

 #print('gsi_var.ndim = ', gsi_var.ndim)
 #print('gsi_var.shape = ', gsi_var.shape)

#=======================================================================================================================
  var = jedi_var - gsi_var

  print('var.shape = ', var.shape)
  nt, nz, ny, nx = var.shape

#=======================================================================================================================
  gsi_sqrt = np.zeros((nz))
  jedi_sqrt = np.zeros((nz))
  gsi_jedi_sqrt = np.zeros((nz))

  for lvl in range(nz):
    gsi_sqrt[lvl] = np.sqrt(np.mean(gsi_var[0,lvl,:,:]*gsi_var[0,lvl,:,:]))
    jedi_sqrt[lvl] = np.sqrt(np.mean(jedi_var[0,lvl,:,:]*jedi_var[0,lvl,:,:]))
    gsi_jedi_sqrt[lvl] = np.sqrt(np.mean(var[0,lvl,:,:]*var[0,lvl,:,:]))

  print('gsi_sqrt.shape = ', gsi_sqrt.shape)

  print('nz = ', nz)
  print('ny = ', ny)
  print('nx = ', nx)

  print('gsi_sqrt = ', gsi_sqrt)
  print('jedi_sqrt = ', jedi_sqrt)
  print('gsi_jedi_sqrt = ', gsi_jedi_sqrt)

  y = np.arange(0.0, float(nz), 1.0)

  plt.figure(num = 3, figsize=(8, 5))  
  plt.plot(gsi_sqrt, y,
           color='blue',  
           linewidth=1.0,  
           linestyle='--')

  plt.plot(jedi_sqrt, y, 
           color='cyan',  
           linewidth=1.0,  
           linestyle='dotted')

  plt.plot(gsi_jedi_sqrt, y, 
           color='red',  
           linewidth=2.0)

  ax = plt.gca()

  ax.xaxis.set_ticks_position('bottom')
  ax.yaxis.set_ticks_position('left')

  plt.show()

  with open('profile_data.txt', 'w') as f:
    f.write('%d, %d, %d\n' %(nz, ny, nx))
    for i in range(nz):
        f.write("%f, %f, %f\n" % (gsi_sqrt[i], jedi_sqrt[i], gsi_jedi_sqrt[i]))

