import sys
import numpy as np
from netCDF4 import Dataset

class ReadOceanLatLonData():
  def __init__(self, debug=0, datafile=None):
    self.debug = debug
    self.datafile = datafile

    if(self.debug):
      print('debug = ', debug)

    self.lat1d, self.lon1d = self.get_latlon()

  def get_latlon(self):
    print('reading ', self.datafile)
    nc = Dataset(self.datafile)
    lon = nc.variables['lon'][:]
    lat = nc.variables['lat'][:]

    print('lon.ndim=', lon.ndim)
    print('lon.size=', lon.size)
    print('lon.shape=', lon.shape)

    print('lat.ndim=', lat.ndim)
    print('lat.size=', lat.size)
    print('lat.shape=', lat.shape)

    nx, = lon.shape
    ny, = lat.shape

    print('nx = ', nx)
    print('ny = ', ny)

    lats = np.zeros((ny, nx), dtype=float)
    lons = np.zeros((ny, nx), dtype=float)

    for j in range(ny):
      for i in range(nx):
        lats[j,i] = lat[j]
        lons[j,i] = lon[i]

    print('lons[0,:] = ', lons[0,:])
    print('lats[:,0] = ', lats[:,0])

    nc.close()

    lon1d = np.reshape(lons, (nx*ny,))
    lat1d = np.reshape(lats, (nx*ny,))

   #print('len(lon1d) = ', len(lon1d))

    return lat1d, lon1d

  def read3Dvar(self,varname,ntime=0):
    """
    read FV3 cubed sphere 3D data.

    datafile : data filename
    varname : var name to read from data file

    returns data array"""

    data = None
    print('reading ', self.datafile)
    print('varname ', varname)
    nc = Dataset(self.datafile)
    data = nc.variables[varname][ntime,:,:,:]

    print('data.ndim=', data.ndim)
    print('data.shape=', data.shape)
    print('data.size=', data.size)

    nc.close()

    return data

  def get_level(self, data, it=0, level=0):
    if(3 == data.ndim):
      nz, ny, nx = data.shape
      var2d = data[level,:,:]
    else:
      nt, nz, ny, nx = data.shape
      var2d = data[it,level,:,:]

    var1d = var2d.reshape((ny*nx))
   #print('len(var1d) = ', len(var1d))
    return var1d

#----------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  datadir = '/work2/noaa/gsienkf/weihuang/jedi/singleobs/sst/soca_solver.20t4n_80p'

  datafile = '%s/ocn.LETKF.an.2015-12-01T12:00:00Z.nc' %(datadir)
