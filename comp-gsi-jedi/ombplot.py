#=========================================================================
import os
import sys
import math
import types
import getopt
import netCDF4
import numpy as np

sys.path.append('../plot-utils')
from plottools import PlotTools

import matplotlib
import matplotlib.pyplot

from matplotlib import cm
from mpl_toolkits.basemap import Basemap

#=========================================================================
class CheckObsInfo():
  def __init__(self, debug=0, jediOutFiles=[]):
    self.debug = debug
    self.jediOutFiles = jediOutFiles
    self.varname = None

  def set_mask(self, var):
    self.mask = []
    for n in range(len(var)):
     #if(np.isnan(var[n])):
      if(math.isnan(var[n])):
        self.mask.append(n)

  def get_unmasked_value(self, var):
    umval = np.delete(var, self.mask)
    return umval

  def get_info(self, varname):
    self.varname = varname

    if(self.varname is None):
      print('varname is None. Stop.')
      sys.exit(-1)

    jediinfo = {}

    jedilat = []
    jedilon = []
    jediprs = []
    jedisid = []

    jediqc = []
    jediobs = []
    jedierr = []
    jedihofx = []
    jediombg = []
    gsihofx = []

    for flnm in self.jediOutFiles:
      if(not os.path.exists(flnm)):
        print('file: %s does not exist, stop.' %(flnm))
        sys.exit(-1)

      ncfile = netCDF4.Dataset(flnm, 'r')

      ncgroup = ncfile['/MetaData/']
      lat = ncgroup.variables['latitude'][:]
     #lat = self.get_unmasked_value(var)
      lon = ncgroup.variables['longitude'][:]
     #lon = self.get_unmasked_value(var)
      prs = ncgroup.variables['air_pressure'][:]
     #prs = 0.01*self.get_unmasked_value(var)
      prs = 0.01*prs
      sid = ncgroup.variables['station_id'][:]

      jedilat.extend(lat)
      jedilon.extend(lon)
      jediprs.extend(prs)
      jedisid.extend(sid)

      ncgroup = ncfile['/ObsValue/']
      obs = ncgroup.variables[self.varname][:]

      ncgroup = ncfile['/ObsError/']
      oberr = ncgroup.variables[self.varname][:]

      ncgroup = ncfile['/GsiHofX/']
      ghofx = ncgroup.variables[self.varname][:]

      ncgroup = ncfile['/hofx_y_mean_xb0/']
      jhofx = ncgroup.variables[self.varname][:]

      ncgroup = ncfile['/ombg/']
      ombg = ncgroup.variables[self.varname][:]

      ncgroup = ncfile['/EffectiveQC0/']
      qcidx = ncgroup.variables[self.varname][:]

      if('surface_pressure' == self.varname):
        obs = 0.01*obs
        err = 0.01*oberr
        ghofx = 0.01*ghofx
        jhofx = 0.01*jhofx
        ombg = 0.01*ombg
      elif('specific_humidity' == self.varname):
        obs = 1000.0*obs
        err = 1000.0*oberr
        ombg = 1000.0*ombg
        ghofx = 1000.0*ghofx
        jhofx = 1000.0*jhofx

      jediqc.extend(qcidx)
      jediobs.extend(obs)
      jedierr.extend(oberr)
      jediombg.extend(ombg)
      jedihofx.extend(jhofx)
      gsihofx.extend(ghofx)

      ncfile.close()

      print('flnm: ', flnm)
      print("len(lat) = ", len(lat))
      print("len(sid) = ", len(sid))
      print("len(jedilat) = ", len(jedilat))
      print("len(jedisid) = ", len(jedisid))

    self.set_mask(jedihofx)

    jediinfo['lat'] = self.get_unmasked_value(jedilat)
    jediinfo['lon'] = self.get_unmasked_value(jedilon)
    jediinfo['prs'] = self.get_unmasked_value(jediprs)
    jediinfo['qc'] = self.get_unmasked_value(jediqc)

    jediinfo['obs'] = self.get_unmasked_value(jediobs)
    jediinfo['err'] = self.get_unmasked_value(jedierr)
    jediinfo['sid'] = self.get_unmasked_value(jedisid)
    jediinfo['ombg'] = self.get_unmasked_value(jediombg)
    jediinfo['jedihofx'] = self.get_unmasked_value(jedihofx)
    jediinfo['gsihofx'] = self.get_unmasked_value(gsihofx)

    print("len(jediinfo['lat']) = ", len(jediinfo['lat']))
    print("len(jediinfo['sid']) = ", len(jediinfo['sid']))

    return jediinfo

#=========================================================================
class StatsHandler():
  def __init__(self, debug=0, output=0, varname='surface_pressure'):
    self.debug = debug
    self.output = output
    self.varname = varname

    if(self.debug):
      print('self.output = ', self.output)
      print('self.varname = ', self.varname)

#------------------------------------------------------------------------------
  def set_var(self, jedidict):
    self.obslat = jedidict['lat']
    self.obslon = jedidict['lon']
    self.gsihofx = jedidict['gsihofx']
    self.jedihofx = jedidict['jedihofx']
    self.obs = jedidict['obs']
    self.ombg = jedidict['ombg']

    nobs = len(self.gsihofx)
    self.GSI_omb = np.zeros((nobs))
    self.JEDI_omb = np.zeros((nobs))

    for n in range(nobs):
      self.GSI_omb[n] = self.gsihofx[n] + self.ombg[n] - self.obs[n]
      self.JEDI_omb[n] = self.jedihofx[n] + self.ombg[n] - self.obs[n]

#------------------------------------------------------------------------------
  def plotit(self, clevs, cblevs, cmapname, units='hPa', precision=1):
    nlon = 360
    nlat = nlon/2 + 1
    dlon = 360.0/nlon
    dlat = 180.0/(nlat - 1)
    lon = np.arange(0.0, 360.0, dlon)
    lat = np.arange(-90.0, 90.0+dlat, dlat)

    pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)

   #------------------------------------------------------------------------------

    pt.set_clevs(clevs=clevs)
    pt.set_cblevs(cblevs=cblevs)
    pt.set_cmapname(cmapname)
    pt.set_precision(precision=precision)

    label = '%s GSI omb - JEDI omb, units: %s' %(self.varname, units)
    pt.set_label(label)

    imgname = '%s_GSIomb-JEDIomb' %(self.varname)
    title = '%s GSIomb-JEDIomb' %(self.varname)

    obsvar = np.array(self.GSI_omb) - np.array(self.JEDI_omb)

   #------------------------------------------------------------------------------
    meangsiomb = np.mean(np.abs(self.GSI_omb))
    title = '%s mean(abs(GSIomb)): %f' %(title, meangsiomb)
    pt.set_imagename(imgname)
    pt.set_title(title)
  
    pt.obsonly(self.obslat, self.obslon, obsvar, inbound=True)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb-JEDIomb_scatter' %(varname)
    title = '%s GSIomb-JEDIomb Scatter' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.scatter_plot(self.JEDI_omb, self.GSI_omb, obsvar, self.varname, inbound=True)

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  varname = 'surface_pressure'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'varname='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--varname'):
      varname = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('varname = ', varname)

#================================================================================================================
  datadir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/surf/ioda_v2_data'

  jedioutlist = ['sfc_ps_obs_2020011006_0000.nc4',
                 'sfcship_ps_obs_2020011006_0000.nc4',
                 'sondes_ps_obs_2020011006_0000.nc4']
  jediOutFiles = []
  for f in jedioutlist:
    flnm = '%s/out/%s' %(datadir, f)
    jediOutFiles.append(flnm)

  print('jediOutFiles:', jediOutFiles)

 #------------------------------------------------------------------------------

 #clevs = np.arange(-20.0, 20.5, 0.5)
 #cblevs = np.arange(-20.0, 22.0, 2.0)
  clevs = np.arange(-2.0, 2.1, 0.1)
  cblevs = np.arange(-2.0, 4.0, 2.0)
 #cmapname = 'bwr'
  cmapname = 'brg'
 #cmapname = 'YlGn'

  if(varname == 'surface_pressure'):
    units = 'hPa'
    clevs = np.arange(-2.0, 2.1, 0.1)
    cblevs = np.arange(-2.0, 2.5, 0.5)
  elif(varname == 'air_temperature'):
    units = 'K'
    clevs = np.arange(-5.0, 5.1, 0.2)
    cblevs = np.arange(-5.0, 5.5, 1.0)
  elif(varname == 'eastward_wind' or varname == 'northward_wind'):
    clevs = np.arange(-5.0, 5.2, 0.2)
    cblevs = np.arange(-5.0, 6.0, 1.0)
    units = 'm/s'
  elif(varname == 'specific_humidity'):
    units = 'g/kg'
    clevs = np.arange(-5.0, 5.2, 0.2)
    cblevs = np.arange(-5.0, 6.0, 1.0)

  print('clevs = ', clevs)
  print('cblevs = ', cblevs)

#------------------------------------------------------------------------------
  coi = CheckObsInfo(debug=debug, jediOutFiles=jediOutFiles)
  jedidict = coi.get_info(varname)

  sh = StatsHandler(debug=debug, output=output, varname=varname)
  sh.set_var(jedidict)
  sh.plotit(clevs, cblevs, cmapname, units=units)

