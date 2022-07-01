#=========================================================================
import os
import sys
import math
import time
import types
import getopt
import netCDF4

import numpy as np

#=========================================================================
class CheckObsInfo():
  def __init__(self, debug=0, jediOutFiles=[]):
    self.debug = debug
    self.jediOutFiles = jediOutFiles
    self.varname = None

  def process(self, varname):
    self.varname = varname

    if(self.varname is None):
      print('varname is None. Stop.')
      sys.exit(-1)

    return self.get_jediinfo(()

  def set_mask(self, var):
    self.mask = []
    for n in range(len(var)):
     #if(np.isnan(var[n])):
      if(math.isnan(var[n])):
        self.mask.append(n)

  def get_unmasked_value(self, var):
    umval = np.delete(var, self.mask)
    return umval

  def get_jediinfo(self):
    jediinfo = {}
    jedilat = []
    jedilon = []
    jediprs = []
    jediobs = []
    jedierr = []
    jedihofx = []
    jediombg = []
    gsihofx = []
    jedisid = []
    jediqc = []

    for flnm in self.jediInFiles:
      ncfile = netCDF4.Dataset(flnm, 'r')

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

      ncgroup = ncfile['/MetaData/']
      lat = ncgroup.variables['latitude'][:]
     #lat = self.get_unmasked_value(var)
      lon = ncgroup.variables['longitude'][:]
     #lon = self.get_unmasked_value(var)
      prs = ncgroup.variables['air_pressure'][:]
     #prs = 0.01*self.get_unmasked_value(var)
      prs = 0.01*prs

      jedilat.extend(lat)
      jedilon.extend(lon)
      jediprs.extend(prs)

      if('surface_pressure' == self.varname):
        obs = 0.01*obs
        err = 0.01*oberr
        gsihofx = 0.01*gsihofx
        jedihofx = 0.01*jedihofx
        ombg = 0.01*ombg
      elif('specific_humidity' == self.varname):
        obs = 1000.0*obs
        err = 1000.0*oberr
        ombg = 1000.0*ombg
        gsihofx = 1000.0*gsihofx
        jedihox = 1000.0*jedihox

      jediobs.extend(obs)
      jedierr.extend(oberr)
      jedihofx.extend(hofx)

      sid = ncgroup.variables['station_id'][:]
      jedisid.extend(sid)
      jediqc.extend(qcindx)
      jediombg.extend(ombg)
      jedihofx.extend(jhofx)
      gsihofx.extend(ghofx)

      ncfile.close()

      print('flnm: ', flnm)
      print("len(lat) = ", len(lat))
      print("len(sid) = ", len(sid))
      print("len(jedilat) = ", len(jedilat))
      print("len(jedisid) = ", len(jedisid))

    self.jedilat = jedilat
    self.jedilon = jedilon
    self.jediprs = jediprs

    jediinfo['lat'] = jedilat
    jediinfo['lon'] = jedilon
    jediinfo['prs'] = jediprs
    jediinfo['obs'] = jediobs
    jediinfo['err'] = jedierr
    jediinfo['sid'] = jedisid
    jediinfo['ombg'] = jediombg
    jediinfo['jedihofx'] = jedihofx
    jediinfo['gsihofx'] = gsihofx

    print("len(jediinfo['lat']) = ", len(jediinfo['lat']))
    print("len(jediinfo['sid']) = ", len(jediinfo['sid']))

    return jediinfo

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
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

#=======================================================================================================================
  datadir = '/work2/noaa/gsienkf/weihuang/C96_psonly_delp/2020011006'
  gsiobsfile = '%s/diag_conv_ps_ges.2020011006_ensmean.nc4' %(datadir)

  datadir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/surf/ioda_v2_data'

  jediinlist = ['sfc_ps_obs_2020011006.nc4',
                'sfcship_ps_obs_2020011006.nc4',
                'sondes_ps_obs_2020011006.nc4']
  jediInFiles = []
  for f in jediinlist:
    flnm = '%s/%s' %(datadir, f)
    jediInFiles.append(flnm)

  jedioutlist = ['sfc_ps_obs_2020011006_0000.nc4',
                 'sfcship_ps_obs_2020011006_0000.nc4',
                 'sondes_ps_obs_2020011006_0000.nc4']
  jediOutFiles = []
  for f in jedioutlist:
    flnm = '%s/out/%s' %(datadir, f)
    jediOutFiles.append(flnm)

  print('jediInFiles:', jediInFiles)
  print('jediOutFiles:', jediOutFiles)

  coi = CheckObsInfo(debug=debug, gsifile=gsiobsfile, jediInFiles=jediInFiles, jediOutFiles=jediOutFiles)

  coi.process(varname=varname)

