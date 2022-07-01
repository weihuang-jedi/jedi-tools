#=========================================================================
import os
import matplotlib.pyplot as plt
from netCDF4 import Dataset as netcdf_dataset
import numpy as np

from cartopy import config
import cartopy.crs as ccrs

#=========================================================================
class PlotToolsWithCartopy():
  def __init__(self, debug=0, output=0, lat=[], lon=[]):
    self.debug = debug
    self.output = output
    self.lat = lat
    self.lon = lon

    self.set_default()
    self.set_grid(lat, lon)

  def simple_plot(self, lons, lats, var):
    ax = plt.axes(projection=ccrs.PlateCarree())

    plt.contourf(lons, lats, var, 60,
                 transform=ccrs.PlateCarree())

    ax.coastlines()

    plt.show()

# ----
if __name__ == '__main__':
  debug = 1
  output = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)

 #pt = PlotTools(debug=debug, output=output, lat=lat, lon=lon)
 #pt.plot(pvar)

