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
  def __init__(self, debug=0, output=0, varname='surface_pressure'):
    self.debug = debug
    self.output = output
    self.varname = varname

    if(self.debug):
      print('self.output = ', self.output)
      print('self.varname = ', self.varname)

    self.filename = 'sondes_stats/stats_gsiNjedi_%s_common.txt' %(varname)

    self.read_data(self.filename)

  def read_data(self, filename):
    with open(filename, 'r') as textreader:
      lines = textreader.readlines()

    self.latitude = []
    self.longitude = []
    self.pressure = []
    self.ObsValue = []
    self.GSI_HofX = []
    self.JEDI_HofX = []
    self.GSI_omb = []
    self.JEDI_omb = []
    self.GSI_ob_error = []
    self.JEDI_ob_error = []
    self.JEDI_hofx_y_mean_xb0 = []

    nlines = len(lines)
    for i in range(1, nlines):
      item = lines[i].split(', ')
      if('specific_humidity' == self.varname):
        omb = abs(float(item[6]))
        if(omb > 100.0):
          continue
        omb = abs(float(item[7]))
        if(omb > 100.0):
          continue
     #print('GSI_omb: %f, JEDI_omb: %f' %(float(item[6]), float(item[7])))
      self.latitude.append(float(item[0]))
      self.longitude.append(float(item[1]))
      self.pressure.append(float(item[2]))
      self.ObsValue.append(float(item[3]))
      self.GSI_HofX.append(float(item[4]))
      self.JEDI_HofX.append(float(item[5]))
      self.GSI_omb.append(float(item[6]))
      self.JEDI_omb.append(float(item[7]))
      self.GSI_ob_error.append(float(item[8]))
      self.JEDI_ob_error.append(float(item[9]))
      self.JEDI_hofx_y_mean_xb0.append(float(item[10]))

#------------------------------------------------------------------------------
  def plotpanel(self, clevs, cblevs, cmapname, prs, units='hPa', precision=1):
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

   #------------------------------------------------------------------------------
  
    img_label = '%s' %(self.varname)
    ttl_label = '%s' %(self.varname)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb_cdf' %(img_label)
    title = '%s GSIomb CDF' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.plot_cdf_panel(self.GSI_omb, self.pressure, prs)

   #------------------------------------------------------------------------------
    imgname = '%s_JEDIomb_cdf' %(img_label)
    title = '%s JEDIomb CDF' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.plot_cdf_panel(self.JEDI_omb, self.pressure, prs)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb-JEDIomb_cdf' %(img_label)
    title = '%s GSIomb-JEDIomb CDF' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)

    label = '%s GSI omb - JEDI omb, units: %s' %(ttl_label, units)
    pt.set_label(label)

    obsvar = np.array(self.GSI_omb) - np.array(self.JEDI_omb)

    pt.plot_cdf_panel(obsvar, self.pressure, prs)

   #------------------------------------------------------------------------------
    imgname = '%s_JEDIomb_Histogram' %(img_label)
    title = '%s JEDIomb Histogram' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot_histograph_panel(self.JEDI_omb, self.pressure, prs)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb_Histogram' %(img_label)
    title = '%s GSIomb Histogram' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot_histograph_panel(self.GSI_omb, self.pressure, prs)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb_JEDIomb_Histogram' %(img_label)
    title = '%s GSIomb-JEDIomb Histogram' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)
    pt.plot_histograph_panel(obsvar, self.pressure, prs)

    return

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb-JEDIomb' %(img_label)
    title = '%s GSIomb-JEDIomb' %(ttl_label)
    meangsiomb = np.mean(np.abs(GSI_omb))
    title = '%s mean(abs(GSIomb)): %f' %(title, meangsiomb)
    pt.set_imagename(imgname)
    pt.set_title(title)
  
    pt.obsonly(obslat, obslon, obsvar, inbound=True)

   #------------------------------------------------------------------------------
    imgname = '%s_GSIomb-JEDIomb_scatter' %(img_label)
    title = '%s GSIomb-JEDIomb Scatter' %(ttl_label)
    pt.set_imagename(imgname)
    pt.set_title(title)

    pt.scatter_plot(JEDI_omb, GSI_omb, obsvar, img_label, inbound=True)

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
 #varname = 'surface_pressure'
  varname = 'specific_humidity'

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
  clevs = np.arange(-1.0, 1.1, 0.1)
  cblevs = np.arange(-1.0, 1.5, 0.5)
 #cmapname = 'bwr'
  cmapname = 'brg'
 #cmapname = 'YlGn'

  if(varname == 'surface_pressure'):
    units = 'hPa'
    clevs = np.arange(-1.0, 1.1, 0.1)
    cblevs = np.arange(-1.0, 1.5, 0.5)
  elif((varname == 'air_temperature')
    or (varname == 'virtual_temperature')) :
    units = 'K'
    clevs = np.arange(-5.0, 5.2, 0.2)
    cblevs = np.arange(-5.0, 6.0, 1.0)
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

  prs = [100.0, 200.0, 300.0, 500.0, 700.0, 850.0, 1000.0]

  sh.plotpanel(clevs, cblevs, cmapname, prs, units=units)

