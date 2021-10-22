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
  uvOnly = 0
  plotdiff = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'uvOnly=', 'plotdiff='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--uvOnly'):
      uvOnly = int(a)
    elif o in ('--plotdiff'):
      plotdiff = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('plotdiff = ', plotdiff)
  print('uvOnly = ', uvOnly)

 #griddir = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/'
  griddir = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C48/'

  if(uvOnly):
    datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvOnly/increment/'
    if(plotdiff):
      snd_dir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.all/increment/'
  else:
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.all/increment/'
    datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'

  datafiles = []
  snd_files = []
  gridspecfiles = []
  for ntile in range(1,7,1):
    gridfile = '%sC48_grid.tile%s.nc' %(griddir, ntile)
    gridspecfiles.append(gridfile)

    datafile = '%s20210109.000000.fv_core.res.tile%s.nc' %(datadir, ntile)
    datafiles.append(datafile)
    if(plotdiff):
      snd_file = '%s20210109.000000.fv_core.res.tile%s.nc' %(snd_dir, ntile)
      snd_files.append(snd_file)

  rg = regridder(debug=debug, datafiles=datafiles, gridspecfiles=gridspecfiles)
  if(plotdiff):
    rg.setSecondFiles(snd_files)

  nlon = 360
  nlat = nlon/2 + 1
  varname = 'T'
  var = rg.get_latlon_data(varname, nlon=nlon, nlat=nlat, method='linear')

  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

  print('var.ndim = ', var.ndim)
  print('var.shape = ', var.shape)

  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)

  gp.set_label('Temperature (K)')

 #imgpreix = 'allObs'
 #imgpreix = 'uvOnly'
  imgpreix = 'uvTq'

 #title_preix = 'All Obs'
  title_preix = 'uvOnly'

 #levs = [30, 55]
  levs = [10, 23, 30, 52]

  for lev in levs:
    pvar = var[lev,:,:]
    if(uvOnly):
      if(plotdiff):
        imgname = 'All-uvOnly_getkf_sondes_lev_%d.png' %(lev)
        title = 'All-uvOnly GETKF Sondes Temperature at level %d' %(lev)
      else:
        imgname = 'uvOnly_getkf_sondes_lev_%d.png' %(lev)
        title = 'uvOnly GETKF Sondes Temperature at level %d' %(lev)
    else:
     #imgname = 'allobs_getkf_sondes_lev_%d.png' %(lev)
     #title = 'All Obs GETKF Sondes Temperature at level %d' %(lev)
      imgname = 'uvTq_getkf_sondes_lev_%d.png' %(lev)
      title = 'uvTq GETKF Sondes Temperature at level %d' %(lev)
    gp.set_imagename(imgname)
    gp.set_title(title)
    gp.plot(pvar)

 #lons = [100, 115, 125, 140, 175, 190, 225]
  lons = [40, 105, 170, 270, 300]

  for lon in lons:
    pvar = var[:,:,lon]
    if(uvOnly):
      if(plotdiff):
        imgname = 'All-uvOnly_getkf_sondes_lon_%d.png' %(lon)
        title = 'All-uvOnly GETKF Sondes Temperature at longitude %d' %(lon)
      else:
        imgname = 'uvOnly_getkf_sondes_lon_%d.png' %(lon)
        title = 'uvOnly GETKF Sondes Temperature at longitude %d' %(lon)
    else:
     #imgname = 'allobs_getkf_sondes_lon_%d.png' %(lon)
     #title = 'All Obs GETKF Sondes Temperature at longitude %d' %(lon)
      imgname = 'uvTq_getkf_sondes_lon_%d.png' %(lon)
      title = 'uvTq GETKF Sondes Temperature at longitude %d' %(lon)
    gp.set_imagename(imgname)
    gp.set_title(title)
    gp.plot_meridional_section(pvar)

 #lats = [-35, -20, 45, 55]
  lats = [-30, 0, 45, 70]
  for lat in lats:
    pvar = var[:,90+lat,:]
    if(uvOnly):
      if(plotdiff):
        imgname = 'All-uvOnly_getkf_sondes_lat_%d.png' %(lat)
        title = 'All-uvOnly GETKF Sondes Temperature at latitude %d' %(lat)
      else:
        imgname = 'uvOnly_getkf_sondes_lat_%d.png' %(lat)
        title = 'uvOnly GETKF Sondes Temperature at latitude %d' %(lat)
    else:
     #imgname = 'allobs_getkf_sondes_lat_%d.png' %(lat)
     #title = 'All Obs GETKF Sondes Temperature at latitude %d' %(lat)
      imgname = 'uvTq_getkf_sondes_lat_%d.png' %(lat)
      title = 'uvTq GETKF Sondes Temperature at latitude %d' %(lat)
    gp.set_imagename(imgname)
    gp.set_title(title)
    gp.plot_zonal_section(pvar)

