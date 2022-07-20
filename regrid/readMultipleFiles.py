import xarray as xr
import xesmf as xe
import numpy as np
import getopt
import glob
import sys
import os

#-------------------------------------------------------------------------------------------
class GenFv3WeightFile():
  def __init__(self, debug=0, griddir=None, resolution='C96', wgtdir='grids/'):
   #List all matching files
   #self.griddir = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/'
    self.griddir = griddir

   #open input file to get input grid
    filestr = '%s%s/%s_grid_spec.tile?.nc' %(self.griddir, resolution, resolution)
    self.files=glob.glob(filestr)
    self.files.sort()

    print('files=', self.files)

    self.get_gridinfo()

  def get_gridinfo(self):
   #Loop through each file in the list
    i = self.files[0]
   #Load a single dataset
    ds_in = xr.open_dataset(i)

   #Create a new variable called 'time' from the `time_coverage_start` field, and 
    grid_x = ds_in['grid_x']
    grid_xt= ds_in['grid_xt']
    grid_y = ds_in['grid_y']
    grid_yt= ds_in['grid_yt']

   #print('grid_x = ', grid_x)
   #print('len(grid_x) = ', len(grid_x))
   #print('grid_xt = ', grid_xt)
   #print('len(grid_xt) = ', len(grid_xt))

    self.nx = len(grid_xt)
    self.ny = len(grid_yt)
    self.nxp = len(grid_x)
    self.nyp = len(grid_y)

    print('nx  = %d, ny  = %d' %(self.nx,  self.ny))
    print('nxp = %d, nyp = %d' %(self.nxp, self.nyp))

    ds_in.close()

   #Create list for all tiles.
    tlat = []
    tlon = []
    ulat = []
    ulon = []
    vlat = []
    vlon = []

   #Loop through each file in the list
    for i in self.files:
     #Load a single dataset
      ds_in = xr.open_dataset(i)

      lont = ds_in['grid_lont']
      latt = ds_in['grid_latt']

      # Add the dataset to the list
      tlon.append(lont)
      tlat.append(latt)

      xlon = ds_in['grid_lon']
      xlat = ds_in['grid_lat']

      xlonl = xlon.sel(grid_x=slice(0,self.nx))
      xlatl = xlat.sel(grid_x=slice(0,self.nx))

      xlonr = xlon.sel(grid_x=slice(1,self.nxp))
      xlatr = xlat.sel(grid_x=slice(1,self.nxp))

      xlonl=xlonl.rename({'grid_x': 'grid_xt'})
      xlatl=xlatl.rename({'grid_x': 'grid_xt'})

      xlonr=xlonr.rename({'grid_x': 'grid_xt'})
      xlatr=xlatr.rename({'grid_x': 'grid_xt'})

      xlonu = 0.5*(xlonl + xlonr)
      xlatu = 0.5*(xlatl + xlatr)

      # Add the dataset to the list
      ulon.append(xlonu)
      ulat.append(xlatu)

      xlonb = xlon.sel(grid_y=slice(0,self.ny))
      xlatb = xlat.sel(grid_y=slice(0,self.ny))

      xlont = xlon.sel(grid_y=slice(1,self.nyp))
      xlatt = xlat.sel(grid_y=slice(1,self.nyp))

      xlonb=xlonl.rename({'grid_y': 'grid_yt'})
      xlatb=xlatl.rename({'grid_y': 'grid_yt'})

      xlont=xlonr.rename({'grid_y': 'grid_yt'})
      xlatt=xlatr.rename({'grid_y': 'grid_yt'})

      xlonv = 0.5*(xlonb + xlont)
      xlatv = 0.5*(xlatb + xlatt)

      # Add the dataset to the list
      vlon.append(xlonv)
      vlat.append(xlatv)

      ds_in.close()

   #Combine individual datasets into a single xarray along the 'x'/'xt' dimension
    self.tlon = xr.concat(tlon, dim='grid_xt')
    self.tlat = xr.concat(tlat, dim='grid_xt')

    self.ulon = xr.concat(ulon, dim='grid_xt')
    self.ulat = xr.concat(ulat, dim='grid_xt')

    self.vlon = xr.concat(vlon, dim='grid_x')
    self.vlat = xr.concat(vlat, dim='grid_x')

    print('self.tlon = ', self.tlon)
    print('self.ulon = ', self.ulon)
    print('self.vlon = ', self.vlon)

  def processing(self):
   #Create list for 
    individual_files = []

   #Loop through each file in the list
    for i in self.files:
     #Load a single dataset
      ds_in = xr.open_dataset(i)

      grid_lon = ds_in['grid_lon']

     #print(grid_lon)

      grid_lonl = grid_lon.sel(grid_x=slice(0,nx))
      grid_lonr = grid_lon.sel(grid_x=slice(1,nxp))

      grid_lonl=grid_lonl.rename({'grid_x': 'grid_xt'})
      grid_lonr=grid_lonr.rename({'grid_x': 'grid_xt'})

      grid_lonu = 0.5*(grid_lonl + grid_lonr)

      print('grid_lonu =', grid_lonu)
    
      # Add the dataset to the list
      individual_files.append(grid_lonu)

   #Combine individual datasets into a single xarray along the 'time' dimension
    modis_ds = xr.concat(individual_files, dim='grid_xt')

    print(modis_ds)

#-------------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  wgtdir = 'grids/'
  griddir = '/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/'
  resolution = 'C96'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'wgtdir='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--wgtdir'):
      wgtdir = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('wgtdir = ', wgtdir)

  fv3wgt = GenFv3WeightFile(debug=0, griddir=griddir, resolution=resolution, wgtdir=wgtdir)

