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
    self.resolution = resolution
    self.wgtdir = wgtdir

   #open input file to get input grid
    filestr = '%s%s/%s_grid_spec.tile?.nc' %(self.griddir, self.resolution, self.resolution)
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

      xlonb=xlonb.rename({'grid_y': 'grid_yt'})
      xlatb=xlatb.rename({'grid_y': 'grid_yt'})

      xlont=xlont.rename({'grid_y': 'grid_yt'})
      xlatt=xlatt.rename({'grid_y': 'grid_yt'})

      xlonv = 0.5*(xlonb + xlont)
      xlatv = 0.5*(xlatb + xlatt)

     #print('xlonb = ', xlonb)
     #print('xlont = ', xlont)
     #print('xlonv = ', xlonv)

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

  def gen_wgtfile(self):
   #interpolation of tripolar t-points to 1-degree grid
    self.t2t_wgtfile = '%sFV3_%s.Ct.%s.Ct.bilinear.nc' %(self.wgtdir, self.resolution, self.ores)

   #interpolation of models u and v points to model's t point
    self.u2t_wgtfile = '%sFV3_%s.Cu.%s.Ct.bilinear.nc' %(self.wgtdir, self.resolution, self.resolution)
    self.v2t_wgtfile = '%sFV3_%s.Cv.%s.Ct.bilinear.nc' %(self.wgtdir, self.resolution, self.resolution)

    if(os.path.isfile(self.t2t_wgtfile) and os.path.isfile(self.u2t_wgtfile)
      and os.path.isfile(self.v2t_wgtfile)):
      return

   #rename lat and lons from grid files for ESMF interpolation
    output_t_grid=self.tlon.rename({'grid_xt': 'lon', 'grid_yt': 'lat'})
    output_u_grid=self.ulon.rename({'grid_xt': 'lon', 'grid_y':  'lat'})
    output_v_grid=self.vlon.rename({'grid_x':  'lon', 'grid_yt': 'lat'})

   #define target grid  need to change to (0,360,0.25)   and (-90,90.25,0.25)
    lon1d=np.arange(0,360,1.0)
    lat1d=np.arange(-90,91,1.0)

    lons, lats=np.meshgrid(lon1d,lat1d)
    da_out_lons=xr.DataArray(lons,dims=['nx','ny'])
    da_out_lats=xr.DataArray(lats,dims=['nx','ny'])
    ds_out_lons=da_out_lons.to_dataset(name='lon')
    ds_out_lats=da_out_lats.to_dataset(name='lat')
    ds_out=xr.merge([ds_out_lons, ds_out_lats])

    rg_tt = xe.Regridder(output_t_grid, ds_out, 'bilinear',
                         periodic=True, filename=self.t2t_wgtfile)
    rg_ut = xe.Regridder(output_u_grid, output_t_grid, 'bilinear',
                         periodic=True, filename=self.u2t_wgtfile)
    rg_vt = xe.Regridder(output_v_grid, output_t_grid, 'bilinear',
                         periodic=True, filename=self.v2t_wgtfile)

    if(not os.path.isfile(self.t2t_wgtfile)):
      print('weight file %s does not exist. Stop' %self.t2t_wgtfile)
      sys.exit(-1)
    if(not os.path.isfile(self.u2t_wgtfile)):
      print('weight file %s does not exist. Stop' %self.u2t_wgtfile)
      sys.exit(-1)
    if(not os.path.isfile(self.v2t_wgtfile)):
      print('weight file %s does not exist. Stop' %self.v2t_wgtfile)
      sys.exit(-1)

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

     #print('grid_lonu =', grid_lonu)
    
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

