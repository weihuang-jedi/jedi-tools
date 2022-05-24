# =========================================================================
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

  def get_groupNvar_name(self, gvstr):
    np = gvstr.rfind('/')
    if (np < 0):
      gname = None
      vname = gvstr
    else:
      gname = gvstr[:np]
      vname = gvstr[np+1:]

   #if(self.debug):
   #  print('gname = ', gname)
   #  print('vname = ', vname)

    return gname, vname

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

  def get_var(self, varname):
    print('Processing FV3 file %s for variable %s.' % (self.filename, varname))

    gname, vname = self.get_groupNvar_name(varname)

   #print('gname = ', gname)
   #print('vname = ', vname)

    ncfile = netCDF4.Dataset(self.filename, 'r')
    if (gname is None):
      var = ncfile.variables[varname][:]
    else:
     #print('gname = ', gname)
     #print('vname = ', vname)

      ncgroup = ncfile[gname]
      var = ncgroup.variables[vname][:]
    ncfile.close()
    return var

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
    lat = self.get_var('/MetaData/latitude')
    lon = self.get_var('/MetaData/longitude')

    return lat, lon

  def get_latlon4var(self, varname=None):
    lat, lon = self.get_latlon()
    if(varname is None):
      return lat, lon

    var = self.get_var(varname)

    mask = []

    for n in range(len(var)):
     #if(math.isnan(var[n]) or var[n] > 12):
     #  mask.append(n)
     #if(np.isnan(var[n])):
      if(math.isnan(var[n])):
        mask.append(n)
     #else:
     #  if((var[n] < -2000.0) or (var[n] > 2000.0)):
     #    mask.append(n)
     #else:
     #  print('var[%d] = %f' %(n, var[n]))

   #print('len(mask) = ', len(mask))

    short_lat = np.delete(lat, mask)
    short_lon = np.delete(lon, mask)
    short_var = np.delete(var, mask)

   #print('len(short_lat) = ', len(short_lat))
   #print('len(short_lon) = ', len(short_lon))

    return short_lat, short_lon, short_var

# ----
if __name__ == '__main__':
  debug = 1

  dirname = '/work/noaa/gsienkf/weihuang/soca/soca_letkf_data'
  filename = 'ioda_v2_input_sst_avhrr19_l3u_nesdis_2015120112.nc'

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

  for varname in ['sea_surface_skin_temperature']:
    print('\tvarname = ', varname)

    n = 0
    for grp in nc_grps:
      n += 1
      print('Group No %d: %s' %(n, grp))
  
      if(grp in ['MetaData']):
        continue
  
     #if(grp in ['GsiInputObsError']):
     #  if(varname not in ['eastward_wind', 'northward_wind']):
     #    continue

      if(grp != 'VarMetaData'):
        var = rio.get_grpvar(grp, varname)
        print('\tvalue = ', var)
        print('\tmin: %f, max: %f, avg: %f' %(np.min(var), np.max(var), np.mean(var)))
        print('\n')

     #for i in range(len(var)):
     #  if(var[i] > 1.0e7):
     #    print('\tvar[%d] = %f' %(i, var[i]))

