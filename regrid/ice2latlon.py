import xarray as xr
import numpy as np
import xesmf as xe
import os, sys
import glob
import getopt

#-------------------------------------------------------------------------------------------
class Ocean2LatLon():
  def __init__(self, debug=0, wgtdir='grids/'):
    self.debug = debug
    self.wgtdir = wgtdir

    if(self.debug):
      print('debug = ', debug)
      print('wgtdir = ', wgtdir)

   #Read in tri-polar rot vars.
    grid_in = xr.open_dataset('grids/ocn_2014_01.nc')
    self.cos_rot = grid_in.cos_rot
    self.sin_rot = grid_in.sin_rot
    self.output_t_grid=grid_in.rename({'geolon': 'lon', 'geolat': 'lat'})
    grid_in.close()

   #specify an default input/output resolution
    self.ires = 'mx100'
    self.ores='360x181'

  def set_ires(self, ires='mx100'):
    self.ires = ires

  def set_ores(self, ores='360x181'):
    self.ores = ores

  def set_wgtdir(self, wgtdir='./'):
    self.wgtdir = wgtdir

  def gen_wgtfile(self, infilename=None):
    if(not os.path.isfile(infilename)):
      print('input file %s does not exist. Stop' %infilename)
      sys.exit(-1)

   #interpolation of tripolar t-points to 1-degree grid
    self.t2t_wgtfile = '%s%s.Ct.%s.Ct.bilinear.nc' %(self.wgtdir, self.ires, self.ores)

    if(os.path.isfile(self.t2t_wgtfile)):
      return

   #OPEN 1 degree history file to get input grid
    ds_in=xr.open_dataset(infilename)

   #rename lat and lons from grid files for ESMF interpolation
    output_t_grid=self.output_t_grid

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

    if(not os.path.isfile(self.t2t_wgtfile)):
      print('weight file %s does not exist. Stop' %self.t2t_wgtfile)
      sys.exit(-1)

  def process_file(self, infilename=None, outfilename=None):
    if(not os.path.isfile(infilename)):
      print('input file %s does not exist. Stop' %infilename)
      sys.exit(-1)
      
    ds_in=xr.open_dataset(infilename)

    if(outfilename is None or infilename == outfilename):
      path, flnm = os.path.split(infilename)
      if(flnm.find('.nc') > 0):
        namestr = '_%s.nc' %(self.ores)
        outfilename =flnm.replace('.nc', namestr)
      else:
        outfilename ='./%s_%s.nc' %(flnm, self.ores)

   #ds_in_t=ds_in.rename({'ni': 'lon', 'nj': 'lat'})
    ds_in_t=self.output_t_grid

   #output grid
    lon1d=np.arange(0,360,1.0)
    lat1d=np.arange(-90,91,1.0)
    lons, lats=np.meshgrid(lon1d,lat1d)

    da_out_lons=xr.DataArray(lons,dims=['nx','ny'])
    da_out_lats=xr.DataArray(lats,dims=['nx','ny'])
    ds_out_lons=da_out_lons.to_dataset(name='lon')
    ds_out_lats=da_out_lats.to_dataset(name='lat')

    grid_out=xr.merge([ds_out_lons,ds_out_lats])

   #define regridding instances
    rg_tt = xe.Regridder(ds_in_t, grid_out, 'bilinear',
                         periodic=True, reuse_weights=True, filename=self.t2t_wgtfile)

   #print('Processing file: ', infilename)

    ds_in=xr.open_dataset(infilename)
    ds_out=[]
    pos='T'
   #print('ds_in.keys(): ', ds_in.keys())
    for i in list(ds_in.keys()):
      print('\tWorking on: ', i)
     #print('\t\tds_in[i] = ', ds_in[i])
      print('\t\tds_in[i].dims = ', ds_in[i].dims)
     #print('\t\tds_in[i].coords = ', ds_in[i].coords)
      if len(ds_in[i].dims) > 1:
        coords=ds_in[i].coords.to_index()
        print('\tcoords.names = ', coords.names)

        if coords.names[0] == 'ncat':  # 3-dimensional data
          interp_out= rg_tt(ds_in[i].values)
          da_out=xr.DataArray(interp_out,dims=['ncat','lat','lon'])                    
          da_out.attrs['long_name']=i
          da_out.attrs['units']='unknown'
          ds_out.append(da_out.to_dataset(name=i))
        else: # 2 dimension data
          interp_out= rg_tt(ds_in[i].values)
          da_out=xr.DataArray(interp_out,dims=['lat','lon'])                    
          da_out.attrs['long_name']=i
          da_out.attrs['units']='unknown'
          ds_out.append(da_out.to_dataset(name=i))
    ds_out=xr.merge(ds_out)
    ds_out=ds_out.assign_coords(lon=('lon',lon1d))
    ds_out=ds_out.assign_coords(lat=('lat',lat1d))
    ds_out=ds_out.assign_coords(ncat=('ncat',ds_in.ncat.values))
    ds_out['lon'].attrs['units']='degrees_east'
    ds_out['lon'].attrs['axis']='X'
    ds_out['lon'].attrs['standard_name']='longitude'
    ds_out['lat'].attrs['units']='degrees_north'
    ds_out['lat'].attrs['axis']='Y'
    ds_out['lat'].attrs['standard_name']='latitude'
    ds_out['ncat'].attrs['units']='None'
    ds_out['ncat'].attrs['positive']='up'
    ds_out['ncat'].attrs['axis']='cat'

    ds_out.to_netcdf(outfilename)
    ds_out.close()

    ds_in.close()

#------------------------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  wgtdir = 'grids/'

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

  nemsrc = '/work/noaa/gsienkf/weihuang/jedi/vis_tools/sergey.samples/RESTART/'
  outdir = 'output/'

 #open input file to get input grid
 #files=glob.glob(nemsrc + 'MOM.res.????-??-??-??-00-00.nc')
  files=glob.glob(nemsrc + 'iced.????-??-??-?????.nc')
  files.sort()

  o2ll = Ocean2LatLon(debug=debug, wgtdir=wgtdir)
  inres = 'mx100'
  outres='360x181'

  o2ll.set_ires(ires=inres)
  o2ll.set_ores(ores=outres)

 #generate weight file if needed.
  o2ll.gen_wgtfile(infilename=files[0])

  for infile in files:
    print('Processing:', infile)
    path, flnm = os.path.split(infile)
    if(flnm.find('.nc') > 0):
      namestr = '_%s.nc' %(outres)
      outfile = outdir + flnm.replace('.nc', namestr)
    else:
      outfile = '%s%s_%s.nc' %(outdir, flnm, outres)
    print('\toutput file:', outfile)

    o2ll.process_file(infilename=infile, outfilename=outfile)

