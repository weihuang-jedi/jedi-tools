#=========================================================================
import os
import sys
import types
import getopt

import numpy as np

sys.path.append('../plot-utils')
from plottools import PlotTools

import matplotlib
import matplotlib.pyplot

from matplotlib import cm
from mpl_toolkits.basemap import Basemap

#=========================================================================
class StatsHandler():
  def __init__(self, debug=0, output=0, varname='brightness_temperature'):
    self.debug = debug
    self.output = output
    self.varname = varname

    if(self.debug):
      print('self.output = ', self.output)
      print('self.varname = ', self.varname)

    self.filename = 'amsua_stats/stats_gsiNjedi_%s_common.txt' %(varname)

    self.read_data(self.filename)

  def read_data(self, filename):
    with open(filename, 'r') as textreader:
      lines = textreader.readlines()

    self.latitude = []
    self.longitude = []
    self.ObsValue = []
    self.GSI_HofX = []
    self.JEDI_HofX = []
    self.GSI_omb = []
    self.JEDI_omb = []
    self.GSI_ob_error = []
    self.JEDI_ob_error = []
    self.JEDI_hofx_y_mean_xb0 = []
    self.EffectiveError0 = []

    nlines = len(lines)
    for i in range(1, nlines):
      item = lines[i].split(', ')
      self.latitude.append(float(item[0]))
      self.longitude.append(float(item[1]))
      self.ObsValue.append(float(item[2]))
      self.GSI_HofX.append(float(item[3]))
      self.JEDI_HofX.append(float(item[4]))
      self.GSI_omb.append(float(item[5]))
      self.JEDI_omb.append(float(item[6]))
      self.GSI_ob_error.append(float(item[7]))
      self.JEDI_ob_error.append(float(item[8]))
      self.JEDI_hofx_y_mean_xb0.append(float(item[9]))
     #self.EffectiveError0.append(float(item[10]))
     #info = item[11].split(',')
     #self.EffectiveError0.append(float(info[0]))

#------------------------------------------------------------------------------
  def get_omb(self):
    return self.latitude, self.longitude, self.GSI_omb, self.JEDI_omb

#------------------------------------------------------------------------------
  def plotit(self, clevs, cblevs, cmapname, units='K', precision=1):
    nlon = 360
    nlat = nlon/2 + 1
    dlon = 360.0/nlon
    dlat = 180.0/(nlat - 1)
    lon = np.arange(0.0, 360.0, dlon)
    lat = np.arange(-90.0, 90.0+dlat, dlat)

    pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)

   #------------------------------------------------------------------------------
    obslat, obslon, GSI_omb, JEDI_omb = self.get_omb()

    pt.set_clevs(clevs=clevs)
    pt.set_cblevs(cblevs=cblevs)
    pt.set_cmapname(cmapname)
    pt.set_precision(precision=precision)

   #------------------------------------------------------------------------------
    label = '%s GSI omb, units: %s' %(self.varname, units)
    pt.set_label(label)

    imgname = '%s_GSIomb' %(self.varname)
    title = '%s GSIomb' %(self.varname)

    obsvar = np.array(GSI_omb)

    meangsiomb = np.mean(np.abs(GSI_omb))
    title = '%s mean(abs(GSIomb)): %f' %(title, meangsiomb)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.obsonly(obslat, obslon, obsvar, inbound=True)

   #------------------------------------------------------------------------------
    label = '%s JEDI omb, units: %s' %(self.varname, units)
    pt.set_label(label)

    imgname = '%s_JEDIomb' %(self.varname)
    title = '%s JEDIomb' %(self.varname)

    obsvar = np.array(JEDI_omb)

    meangsiomb = np.mean(np.abs(JEDI_omb))
    title = '%s mean(abs(JEDIomb)): %f' %(title, meangsiomb)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.obsonly(obslat, obslon, obsvar, inbound=True)

   #------------------------------------------------------------------------------
    label = '%s GSI omb - JEDI omb, units: %s' %(self.varname, units)
    pt.set_label(label)

    imgname = '%s_GSIomb-JEDIomb' %(self.varname)
    title = '%s GSIomb-JEDIomb' %(self.varname)

    obsvar = np.array(GSI_omb) - np.array(JEDI_omb)

    meangsiomb = np.mean(np.abs(GSI_omb))
    title = '%s mean(abs(GSIomb)): %f' %(title, meangsiomb)
    pt.set_imagename(imgname)
    pt.set_title(title)
  
    pt.obsonly(obslat, obslon, obsvar, inbound=True)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb_cdf' %(varname)
    title = '%s GSIomb CDF' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.plot_cdf(GSI_omb)

   #------------------------------------------------------------------------------
    imgname = '%s_JEDIomb_cdf' %(varname)
    title = '%s JEDIomb CDF' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.plot_cdf(JEDI_omb)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb-JEDIomb_cdf' %(varname)
    title = '%s GSIomb-JEDIomb CDF' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.plot_cdf(obsvar)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb-JEDIomb_scatter' %(varname)
    title = '%s GSIomb-JEDIomb Scatter' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.scatter_plot(JEDI_omb, GSI_omb, obsvar, self.varname, inbound=True)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb_JEDIomb_Histogram' %(varname)
    title = '%s Histogram' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot2histogram(GSI_omb, JEDI_omb, name1='GSI omb', name2='JEDI omb')

   #------------------------------------------------------------------------------
    imgname = '%s_JEDIomb_Histogram' %(varname)
    title = '%s JEDIomb Histogram' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot_histograph(JEDI_omb)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb_Histogram' %(varname)
    title = '%s GSIomb Histogram' %(varname)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot_histograph(GSI_omb)

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  varname = 'brightness_temperature'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'varname='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--varname'):
      varname = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('varname = ', varname)

 #------------------------------------------------------------------------------
  sh = StatsHandler(debug=debug, output=output, varname=varname)
 #clevs = np.arange(-20.0, 20.5, 0.5)
 #cblevs = np.arange(-20.0, 22.0, 2.0)
  clevs = np.arange(-1.0, 1.1, 0.05)
  cblevs = np.arange(-1.0, 1.2, 0.2)
 #cmapname = 'bwr'
  cmapname = 'brg'
 #cmapname = 'YlGn'

  units = 'K'
  print('clevs = ', clevs)
  print('cblevs = ', cblevs)

  sh.plotit(clevs, cblevs, cmapname, units=units)

