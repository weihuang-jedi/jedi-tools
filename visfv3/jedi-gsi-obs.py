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

    nobs = len(self.gsilat)
    self.jediEffectiveError0 = np.zeros((nobs), dtype=float)
    self.jedihofx_y_mean_xb0 = np.zeros((nobs), dtype=float)
    self.jediombg = np.zeros((nobs), dtype=float)

    self.reorderobs()

    self.readJEDIobsout()

    flnm = 'stats_gsiNjedi_%s.txt' %(self.varname)
    self.writedata(flnm)

#----------------------------------------------------------------
  def get_gsiinfo(self):
    gsiinfo = {}

    ncfile = netCDF4.Dataset(self.gsifile, 'r')
    lat = ncfile.variables['Latitude'][:]
    lon = ncfile.variables['Longitude'][:]

    gsiinfo['lat'] = lat
    gsiinfo['lon'] = lon

    self.gsilat = lat
    self.gsilon = lon

    prs = ncfile.variables['Pressure'][:]
    gsiinfo['prs'] = prs

    if('surface_pressure' == self.varname or
       'specific_humidity' == self.varname or
       'air_temperature' == self.varname):
      obs = ncfile.variables['Observation'][:]
      omb = ncfile.variables['Obs_Minus_Forecast_adjusted'][:]
     #omb = ncfile.variables['Obs_Minus_Forecast_unadjusted'][:]
    elif('eastward_wind' == self.varname):
      obs = ncfile.variables['u_Observation'][:]
      omb = ncfile.variables['u_Obs_Minus_Forecast_adjusted'][:]
    elif('northward_wind' == self.varname):
      obs = ncfile.variables['v_Observation'][:]
      omb = ncfile.variables['v_Obs_Minus_Forecast_adjusted'][:]
    gsiinfo['obs'] = obs
    gsiinfo['omb'] = omb

    err = ncfile.variables['Errinv_Final'][:]
    oberr = 1.0/err
    gsiinfo['err'] = oberr

    sid = ncfile.variables['Station_ID'][:]
    gsiinfo['sid'] = sid

    ncfile.close()

    print("len(gsiinfo['sid']) = ", len(gsiinfo['sid']))

    return gsiinfo

#----------------------------------------------------------------
  def get_jediinfo(self):
    jediinfo = {}
    ncfile = netCDF4.Dataset(self.jedifile, 'r')

    ncgroup = ncfile['/ObsValue/']
    var = ncgroup.variables[self.varname][:]
    self.set_mask(var)
    obs = 0.01*self.get_unmasked_value(var)
    jediinfo['obs'] = obs

   #ncgroup = ncfile['/GsiFinalObsError/']
    ncgroup = ncfile['/ObsError/']
    var = ncgroup.variables[self.varname][:]
    oberr = 0.01*self.get_unmasked_value(var)
    jediinfo['err'] = oberr

    ncgroup = ncfile['/GsiHofX/']
    var = ncgroup.variables[self.varname][:]
    hofx = 0.01*self.get_unmasked_value(var)
    jediinfo['hofx'] = hofx

    ncgroup = ncfile['/MetaData/']
    var = ncgroup.variables['latitude'][:]
    lat = self.get_unmasked_value(var)
    var = ncgroup.variables['longitude'][:]
    lon = self.get_unmasked_value(var)

    jediinfo['lat'] = lat
    jediinfo['lon'] = lon

    self.jedilat = lat
    self.jedilon = lon

    var = ncgroup.variables['station_id'][:]
    sid =self.get_unmasked_value(var)
    jediinfo['sid'] = sid

    ncfile.close()

    print("len(jediinfo['sid']) = ", len(jediinfo['sid']))

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
    self.delt = 0.000001
    self.jediidx = []

    nlat = len(self.gsilat)
    xb = time.time()
    for i in range(nlat):
      found, idx = self.findobs(i)
      if(found):
        self.jediidx.append(idx)
       #infostr = 'found gsi lat: %f, lon %f, ' %(self.gsilat[i], self.gsilon[i])
       #infostr = '%s matches jedi lat: %f, lon %f' %(infostr, self.jedilat[idx], self.jedilon[idx])
       #print(infostr)
      else:
        infostr = 'did not find matched gsi lat: %f, lon %f, ' %(self.gsilat[i], self.gsilon[i])
        print(infostr)
      
     #xe = time.time()
     #print('Loop on No. %d and %d use time: %f' %(i, idx, xe - xb))
     #xb = xe

  def findobs(self, i):
    for n in range(len(self.jedilat)):
      if(abs(self.jedilat[n] - self.gsilat[i]) < self.delt):
        if(abs(self.jedilon[n] - self.gsilon[i]) < self.delt):
          return 1, n
    return 0, 0

  def readJEDIobsout(self):
    nprocs = 36
    for n in range(nprocs):
      flstr = '%04d' %(n)
      flnm = self.jediOutFile.replace('0000', flstr)

      ncfile = netCDF4.Dataset(flnm, 'r')
 
      ncgroup = ncfile['/EffectiveError0/']
      var = ncgroup.variables[self.varname][:]
      self.set_mask(var)
      EffectiveError0 = 0.01*self.get_unmasked_value(var)

      ncgroup = ncfile['/MetaData/']
      var = ncgroup.variables['latitude'][:]
      lat = self.get_unmasked_value(var)
      var = ncgroup.variables['longitude'][:]
      lon = self.get_unmasked_value(var)

      ncgroup = ncfile['/hofx_y_mean_xb0/']
      var = ncgroup.variables[self.varname][:]
      hofx_y_mean_xb0 = 0.01*self.get_unmasked_value(var)

      ncgroup = ncfile['/ombg/']
      var = ncgroup.variables[self.varname][:]
      ombg = 0.01*self.get_unmasked_value(var)

      ncfile.close()

     #print('Find %d ombg for proc %d' %(len(ombg), n))
     #print('ombg = ', ombg)

      self.insert2JEDI(lat, lon, EffectiveError0, hofx_y_mean_xb0, ombg)

  def insert2JEDI(self, lat, lon, EffectiveError0, hofx_y_mean_xb0, ombg):
    self.delt = 0.001
    na = 0
    for n in range(len(self.jedilat)):
      for i in range(len(lat)):
        if(abs(self.jedilat[n] - lat[i]) < self.delt):
          if(abs(self.jedilon[n] - lon[i]) < self.delt):
            self.jediEffectiveError0[n] = EffectiveError0[i]
            self.jedihofx_y_mean_xb0[n] = hofx_y_mean_xb0[i]
            self.jediombg[n] = ombg[i]
            na += 1

   #print('\tInsert %d obs to jedi.' %(na))
   #print('self.jediombg = ', self.jediombg)

  def writedata(self, flnm):
    OUTF = open(flnm, 'w')
    infostr = 'latitude, longitude, ObsValue, GSI HofX, JEDI HofX, '
    infostr = infostr + 'GSI omb, JEDI omb, GSI ob error, JEDI ob error, '
    infostr = infostr + 'JEDI hofx_y_mean_xb0, EffectiveError0'
    OUTF.write('%s\n' %(infostr))
    nlat = len(self.gsilat)
    for n in range(nlat):
      i = self.jediidx[n]
      if((abs(self.gsilat[n] - self.jedilat[i]) > self.delt) or
         (abs(self.gsilon[n] - self.jedilon[i]) > self.delt)):
         infostr = 'gsi lat: %f, lon %f did not match ' %(self.gsilat[n], self.gsilon[n])
         infostr = '%s jedi lat: %f, lon %f. Exit.' %(infostr, self.jedilat[i], self.jedilon[i])
         print(infostr)
         sys.exit(-1)
     #if(abs(self.gsiinfo['obs'][n] - self.jediinfo['obs'][i]) > self.delt):
     #if(abs(self.gsiinfo['obs'][n] - self.jediinfo['obs'][i]) > 0.01):
     #   infostr = 'gsi obs: %f, did not match ' %(self.gsiinfo['obs'][n])
     #   infostr = '%s jedi obs: %f. Exit.' %(infostr, self.jediinfo['obs'][i])
     #   print(infostr)
     #   sys.exit(-1)

      infostr = '%f, %f, %f,' %(self.gsilat[n], self.gsilon[n], self.jediinfo['obs'][i])
      gsihofx = self.gsiinfo['obs'][n] - self.gsiinfo['omb'][n]
      infostr = '%s %f, %f,' %(infostr, gsihofx, self.jediinfo['hofx'][i])
      infostr = '%s %f, %f,' %(infostr, self.gsiinfo['omb'][n], self.jediombg[i])

      if(math.isnan(self.gsiinfo['err'][n])):
        gsierr = 999999.0
      else:
        gsierr = self.gsiinfo['err'][n]
      jedierr = self.jediinfo['err'][i]
      if(gsierr > 999999.0):
        gsierr = 999999.0
      if(jedierr > 999999.0):
        jedierr = 999999.0
     #infostr = '%s %f, %f,' %(infostr, self.gsiinfo['err'][n], self.jediinfo['err'][i])
      infostr = '%s %f, %f,' %(infostr, gsierr, jedierr)
      infostr = '%s %f, %f' %(infostr, self.jedihofx_y_mean_xb0[n], self.jediEffectiveError0[i])
      OUTF.write('%s\n' %(infostr))
    OUTF.close()

  def readdata(self, flnm):
    lat = []
    lon = []
    INF = open(flnm, 'r')
    lines = INF.readlines()
    for line in lines:
      item = line.split(', ')
      lat.append(float(item[0]))
      lon.append(float(item[1]))
    INF.close()

    return lat, lon

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
  jediobsfile = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/ioda_v2_data/obs/ncdiag.oper.ob.PT6H.sondes.2021-01-08T21:00:00Z.nc4'

 #jediOutFile = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/ioda_v2_data/ps-out/ncdiag.oper.ob.PT6H.sondes.2021-01-08T21:00:00Z_0000.nc4'
  jediOutFile = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/anna-request/ioda_v2_data/out-2/ncdiag.oper.ob.PT6H.sondes.2021-01-08T21:00:00Z_0000.nc4'

  gsidatadir = '/work/noaa/gsienkf/weihuang/jedi/vis_tools/visfv3'
  if(varname == 'surface_pressure'):
    gsiobsfile = '%s/jeff-runs/PSonly/diag_conv_ps_ges.2021010900_ensmean.nc4' %(gsidatadir)
  else:
    if(varname == 'air_temperature' or
       varname == 'virtual_temperature'):
      gsiobsfile = '%s/jeff-runs/allsondeobs/diag_conv_t_ges.2021010900_ensmean.nc4' %(gsidatadir)
    elif(varname == 'specific_humidity'):
      gsiobsfile = '%s/jeff-runs/allsondeobs/diag_conv_q_ges.2021010900_ensmean.nc4' %(gsidatadir)
    else:
      gsiobsfile = '%s/jeff-runs/allsondeobs/diag_conv_uv_ges.2021010900_ensmean.nc4' %(gsidatadir)

  coi = CheckObsInfo(debug=debug, jedifile=jediobsfile, gsifile=gsiobsfile, jediOutFile=jediOutFile)

  coi.process(varname=varname)

