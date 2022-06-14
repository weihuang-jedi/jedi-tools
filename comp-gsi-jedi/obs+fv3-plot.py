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

from readIODA2Obs import ReadIODA2Obs

sys.path.append('plot-utils')
from plottools import PlotTools

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  addobs = 1
  uselogp = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=',
                             'addobs=', 'uselogp='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--addobs'):
      addobs = int(a)
    elif o in ('--uselogp'):
      uselogp = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('addobs = ', addobs)

#------------------------------------------------------------------------------
  casedir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/surf/run_80.40t1n_30p'
  filename = '%s/analysis/increment/xainc.20200110_030000z.nc4' %(casedir)

  nc = Dataset(filename)
  lon = nc.variables['lon'][:]
  lat = nc.variables['lat'][:]
  var = nc.variables['t'][0,:,:,:]

  nx, = lon.shape
  ny, = lat.shape

  print('nx=', nx)
  print('lon = ', lon)
  print('ny=', ny)
  print('lat = ', lat)

  print('var.shape = ', var.shape)
  print('var.ndim = ', var.ndim)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  if(addobs):
    filename = '%s/ioda_v2_data/sfc_ps_obs_2020011006.nc4' %(casedir)
 
    rio = ReadIODA2Obs(debug=debug, filename=filename)
    olat, olon = rio.get_latlon()

    for n in range(len(olon)):
      if(olon[n] < 0.0):
        olon[n] += 360.0

   #print('olat = ', olat)
   #print('olon = ', olon)

    pt.set_obs_latlon(obslat=olat, obslon=olon)

#------------------------------------------------------------------------------
  pt.set_label('Temperature (K)')

  image_prefix = 'surf_temperature'
  title_preix = 'surf Temperature at'

#------------------------------------------------------------------------------
 #clevs = np.arange(-2.0, 2.05, 0.05)
 #cblevs = np.arange(-2.0, 2.5, 0.5)
  clevs = np.arange(-0.5, 0.52, 0.02)
  cblevs = np.arange(-0.5, 0.6, 0.1)
 #clevs = np.arange(-0.2, 0.21, 0.01)
 #cblevs = np.arange(-0.2, 0.3, 0.1)
 #clevs = np.arange(-0.1, 0.102, 0.002)
 #cblevs = np.arange(-0.1, 0.11, 0.01)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)
  pt.set_precision(precision=1)

 #------------------------------------------------------------------------------
  levs = [0, 1, 40, 50, 62, 63]
 #levs = [61, 62, 63]
  for lev in levs:
    pvar = var[lev,:,:]
    imgname = '%s_lev_%d.png' %(image_prefix, lev)
    title = '%s level %d' %(title_preix, lev)
    pt.set_imagename(imgname)
    pt.set_title(title)
    if(addobs):
     #pt.plot(pvar, addmark=1, marker='x', size=3, color='green')
     #pt.plot(pvar, addmark=1, marker='x', size=1, color='green')
      pt.plot(pvar, addmark=1, marker='+', size=20, color='red')
    else:
      pt.plot(pvar)

 #------------------------------------------------------------------------------
 #clevs = np.arange(-0.5, 0.51, 0.01)
 #cblevs = np.arange(-0.5, 0.6, 0.1)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)

 #lons = [60, 200]
  lons = [35, 75, 160, 205, 210]
 #lons = [170]
  for lon in lons:
    pvar = var[:,:,lon]
    title = '%s longitude %d' %(title_preix, lon)
    pt.set_title(title)

    imgname = '%s_lon_%d_logp.png' %(image_prefix, lon)
    pt.set_imagename(imgname)
    pt.plot_meridional_section_logp(pvar)

    imgname = '%s_lon_%d_level.png' %(image_prefix, lon)
    pt.set_imagename(imgname)
    pt.plot_meridional_section(pvar)

 #------------------------------------------------------------------------------
 #lats = [50, 55]
  lats = [-49, -31, -27, 12, 40]
 #lats = [-41, -23, 0, 22, 41]
  for lat in lats:
    pvar = var[:,90+lat,:]
    title = '%s latitude %d' %(title_preix, lat)
    pt.set_title(title)

    imgname = '%s_lat_%d_logp.png' %(image_prefix, lat)
    pt.set_imagename(imgname)
    pt.plot_zonal_section_logp(pvar)

    imgname = '%s_lat_%d_level.png' %(image_prefix, lat)
    pt.set_imagename(imgname)
    pt.plot_zonal_section(pvar)

