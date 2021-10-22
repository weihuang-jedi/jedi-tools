#============================================================================================================

import netCDF4
import os
import sys
import types

import numpy as np

#--------------------------------------------------------------------------------------------
class TileInfo():
  def __init__(self, grid_res='C96'):
   #self.grid_dir='/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid'
    self.grid_dir='/scratch2/BMC/gsienkf/Wei.Huang/jedi/oldvis/UFS-RNR-tools/JEDI.FV3-increments/grid'
    self.grid_res=grid_res
    print('grid_res = ', grid_res)

  def get_latlon_location(self, tile=4, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91]):
   #grid_path = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/' + self.grid_res
   #ncfilename = os.path.join(grid_path, '%s_grid_spec.tile%d.nc' % (self.grid_res, tile))

    ncfilename = '%s/%s/%s_grid_spec.tile%d.nc' % (self.grid_dir, self.grid_res, self.grid_res, tile)
    ncfile = netCDF4.Dataset(ncfilename, 'r')

    lat2d = ncfile.variables['grid_latt'][:]
    lon2d = ncfile.variables['grid_lont'][:]

    msg = ('Lat coordinate range: (%s, %s).' % (lat2d.min(), lat2d.max()))
    print(msg)
    msg = ('Lon coordinate range: (%s, %s).' % (lon2d.min(), lon2d.max()))
    print(msg)

    ny, nx = lat2d.shape

   #print('nx = ', nx)
   #print('ny = ', ny)

   #print('lat2d.shape = ', lat2d.shape)
   #print('lat2d = ', lat2d)

    ncfile.close()

    return lat2d, lon2d

  def get_data(self, lat, lon, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91], filename=None):
    if(filename is None):
      print('filename is None. Stop.')
      sys.exit(-1)

    if(not os.path.exists(filename)):
      print('filename %s doest not exist. Stop.' %(filename))
      sys.exit(-1)

    ncfile = netCDF4.Dataset(filename, 'r')

    u = ncfile.variables['ua'][0,:,:,:]
    v = ncfile.variables['va'][0,:,:,:]
    t = ncfile.variables['T'][0,:,:,:]
    delp = ncfile.variables['delp'][0,:,:,:]

    ncfile.close()

    msg = ('Lat coordinate range: (%s, %s).' % (var.min(), var.max()))
    print(msg)

    nz, ny, nx = t.shape

    print('nx = ', nx)
    print('ny = ', ny)
    print('nz = ', nz)

    for n in len(xloc):
      i = xloc[n]
      j = yloc[n]
      print('lat: %f, lon: %f' %(lat[j][i], lon[j][i]))
      prs = 0.0
      for k in range(nz):
        m = nz-1-k
        prs = prs + delp[m][nc][n]
        print('Level %d: prs = %f8.2, u = %f6.2, v = %f' %(k, prs, u[k][j][i], v[k][j][i], t[k][j][i]))

#--------------------------------------------------------------------------------------------
if __name__ == '__main__':
  xloc=[48, 48, 48, 48, 48]
  yloc=[ 5, 26, 48, 70, 91]
  tile=4

  ti = TileInfo(grid_res='C96')
  lat, lon = ti.get_latlon_location(tile=tile, xloc=xloc, yloc=yloc)

 #dirname = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/Data/bkg'
  dirname = '/scratch2/BMC/gsienkf/Wei.Huang/jedi/run/case_study/Data/bkg'
  filename = '%s/fv_core.res.tile%d.nc' %(dirname, tile)
  ti.get_data(lat, lon, xloc=xloc, yloc=xloc, filename=filename, varname='T')

