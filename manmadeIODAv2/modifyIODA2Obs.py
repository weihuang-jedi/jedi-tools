#=========================================================================
import os
import sys
import getopt
import math
import numpy as np
import netCDF4 as nc4

#=========================================================================
class ModifyIODA2Obs():
  def __init__(self, debug=0, src_flnm=None, tar_flnm='test.nc4'):
    self.debug = debug
    self.src_flnm = src_flnm
    self.tar_flnm = tar_flnm

    self.ncin = nc4.Dataset(self.src_flnm, 'r')
    self.ncout = nc4.Dataset(self.tar_flnm, 'w')

 #Destructor
  def __del__(self):
   #Close the netcdf files
    self.ncin.close()
    self.ncout.close()

  def process(self, grpname='Unknown', varname='Unknown'):
   #NetCDF global attributes
    self.attrs = self.ncin.ncattrs()
    if (self.debug):
      print("NetCDF Global Attributes:")
    for attr in self.attrs:
      if (self.debug):
        print('\t%s:' % attr, repr(self.ncin.getncattr(attr)))
      self.ncout.setncattr(attr, self.ncin.getncattr(attr))

   #Dimension shape information.
    if (self.debug):
      print("NetCDF dimension information:")

    for dim in self.ncin.dimensions:
      if (self.debug):
        print("\tName:", dim)
        print("\t\tsize:", len(self.ncin.dimensions[dim]))

      dimval = self.ncin.dimensions[dim]
      if dimval.isunlimited():
        self.ncout.createDimension(dim, None)
      else:
        self.ncout.createDimension(dim, len(dimval))

   #Variable information.
    if (self.debug):
      print("NetCDF variable information:")
    i = 0
    for vn in self.ncin.variables:
      i += 1
      if (self.debug):
        print('\t\tvar No %d Name: %s' %(i, vn))
      variable = self.ncin.variables[vn]
      self.write_var(self.ncout, variable, vn)

   #Group information.
    if (self.debug):
      print("NetCDF group information:")
    n = 0
    for grp in self.ncin.groups:
      n += 1
      if (self.debug):
        print('\tgroup No. %d: %s' %(n, grp))

      grpout = self.ncout.createGroup(grp)

      if (self.debug):
        print("NetCDF variable information:")
      i = 0
      for vn in self.ncin.groups[grp].variables:
        i += 1
        if (self.debug):
          print('\t\tvar No %d Name: %s' %(i, vn))
        variable = self.ncin.groups[grp].variables[vn]

        if((vn == varname) and (grp == grpname)):
          val = self.get_grpvar(grpname, vn)
         #print('val.type: ', val.type)
          for n in range(len(val)):
            newval = val[n].replace('2020-12-15T02', '2020-01-10T03')
            newval = newval.replace('2020-12-15T01', '2020-01-10T03')
            newval = newval.replace('2020-12-15T00', '2020-01-10T03')
            newval = newval.replace('2020-12-14T23', '2020-01-10T03')
            newval = newval.replace('2020-12-14T22', '2020-01-10T03')
            newval = newval.replace('2020-12-14T21', '2020-01-10T03')
            val[n] = newval
          self.write_var_with_value(grpout, variable, vn, val)
        else:
          self.write_var(grpout, variable, vn)

  def write_var(self, ncout, variable, varname):
    var = variable[:]
    self.write_var_with_value(ncout, variable, varname, var)

  def write_var_with_value(self, ncout, variable, varname, value):
    if (self.debug):
      print('variable.datatype = ', variable.datatype)
      print('variable.dimensions = ', variable.dimensions)

    attrs = variable.ncattrs()
    if('_FillValue' in attrs):
      fv = variable.getncattr('_FillValue')
      ncout.createVariable(varname, variable.datatype, variable.dimensions,
                                fill_value=fv)
    else:
      ncout.createVariable(varname, variable.datatype, variable.dimensions)

   #NetCDF variable attributes
    if (self.debug):
      print("NetCDF variable Attributes:")
    for attr in attrs:
      if('_FillValue' == attr):
        continue
      attr_value = variable.getncattr(attr)
      if (self.debug):
        print('\t%s:' % attr, attr_value)

      ncout.variables[varname].setncattr(attr, attr_value)

    ncout.variables[varname][:] = value

  def get_grpvar(self, grpname, varname):
    if(self.debug):
      print('get "/%s/%s"' %(grpname, varname))

    if (grpname is None):
      var = self.ncin.variables[varname][:]
    else:
      var = self.ncin.groups[grpname].variables[varname][:]

    return var

#-----------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1

 #indir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/amsua/amsua-obs'
 #outdir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/amsua/manmade-amsua-obs'
 #inflnm = 'amsua_n19_obs_2020121500_m.nc4'

  indir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/iasi/iasi-obs'
  outdir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/iasi/manmade-iasi-obs'
 #inflnm = 'iasi_metop-a_obs_2020121500_m.nc4'
  inflnm = 'iasi_metop-b_obs_2020121500_m.nc4'

 #opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'dirname=', 'filename='])

 #for o, a in opts:
 #  if o in ('--debug'):
 #    debug = int(a)
 #  elif o in ('--dirname'):
 #    dirname = a
 #  elif o in ('--filename'):
 #    filename = a
 # #else:
 # #  assert False, 'unhandled option'

  src_file = '%s/%s' %(indir, inflnm)
  tar_file = '%s/%s' %(outdir, inflnm)

  mf = ModifyIODA2Obs(debug=debug, src_flnm=src_file, tar_flnm=tar_file)

  mf.process(grpname='MetaData', varname='datetime')

