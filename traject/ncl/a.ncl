 f = addfile("MRMS_EchoTop_18_00.50_20160920-161035.grib2", "r")
;f = addfile("MRMS_EchoTop_30_00.50_20160920-172432.grib2", "r")
;f = addfile("MRMS_EchoTop_50_00.50_20160920-170636.grib2", "r")

;print(f)

;exit

 var = f->EchoTop18_P0_L102_GLL0
;var = f->EchoTop30_P0_L102_GLL0
;var = f->EchoTop50_P0_L102_GLL0

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

 wks = gsn_open_wks("png", "echoTop_18")

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
                  
 plot = gsn_csm_contour_map(wks, var, res)        ; create plot

