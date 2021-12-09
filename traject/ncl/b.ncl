 f = addfile("MRMS_ReflectivityAtLowestAltitude_00.50_20160920-173034.grib2", "r")

;print(f)

;exit

 var = f->ReflectivityAtLowestAltitude_P0_L102_GLL0

 lon = var&lon_0
 lat = var&lat_0

 nlon = dimsizes(lon)
 nlat = dimsizes(lat)

 print("nlon = " + nlon + ", nlat = " + nlat)
 print("left-top: (lon, lat) = (" + lon(0) + ", " + lat(0) + ")")
 print("right-low: (lon, lat) = (" + lon(nlon-1) + ", " + lat(nlat-1) + ")")
 print("var = " + var(::1000, ::1000))

 printVarSummary(var)
 printMinMax(var, True)

;wks = gsn_open_wks("x11", "reflectivity")
 wks = gsn_open_wks("png", "reflectivity")

 res               = True                  ; plot mods desired
 res@cnFillOn      = True                  ; turn on color fill
 res@cnFillPalette = "BlWhRe"              ; choose colormap

 res@cnLinesOn     = False
 res@cnConstFEnableFill = True

 res@mpLimitMode   = "LatLon"
 res@mpMinLatF     = min(lat)
 res@mpMaxLatF     = max(lat)
 res@mpMinLonF     = min(lon)
 res@mpMaxLonF     = max(lon)
 res@mpCenterLonF  = 265.0

 res@gsnAddCyclic  = False

;automatically create nice min/max/ci values for blue/red colortable
;symMinMaxPlt(var,20,False,res)  
                  
 var@_FillValue = -999.0

 var = where(var .lt. 0.0, var@_FillValue, var)

;inc = 10
;inc = 5
 inc = 4
 plot = gsn_csm_contour_map(wks, var(::inc, ::inc), res)        ; create plot

