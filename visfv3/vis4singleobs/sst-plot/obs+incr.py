#=========================================================================
import os
import sys
import types
import getopt

import numpy as np
import matplotlib
import matplotlib.pyplot

from matplotlib import cm
from mpl_toolkits.basemap import Basemap

from readIODA2Obs import ReadIODA2Obs
from readOceanLatLonData import ReadOceanLatLonData

sys.path.append('plot-utils')
from plottools import PlotTools

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  addobs = 1
  uselogp = 0
  casename = 'sst'

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
  datadir = '/work2/noaa/gsienkf/weihuang/jedi/singleobs/vis/sst-plot'
  datafile = '%s/ocn.LETKF.an.2015-12-01T12:00:00Z_360x180.nc' %(datadir)

  reader = ReadOceanLatLonData(debug=debug, datafile=datafile)
  lat1d, lon1d = reader.get_latlon()

  varname = 'Temp'
  var = reader.read3Dvar(varname)

  print('var.ndim=', var.ndim)
  print('var.shape=', var.shape)
  print('var.size=', var.size)

  var1d = reader.get_level(var, level=1)

#------------------------------------------------------------------------------
  nlon = 360
  nlat = 180
  dlon = 360.0/nlon
  dlat = 180.0/nlat
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0+0.5*dlat, 90.0+0.5*dlat, dlat)

  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  if(addobs):
    datadir = '/work2/noaa/gsienkf/weihuang/jedi/singleobs/sst'
    obsfile = '%s/ioda_v2_data/ioda_v2_sst_avhrrmta_l3u_nesdis.nc' %(datadir)
 
    rio = ReadIODA2Obs(debug=debug, filename=obsfile)
    olat, olon = rio.get_latlon()

    for n in range(len(olon)):
      if(olon[n] < 0.0):
        olon[n] += 360.0

   #print('olat = ', olat)
   #print('olon = ', olon)

    pt.set_obs_latlon(obslat=olat, obslon=olon)

#------------------------------------------------------------------------------
  pt.set_label('Temperature (C)')

  image_prefix = '%s_temperature' %(casename)
  title_preix = '%s Temperature at' %(casename)

#------------------------------------------------------------------------------
 #clevs = np.arange(-2.0, 2.05, 0.05)
 #cblevs = np.arange(-2.0, 2.5, 0.5)
 #clevs = np.arange(-1.0, 1.1, 0.1)
 #cblevs = np.arange(-1.0, 1.2, 0.2)
 #clevs = np.arange(-0.2, 0.21, 0.01)
 #cblevs = np.arange(-0.2, 0.3, 0.1)
 #clevs = np.arange(-0.1, 0.102, 0.002)
 #cblevs = np.arange(-0.1, 0.11, 0.01)
  clevs = np.arange(-0.01, 0.011, 0.001)
  cblevs = np.arange(-0.01, 0.012, 0.002)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)
  pt.set_precision(precision=4)

 #------------------------------------------------------------------------------
 #levs = [0, 1, 2, 5, 10, 20]
  levs = [0]
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
  lons = [35, 75, 160, 205, 209]
  for lon in lons:
    pvar = var[:,:,lon]
    title = '%s longitude %d' %(title_preix, lon)
    pt.set_title(title)

    imgname = '%s_lon_%d_level.png' %(image_prefix, lon)
    pt.set_imagename(imgname)
    pt.plot_meridional_section(pvar)

 #------------------------------------------------------------------------------
 #lats = [50, 55]
  lats = [-50, -32, -28, 12, 40]
  for lat in lats:
    pvar = var[:,90+lat,:]
    title = '%s latitude %d' %(title_preix, lat)
    pt.set_title(title)

    imgname = '%s_lat_%d_level.png' %(image_prefix, lat)
    pt.set_imagename(imgname)
    pt.plot_zonal_section(pvar)

