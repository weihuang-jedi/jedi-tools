#=========================================================================
import os
import sys
import getopt
import math
import numpy as np
import netCDF4

from benedict import benedict

#=========================================================================
#benedict is well tested and documented, check the README to see all the features:
#https://github.com/fabiocaccamo/python-benedict
class ReadYAML():
  def __init__(self, debug=0, yamlpath=None):
    self.debug = debug
    self.yamlpath = yamlpath
    self.set_yamlpath(yamlpath=yamlpath)

    if(self.debug):
      print('debug = ', debug)
      print('yamlpath = ', yamlpath)
      self.print()

  def set_yamlpath(self, yamlpath=None):
   #path can be a yaml string, a filepath or a remote url
    self.yamlpath = yamlpath

    self.dict = benedict.from_yaml(self.yamlpath)

   #print(self.dict)

  def get_dict(self):
    return self.dict

  def print(self):
    n = 0
    for key in self.dict.keys():
      n += 1
      val = self.dict[key]
      print('key %d: %s' %(n, key))
      print('\tval:', val)

   #write it back to disk
   #dict.to_yaml(filepath=self.yamlpath)

#=========================================================================
class WriteIODA2Obs():
  def __init__(self, debug=0, filename=None, yamlfile=None):
    self.debug = debug
    self.filename = filename
    self.yamlpath = yamlfile

    if(self.debug):
      print('debug = ', debug)
      print('filename = ', filename)

    self.nvars = 4

    ry = ReadYAML(yamlpath=self.yamlpath)
    self.dict = ry.get_dict()

    self.set_filename(filename=self.filename)

  def set_filename(self, filename=None):
    self.filename = filename
    self.createNCfile()
    self.closeNCfile()

  def closeNCfile(self):
    self.ncfile.close()

  def createNCfile(self):
    self.ncfile = netCDF4.Dataset(self.filename, 'w', format='NETCDF4')

    adict = self.dict['global attributes']
    self.ncfile.title='Manually created IODA V2 Sondes data'
    self.ncfile._ioda_layout = adict['_ioda_layout']
    self.ncfile._ioda_layout_version = adict['_ioda_layout_version']
    self.ncfile.yamlfile = self.yamlpath
   #self.ncfile.datafile = self.datafile
    self.ncfile.filename = self.filename

   #print(self.ncfile.title)
   #print(self.ncfile)

   #self.date_time = netCDF4.stringtochar(np.array(['2020-01-10T06:58:21Z'], 'S20'))

   #Create the unlimited time dimension:
    self.ncfile.createDimension('nlocs', None)
   #self.ncfile.createDimension('nchar', 20)

    vdict = self.dict['variables']['nlocs']
    self.dimname = 'nlocs'
    self.nlocs = self.ncfile.createVariable('nlocs', 'i4', (self.dimname,))
    self.nlocs.suggested_chunk_dim = vdict['suggested_chunk_dim']
    self.nlocs[:] = [n for n in range(4)]

   #for dim in self.ncfile.dimensions.items():
   #  print(dim)

   #nc_f0 = Dataset('path_to_nc','r')
   #var = nc_f0.groups['group_name'].variables['var_name']

    self.writeVars()

  def put_grpvar(self, grpname, varname, var, val1, val2):
     #var = self.ncfile.groups[grpname].variables[varname][:]
      I = np.where(var == val1)
      var[I] = val2
      self.ncfile.groups[grpname].variables[varname][:] = var

  def writeVars(self):
    n = 0
    for gname in self.dict.keys():
      if(gname in ['dimensions', 'variables', 'global attributes']):
        continue

      n += 1
     #type = self.dict[gname]['type']
      vars = self.dict[gname]['variables']
      print('group %d: %s' %(n, gname))
      print('\tvars: ', vars)

      if(gname == 'MetaData'):
        print('need to handle %s' %(gname))
      else:
       #Create group
        group = self.ncfile.createGroup(gname)
       #group.createDimension('nlocs', len(self.nlocs))
       #group.self.ncfile
        for vname in vars.keys():
          print('\t\tvname: %s' %(vname))
          vdict = vars[vname]
          type = vdict['type']
          if(type == 'float'):
            var = group.createVariable(vname, np.float32, (self.dimname,))
          else:
            var = group.createVariable(vname, np.int32, (self.dimname,))
   #lat.units = 'degrees_north'
   #lat.long_name = 'latitude'
   #lat[:] = 17.002
          for attr in vdict.keys():
            print('\t\t\tattr: %s' %(attr))
            if(attr == '_FillValue'):
              var._FillValue = vdict[attr]
            elif(attr == 'units'):
              var.units = vdict[attr]
            elif(attr == 'coordinates'):
              var.coordinates = vdict[attr]
          #Assign value
          if(gname == 'GsiAdjustObsError'):
            var[:] = 1.2
          elif(gname == 'GsiFinalObsError'):
            var[:] = 1.5
          elif(gname == 'GsiHofX'):
            var[:] = 220.8092
          elif(gname == 'GsiHofXBc'):
            var[:] = 220.8092
          elif(gname == 'GsiInputObsError'):
            var[:] = 2.5
          elif(gname == 'GsiQCWeight'):
            var[:] = 4.0
          elif(gname == 'ObsError'):
            var[:] = 1.0
          elif(gname == 'ObsValue'):
            var[:] = 220.8092

#-----------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  filename = './ioda_v2_sondes_sample.nc'
  yamlfile = 'base.yaml'
  datafile = 'data.yaml'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'yamlfile=', 'datafile='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--filename'):
      filename = a
    elif o in ('--yamlfile'):
      yamlfile = a
    elif o in ('--datafile'):
      datafile = a
   #else:
   #  assert False, 'unhandled option'

  wio = WriteIODA2Obs(filename=filename, yamlfile=yamlfile)

