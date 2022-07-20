;-----------------------------------------------------
; read input file and set variables
;-----------------------------------------------------
 f = addfile("input.nc", "r")
 x = f->t(0,:,:,:)
 x@units = "K"

;printVarSummary(x)
;printMinMax(x, True)
;-----------------------------------------------------
; perform conservative remapping to two different grid resolutions
;-----------------------------------------------------
 opt      = False

 nlat = 180                              ; RES   = ""    
 mlon = 360                              
 lat  = latGlobeFo(nlat, "lat", "latitude", "degrees_north")
 lon  = lonGlobeFo(mlon, "lon", "longitude", "degrees_east" )
 z    = area_conserve_remap_Wrap(x&lon, x&lat, x, lon, lat, opt)

;printVarSummary(z)
;printMinMax(z, True)

;-----------------------------------------------------
; Create netCDF
;-----------------------------------------------------
   
 globeAtt               = 1
 globeAtt@title         = "Gaussian to lat/lon grid"    
 globeAtt@source_file   = "FV3 Gaussian grid data file"
 globeAtt@creation_date = systemfunc ("date" )
     
 ncout = "output.nc"
 system ("/bin/rm -f " +  ncout)    ; remove any pre-exist file 
           
 ncdf = addfile(ncout,"c")     
 fileattdef(ncdf, globeAtt)        ; create the global [file] attributes

 filedimdef(ncdf,"time",-1,True)    ; make time and UNLIMITED dimension      
                                    ; recommended  for most applications
 ncdf->t = z
 delete(ncdf)

