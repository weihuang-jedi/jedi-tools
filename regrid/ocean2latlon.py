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
    grid_in.close()

   #specify an default input/output resolution
    self.ires = 'mx100'
    self.ores='360x181'

    self.set_ires(ires=self.ires)

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

   #interpolation of models u and v points to model's t point
    self.u2t_wgtfile = '%s%s.Cu.%s.Ct.bilinear.nc' %(self.wgtdir, self.ires, self.ires)
    self.v2t_wgtfile = '%s%s.Cv.%s.Ct.bilinear.nc' %(self.wgtdir, self.ires, self.ires)

    if(os.path.isfile(self.t2t_wgtfile) and os.path.isfile(self.u2t_wgtfile)
      and os.path.isfile(self.v2t_wgtfile)):
      return

   #OPEN 1 degree history file to get input grid
    ds_in=xr.open_dataset(infilename)

   #rename lat and lons from grid files for ESMF interpolation
   #output_t_grid=ds_in.rename({'geolon': 'lon', 'geolat': 'lat'})
   #output_u_grid=ds_in.rename({'geolon_u': 'lon', 'geolat_u': 'lat'})
   #output_v_grid=ds_in.rename({'geolon_v': 'lon', 'geolat_v': 'lat'})

    output_t_grid=ds_in.rename({'lonh': 'lon', 'lath': 'lat'})
    output_u_grid=ds_in.rename({'lonq': 'lon', 'lath': 'lat'})
    output_v_grid=ds_in.rename({'lonh': 'lon', 'latq': 'lat'})

    print('output_t_grid=', output_t_grid)

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

   #ds_in_t=ds_in.rename({'geolon': 'lon', 'geolat': 'lat'})
   #ds_in_u=ds_in.rename({'geolon_u': 'lon', 'geolat_u': 'lat'})
   #ds_in_v=ds_in.rename({'geolon_v': 'lon', 'geolat_v': 'lat'})
    ds_in_t=ds_in.rename({'lonh': 'lon', 'lath': 'lat'})
    ds_in_u=ds_in.rename({'lonq': 'lon', 'lath': 'lat'})
    ds_in_v=ds_in.rename({'lonh': 'lon', 'latq': 'lat'})

   #output grid
    lon1d=np.arange(0,360,1.0)
    lat1d=np.arange(-90,91,1.0)
    lons,lats=np.meshgrid(lon1d,lat1d)

    da_out_lons=xr.DataArray(lons,dims=['nx','ny'])
    da_out_lats=xr.DataArray(lats,dims=['nx','ny'])
    ds_out_lons=da_out_lons.to_dataset(name='lon')
    ds_out_lats=da_out_lats.to_dataset(name='lat')

    grid_out=xr.merge([ds_out_lons,ds_out_lats])

   #define regridding instances
    rg_tt = xe.Regridder(ds_in_t, grid_out, 'bilinear',
                         periodic=True,reuse_weights=True, filename=self.t2t_wgtfile)
    rg_ut = xe.Regridder(ds_in_u, ds_in_t, 'bilinear',
                         periodic=True,reuse_weights=True, filename=self.u2t_wgtfile)
    rg_vt = xe.Regridder(ds_in_v, ds_in_t, 'bilinear',
                         periodic=True,reuse_weights=True, filename=self.v2t_wgtfile)

   #print('Processing file: ', infilename)

    ds_in=xr.open_dataset(infilename)
    ds_out=[]
   #print('ds_in.keys(): ', ds_in.keys())
    for i in list(ds_in.keys()):
      print('\tWorking on: ', i)
     #print('\t\tds_in[i].coords = ', ds_in[i].coords)
      if len(ds_in[i].coords) > 2:
        coords=ds_in[i].coords.to_index()
       #print('\tcoords.names = ', coords.names)
        pos='skip'

        if coords.names[0] != 'Time':
          print('\t\tcoords.names[:] = ', coords.names[:])
        else:
          if i=='u':
            i2='v'
            pos='U'
          elif i=='uh':
            i2='vh'
            pos='U'
          elif i=='ub':
            i2='vb'
            pos='U'
          elif i=='u2':
            i2='v2'
            pos='U'
          elif i=='diffu':
            i2='diffv'
            pos='U'
          elif i=='ubtav':
            i2='vbtav'
            pos='U'
          elif i in ['v', 'vh', 'vb', 'v2', 'diffv', 'vbtav', 'Kv_shear_Bu', 'Kd_shear', 'Kv_shear']:
            pos='skip'
          else:
            pos='T'

        if coords.names[1] == 'Layer':  # 3-dimensional data
          if pos=='T':  # interplate to lat-lon grid
            interp_out= rg_tt(ds_in[i].values)
            da_out=xr.DataArray(interp_out,dims=['time','lev','lat','lon'])                    
            da_out.attrs['long_name']=ds_in[i].long_name
            da_out.attrs['units']=ds_in[i].units
            ds_out.append(da_out.to_dataset(name=i))
          elif pos == 'U':  #  interplate u and v to t-point, then rotate currents/winds to earth relative before interpolate to lat-lon grid
           #interpolate to t-points
            interp_u= rg_ut(ds_in[i].values)
            interp_v= rg_ut(ds_in[i2].values)
           #rotate to earth-relative 
            urot=np.zeros([np.shape(interp_u)[1],np.shape(interp_u)[2],np.shape(interp_u)[3]])
            vrot=np.zeros([np.shape(interp_u)[1],np.shape(interp_u)[2],np.shape(interp_u)[3]])
            for k in range(np.shape(interp_u)[1]):
              urot[k] =   interp_u[0,k,:,:]*self.cos_rot + interp_v[0,k,:,:]*self.sin_rot
              vrot[k] =   interp_v[0,k,:,:]*self.cos_rot - interp_u[0,k,:,:]*self.sin_rot
           #interoplate to lat-lon grid
            uinterp_out= rg_tt(urot)
            vinterp_out= rg_tt(vrot)
            da_out=xr.DataArray(np.expand_dims(uinterp_out, 0),dims=['time','lev','lat','lon'])                    
            da_out.attrs['long_name']=ds_in[i].long_name
            da_out.attrs['units']=ds_in[i].units
            ds_out.append(da_out.to_dataset(name=i))
            da_out=xr.DataArray(np.expand_dims(vinterp_out, 0),dims=['time','lev','lat','lon'])
            da_out.attrs['long_name']=ds_in[i2].long_name
            da_out.attrs['units']=ds_in[i2].units
            ds_out.append(da_out.to_dataset(name=i2))
        
        else: # 2 dimension data
          if pos=='T':  # interplate to lat-lon grid
            interp_out= rg_tt(ds_in[i].values)
            da_out=xr.DataArray(interp_out,dims=['time','lat','lon'])                    
            da_out.attrs['long_name']=ds_in[i].long_name
            da_out.attrs['units']=ds_in[i].units
            ds_out.append(da_out.to_dataset(name=i))
          elif pos == 'U':  #  interplate u and v to t-point, then rotate currents/winds to earth relative before interpolate to lat-lon grid
           #interpolate to t-points
            interp_u= rg_ut(ds_in[i].values)
            interp_v= rg_ut(ds_in[i2].values)
           #rotate to earth-relative 
            urot = interp_u[0,:,:]*self.cos_rot + interp_v[0,:,:]*self.sin_rot
            vrot = interp_v[0,:,:]*self.cos_rot - interp_u[0,:,:]*self.sin_rot
           #interoplate to lat-lon grid
            uinterp_out= rg_tt(urot)
            vinterp_out= rg_tt(vrot)
            da_out=xr.DataArray(np.expand_dims(uinterp_out, 0),dims=['time','lat','lon'])                    
            da_out.attrs['long_name']=ds_in[i].long_name
            da_out.attrs['units']=ds_in[i].units
            ds_out.append(da_out.to_dataset(name=i))
            da_out=xr.DataArray(np.expand_dims(vinterp_out, 0),dims=['time','lat','lon'])
            da_out.attrs['long_name']=ds_in[i2].long_name
            da_out.attrs['units']=ds_in[i2].units
            ds_out.append(da_out.to_dataset(name=i2))
  
    ds_out=xr.merge(ds_out)
    ds_out=ds_out.assign_coords(lon=('lon',lon1d))
    ds_out=ds_out.assign_coords(lat=('lat',lat1d))
    ds_out=ds_out.assign_coords(lev=('lev',ds_in.Layer.values))
    ds_out=ds_out.assign_coords(time=('time',ds_in.Time.values))
    ds_out['lon'].attrs['units']='degrees_east'
    ds_out['lon'].attrs['axis']='X'
    ds_out['lon'].attrs['standard_name']='longitude'
    ds_out['lat'].attrs['units']='degrees_north'
    ds_out['lat'].attrs['axis']='Y'
    ds_out['lat'].attrs['standard_name']='latitude'
    ds_out['lev'].attrs['units']='meters'
    ds_out['lev'].attrs['positive']='down'
    ds_out['lev'].attrs['axis']='Z'

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
 #files=glob.glob('ocn_????_??_??.nc')
  files=glob.glob(nemsrc + 'MOM.res.????-??-??-??-00-00.nc')
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

