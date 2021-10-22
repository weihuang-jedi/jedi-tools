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

from genplot import GeneratePlot as genplot
from scipy_regridder import RegridFV3 as regridder
from readIODA2Obs import ReadIODA2Obs

#------------------------------------------------------------------------------
if __name__ == '__main__':
 #filename = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/ioda_v2_data/out/ncdiag.oper.ob.PT6H.sondes.2021-01-08T21:00:00Z_0000.nc4'
  filename = '/work/noaa/gsienkf/weihuang/jedi/surface/ioda_v2_data/out/ncdiag.oper.ob.PT6H.sfc.2021-01-08T21:00:00Z_0000.nc4'
  debug = 1
  output = 0

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
  nlon = 360
  nlat = nlon/2 + 1
  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
  clevs = np.arange(-20.0, 20.5, 0.5)
  cblevs = np.arange(-20.0, 22.0, 2.0)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)

#------------------------------------------------------------------------------
  rio = ReadIODA2Obs(debug=debug, filename=filename)

  nprocs = 36
  full_lat = []
  full_lon = []
  full_var = []

  for n in range(nprocs):
    flstr = '%04d' %(n)
    flnm = filename.replace('0000', flstr)
    rio.set_filename(filename=flnm)
    lat, lon, var = rio.get_latlon4var(varname='/ombg/surface_pressure')
    full_lat.extend(lat)
    full_lon.extend(lon)
    var = 0.01*var #convert to hPa.
    full_var.extend(var)
    print('len(var) = ', len(var))
    print('len(full_var) = ', len(full_var))

 #print('lat = ', lat)
 #print('lon = ', lon)
  print('len(full_lat) = ', len(full_lat))
  print('len(full_var) = ', len(full_var))
  print('var min: %f, var max: %f' %(np.min(full_var), np.max(full_var)))

#------------------------------------------------------------------------------
  gp.set_label('Surface Pressure (hPa)')

  imgname = 'sondes_obs_ps_only'
  title = 'Sondes Surface Pressure OBS (only)'

  gp.set_imagename(imgname)
  gp.set_title(title)
  gp.obsonly(full_lat, full_lon, full_var)

