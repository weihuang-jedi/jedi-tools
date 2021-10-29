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
  def __init__(self, debug=0, output=0, filename=None):
    self.debug = debug
    self.output = output
    self.filename = filename

    if(self.debug):
      print('self.output = ', self.output)
      print('self.filename = ', self.filename)

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
      self.EffectiveError0.append(float(item[10]))
     #info = item[10].split(',')
     #self.EffectiveError0.append(float(info[0]))

  def get_omb(self):
    return self.latitude, self.longitude, self.GSI_omb, self.JEDI_omb

  def get_HofX(self):
    return self.latitude, self.longitude, self.GSI_HofX, self.JEDI_HofX

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
  filename = 'gsiNjedi_stats.txt'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'filename='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--filename'):
      filename = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('filename = ', filename)

  sh = StatsHandler(debug=debug, output=output, filename=filename)

  obslat, obslon, GSI_HofX, JEDI_HofX = sh.get_HofX()

#------------------------------------------------------------------------------
  nlon = 360
  nlat = nlon/2 + 1
  dlon = 360.0/nlon
  dlat = 180.0/(nlat - 1)
  lon = np.arange(0.0, 360.0, dlon)
  lat = np.arange(-90.0, 90.0+dlat, dlat)

#------------------------------------------------------------------------------
  pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)

 #clevs = np.arange(-20.0, 20.5, 0.5)
 #cblevs = np.arange(-20.0, 22.0, 2.0)
  clevs = np.arange(-2.0, 2.1, 0.1)
  cblevs = np.arange(-2.0, 3.0, 1.0)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)
  pt.set_precision(precision=0)
 #pt.set_cmapname('bwr')
  pt.set_cmapname('brg')
 #pt.set_cmapname('YlGn')

 #print('clevs = ', clevs)
 #print('cblevs = ', cblevs)

  pt.set_label('JEDI HofX - GSI HofX, Surface Pressure (hPa)')

  imgname = 'JEDI_HofX-GSI_HofX_sondes_obs_ps_only'
  title = 'JEDI_HofX-GSI_HofX Sondes Surface Pressure OBS (only)'

  obsvar = np.array(JEDI_HofX) - np.array(GSI_HofX)

  meangsi_HofX = np.mean(np.abs(GSI_HofX))

  title = '%s mean(abs(GSI_HofX)): %f' %(title, meangsi_HofX)

 #meanjedi_HofX = np.mean(np.abs(GSI_HofX))
 #print('mean(abs(JEDI_HofX)): %f' %(meanjedi_HofX))
 #print('JEDI_HofX = ', JEDI_HofX)

  pt.set_imagename(imgname)
  pt.set_title(title)
  
 #pt.obsonly2(obslat, obslon, obsvar, inbound=True, vm=100.0)
  pt.obsonly(obslat, obslon, obsvar, inbound=True)

  clevs = np.arange(-2.0, 2.1, 0.1)
  cblevs = np.arange(-2.0, 3.0, 1.0)
  pt.set_clevs(clevs=clevs)
  pt.set_cblevs(cblevs=cblevs)

  imgname = 'JEDI_HofX-GSI_HofX_sondes_obs_ps_only_scatter'
  title = 'JEDI_HofX-GSI_HofX Sondes Surface Pressure OBS (only)'
  pt.set_imagename(imgname)
  pt.set_title(title)
 #pt.set_cmapname('rainbow')
  pt.set_cmapname('brg')

  pt.scatter_plot2(GSI_HofX, JEDI_HofX, obsvar, inbound=True, vm=50.0)

