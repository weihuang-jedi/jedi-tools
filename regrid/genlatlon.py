#https://towardsdatascience.com/create-netcdf-files-with-python-1d86829127dd
#---------------------------------------------------------------------------
import netCDF4 as nc
import numpy as np

nlat = 181
nlon = 360

fn = 'll1.0deg_grid.nc'
ds = nc.Dataset(fn, 'w', format='NETCDF4')

time = ds.createDimension('time', None)
lat = ds.createDimension('lat', nlat)
lon = ds.createDimension('lon', nlon)

times = ds.createVariable('time', 'f4', ('time',))
lats = ds.createVariable('lat', 'f4', ('lat',))
lons = ds.createVariable('lon', 'f4', ('lon',))
value = ds.createVariable('value', 'f4', ('time', 'lat', 'lon',))
value.units = 'Unknown'

dlon = 360.0/nlon
dlat = 180.0/(nlat - 1)

lats[:] = np.arange(-90.0, 90.0+dlat, dlat)
lons[:] = np.arange(0.0, 360.0, dlon)

print('var size before adding data', value.shape)

value[0, :, :] = np.random.uniform(0, nlat*nlon, size=(nlat, nlon))

print('var size after adding first data', value.shape)

xval = np.linspace(0.0, 360.0, nlon)
yval = np.linspace(-90.0, 90.0+dlat, nlat)
value[1, :, :] = np.array(xval.reshape(-1, 1) + yval)

print('var size after adding second data', value.shape)

ds.close()

