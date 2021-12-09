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

from scipy_regridder import RegridFV3 as regridder
from readIODA2Obs import ReadIODA2Obs

sys.path.append('../plot-utils')
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
 #griddir = '/work/noaa/gsienkf/weihuang/UFS-RNR-tools/JEDI.FV3-increments/grid/C96'
  griddir = '/work/noaa/gsienkf/weihuang/UFS-RNR-tools/JEDI.FV3-increments/grid/C48'

  casedir = '/work/noaa/gsienkf/weihuang/jedi/case_study/amsua'
 #datadir = '%s/huge_incr_analysis/increment/' %(casedir)
  datadir = '%s/analysis/increment/' %(casedir)

  datafiles = []
  gridspecfiles = []
  for ntile in range(1,7,1):
    gridfile = '%s/C48_grid.tile%s.nc' %(griddir, ntile)
    gridspecfiles.append(gridfile)

    datafile = '%s/20210109.000000.fv_core.res.tile%s.nc' %(datadir, ntile)
    datafiles.append(datafile)

#------------------------------------------------------------------------------
  if(addobs):
    filename = '%s/ioda_v2_data/obs/amsua_n15_obs_2021010900.nc4' %(casedir)

    print('obs filename: ', filename)

    rio = ReadIODA2Obs(debug=debug, filename=filename)
    obslat, obslon = rio.get_latlon()

   #print('obslat = ', obslat)
   #print('obslon = ', obslon)

    print('len(obslat) = ', len(obslat))
    print('len(obslon) = ', len(obslon))

   #sys.exit(-1)

#------------------------------------------------------------------------------
  rg = regridder(debug=debug, datafiles=datafiles, gridspecfiles=gridspecfiles)

  nlon = 360
  nlat = nlon/2 + 1
  varname = 't'
  var = rg.get_latlon_data(varname, nlon=nlon, nlat=nlat, method='linear')

  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0+0.5*dlon, 360.0+0.5*dlon, dlon)
  lat = np.arange(-90.0+0.5*dlat, 90.0+0.5*dlat, dlat)

 #print('var.ndim = ', var.ndim)
 #print('var.shape = ', var.shape)

  if(debug):
    msg = ('variable min, max: (%s, %s).' % (var.min(), var.max()))
    print(msg)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  if(addobs):
    pt.set_obs_latlon(obslat=obslat, obslon=obslon)

#------------------------------------------------------------------------------
  pt.set_label('Temperature (K)')

  image_prefix = 'amsua_JEDI_temperature'
  title_preix = 'amsua JEDI Temperature at'

#------------------------------------------------------------------------------
 #clevs = np.arange(-0.5, 0.51, 0.01)
 #cblevs = np.arange(-0.5, 0.6, 0.1)
 #clevs = np.arange(-5.0, 5.1, 0.1)
 #cblevs = np.arange(-5.0, 6.0, 1.0)
 #clevs = np.arange(-1.0, 1.01, 0.01)
 #cblevs = np.arange(-1.0, 1.2, 0.2)
  clevs = np.arange(-0.2, 0.21, 0.01)
  cblevs = np.arange(-0.2, 0.3, 0.1)
  clevs = 500.0*clevs
  cblevs = 500.0*cblevs
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)
 #pt.set_precision(precision=2)
  pt.set_precision(precision=0)

 #------------------------------------------------------------------------------
  levs = [30, 33, 40, 60, 63]
  for lev in levs:
    pvar = var[lev,:,:]
    if(debug):
      msg = ('variable at level %d, min, max: (%s, %s).' % (lev, pvar.min(), pvar.max()))
      print(msg)
    imgname = '%s_lev_%d.png' %(image_prefix, lev)
    title = '%s level %d' %(title_preix, lev)
    pt.set_imagename(imgname)
    pt.set_title(title)
    if(addobs):
     #pt.plot(pvar, addmark=1, marker='x', size=3, color='green')
      pt.plot(pvar, addmark=1, marker='x', size=1, color='green')
    else:
      pt.plot(pvar)

 #------------------------------------------------------------------------------
  lons = [60, 105, 170, 270, 300]
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
  lats = [-50, 0, 45, 70]
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

