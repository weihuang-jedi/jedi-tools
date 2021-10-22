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

#------------------------------------------------------------------------------
  griddir = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/'

  datadir = '/work/noaa/gsienkf/weihuang/jedi/vis_tools/weiinterp/'

  datafiles = []
  gridspecfiles = []
  for ntile in range(1,7,1):
    gridfile = '%sC96_grid.tile%s.nc' %(griddir, ntile)
    gridspecfiles.append(gridfile)

    datafile = '%sgrid.tile%s.nc' %(datadir, ntile)
    datafiles.append(datafile)

  rg = regridder(debug=debug, datafiles=datafiles, gridspecfiles=gridspecfiles)

  nlon = 360
  nlat = nlon/2 + 1
  varname = 'tilenumb'
  var = rg.get_latlon_tile(varname, nlon=nlon, nlat=nlat, method='linear')

  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

  print('var.ndim = ', var.ndim)
  print('var.shape = ', var.shape)

#------------------------------------------------------------------------------
  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
  clevs = np.arange(1.0, 8, 1.0)
  cblevs = np.arange(1.0, 8.0, 1.0)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)
  gp.set_cmapname(cmapname='rainbow')

#------------------------------------------------------------------------------
  gp.set_label('Tile Number')

  imgname = 'tile_number'
  title = 'Tile Number'

  gp.set_imagename(imgname)
  gp.set_title(title)
  gp.plot(var)

