#=========================================================================
import os
import sys
import getopt
import math
import numpy as np
import netCDF4

#=========================================================================
class ReadIODA2Obs():
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

    self.set_vardims()

  def set_filename(self, filename=None):
    self.filename = filename

  def ncdump(self, nc_fid, verb=True):
    '''
    ncdump outputs dimensions, variables and their attribute information.
    The information is similar to that of NCAR's ncdump utility.
    ncdump requires a valid instance of Dataset.

    Parameters
    ----------
    nc_fid : netCDF4.Dataset
        A netCDF4 dateset object
    verb : Boolean
        whether or not nc_attrs, nc_dims, and nc_grps are printed

    Returns
    -------
    nc_attrs : list
        A Python list of the NetCDF file global attributes
    nc_dims : list
        A Python list of the NetCDF file dimensions
    nc_grps : list
        A Python list of the NetCDF file groups
    '''
    def print_ncattr(key):
        """
        Prints the NetCDF file attributes for a given key

        Parameters
        ----------
        key : unicode
            a valid netCDF4.Dataset.variables key
        """
        try:
            print("\t\ttype:", repr(nc_fid.variables[key].dtype))
            for ncattr in nc_fid.variables[key].ncattrs():
                print('\t\t%s:' % ncattr,
                      repr(nc_fid.variables[key].getncattr(ncattr)))
        except KeyError:
            print("\t\tWARNING: %s does not contain variable attributes" % key)

    # NetCDF global attributes
    nc_attrs = nc_fid.ncattrs()
    if verb:
        print("NetCDF Global Attributes:")
        for nc_attr in nc_attrs:
            print('\t%s:' % nc_attr, repr(nc_fid.getncattr(nc_attr)))
    nc_dims = [dim for dim in nc_fid.dimensions]  # list of nc dimensions
    # Dimension shape information.
    if verb:
        print("NetCDF dimension information:")
        for dim in nc_dims:
            print("\tName:", dim)
            print("\t\tsize:", len(nc_fid.dimensions[dim]))
            if ('ndatetime' == dim):
                self.ndatetime = len(nc_fid.dimensions[dim])
            elif ('nlocs' == dim):
                self.nlocs = len(nc_fid.dimensions[dim])
            elif ('nstring' == dim):
                self.nstring = len(nc_fid.dimensions[dim])
            print_ncattr(dim)
    # Group information.
    nc_grps = [grp for grp in nc_fid.groups]  # list of nc groups
    self.ngrps = len(nc_grps)
    if verb:
        print("NetCDF group information:")
        n = 0
        for grp in nc_grps:
            n += 1
            print('\tgroup No. %d: %s' %(n, grp))

        print('\tself.ndatetime:', self.ndatetime)
        print('\tself.nlocs:', self.nlocs)
        print('\tself.nstring:', self.nstring)
        print('\tself.ngrps:', self.ngrps)

        nc_vars = [var for var in nc_fid.groups[grp].variables]  # list of nc variables
        if verb:
            print("NetCDF variable information:")
            i = 0
            for var in nc_vars:
                i += 1
                print('\t\tvar No %d Name: %s' %(i, var))

    return nc_attrs, nc_dims, nc_grps

  def get_grpvar(self, grpname, varname):
   #print('grpname = ', grpname)
   #print('varname = ', varname)

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

#-----------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
 #dirname = '/work2/noaa/gsienkf/weihuang/scripts/convert/output'
 #filename = 'sondes_ps_obs_2020011006.nc4'

  dirname = '/work2/noaa/gsienkf/weihuang/scripts/convert/sondesobs'
  filename = 'ioda_v2_sondes_obs_2020011006.nc4'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'dirname=', 'filename='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--dirname'):
      dirname = a
    elif o in ('--filename'):
      filename = a
   #else:
   #  assert False, 'unhandled option'

  fullpath = '%s/%s' %(dirname, filename)

  print('debug = ', debug)
  print('fullpath = ', fullpath)

  rio = ReadIODA2Obs(debug=debug, filename=fullpath)

  nc_attrs, nc_dims, nc_grps = rio.get_fileinfo()

  for varname in ['air_temperature', 'eastward_wind', 'northward_wind', 'specific_humidity', 'virtual_temperature']:
    print('\tvarname = ', varname)

    n = 0
    for grp in nc_grps:
      n += 1
      print('Group No %d: %s' %(n, grp))
  
      if(grp in ['MetaData']):
        continue
  
      if(grp in ['GsiInputObsError']):
        if(varname not in ['eastward_wind', 'northward_wind']):
          continue

      var = rio.get_grpvar(grp, varname)
      print('\tvalue = ', var)
      print('\tmin: %f, max: %f, avg: %f' %(np.min(var), np.max(var), np.mean(var)))
      print('\n')

      for i in range(len(var)):
        if(var[i] > 1.0e7):
          print('\tvar[%d] = %f' %(i, var[i]))

