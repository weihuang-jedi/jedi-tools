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
  def __init__(self, debug=0, jedifile=None, gsifile=None, jediOutFile=None):
    self.debug = debug
    self.gsifile = gsifile
    self.jedifile = jedifile
    self.jediOutFile = jediOutFile
    self.varname = None

  def process(self, varname):
    self.varname = varname

    if(self.varname is None):
      print('varname is None. Stop.')
      sys.exit(-1)

    self.gsiinfo = self.get_gsiinfo()
    self.jediinfo = self.get_jediinfo()

    nobs = len(self.jedilat)
    self.jedihofx_y_mean_xb0 = np.zeros((nobs), dtype=float)
    self.jediombg = np.zeros((nobs), dtype=float)

    self.reorderobs()

    self.readJEDIobsout()

    self.writedata()

#----------------------------------------------------------------
  def get_gsiinfo(self):
    gsiinfo = {}

    ncfile = netCDF4.Dataset(self.gsifile, 'r')
    lat = ncfile.variables['latitude@MetaData'][:]
    lon = ncfile.variables['longitude@MetaData'][:]
    prs = ncfile.variables['air_pressure@MetaData'][:]

    gsiinfo['lat'] = lat
    gsiinfo['lon'] = lon
    gsiinfo['prs'] = prs

    self.gsilat = lat
    self.gsilon = lon
    self.gsiprs = prs

    obsname = '%s@ObsValue' %(self.varname)
    ombname = '%s@GsiAdjustObsError' %(self.varname)
    errname = '%s@GsiFinalObsError' %(self.varname)

    obs = ncfile.variables[obsname][:]
    omb = ncfile.variables[ombname][:]
    err = ncfile.variables[errname][:]
    oberr = 1.0/err

    if('specific_humidity' == self.varname):
      gsiinfo['obs'] = 1000.0*obs
      gsiinfo['omb'] = 1000.0*omb
      gsiinfo['err'] = 1000.0*oberr
    else:
      gsiinfo['obs'] = obs
      gsiinfo['omb'] = omb
      gsiinfo['err'] = oberr

    ncfile.close()

    return gsiinfo

#----------------------------------------------------------------
  def get_jediinfo(self):
    jediinfo = {}
    ncfile = netCDF4.Dataset(self.jedifile, 'r')

    var = self.get_data_1d(ncfile, 'ObsValue', self.varname)
    self.set_mask(var)
    obs = self.get_unmasked_value(var)

    var = self.get_data_1d(ncfile, 'ObsError', self.varname)
    self.set_mask(var)
    oberr = self.get_unmasked_value(var)

    var = self.get_data_1d(ncfile, 'GsiHofX', self.varname)
    self.set_mask(var)
    hofx = self.get_unmasked_value(var)

    var = self.get_data_1d(ncfile, 'MetaData', 'latitude')
    lat = self.get_unmasked_value(var)

    var = self.get_data_1d(ncfile, 'MetaData', 'longitude')
    lon = self.get_unmasked_value(var)

    var = self.get_data_1d(ncfile, 'MetaData', 'air_pressure')
    prs = 0.01*self.get_unmasked_value(var)

    jediinfo['lat'] = lat
    jediinfo['lon'] = lon
    jediinfo['prs'] = prs

    self.jedilat = lat
    self.jedilon = lon
    self.jediprs = prs

    if('surface_pressure' == self.varname):
      jediinfo['obs'] = 0.01*obs
      jediinfo['err'] = 0.01*oberr
      jediinfo['hofx'] = 0.01*hofx
    elif('specific_humidity' == self.varname):
      jediinfo['obs'] = 1000.0*obs
      jediinfo['err'] = 1000.0*oberr
      jediinfo['hofx'] = 1000.0*hofx
    else:
      jediinfo['obs'] = obs
      jediinfo['err'] = oberr
      jediinfo['hofx'] = hofx

    ncfile.close()

    return jediinfo

  def set_mask(self, var):
    self.mask = []
    for n in range(len(var)):
     #if(np.isnan(var[n])):
      if(math.isnan(var[n])):
        self.mask.append(n)

  def get_unmasked_value(self, var):
    umval = np.delete(var, self.mask)
    return umval

  def reorderobs(self):
    self.delt = 0.001
    self.gsiidx = []
    self.jediidx = []

    nlat = len(self.gsilat)
    xb = time.time()
    for i in range(nlat):
      found, idx = self.findobs(i)
      if(found):
        self.gsiidx.append(i)
        self.jediidx.append(idx)
       #infostr = 'found gsi lat: %8.3f, lon %8.3f, ' %(self.gsilat[i], self.gsilon[i])
       #infostr = '%s matches jedi lat: %8.3f, lon %8.3f' %(infostr, self.jedilat[idx], self.jedilon[idx])
       #print(infostr)
      else:
        infostr = 'did not find matched gsi lat: %8.3f, lon %8.3f, ' %(self.gsilat[i], self.gsilon[i])
        print(infostr)
      
     #xe = time.time()
     #print('Loop on No. %d and %d use time: %8.3f' %(i, idx, xe - xb))
     #xb = xe

    self.gsiall = np.linspace(0, len(self.gsilat), len(self.gsilat), endpoint=False, dtype=int)
    self.gsionly = np.delete(self.gsiall, self.gsiidx)

    self.jediall = np.linspace(0, len(self.jedilat), len(self.jedilat), endpoint=False, dtype=int)
    self.jedionly = np.delete(self.jediall, self.jediidx)

  def findobs(self, i):
    for n in range(len(self.jedilat)):
      if(abs(self.jedilat[n] - self.gsilat[i]) < self.delt):
        if(abs(self.jedilon[n] - self.gsilon[i]) < self.delt):
          return 1, n
    return 0, 0

  def get_data_1d(self, ncfile, groupname, varname):
   #print('groupname: %s, varname: %s' %(groupname, varname))
    ncgroup = ncfile.groups[groupname]
    var = ncgroup.variables[varname][:]
   #print('length %d' %(len(var)))
   #print('var = ', var)
    return var

  def get_data_2d(self, ncfile, groupname, varname):
   #print('groupname: %s, varname: %s' %(groupname, varname))
    ncgroup = ncfile.groups[groupname]
    var = ncgroup.variables[varname][:][:]
    var = var[:,0]
   #print('length %d' %(len(var)))
   #print('var = ', var)
    return var

  def readJEDIobsout(self):
    nprocs = 36
    self.oldlat = []
    self.oldlon = []
    self.oldprs = []
    for n in range(nprocs):
      flstr = '%04d' %(n)
      flnm = self.jediOutFile.replace('0000', flstr)

      print('Reading JEDI out obs for proc: %d' %(n))

      ncfile = netCDF4.Dataset(flnm, 'r')
 
      var = self.get_data_1d(ncfile, 'ObsValue', self.varname)
      self.set_mask(var)
      obs = self.get_unmasked_value(var)

      var = self.get_data_1d(ncfile, 'MetaData', 'latitude')
      lat = self.get_unmasked_value(var)

      var = self.get_data_1d(ncfile, 'MetaData', 'longitude')
      lon = self.get_unmasked_value(var)

      var = self.get_data_1d(ncfile, 'MetaData', 'air_pressure')
      prs = 0.01*self.get_unmasked_value(var)

      var = self.get_data_1d(ncfile, 'hofx_y_mean_xb0', self.varname)
      hofx_y_mean_xb0 = self.get_unmasked_value(var)

      var = self.get_data_1d(ncfile, 'ombg', self.varname)
      ombg = self.get_unmasked_value(var)

      ncfile.close()

      if('surface_pressure' == self.varname):
        ombg = 0.01*ombg
        hofx_y_mean_xb0 = 0.01*hofx_y_mean_xb0
      elif('specific_humidity' == self.varname):
        ombg = 1000.0*ombg
        hofx_y_mean_xb0 = 1000.0*hofx_y_mean_xb0

     #print('Find %d ombg for proc %d' %(len(ombg), n))
     #print('ombg = ', ombg)

      self.insert2JEDI(lat, lon, prs, hofx_y_mean_xb0, ombg)

  def insert2JEDI(self, lat, lon, prs, hofx_y_mean_xb0, ombg):
    if(len(self.oldlat) < 1):
      newidx = np.linspace(0, len(lat), len(lat), endpoint=False, dtype=int)
    else:
      usedidx = []
      for i in range(len(lat)):
        for n in range(len(self.oldlat)):
          if(abs(self.oldlat[n] - lat[i]) < self.delt and
             abs(self.oldlon[n] - lon[i]) < self.delt and
             abs(self.oldprs[n] - prs[i]) < self.delt):
             usedidx.append(i)
             break
      newidx = np.linspace(0, len(lat), len(lat), endpoint=False, dtype=int)
      newidx = np.delete(newidx, usedidx)

    self.delt = 0.001
    for n in range(len(self.jedilat)):
      for i in newidx:
        if(abs(self.jedilat[n] - lat[i]) < self.delt):
          if(abs(self.jedilon[n] - lon[i]) < self.delt):
            if(abs(self.jediprs[n] - prs[i]) < self.delt):
              self.jedihofx_y_mean_xb0[n] = hofx_y_mean_xb0[i]
              self.jediombg[n] = ombg[i]

   #print('\tInsert %d obs to jedi.' %(na))
   #print('self.jediombg = ', self.jediombg)

  def writedata(self):
   #---------------------------------------------------------------------------------------------
    flnm = 'stats_gsiNjedi_%s_common.txt' %(self.varname)
    OUTF = open(flnm, 'w')
    infostr = 'latitude, longitude, pressure, ObsValue, GSI HofX, JEDI HofX, '
    infostr = infostr + 'GSI omb, JEDI omb, GSI ob error, JEDI ob error, '
    infostr = infostr + 'JEDI hofx_y_mean_xb0'
    OUTF.write('%s\n' %(infostr))
    nobs = len(self.gsiidx)
    print('len(self.gsiidx) = ', len(self.gsiidx))
    print('len(self.jediidx) = ', len(self.jediidx))
    print("len(self.gsiinfo['err']) = ", len(self.gsiinfo['err']))
    print("len(self.jediinfo['err']) = ", len(self.jediinfo['err']))

    for k in range(nobs-1):
      n = self.gsiidx[k]
      i = self.jediidx[k]
      if(n >= nobs-1 or i >= nobs-1):
        continue

      if((abs(self.gsilat[n] - self.jedilat[i]) > self.delt) or
         (abs(self.gsilon[n] - self.jedilon[i]) > self.delt)):
         infostr = 'gsi lat: %8.3f, lon %8.3f did not match ' %(self.gsilat[n], self.gsilon[n])
         infostr = '%s jedi lat: %8.3f, lon %8.3f. Exit.' %(infostr, self.jedilat[i], self.jedilon[i])
         print(infostr)
         sys.exit(-1)

      infostr = '%8.3f, %8.3f,' %(self.gsilat[n], self.gsilon[n])
      infostr = '%s %8.3f, %8.3f,' %(infostr, self.gsiinfo['prs'][n], self.jediinfo['obs'][i])
      gsihofx = self.gsiinfo['obs'][n] - self.gsiinfo['omb'][n]
      infostr = '%s %8.3f, %8.3f,' %(infostr, gsihofx, self.jediinfo['hofx'][i])
      infostr = '%s %8.3f, %8.3f,' %(infostr, self.gsiinfo['omb'][n], self.jediombg[i])

      if(math.isnan(self.gsiinfo['err'][n])):
        gsierr = 999999.0
      else:
        gsierr = self.gsiinfo['err'][n]
      jedierr = self.jediinfo['err'][i]
      if(gsierr > 999999.0):
        gsierr = 999999.0
      if(jedierr > 999999.0):
        jedierr = 999999.0
      infostr = '%s %8.3f, %8.3f,' %(infostr, gsierr, jedierr)
      infostr = '%s %8.3f' %(infostr, self.jedihofx_y_mean_xb0[i])
      OUTF.write('%s\n' %(infostr))
    OUTF.close()

   #---------------------------------------------------------------------------------------------
    flnm = 'stats_gsiNjedi_%s_gsionly.txt' %(self.varname)
    OUTF = open(flnm, 'w')
    infostr = 'latitude, longitude, pressure, ObsValue, GSI HofX, '
    infostr = infostr + 'GSI omb, GSI ob error'
    OUTF.write('%s\n' %(infostr))
    nobs = len(self.gsionly)
    for k in range(nobs):
      n = self.gsionly[k]

      infostr = '%8.3f, %8.3f, %8.3f,' %(self.gsilat[n], self.gsilon[n], self.gsiinfo['prs'][n])
      gsihofx = self.gsiinfo['obs'][n] - self.gsiinfo['omb'][n]
      infostr = '%s %8.3f, %8.3f,' %(infostr, gsihofx, self.gsiinfo['omb'][n])

      if(math.isnan(self.gsiinfo['err'][n])):
        gsierr = 999999.0
      else:
        gsierr = self.gsiinfo['err'][n]
      if(gsierr > 999999.0):
        gsierr = 999999.0
      infostr = '%s %8.3f' %(infostr, gsierr)
      OUTF.write('%s\n' %(infostr))
    OUTF.close()

   #---------------------------------------------------------------------------------------------
    flnm = 'stats_gsiNjedi_%s_jedionly.txt' %(self.varname)
    OUTF = open(flnm, 'w')
    infostr = 'latitude, longitude, pressure, ObsValue, JEDI HofX, '
    infostr = infostr + 'JEDI omb, JEDI ob error, '
    infostr = infostr + 'JEDI hofx_y_mean_xb0'
    OUTF.write('%s\n' %(infostr))
    nobs = len(self.jedionly)
    for k in range(nobs):
      i = self.jedionly[k]

      infostr = '%8.3f, %8.3f,' %(self.jedilat[i], self.jedilon[i])
      infostr = '%s %8.3f, %8.3f,' %(infostr, self.jediinfo['prs'][i], self.jediinfo['obs'][i])
      infostr = '%s %8.3f, %8.3f,' %(infostr, self.jediinfo['hofx'][i], self.jediombg[i])

      jedierr = self.jediinfo['err'][i]
      if(jedierr > 999999.0):
        jedierr = 999999.0
      infostr = '%s %8.3f,' %(infostr, jedierr)
      infostr = '%s %8.3f' %(infostr, self.jedihofx_y_mean_xb0[i])
      OUTF.write('%s\n' %(infostr))
    OUTF.close()

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
 #varname = 'surface_pressure'
  varname = 'eastward_wind'

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
  jedidir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/rerun/ioda_v2_data'
  jediobsfile = '%s/obs/ioda_v2_sondes_all_obs_2021010900.nc4' %(jedidir)

  gsidatadir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/diag2iodav2'
  if(varname == 'surface_pressure'):
    jediOutFile = '%s/ps-out/ps_obs_2021010900_0000.nc4' %(jedidir)
    gsiobsfile = '%s/sondes_ps_obs_2021010900.nc4' %(gsidatadir)
  else:
    jediOutFile = '%s/uvtq+tv-out/uvtq_obs_2021010900_0000.nc4' %(jedidir)
    if(varname == 'virtual_temperature'):
      gsiobsfile = '%s/sondes_tv_obs_2021010900.nc4' %(gsidatadir)
    elif(varname == 'air_temperature'):
      gsiobsfile = '%s/sondes_tsen_obs_2021010900.nc4' %(gsidatadir)
    elif(varname == 'specific_humidity'):
      gsiobsfile = '%s/sondes_q_obs_2021010900.nc4' %(gsidatadir)
    else:
      gsiobsfile = '%s/sondes_uv_obs_2021010900.nc4' %(gsidatadir)

  coi = CheckObsInfo(debug=debug, jedifile=jediobsfile, gsifile=gsiobsfile, jediOutFile=jediOutFile)

  coi.process(varname=varname)
