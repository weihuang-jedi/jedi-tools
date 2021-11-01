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

from scipy_regridder import RegridFV3 as regridder
from readIODA2Obs import ReadIODA2Obs

sys.path.append('../plot-utils')
from plottools import PlotTools

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  uvOnly = 0
  addobs = 0
  uselogp = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'uvOnly=',
                             'addobs=', 'uselogp='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--uvOnly'):
      uvOnly = int(a)
    elif o in ('--addobs'):
      addobs = int(a)
    elif o in ('--uselogp'):
      uselogp = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('uvOnly = ', uvOnly)

#------------------------------------------------------------------------------
 #griddir = '/work/noaa/gsienkf/weihuang/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/'
  griddir = '/work/noaa/gsienkf/weihuang/UFS-RNR-tools/JEDI.FV3-increments/grid/C48/'

  if(uvOnly):
    datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.new_uvonly/increment/'
  else:
    casedir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes'
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.all/increment/'
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.psOnly.wrong/increment/'
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/surface/analysis.getkf.5members.36procs/increment/'
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs/increment/'
   #datadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.new_psonly/increment/'
   #datadir = '%s/anna-request/analysis.getkf.80members.36procs.1/increment/' %(casedir)
    datadir = '%s/anna-request/analysis.getkf.80members.36procs.2/increment/' %(casedir)

  datafiles = []
  snd_files = []
  gridspecfiles = []
  for ntile in range(1,7,1):
    gridfile = '%sC48_grid.tile%s.nc' %(griddir, ntile)
    gridspecfiles.append(gridfile)

    datafile = '%s20210109.000000.fv_core.res.tile%s.nc' %(datadir, ntile)
    datafiles.append(datafile)

  rg = regridder(debug=debug, datafiles=datafiles, gridspecfiles=gridspecfiles)

  nlon = 360
  nlat = nlon/2 + 1
  varname = 'T'
  var = rg.get_latlon_data(varname, nlon=nlon, nlat=nlat, method='linear')

  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

 #print('var.ndim = ', var.ndim)
 #print('var.shape = ', var.shape)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
  if(addobs):
    filename = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/ioda_v2_data/obs/ncdiag.oper.ob.PT6H.sondes.2021-01-08T21:00:00Z.nc4'
    rio = ReadIODA2Obs(debug=debug, filename=filename)
   #lat, lon = rio.get_latlon()
   #lat, lon, prs = rio.get_latlon4var(varname='/ObsValue/surface_pressure')
    lat, lon, prs = rio.get_latlon4var(varname='/ObsValue/air_temperature')

   #print('lat = ', lat)
   #print('lon = ', lon)

    pt.set_obs_latlon(obslat=lat, obslon=lon)

#------------------------------------------------------------------------------
  pt.set_label('Temperature (K)')

  if(uvOnly):
    image_prefix = 'new_uvOnly'
    title_preix = 'new uvOnly JEDI Sondes Temperature at'
  else:
   #image_prefix = 'uvTq_jedi_sondes'
   #title_preix = 'uvTq JEDI Sondes Temperature at'
   #image_prefix = 'PSonly_jedi_sondes'
   #title_preix = 'PSonly JEDI Sondes Temperature at'
    image_prefix = 'LETKF_PSonly_jedi_sondes'
    title_preix = 'LETKF PSonly JEDI Sondes Temperature at'

#------------------------------------------------------------------------------
 #clevs = np.arange(-0.5, 0.51, 0.01)
 #cblevs = np.arange(-0.5, 0.6, 0.1)
 #clevs = np.arange(-5.0, 5.1, 0.1)
 #cblevs = np.arange(-5.0, 6.0, 1.0)
  clevs = np.arange(-1.0, 1.01, 0.01)
  cblevs = np.arange(-1.0, 1.2, 0.2)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)

#------------------------------------------------------------------------------
  levs = [0, 1, 62, 63]
 #levs = [61, 62, 63]
 #levs = [60]
  for lev in levs:
    pvar = var[lev,:,:]
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
  clevs = np.arange(-0.5, 0.51, 0.01)
  cblevs = np.arange(-0.5, 0.6, 0.1)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)

  lons = [40, 105, 170, 270, 300]
 #lons = [60, 200]
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
  lats = [-30, 0, 45, 70]
 #lats = [50, 55]
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

