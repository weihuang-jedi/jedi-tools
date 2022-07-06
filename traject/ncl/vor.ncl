;-------------------------------------------------------------------------------
 undef("get_vor")
 function get_vor(lat, declin)
 begin
    pi = 4.0*atan(1.0)
    deg2rad = pi/180.0

    rad = deg2rad * (lat - declin)

   ;vor = -sin(rad) * cos(deg2rad * lat) * sin(deg2rad * lat)
    vor = -sin(rad) * sin(deg2rad * lat)

    vor!0 = "lat"
    vor&lat = lat

    return vor
 end 
;-------------------------------------------------------------------------------

 pi = 4.0*atan(1.0)
 deg2rad = pi/180.0

;print("pi = " + pi)
;print("deg2rad = " + deg2rad)

 nlat = 121
 lat = fspan(-30.0, 30.0, nlat)
;lat = fspan(-90.0, 90.0, nlat)

 lat!0 = "lat"
 lat&lat = lat

;print("lat = " + lat(::30))

 declin_winter = -23.5
 declin_spring = 0.0
 declin_summer = 23.5

;---Second plot, 3 curves.
 data2      = new((/4,dimsizes(lat)/),float)

 data2(0,:) = get_vor(lat, declin_winter)
 data2(1,:) = get_vor(lat, declin_spring)
 data2(2,:) = get_vor(lat, declin_summer)
 data2(3,:) = 0.00001 * get_vor(lat, declin_summer)

;wks   = gsn_open_wks ("png","vor")
 wks   = gsn_open_wks ("x11","vor")

;---Set plotting parameters

 res                   = True                      ; plot mods desired
 res@gsnMaximize       = True
;res@xyLineThicknesses = (/  1.0,   2.0,   3.0/)          ; make second line thicker
 res@xyLineColors      = (/"blue","red","yellow"/)          ; change line color
 res@xyDashPattern     = 0                         ; Make curves all solid
 res@xyMarkLineMode    = "MarkLines"               ; Markers *and* lines
 res@xyMarkers         = (/6,11,16,0/)               ; 3 different markers
 res@xyMarkerColors   := (/"blue","green","red","black"/) ; 3 different colors

 res@tiMainString      = "Solar Radiation Reach the top of Atmosphere"

 plot  = gsn_csm_xy (wks, lat, data2, res)

