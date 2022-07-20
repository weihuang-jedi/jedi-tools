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

      for j in range(0, nlat, 10):
        for i in range(0, nlon, 10):
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

  def plotOnMapAtLat(self, latlist=[90]):
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

      for jlat in latlist:
        j = int(180+2*jlat)
        for i in range(nlon):
          x = lon[:, j, i]
          y = lat[:, j, i]
          self.basemap.plot(x, y)

   #m.drawcountries(zorder=0, color='gray')

    self.title = 'Trajectory at lat: ['

    for n in range(len(latlist)):
      if(n):
        self.title = '%s, %d' %(self.title, latlist[n])
      else:
        self.title = '%s%d' %(self.title, latlist[n])
    self.title = '%s]' %(self.title)

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

    self.plt.xlim((-90.0, 90.0))
    self.plt.ylim((0.0, 16000.0))

    major_ticks_top=np.linspace(-90,90,13)
    self.ax.set_xticks(major_ticks_top)

    major_ticks_top=np.linspace(0,16000,17)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(-90,90,37)
    self.ax.set_xticks(minor_ticks_top,minor=True)

    minor_ticks_top=np.linspace(0,16000,33)
    self.ax.set_yticks(minor_ticks_top,minor=True)

    self.ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    self.ax.grid(b=True, which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend()
    self.image_name = 'trajectory_lathgt_at_%d.png' %(int(ilon/2))
    self.display(output=self.output, image_name=self.image_name)

  def plotLonHgtAverageBetween(self, startlat=-90, endlat=90):
    self.plt = plt
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    ib = 20
    ie = 700

    jb = int(2*(90+startlat))
    je = int(2*(90+endlat)) + 1

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

      avglon = np.mean(lon[:,jb:je,ib:ie], axis=1)
      avghgt = np.mean(hgt[:,jb:je,ib:ie], axis=1)
      print('avglon.shape = ', avglon.shape)

      naltplt, nlonplt = avglon.shape
      for i in range(nlonplt):
        x = avglon[:, i]
        y = avghgt[:, i]
        self.plt.plot(x, y, '-o', markersize=2, markevery=x.size)

    self.title = 'Trajectory_between_Lat_%d, %d' %(startlat, endlat)

    self.ax.set_title(self.title)

    self.plt.xlim((0.0, 360.0))
    self.plt.ylim((0.0, 16000.0))

    major_ticks_top=np.linspace(0,360,25)
    self.ax.set_xticks(major_ticks_top)

    major_ticks_top=np.linspace(0,16000,17)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(0,360,73)
    self.ax.set_xticks(minor_ticks_top,minor=True)

    minor_ticks_top=np.linspace(0,16000,33)
    self.ax.set_yticks(minor_ticks_top,minor=True)

    self.ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    self.ax.grid(b=True, which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend()
    self.image_name = 'trajectory_lonhgt_avg_%d-%d.png' %(startlat, endlat)
    self.display(output=self.output, image_name=self.image_name)

  def plotLatHgtCrossingPole(self, ilon=1):
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

      i2 = ilon + int(nlon/2)
      if(i2 > nlon):
        i2 -= nlon

      print('nt = ', nt)
      print('nlon = ', nlon)
      print('nlat = ', nlat)

      for j in range(int(nlat/2), nlat):
        x = lat[:, j, i]
        y = hgt[:, j, i]
        self.plt.plot(x, y, '-o', markersize=2, markevery=x.size)

      for j in range(int(nlat/2), nlat):
        x = 180.0-lat[:, j, i2]
        y = hgt[:, j, i2]
        self.plt.plot(x, y, '-o', markersize=2, markevery=x.size)

    self.title = 'Trajectory_lon_%d' %(int(ilon/2))

    self.ax.set_title(self.title)

    self.plt.xlim((0.0, 180.0))
    self.plt.ylim((0.0, 16000.0))

    major_ticks_top=np.linspace(0,180,13)
    self.ax.set_xticks(major_ticks_top)

    major_ticks_top=np.linspace(0,16000,17)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(0,180,37)
    self.ax.set_xticks(minor_ticks_top,minor=True)

    minor_ticks_top=np.linspace(0,16000,33)
    self.ax.set_yticks(minor_ticks_top,minor=True)

    self.ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    self.ax.grid(b=True, which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend()
    self.image_name = 'trajectory_lathgt_crosspole_%d.png' %(int(ilon/2))
    self.display(output=self.output, image_name=self.image_name)

  def plotLatHgtAverageBetween(self, startlon=0, endlon=360):
    self.plt = plt
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    ib = int(2*startlon)
    ie = int(2*endlon)

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

      avglat = np.mean(lat[:,:,ib:ie], axis=2)
      avghgt = np.mean(hgt[:,:,ib:ie], axis=2)
      print('avglat.shape = ', avglat.shape)

      for j in range(nlat):
        x = avglat[:, j]
        y = avghgt[:, j]
        self.plt.plot(x, y, '-o', markersize=2, markevery=x.size)

    self.title = 'Trajectory_between_Lon_%d, %d' %(startlon, endlon)

    self.ax.set_title(self.title)

    self.plt.xlim((-90.0, 90.0))
    self.plt.ylim((0.0, 16000.0))

    major_ticks_top=np.linspace(-90,90,13)
    self.ax.set_xticks(major_ticks_top)

    major_ticks_top=np.linspace(0,16000,17)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(-90,90,37)
    self.ax.set_xticks(minor_ticks_top,minor=True)

    minor_ticks_top=np.linspace(0,16000,33)
    self.ax.set_yticks(minor_ticks_top,minor=True)

    self.ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    self.ax.grid(b=True, which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend()
    self.image_name = 'trajectory_lathgt_avg_%d-%d.png' %(startlon, endlon)
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

    major_ticks_top=np.linspace(0,10000,11)
    self.ax.set_yticks(major_ticks_top)

    minor_ticks_top=np.linspace(0,360,37)
    self.ax.set_xticks(minor_ticks_top,minor=True)

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

  filelist = ['trajectory_1000m.nc', 'trajectory_3000m.nc',
              'trajectory_5000m.nc', 'trajectory_7000m.nc',
              'trajectory_9000m.nc', 'trajectory_11000m.nc',
              'trajectory_13000m.nc', 'trajectory_15000m.nc']

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

 #pt = PlotTrajectory(debug=debug, output=output, filelist=filelist[0:11:2])
  pt = PlotTrajectory(debug=debug, output=output, filelist=filelist[0:2])
 #pt = PlotTrajectory(debug=debug, output=output, filelist=filelist[3:4:2])
 #pt = PlotTrajectory(debug=debug, output=output, filelist=filelist[2:3])

 #pt.plotOnMap()
 #pt.plotOnMapAtLat(latlist=[-30, -15, 0, 15, 30])

  pt.plotLonHgtAverageBetween(startlat=-10, endlat=10)
  pt.plotLonHgtAverageBetween(startlat=-5, endlat=5)
  pt.plotLonHgtAverageBetween(startlat=-2, endlat=2)

  for j in [-10, -5, 0, 5, 10]:
    jlat = 2*(j+90)
    pt.plotLonHgt(jlat=jlat)

 #for i in [0, 90, 160, 180, 200, 225, 270]:
 #for i in [0, 180]:
 #  ilon = 2*i
 #  pt.plotLatHgt(ilon=ilon)

 #pt.plotLatHgtAverageBetween(startlon=0, endlon=360)
 #pt.plotLatHgtAverageBetween(startlon=0, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=90, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=120, endlon=180)

 #pt.plotLatHgtAverageBetween(startlon=150, endlon=210)
 #pt.plotLatHgtAverageBetween(startlon=150, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=180, endlon=210)

 #pt.plotLatHgtAverageBetween(startlon=160, endlon=200)
 #pt.plotLatHgtAverageBetween(startlon=160, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=180, endlon=200)

 #pt.plotLatHgtAverageBetween(startlon=170, endlon=190)
 #pt.plotLatHgtAverageBetween(startlon=170, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=180, endlon=190)

  pt.plotLatHgtAverageBetween(startlon=175, endlon=185)
 #pt.plotLatHgtAverageBetween(startlon=175, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=180, endlon=185)

 #pt.plotLatHgtAverageBetween(startlon=178, endlon=182)
 #pt.plotLatHgtAverageBetween(startlon=178, endlon=180)
 #pt.plotLatHgtAverageBetween(startlon=180, endlon=182)

 #for i in [0, 45, 90, 120, 135]:
  for i in [0]:
    ilon = 2*i
    pt.plotLatHgtCrossingPole(ilon=ilon)

