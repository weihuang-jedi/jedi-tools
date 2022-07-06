;-----------------------------------------------------
; read input file and set variables
;-----------------------------------------------------
 f = addfile("input.nc", "r")
 x = f->tmp(0,:,:,:)
 x@units = "K"

;printVarSummary(x)
;printMinMax(x, True)
;-----------------------------------------------------
; perform conservative remapping to two different grid resolutions
;-----------------------------------------------------
 opt      = False

 pfull = x&pfull
 lati = x&grid_yt
 lon = x&grid_xt
 lat = lati(::-1)
 x&grid_yt = lat(::-1)
 y = (/x(:,::-1,:)/)

 y!0   = "pfull"
 y!1   = "lat"
 y!2   = "lon"
 y&pfull = pfull 
 y&lat = lat 
 y&lon = lon 

 nlat =  180                              ; RES   = ""    
 mlon =  360                              
 lato = latGlobeFo(nlat, "lat", "latitude", "degrees_north")
 lono = lonGlobeFo(mlon, "lon", "longitude", "degrees_east" )
 z    = area_conserve_remap_Wrap (y&lon, y&lat, y, lono, lato, opt)

;printVarSummary(z)
;printMinMax(z, True)

;-----------------------------------------------------
; Create netCDF
;-----------------------------------------------------
   
 globeAtt              = 1
 globeAtt@title        = "Gaussian to lat/lon grid"    
 globeAtt@source_file  = "GSI Gaussian data"
 globeAtt@creation_date= systemfunc ("date" )
     
 ncout = "output.nc"
 system ("/bin/rm -f " +  ncout)    ; remove any pre-exist file 
           
 ncdf = addfile(ncout,"c")     
 fileattdef(ncdf, globeAtt)         ; create the global [file] attributes

 filedimdef(ncdf,"time",-1,True)    ; make time and UNLIMITED dimension      
                                    ; recommended  for most applications
 ncdf->t = z
 delete(ncdf)

