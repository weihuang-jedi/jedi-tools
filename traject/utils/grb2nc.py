import os, sys
import glob
import getopt
import pygrib

import xarray as xr
import numpy as np

#-------------------------------------------------------------------------------------------
class Grb2NC():
  def __init__(self, debug=0, outfilename='my.nc'):
    self.debug = debug
    self.outfilename = outfilename

    if(self.debug):
      print('debug = ', debug)
      print('outfilename = ', outfilename)

  def process_file(self, infilename=None):
    if(not os.path.isfile(infilename)):
      print('input file %s does not exist. Stop' %infilename)
      sys.exit(-1)
      
    print('Processing file: ', infilename)

    grbs = pygrib.open(infilename)

    varname = 'Specific humidity'
    grb = grbs.select(name=varname)[0]
    data=grb.values
    lats, lons = grb.latlons()

   #msg = pygrib.gribmessage
   #print('\t\tmsg: ', msg)

   #print('lats = ', lats)
   #print('lons = ', lons)

    lon = lons[0, :]
    lat = lats[:, 0]

   #print('lat = ', lat)
   #print('lon = ', lon)

    if(self.outfilename is None):
      path, flnm = os.path.split(infilename)
      self.outfilename ='%s/my.nc' %(flnm)

    self.ds_out=[]

   #print('grbs:', grbs)
   #grbs.seek(0)
    for grb in grbs:
      print('\tWorking on: ', grb)

      print('grb.keys = ', grb.keys())

      var = grb.values
     #print('var = ', var)
      print('var.ndim = ', var.ndim)
      print('var.shape = ', var.shape)
     #print('var.size = ', var.size)
     #print('var.dtype = ', var.dtype)
     #print('var min: %f, max: %f' %(var.min(), var.max()))

     #self.da_out=xr.DataArray(var,dims=['time','lev','lat','lon'])                    
     #self.da_out.attrs['long_name']=long_name
     #self.da_out.attrs['units']=units
     #self.ds_out.append(da_out.to_dataset(name=varname))

    grbs.close()

    self.ds_out=xr.merge(self.ds_out)
    self.ds_out=self.ds_out.assign_coords(lon=('lon',lon))
    self.ds_out=self.ds_out.assign_coords(lat=('lat',lat))
   #self.ds_out=self.ds_out.assign_coords(lay=('lev',ds_in.Layer.values))
   #self.ds_out=self.ds_out.assign_coords(time=('time',ds_in.Time.values))
    self.ds_out['lon'].attrs['units']='degrees_east'
    self.ds_out['lon'].attrs['axis']='X'
    self.ds_out['lon'].attrs['standard_name']='longitude'

    self.ds_out['lat'].attrs['units']='degrees_north'
    self.ds_out['lat'].attrs['axis']='Y'
    self.ds_out['lat'].attrs['standard_name']='latitude'

   #self.ds_out['lev'].attrs['units']='Level'
   #self.ds_out['lev'].attrs['axis']='Z'
   #self.ds_out['lev'].attrs['standard_name']='level'

   #self.ds_out['time'].attrs['units']='Date'
   #self.ds_out['time'].attrs['axis']='t'
   #self.ds_out['time'].attrs['standard_name']='Time'

    self.ds_out.to_netcdf(self.outfilename)

  def closefile(self):
    self.ds_out.close()

#------------------------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  datadir = '/work2/noaa/gsienkf/weihuang/gfs/data/'
  outfilename = 'my.nc'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'datadir=', 'outfilename='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--datadir'):
      datadir = a
    elif o in ('--outfilename'):
      outfilename = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('datadir = ', datadir)
  print('outfilename = ', outfilename)

 #open input file to get input grid
 #files=glob.glob('ocn_????_??_??.nc')
  files=glob.glob(datadir + 'gfs_4_????????_??00_000.grb2')
  files.sort()

 #print('files = ', files)

  g2n = Grb2NC(debug=debug, outfilename=outfilename)

  for infile in files:
    g2n.process_file(infilename=infile)
    sys.exit(-1)

  g2n.closefile()

