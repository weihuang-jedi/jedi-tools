#============================================================================================================

import netCDF4
import os
import sys
import types

import numpy as np

#--------------------------------------------------------------------------------------------
class TileInfo():
  def __init__(self, grid_res='C96'):
    self.grid_res=grid_res
    print('grid_res = ', grid_res)

  def get_latlon_location(self, tile=4, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91]):
    grid_path = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/' + self.grid_res

    ncfilename = os.path.join(grid_path, '%s_grid_spec.tile%d.nc' % (self.grid_res, tile))
    ncfile = netCDF4.Dataset(ncfilename, 'r')

    lat2d = ncfile.variables['grid_latt'][:]
    lon2d = ncfile.variables['grid_lont'][:]

    msg = ('Lat coordinate range: (%s, %s).' % (lat2d.min(), lat2d.max()))
    print(msg)
    msg = ('Lon coordinate range: (%s, %s).' % (lon2d.min(), lon2d.max()))
    print(msg)

    ny, nx = lat2d.shape

    print('lat2d.shape = ', lat2d.shape)
   #print('lat2d = ', lat2d)

    ncfile.close()

    print('nx = ', nx)
    print('ny = ', ny)

    nc = int(ny/2)

    print('nc = ', nc)

    lat1d = []
    lon1d = []
    for n in xloc:
      print('No. %d: (lat, lon) = (%f, %f)' %(n, lat2d[nc][n], lon2d[nc][n]))
      lat1d.append(lat2d[nc][n])
      lon1d.append(lon2d[nc][n])

    print('\n\n')
    print('lat = ', lat1d)
    print('lon = ', lon1d)
    print('\n\n')

   #lat1d = []
   #lon1d = []
   #nc = int(nx/2)
   #for n in yloc:
   #  print('No. %d: (lat, lon) = (%f, %f)' %(n, lat2d[n][nc], lon2d[n][nc]))
   #  lat1d.append(lat2d[n][nc])
   #  lon1d.append(lon2d[n][nc])

   #print('\n\n')
   #print('lat = ', lat1d)
   #print('lon = ', lon1d)

    return lat2d, lon2d

  def get_data(self, lat, lon, xloc=[5, 26, 48, 70, 91], yloc=[5, 26, 48, 70, 91], filename=None, varname='T'):
    if(filename is None):
      print('filename is None. Stop.')
      sys.exit(-1)

    if(not os.path.exists(filename)):
      print('filename %s doest not exist. Stop.' %(filename))
      sys.exit(-1)

    ncfile = netCDF4.Dataset(filename, 'r')

    var = ncfile.variables[varname][0,:,:,:]
    delp = ncfile.variables['delp'][0,:,:,:]

    msg = ('Lat coordinate range: (%s, %s).' % (var.min(), var.max()))
    print(msg)

    nz, ny, nx = var.shape

    print('var.shape = ', var.shape)
   #print('var = ', var)

    ncfile.close()

    print('nx = ', nx)
    print('ny = ', ny)
    print('nz = ', nz)

    nc = int(ny/2)

    print('nc = ', nc)

    for n in xloc:
      print('xloc: ', n)
      print('lat: %f, lon: %f' %(lat[nc][n], lon[nc][n]))
      prs = 0.0
      for k in range(nz):
        m = nz-1-k
        prs = prs + delp[m][nc][n]
        print('Level %d: prs = %f, %s = %f' %(k, prs, varname, var[k][nc][n]))

   #for n in yloc:
   #  print('yloc: ', n)
   #  print('lat: %f, lon: %f' %(lat[n][nc], lon[n][nc]))
   #  prs = 0.0
   #  for k in range(nz):
   #    m = nz-1-k
   #    prs = prs + delp[m][n][nc]
   #    print('Level %d: prs = %f, %s = %f' %(k, prs, varname, var[k][n][nc]))

#--------------------------------------------------------------------------------------------
if __name__ == '__main__':
  xloc=[5, 26, 48, 70, 91]
  yloc=[5, 26, 48, 70, 91]

  ti = TileInfo(grid_res='C96')
  lat, lon = ti.get_latlon_location(tile=4, xloc=xloc, yloc=yloc)

  filename = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/Data/bkg/fv_core.res.tile4.nc'
  ti.get_data(lat, lon, xloc=xloc, yloc=xloc, filename=filename, varname='T')

