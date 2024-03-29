#=========================================================================
import os
import sys
import types
import getopt
import netCDF4

import numpy as np
import matplotlib
import matplotlib.pyplot

from matplotlib import cm
from mpl_toolkits.basemap import Basemap

#from genplot import GeneratePlot as genplot
sys.path.append('../plot-utils')
from plottools import PlotTools
from scipy_regridder import RegridFV3 as regridder

from os import environ
import logging

if 'LOGNAME' in environ:
    username = environ.get('LOGNAME')
else:
    username = 'Unknown'

print('username: ', username)

extData = {'user': username}

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  datadir = '/work/noaa/gsienkf/weihuang/jedi/vis_tools/visfv3'
  filename = '%s/jeff-runs/PSonly/diag_conv_ps_ges.2021010900_ensmean.nc4' %(datadir)

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
  fmtStr = "%(asctime)s: User:%(user)s\n\t%(levelname)s: %(funcName)s Line:%(lineno)d\n\t%(message)s"
  dateStr = "%m/%d/%Y %I:%M:%S %p"
 #logging.basicConfig(filename="log.info",
 #                    level=logging.DEBUG,
 #                    format=fmtStr, datefmt=dateStr)

 #logging.info('Using filename: ' + filename, extra=extData)
 #logging.warning('Output = ' + str(output), extra=extData)

#------------------------------------------------------------------------------
  nlon = 360
  nlat = nlon/2 + 1
  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

 #gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
  gp = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  clevs = np.arange(-10.0, 10.2, 0.2)
  cblevs = np.arange(-10.0, 15.0, 5.0)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)
  gp.set_cmapname('rainbow')

#------------------------------------------------------------------------------
  ncfile = netCDF4.Dataset(filename, 'r')

  obslat = ncfile.variables['Latitude'][:]
  obslon = ncfile.variables['Longitude'][:]

  var = ncfile.variables['Obs_Minus_Forecast_adjusted'][:]
 #var = ncfile.variables['Obs_Minus_Forecast_unadjusted'][:]

  ncfile.close()

#------------------------------------------------------------------------------
  gp.set_label('Surface Pressure (hPa) --OMB')

  imgname = 'gsi_sondes_obs_ps_only_OMB'
  title = 'GSI Sondes Surface Pressure OBS (only) --OMB'

 #logging.info('image name: ' + imgname, extra=extData)

  gp.set_imagename(imgname)
  gp.set_title(title)
  gp.obsonly2(obslat, obslon, var, inbound=True)

