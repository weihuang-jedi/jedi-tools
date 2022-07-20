import sys
import numpy as np
import matplotlib.pyplot as plt
from netCDF4 import Dataset
from mpl_toolkits.basemap import Basemap
from scipy.interpolate import griddata as regridder

class RegridOcean():
  def __init__(self, debug=0, datafile=None, gridspecfile=None):
    self.debug = debug
    self.gridspecfile = gridspecfile
    self.datafile = datafile

    if(self.debug):
      print('debug = ', debug)

    self.lat1d, self.lon1d = self.get_GridSpec_latlon()

  def setDataFiles(self, datafile=None):
    self.datafile = datafile

  def interp_to_latlon(self, var1d, nlon=360, nlat=181, method='linear'):
    '''
    Interpolate a variable on cube-sphere grid (such as FV3) to LatLon grid
    '''
    dlon = 360.0/nlon
    dlat = 180.0/(nlat - 1)
   #Create a lat-lon uniform grid
    out_lon = np.arange(0.0, 360.0, dlon)
    out_lat = np.arange(-90.0, 91.0, dlat)
    lon, lat = np.meshgrid(out_lon, out_lat)

   #print('out_lon.size = ', out_lon.size)
   #print('lon.size = ', lon.size)

   #print('lon1d.ndim = ', lon1d.ndim)
   #print('lon1d.size = ', lon1d.size)
   #print('lon1d.shape = ', lon1d.shape)

   #print('var1d.ndim = ', var1d.ndim)
   #print('var1d.size = ', var1d.size)
   #print('var1d.shape = ', var1d.shape)

    # Interpolate from cube to lat-lon grid
    out_var = regridder((self.lon1d,self.lat1d), var1d,
                        (lon,lat), method=method)

    nlen = int(nlon*nlat)
   #print('nlen = ', nlen)
   #print('lon.size = ', lon.size)
    olon = np.reshape(lon, (nlen, ))
    olat = np.reshape(lat, (nlen, ))
    ovar = np.reshape(out_var, (nlen, ))

    olat = olat[~np.isnan(ovar)]
    olon = olon[~np.isnan(ovar)]
    ovar = ovar[~np.isnan(ovar)]

   #Fill in extrapolated values with nearest neighbor
    out_var = regridder((olon,olat), ovar,
                        (lon,lat), method='nearest')

   #print('out_var.ndim=', out_var.ndim)
   #print('out_var.shape=', out_var.shape)
   #print('out_var.size=', out_var.size)

    return lon, lat, out_var

  def get_GridSpec_latlon(self):
    print('reading ', self.gridspecfile)
    nc = Dataset(self.gridspecfile)
    lons = nc.variables['geolon'][:,:]
    lats = nc.variables['geolat'][:,:]

    print('lons.ndim=', lons.ndim)
    print('lons.size=', lons.size)
    print('lons.shape=', lons.shape)

    ny, nx = lons.shape

    lon1d = np.reshape(lons, (nx*ny,))
    lat1d = np.reshape(lats, (nx*ny,))

   #print('len(lon1d) = ', len(lon1d))
   #print('lons[0,:] = ', lons[0,:])
   #print('lats[:,0] = ', lats[:,0])

    for j in range(ny):
      for i in range(nx):
        if(lons[j,i] < 0.0):
          lons[j,i] += 360.0

   #print('len(lon1d) = ', len(lon1d))
   #print('lons[0,:] = ', lons[0,:])
    print('lats[:,0] = ', lats[:,0])

    nc.close()

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

  def get_level(self, data, level=0):
    if(3 == data.ndim):
      nz, ny, nx = data.shape
      var2d = data[level,:,:]
      var1d = np.reshape(var2d, (ny*nx, ))
    else:
      var1d = []
      nt, nz, ny, nx = data.shape
      for it in range(nt):
        var = data[it,level,:,:]
        var = var.reshape((ny*nx))
        var1d.extend(var)

   #print('len(var1d) = ', len(var1d))
    return var1d

  def get_latlon_data(self, varname, nlon=360, nlat=181, method='linear'):
   #varname = 'T'
    var = self.read3Dvar(varname)

    print('var.ndim=', var.ndim)
    print('var.shape=', var.shape)
    print('var.size=', var.size)

    latlon_var = self.interp2latlon_data(self.lon1d, self.lat1d, var,
                                         nlon=nlon, nlat=nlat, method=method)

    return latlon_var

  def interp2latlon_data(self, var, nlon=360, nlat=181, method='linear'):
    print('var.ndim = ', var.ndim)
    if(2 == var.ndim):
      ny, nx = var.shape

      var1d = np.reshape(var, (ny*nx, ))
      olons,olats,latlon_var = self.interp_to_latlon(var1d, nlon=nlon, nlat=nlat, method=method)
    else:
      if(3 == var.ndim):
        nz, ny, nx = var.shape
      else:
        nt, nz, ny, nx = var.shape

      latlon_var = np.zeros((nz, int(nlat), int(nlon)), dtype=float)

      for level in range(nz):
        var1d = self.get_level(var, level=level)
        if(self.debug):
          print('processing level ', level)
        olons,olats,ovar = self.interp_to_latlon(var1d, nlon=nlon, nlat=nlat, method=method)
        latlon_var[level,:,:] = ovar[:,:]

    return latlon_var

#----------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  gridspecfile = 'grids/ocn_2014_01.nc'
  datadir = '/work2/noaa/gsienkf/weihuang/jedi/singleobs/sst/soca_solver.20t4n_80p'

  datafile = '%s/ocn.LETKF.an.2015-12-01T12:00:00Z.nc' %(datadir)

  ro = RegridOcean(debug=debug, datafile=datafile, gridspecfile=gridspecfile)
  lat1d, lon1d = ro.get_GridSpec_latlon()

  varname = 'Temp'
  var = ro.read3Dvar(varname)

  print('var.ndim=', var.ndim)
  print('var.shape=', var.shape)
  print('var.size=', var.size)

  var1d = ro.get_level(var, level=1)

  print('len(lon1d) = ', len(lon1d))
  print('len(lat1d) = ', len(lat1d))
  print('len(var1d) = ', len(var1d))

  olons,olats,pvar = ro.interp_to_latlon(var1d, nlon=360, nlat=181, method='linear')

  print('pvar.ndim=', pvar.ndim)
  print('pvar.shape=', pvar.shape)
  print('pvar.size=', pvar.size)

 #make plot on output mesh
  m = Basemap(lon_0=180)
  m.drawcoastlines()
  m.drawmapboundary()
 #m.contourf(olons,olats,pvar,15)
  m.contourf(olons,olats,pvar,2)
  m.colorbar()
  plt.show()

