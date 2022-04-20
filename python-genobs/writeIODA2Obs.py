#=========================================================================
import os
import sys
import getopt
import math
import numpy as np
import netCDF4

from benedict import benedict
#import benedict

#=========================================================================
class WriteIODA2Obs():
  def __init__(self, debug=0, filename=None):
    self.debug = debug
    self.filename = filename

    if(self.debug):
      print('debug = ', debug)
      print('filename = ', filename)

    self.ndatetime = 0
    self.nlocs = 0
    self.nstring = 0
    self.ngrps = 0

    self.set_filename(self, filename=filename)

  def set_filename(self, filename=None):
    self.filename = filename
    self.createNCfile()

  def closeNCfile(self):
    self.ncfile.close()

  def createNCfile(self):
    self.ncfile = netCDF4.Dataset('./ioda_v2_sondes_sample.nc', 'w', format='NETCDF4')

    self.ncfile.title='Manually created IODA V2 Sondes data'
    self.ncfile._ioda_layout_version = 0
    print(self.ncfile.title)
    print(self.ncfile)
    print(self.ncfile._ioda_layout_version)

    self.date_time = netCDF4.stringtochar(np.array(['2020-01-10T06:58:21Z'], 'S20'))

   #Create the unlimited time dimension:
    self.ncfile.createDimension('nlocs', None)
   #self.ncfile.createDimension('nchar', 20)

    nlocs = nc.createVariable('nlocs', 'i4', ('nlocs',))

   #lat = ncfile.createVariable('lat', np.float32, ('lat',))
   #lat.units = 'degrees_north'
   #lat.long_name = 'latitude'
   #lat[:] = 17.002

    for dim in self.ncfile.dimensions.items():
      print(dim)

   #nc_f0 = Dataset('path_to_nc','r')
   #var = nc_f0.groups['group_name'].variables['var_name']

  def get_grpvar(self, grpname, varname):
    ncfile = netCDF4.Dataset(self.filename, 'r')

    if (grpname is None):
      var = ncfile.variables[varname][:]
    else:
      var = ncfile.groups[grpname].variables[varname][:]
    ncfile.close()

    return var

  def put_grpvar(self, grpname, varname, var, val1, val2):
    ncfile = netCDF4.Dataset(self.filename, 'r+')

    if (grpname is None):
     #var = ncfile.variables[varname][:]
      I = np.where(var == val1)
      var[I] = val2
      ncfile.variables[varname][:] = var
    else:
     #var = ncfile.groups[grpname].variables[varname][:]
      I = np.where(var == val1)
      var[I] = val2
      ncfile.groups[grpname].variables[varname][:] = var

    ncfile.close()

    return var

  def get_fileinfo(self):
    return self.nc_attrs, self.nc_dims, self.nc_grps

  def set_vardims(self):
    ncfile = netCDF4.Dataset(self.filename, 'r')
    if(self.debug):
      print('self.filename = ', self.filename)
    self.nc_attrs, self.nc_dims, self.nc_grps = self.ncdump(ncfile, verb=True)

    if(self.debug):
      print('nc_attrs: ', self.nc_attrs)
      print('nc_dims: ', self.nc_dims)
      print('nc_grps: ', self.nc_grps)

    ncfile.close()

  def get_latlon(self):
    lat = self.get_grpvar('MetaData', 'latitude')
    lon = self.get_grpvar('MetaData', 'longitude')

    return lat, lon


#=========================================================================
#benedict is well tested and documented, check the README to see all the features:
#https://github.com/fabiocaccamo/python-benedict
class ReadYAML():
  def __init__(self, debug=0, yamlpath=None):
    self.debug = debug
    self.yamlpath = yamlpath

    if(self.debug):
      print('debug = ', debug)
      print('yamlpath = ', yamlpath)

    self.ndatetime = 0
    self.nlocs = 0
    self.nstring = 0
    self.ngrps = 0

    self.set_yamlpath(yamlpath=yamlpath)

  def set_yamlpath(self, yamlpath=None):
   #path can be a yaml string, a filepath or a remote url
    self.yamlpath = yamlpath

    dict = benedict.from_yaml(self.yamlpath)

    print(dict)

   #write it back to disk
   #dict.to_yaml(filepath=self.yamlpath)

#-----------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  yamlfile = 'var.yaml'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'yamlfile=', 'datafile='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--yamlfile'):
      yamlfile = a
    elif o in ('--datafile'):
      datafile = a
   #else:
   #  assert False, 'unhandled option'

  ry = ReadYAML(yamlpath=yamlfile)

