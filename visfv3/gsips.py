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

from genplot import GeneratePlot as genplot
from scipy_regridder import RegridFV3 as regridder
from readGSIobs import ReadGSIobs

#=========================================================================
class PlotGSISurfacePressure():
  def __init__(self, debug=0, output=0, bkg=None, anl=None):
    self.debug = debug
    self.output = output
    self.bkg = bkg
    self.anl = anl

    if(self.debug):
      print('debug = ', debug)

    if(self.debug > 10):
      print('self.bkg = ', self.bkg)
      print('self.anl = ', self.anl)

    self.has_snd_file = 0
    self.snd_file = None

  def set_snd_file(self, filename):
    self.has_snd_file = 1
    self.snd_file = filename

  def get_vardims(self, filename, varname):
    if(self.debug > 1):
      print('varname = ', varname)
      print('filename = ', filename)
    ncfile = netCDF4.Dataset(filename, 'r')
    dimids = ncfile.variables[varname].dimensions

    if(self.debug > 1):
      print('dimids = ', dimids)

    self.nx = 0
    self.ny = 0
    self.nz = 0
    self.ntime = 0

    print('dimids = ', dimids)

    for dimname in dimids:
      if(self.debug > 1):
        print('dimname:', dimname)
      if(dimname == 'time'):
        self.ntime = len(ncfile.dimensions[dimname])
      elif(dimname == 'pfull'):
        self.nz = len(ncfile.dimensions[dimname])
      elif(dimname == 'grid_yt'):
        self.ny = len(ncfile.dimensions[dimname])
      elif(dimname == 'grid_xt'):
        self.nx = len(ncfile.dimensions[dimname])

    if(self.debug):
      print('self.nx = ', self.nx)
      print('self.ny = ', self.ny)
      print('self.nz = ', self.nz)
      print('self.ntime = ', self.ntime)

  def get_var(self, varname):
    print('varname =', varname)

    self.get_vardims(self.bkg, varname)

    lat = np.zeros((self.ny, self.nx))
    lon = np.zeros((self.ny, self.nx))

    anl = np.zeros((self.nz, self.ny, self.nx))
    bkg = np.zeros((self.nz, self.ny, self.nx))

    anl_file = netCDF4.Dataset(self.anl, 'r')
    lat = anl_file.variables['lat'][:, :]
    lon = anl_file.variables['lon'][:, :]
    anl = anl_file.variables[varname][0, :, :]
    anl_file.close()

    self.lats = lat.flatten()
    self.lons = lon.flatten()

    bkg_file = netCDF4.Dataset(self.bkg, 'r')
    bkg = bkg_file.variables[varname][0, :, :]
    bkg_file.close()

    if(self.debug):
      msg = ('analy range for variable %s: (%s, %s).' % (varname, anl.min(), anl.max()))
      print(msg)
      msg = ('bkgrd range for variable %s: (%s, %s).' % (varname, bkg.min(), bkg.max()))
      print(msg)

    incr = anl - bkg

   #print('incr = ', incr)

    return self.lons, self.lats, incr

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  addobs = 1

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'addobs='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--addobs'):
      addobs = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('addobs = ', addobs)

  bkg = 'jeff-runs/PSonly/sfg_2021010900_fhr06_ensmean'
  anl = 'jeff-runs/uvsondeobs/sanl_2021010900_fhr06_ensmean'

#------------------------------------------------------------------------------
  pg = PlotGSISurfacePressure(debug=debug, output=output, bkg=bkg, anl=anl)

  lon1d, lat1d, invar = pg.get_var('pressfc')

  rg = regridder(debug=debug, datafiles=[], gridspecfiles=[])

  nlon = 360
  nlat = nlon/2 + 1
  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

  var = rg.interp2latlon_data(lon1d, lat1d, invar, nlon=nlon, nlat=nlat, method='linear')

#------------------------------------------------------------------------------
  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)
  if(addobs):
   #filename = 'jeff-runs/uvsondeobs/diag_conv_uv_ges.2021010900_ensmean.nc4'
    filename = 'jeff-runs/PSonly/diag_conv_ps_ges.2021010900_ensmean.nc4'
    rgo = ReadGSIobs(debug=debug, filename=filename)
    obslat, obslon = rgo.get_latlon()

    gp.set_obs_latlon(obslat=obslat, obslon=obslon)

#------------------------------------------------------------------------------
  gp.set_label('Surface Pressure')

 #imageprefix = 'uvOnly_gsi_sondes'
 #titleprefix = 'uvOnly GSI Sondes Surface Pressure'
  imageprefix = 'PSonly_gsi_sondes'
  titleprefix = 'PS only GSI Sondes Surface Pressure'

#------------------------------------------------------------------------------
 #clevs = np.arange(-0.5, 0.51, 0.01)
 #cblevs = np.arange(-0.5, 0.6, 0.1)
 #clevs = np.arange(-1.0, 1.01, 0.01)
 #cblevs = np.arange(-1.0, 1.2, 0.2)
  clevs = np.arange(-2.0, 2.02, 0.02)
  cblevs = np.arange(-2.0, 2.5, 0.5)
  gp.set_clevs(clevs=clevs)
  gp.set_cblevs(cblevs=cblevs)

  imgname = '%s_ps.png' %(imageprefix)
  title = '%s Surface Pressure' %(titleprefix)
  gp.set_imagename(imgname)
  gp.set_title(title)
  pvar = 0.01*var
 #gp.plot(pvar, addmark=1, marker='x', size=3, color='green')
  gp.plot(pvar, addmark=1, marker='x', size=1, color='green')

