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
  def __init__(self, debug=0, filename=None, yamlfile=None, datafile=None):
    self.debug = debug
    self.filename = filename
    self.yamlpath = yamlfile
    self.datapath = datafile

    if(self.debug):
      print('debug = ', debug)
      print('filename = ', filename)
      print('yamlfile = ', yamlfile)
      print('datafile = ', datafile)

    rb = ReadYAML(yamlpath=self.yamlpath)
    self.dict = rb.get_dict()

    rd = ReadYAML(yamlpath=self.datapath)
   #rd.print()
    self.metadata = rd.get_dict()
    print('self.metadata = ', self.metadata)
    self.meta = self.metadata['MetaData']
   #print('self.meta = ', self.meta)

    self.nvars = len(self.meta['latitude'])

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
    self.ncfile.basefile = self.yamlpath
    self.ncfile.datafile = self.datapath
    self.ncfile.filename = self.filename

   #Create the unlimited time dimension:
    self.ncfile.createDimension('nlocs', None)
   #self.ncfile.createDimension('nchar', 20)

    vdict = self.dict['variables']['nlocs']
    self.dimname = 'nlocs'
    self.nlocs = self.ncfile.createVariable('nlocs', 'i4', (self.dimname,))
    self.nlocs.suggested_chunk_dim = vdict['suggested_chunk_dim']
    self.nlocs[:] = [n for n in range(self.nvars)]

   #for dim in self.ncfile.dimensions.items():
   #  print(dim)

    self.writeVars()

  def writeVars(self):
    n = 0
    for gname in self.dict.keys():
      if(gname in ['dimensions', 'variables', 'global attributes']):
        continue

      n += 1
     #type = self.dict[gname]['type']
      vars = self.dict[gname]['variables']
     #print('group %d: %s' %(n, gname))
     #print('\tvars: ', vars)

      if(gname == 'MetaData'):
       #handle Metadata
        group = self.ncfile.createGroup(gname)
        for vname in vars.keys():
         #print('\tvname: %s' %(vname))
          vdict = vars[vname]
         #print('\tvdict = ', vdict)

          type = vdict['type']
          if(type == 'float'):
            var = group.createVariable(vname, np.float32, (self.dimname,), fill_value=vdict['_FillValue'])
          else:
            var = group.createVariable(vname, str, (self.dimname,), fill_value=vdict['_FillValue'])

          for attr in vdict.keys():
           #print('\t\t\tattr: %s' %(attr))
            if(attr == 'units'):
              var.units = vdict[attr]
            elif(attr == 'coordinates'):
              var.coordinates = vdict[attr]

          if(vname == 'station_id'):
            sid = []
            for n in range(self.nvars):
              tid = '%d' %(10000+n)
              sid.append(tid)
            str_out = np.array(sid, dtype='object')
           #print('\tsid =', sid)
           #print('\tstr_out =', str_out)
            var[:] = str_out
          elif(vname == 'datetime'):
            str_out = np.array(self.meta[vname], dtype='object')
            var[:] = str_out
          else:
            var[:] = self.meta[vname]
      else:
       #Create group
        group = self.ncfile.createGroup(gname)
        for vname in vars.keys():
         #print('\t\tvname: %s' %(vname))
          vdict = vars[vname]

          type = vdict['type']
          if(type == 'float'):
            var = group.createVariable(vname, np.float32, (self.dimname,), fill_value=vdict['_FillValue'])
          else:
            var = group.createVariable(vname, np.int32, (self.dimname,), fill_value=vdict['_FillValue'])

          for attr in vdict.keys():
           #print('\t\t\tattr: %s' %(attr))
            if(attr == 'units'):
              var.units = vdict[attr]
            elif(attr == 'coordinates'):
              var.coordinates = vdict[attr]
           #elif(attr == '_FillValue'):
           #  var._FillValue = vdict[attr]

          #Assign value
          if(gname == 'GsiAdjustObsError'):
            var[:] = 1.4
          elif(gname == 'GsiFinalObsError'):
            var[:] = 1.25
          elif(gname == 'GsiFinalObsError'):
            var[:] = 1.5
          elif(gname == 'GsiHofX'):
            if(gname in self.metadata.keys()):
              var[:] = self.metadata[gname]
            else:
              var[:] = 1009.869
          elif(gname == 'GsiHofXBc'):
            if(gname in self.metadata.keys()):
              var[:] = self.metadata[gname]
            else:
              var[:] = 1009.869
          elif(gname == 'GsiInputObsError'):
            var[:] = 2.5
          elif(gname == 'GsiQCWeight'):
            var[:] = 4.0
          elif(gname == 'ObsError'):
            var[:] = 1.0
          elif(gname == 'ObsValue'):
            if(gname in self.metadata.keys()):
              var[:] = self.metadata[gname]
            else:
              var[:] = 220.8092
          elif(gname == 'GsiEffectiveQC'):
            var[:] = 0
          elif(gname == 'GsiUseFlag'):
            var[:] = 1
          elif(gname == 'ObsType'):
            var[:] = 181
          elif(gname == 'PreQC'):
            var[:] = 2
          elif(gname == 'PreUseFlag'):
            var[:] = 0

#-----------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  filename = './ioda_v2_sondes_sample.nc'
  yamlfile = 'base.yaml'
  datafile = 'metadata.yaml'

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

  wio = WriteIODA2Obs(filename=filename, yamlfile=yamlfile, datafile=datafile)

