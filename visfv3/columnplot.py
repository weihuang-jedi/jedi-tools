#=============================================================================================
import os
import sys
import getopt
import netCDF4

import numpy as np
import matplotlib.pyplot
#import matplotlib.pyplot as plt

#=============================================================================================
class ColumnPlot():
  def __init__(self, debug=0, output=0, grid_res='C96'):
    self.debug = debug
    self.output = output
    self.grid_res = grid_res

    self.prefix = 'ori'
   #self.prefix = 'new'
   #----------------------------------------------------------------------------------------
    self.markpres = [1000.0, 700.0, 500.0, 200.0, 100.0,
                     50.0, 30.0, 20.0, 10.0, 5.0]
                    #50.0, 30.0, 20.0, 10.0, 5.0, 3.0, 2.0, 1.0]

    self.marklogp = -np.log(self.markpres)

  def set_prefix(self, prefix='ori'):
    self.prefix = prefix

  def get_logp(self, pres):
    parr = 0.01*np.array(pres)
    logp = -np.log(parr)
    return logp

  def set_grid_res(self, grid_res='C96'):
    self.grid_res=grid_res
    print('grid_res = ', grid_res)

  def get_latlon_location(self, tile=4, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91]):
    grid_path = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/' + self.grid_res

    ncfilename = os.path.join(grid_path, '%s_grid_spec.tile%d.nc' % (self.grid_res, tile))
    ncfile = netCDF4.Dataset(ncfilename, 'r')

    lat2d = ncfile.variables['grid_latt'][:]
    lon2d = ncfile.variables['grid_lont'][:]

   #msg = ('Lat coordinate range: (%s, %s).' % (lat2d.min(), lat2d.max()))
   #print(msg)
   #msg = ('Lon coordinate range: (%s, %s).' % (lon2d.min(), lon2d.max()))
   #print(msg)

    ny, nx = lat2d.shape

   #print('lat2d.shape = ', lat2d.shape)
   #print('lat2d = ', lat2d)

    ncfile.close()

    print('nx = ', nx)
    print('ny = ', ny)

    lat1d = []
    lon1d = []
    for n in range(len(xloc)):
      i = xloc[n]
      j = yloc[n]
      print('No. %d: (lat, lon) = (%f, %f)' %(n, lat2d[j][i], lon2d[j][i]))
      lat1d.append(lat2d[j][i])
      lon1d.append(lon2d[j][i])

   #print('\n')
   #print('lat = ', lat1d)
   #print('lon = ', lon1d)

    return lat1d, lon1d

  def get_prs(self, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91], filename=None):
    if(filename is None):
      print('filename is None. Stop.')
      sys.exit(-1)

    if(not os.path.exists(filename)):
      print('filename %s doest not exist. Stop.' %(filename))
      sys.exit(-1)

    ncfile = netCDF4.Dataset(filename, 'r')

    delp = ncfile.variables['delp'][0,:,:,:]

    nz, ny, nx = delp.shape

   #print('var.shape = ', var.shape)
   #print('var = ', var)

    ncfile.close()

   #print('nx = ', nx)
   #print('ny = ', ny)
    print('nz = ', nz)

    parr = []

    for n in range(len(xloc)):
      i = xloc[n]
      j = yloc[n]
      pcol = []
      prs = 0.0
      for k in range(nz):
        m = nz-1-k
        prs = prs + delp[m][j][i]
       #print('Level %d: prs = %f, %s = %f' %(k, prs))
        pcol.append(prs)
      parr.append(pcol)

    return parr

  def get_data(self, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91], filename=None, varname='T'):
    if(filename is None):
      print('filename is None. Stop.')
      sys.exit(-1)

    if(not os.path.exists(filename)):
      print('filename %s doest not exist. Stop.' %(filename))
      sys.exit(-1)

    ncfile = netCDF4.Dataset(filename, 'r')

    var = ncfile.variables[varname][0,:,:,:]

   #msg = ('Lat coordinate range: (%s, %s).' % (var.min(), var.max()))
   #print(msg)

    nz, ny, nx = var.shape

   #print('var.shape = ', var.shape)
   #print('var = ', var)

    ncfile.close()

   #print('nx = ', nx)
   #print('ny = ', ny)
   #print('nz = ', nz)

    varr = []
    for n in range(len(xloc)):
      i = xloc[n]
      j = yloc[n]
      vcol = []
      for k in range(nz):
       #print('Level %d: %s = %f' %(k, varname, var[k][j][i]))
        vcol.append(var[k][j][i])
      varr.append(vcol)

    return varr

  def plot_level(self, n, prs, var, lat, lon, lblprs):
    self.plt = matplotlib.pyplot
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    self.fig = self.plt.figure()
   #self.ax = self.plt.subplot()

    nz = len(prs)

   #print('nz = ', nz)

    y = np.arange(0.0, float(nz), 1.0)

    self.plt.plot(var, y,
             color='blue',
             linewidth=1.5,
             linestyle='--')

    self.plt.xlim((-1.0, 1.0))  
    self.plt.ylim((0, nz-1))  

    ax = self.plt.gca()
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')

    title = '%s Temperature Increment' %(self.prefix)
    self.plt.title(title, fontsize=10)

    xlabel = 'Obs at (lat %f, lon %f), prs ' %(lat, lon)
    for p in lblprs:
      xlabel = '%s %f' %(xlabel, p)
    self.plt.xlabel(xlabel, fontsize=10)
    self.plt.ylabel('Level', fontsize=14)
    self.plt.grid(True)

   #self.plt.legend(['Temperature'])

    imgname = '%s_level_plot_%d.png' %(self.prefix, n)

    if(self.output):
      self.plt.savefig(imgname)
    else:
      self.plt.show()

  def plot_logp(self, n, logp, var, lat, lon, lblprs):
    self.plt = matplotlib.pyplot
    try:
      self.plt.close('all')
      self.plt.clf()
    except Exception:
      pass

    self.fig = self.plt.figure()
    self.ax = self.plt.subplot()

    nz = len(prs)

   #print('nz = ', nz)

    y = np.arange(0.0, float(nz), 1.0)

    self.plt.plot(var[::-1], logp[::-1],
             color='blue',
             linewidth=1.5,
             linestyle='--')

    self.plt.xlim((-0.5, 0.5))  
    self.plt.ylim((-np.log(self.markpres[-1]), 0))  

    ax = self.plt.gca()
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')

    title = '%s Temperature Increment' %(self.prefix)
    self.plt.title(title, fontsize=10)

    xlabel = 'Obs at (lat %f, lon %f), prs ' %(lat, lon)
    for p in lblprs:
      xlabel = '%s %f' %(xlabel, p)
    self.plt.xlabel(xlabel, fontsize=10)
    self.plt.ylabel('hPa', fontsize=14)

    major_ticks_top=np.linspace(-0.5,0.5,11)
    ax.set_xticks(major_ticks_top)

    minor_ticks_top=np.linspace(-0.5,0.5,51)
    ax.set_xticks(minor_ticks_top,minor=True)
   #ax.set_xlabel('Temperature (K)')
    ax.set_xlabel(xlabel)

    ax.set_yticks(self.marklogp)
    ax.set_ylabel('Unit: hPa')

    yticklabels = []
    for p in self.markpres:
      lbl = '%d' %(int(p+0.1))
      yticklabels.append(lbl)
    ax.set_yticklabels(yticklabels)

    ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
    ax.grid(b=True, axis='x', which='minor', color='green', linestyle='dotted', alpha=0.2)

   #self.plt.legend(['Temperature'])

    imgname = '%s_logp_plot_%d.png' %(self.prefix, n)

    if(self.output):
      self.plt.savefig(imgname)
    else:
      self.plt.show()

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0
 #prefix = 'ori'
  prefix = 'new'
  grid_res='C96'

  dirname = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/Data/bkg'
  basefile = '%s/fv_core.res.tile4.nc' %(dirname)

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--prefix'):
      prefix = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)
  print('prefix = ', prefix)

  xloc=[ 5, 26, 48, 70, 91]
  yloc=[48, 48, 48, 48, 48]

  casedir = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/manual-obs'
  dirname = '%s/analysis.getkf.80members.36procs.%s/increment' %(casedir, prefix)
  filename = '%s/20210109.000000.fv_core.res.tile4.nc' %(dirname)

  cp = ColumnPlot(debug=debug, output=output, grid_res='C96')
  cp.set_prefix(prefix=prefix)
  lats, lons = cp.get_latlon_location(tile=4, xloc=xloc, yloc=yloc)
  prs = cp.get_prs(xloc=xloc, yloc=yloc, filename=basefile)
  var = cp.get_data(xloc=xloc, yloc=yloc, filename=filename, varname='T')

  lblprs = [[85747.271484], [70101.424133], [1834.698181, 52426.719421, 93019.151550], [25504.405884], [11484.429932]]

 #print('prs = ', prs)
 #print('var = ', var)

  for n in range(len(xloc)):
    cp.plot_level(n, prs[n], var[n], lats[n], lons[n], lblprs[n])

    p = prs[n]
    v = var[n]
    logp = cp.get_logp(p)
    cp.plot_logp(n, logp, v, lats[n], lons[n], lblprs[n])

