import xarray as xr
ds=xr.open_dataset('/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/C96_mosaic.nc')
ds['gridlocation']='C96/'
ds.to_netcdf('C96_mosaic.nc') # rewrite to netcdf

