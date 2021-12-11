#==================================================================================
import os
import sys
import math
import getopt
import netCDF4

import numpy as np
import matplotlib.pyplot as plt

from mpl_toolkits.basemap import Basemap

#==================================================================================
class PlotTrajectory():
  def __init__(self, debug=0, output=0, filelist=[]):
    self.debug = debug
    self.output = output
    self.filelist = filelist

    if(self.debug):
      print('debug = ', debug)

    if(self.debug > 10):
      print('self.filelist = ', self.filelist)

  def create_image(self, plt_obj, savename):
    msg = ('Saving image as %s.' % savename)
    print(msg)
    kwargs = {'transparent': True, 'dpi': 500}
    plt_obj.savefig(savename, **kwargs)

  def display(self, output=False, image_name=None):
    if(output):
      if(image_name is None):
        image_name=self.image_name
      self.plt.tight_layout()
      kwargs = {'plt_obj': self.plt, 'savename': image_name}
      self.create_image(**kwargs)
    else:
      self.plt.show()

  def set_imagename(self, imagename):
    self.image_name = imagename

  def get_basemap(self):
    basemap_dict = {'resolution': 'c', 'projection': 'cyl',
                    'llcrnrlat': -90.0, 'llcrnrlon': 0.0,
                    'urcrnrlat':  90.0, 'urcrnrlon': 360.0}
    basemap_dict['lat_0'] = 0.0
    basemap_dict['lon_0'] = 180.0

    basemap = Basemap(**basemap_dict)

    return basemap

  def plot_coast_lat_lon_line(self):
   #https://matplotlib.org/basemap/users/geography.html
   #map.drawmapboundary(fill_color='aqua')
   #map.fillcontinents(color='#cc9955', lake_color='aqua')
   #map.drawcounties()
   #map.drawstates(color='0.5')

   #draw coastlines
    color = 'black'
    linewidth = 0.5
    self.basemap.drawcoastlines(color=color, linewidth=linewidth)

   #draw parallels
    color = 'green'
    linewidth = 0.5
    fontsize = 8
    dashes = [10, 10]
    circles = np.arange(-90,90,30)
    self.basemap.drawparallels(np.arange(-90,90,30),labels=[1,1,0,1],
                               color=color, linewidth=linewidth,
                               dashes=dashes, fontsize=fontsize)

   #draw meridians
    color = 'green'
    linewidth = 0.5
    fontsize = 8
    dashes = [10, 10]
    meridians = np.arange(0,360,30)
    self.basemap.drawmeridians(np.arange(0,360,30),labels=[1,1,0,1],
                               color=color, linewidth=linewidth,
                               dashes=dashes, fontsize=fontsize)

  def plotOnMap(self):
    self.plt = plt
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    self.fig = self.plt.figure()
    self.ax = self.plt.subplot()

    self.basemap = self.get_basemap()

    for filename in self.filelist:
      print('Working on file: ', filename)
      ncfile = netCDF4.Dataset(filename, 'r')
      lon = ncfile.variables['x'][:,:,:]
      lat = ncfile.variables['y'][:,:,:]
      hgt = ncfile.variables['z'][:,:,:]
      ncfile.close()

      nt, nlat, nlon = lon.shape

      print('nt = ', nt)
      print('nlon = ', nlon)
      print('nlat = ', nlat)

      for j in range(nlat):
        for i in range(nlon):
          x = lon[:, j, i]
          y = lat[:, j, i]
          self.basemap.plot(x, y)

   #m.drawcountries(zorder=0, color='gray')

    self.title = 'Trajectory'

    self.ax.set_title(self.title)
    self.plot_coast_lat_lon_line()

   #self.plt.legend()
    self.image_name = 'trajectory_latlon.png'
    self.display(output=self.output, image_name=self.image_name)

  def plotLatHgt(self, ilon=1):
    self.plt = plt
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    i = ilon

    self.fig = self.plt.figure()
    self.ax = self.plt.subplot()

    for filename in self.filelist:
      print('Working on file: ', filename)
      ncfile = netCDF4.Dataset(filename, 'r')
      lon = ncfile.variables['x'][:,:,:]
      lat = ncfile.variables['y'][:,:,:]
      hgt = ncfile.variables['z'][:,:,:]
      ncfile.close()

      nt, nlat, nlon = lon.shape

      print('nt = ', nt)
      print('nlon = ', nlon)
      print('nlat = ', nlat)

      for j in range(nlat):
        x = lat[:, j, i]
        y = hgt[:, j, i]
        self.plt.plot(x, y, '-o', markersize=2, markevery=x.size)

    self.title = 'Trajectory_lon_%d' %(int(ilon/2))

    self.ax.set_title(self.title)

    major_ticks_top=np.linspace(-90,90,7)
    self.ax.set_xticks(major_ticks_top)

   #major_ticks_top=np.linspace(0,55000,12)
    major_ticks_top=np.linspace(0,10000,11)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(-90,90,19)
    self.ax.set_xticks(minor_ticks_top,minor=True)

   #minor_ticks_top=np.linspace(0,51000,51)
    minor_ticks_top=np.linspace(0,10000,21)
    self.ax.set_yticks(minor_ticks_top,minor=True)

    self.ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    self.ax.grid(b=True, which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend()
    self.image_name = 'trajectory_lathgt.png'
    self.display(output=self.output, image_name=self.image_name)

  def plotLonHgt(self, jlat=1):
    self.plt = plt
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    j = jlat

    self.fig = self.plt.figure()
    self.ax = self.plt.subplot()

    for filename in self.filelist:
      print('Working on file: ', filename)
      ncfile = netCDF4.Dataset(filename, 'r')
      lon = ncfile.variables['x'][:,:,:]
      lat = ncfile.variables['y'][:,:,:]
      hgt = ncfile.variables['z'][:,:,:]
      ncfile.close()

      nt, nlat, nlon = lon.shape

      print('nt = ', nt)
      print('nlon = ', nlon)
      print('nlat = ', nlat)

      for i in range(nlon):
        x = lon[:, j, i]
        y = hgt[:, j, i]
        self.plt.plot(x, y, '-o', markersize=2, markevery=x.size)

    wlat = int(jlat/2 - 90)

    if(wlat < 0):
      self.title = 'Trajectory_lat_%dS' %(-wlat)
    elif(wlat > 0):
      self.title = 'Trajectory_lat_%dN' %(wlat)
    else:
      self.title = 'Trajectory_lat_%d' %(wlat)

    self.ax.set_title(self.title)

    major_ticks_top=np.linspace(0,360,13)
    self.ax.set_xticks(major_ticks_top)

   #major_ticks_top=np.linspace(0,55000,12)
    major_ticks_top=np.linspace(0,10000,11)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(0,360,37)
    self.ax.set_xticks(minor_ticks_top,minor=True)

   #minor_ticks_top=np.linspace(0,51000,51)
    minor_ticks_top=np.linspace(0,10000,21)
    self.ax.set_yticks(minor_ticks_top,minor=True)

    self.ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    self.ax.grid(b=True, which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend()
    self.image_name = 'trajectory_lathgt.png'
    self.display(output=self.output, image_name=self.image_name)

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0

 #filelist = ['trajectory_2000m.nc']
  filelist = ['trajectory_500m.nc',  'trajectory_1000m.nc',
              'trajectory_2000m.nc', 'trajectory_3000m.nc',
              'trajectory_4000m.nc', 'trajectory_5000m.nc',
              'trajectory_6000m.nc', 'trajectory_7000m.nc',
              'trajectory_8000m.nc', 'trajectory_9000m.nc']

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'filelist='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--filelist'):
      filelist = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('filelist = ', filelist)

  pt = PlotTrajectory(debug=0, output=0, filelist=filelist)

 #pt.plotOnMap()

 #for i in [0, 90, 180, 270]:
 #  ilon = 2*i
 #  pt.plotLatHgt(ilon=ilon)

  for j in [-60, -30, 0, 30, 60]:
    jlat = 2*(j+90)
    pt.plotLonHgt(jlat=jlat)

