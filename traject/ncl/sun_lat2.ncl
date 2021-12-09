;-------------------------------------------------------------------------------
;coszrs = 0.0
;do k=0, 1439
;   xt24 = mod(xtime+radt*0.5+real(k),1440.)
;   tloctm = gmt + xt24/60. + xlong(i,j)/15.
;   hrang = 15. * (tloctm-12.) * degrad
;   xxlat = xlat(i,j) * degrad
;   tloctm = sin(xxlat) * sin(declin) + cos(xxlat) * cos(declin) * cos(hrang)
;   if(tloctm > 0.0) then
;      coszrs = coszrs + tloctm
;   end if
;enddo
;coszrs = coszrs/1440.0
 undef("get_sol_rad")
 function get_sol_rad(lat, lat2d, tim2d, declin)
 begin
    pi = 4.0*atan(1.0)
    deg2rad = pi/180.0

    decrad = deg2rad * declin

    sol2d = sin(lat2d) * sin(decrad) + cos(lat2d) * cos(decrad) * cos(tim2d)

   ;printVarSummary(sol2d)
   ;print("min(sol2d) = " + min(sol2d) + ", max(sol2d) = " + max(sol2d))

    sol2d = where(sol2d .lt. 0.0, 0.0, sol2d)
   ;print("min(sol2d) = " + min(sol2d) + ", max(sol2d) = " + max(sol2d))

    sol_avg = dim_avg_n_Wrap(sol2d, 0)
   ;printVarSummary(sol_avg)
   ;print("min(sol_avg) = " + min(sol_avg) + ", max(sol_avg) = " + max(sol_avg))

    sol_avg!0 = "lat"
    sol_avg&lat = lat

    return sol_avg
 end 

;-----------------------------------------------------------------------------------------
 undef("gen_plot")
 function gen_plot(lat, data12)
 begin
   ;wks   = gsn_open_wks ("png","solar_clear_sky")
    wks   = gsn_open_wks ("x11","solar_clear_sky")

   ;---Set plotting parameters

    res                   = True                      ; plot mods desired
    res@gsnMaximize       = True
   ;res@xyLineThicknesses = (/  1.0,   2.0,   3.0/)   ; make second line thicker
    res@xyLineColors      = (/"blue", "cyan", "green", "yellow", "orange", "red", \
                              "red", "orange", "yellow", "green", "cyan", "blue"/)
    res@xyDashPattern     = 0                         ; Make curves all solid
    res@xyMarkLineMode    = "MarkLines"               ; Markers *and* lines
    res@xyMarkers         = (/16, 12, 10, 8, 6, 4, 4, 6, 8, 10, 12, 16/)
    res@xyMarkerColors   := (/"blue", "cyan", "green", "yellow", "orange", "red", \
                              "red", "orange", "yellow", "green", "cyan", "blue"/)

    res@tiMainString      = "Solar Radiation Reach the top of Atmosphere"

    plot = gsn_csm_xy (wks, lat, data12, res)

    return plot
 end

;-------------------------------------------------------------------------------
 pi = 4.0*atan(1.0)
 deg2rad = pi/180.0

 nlat = 181
 lat = fspan(-90.0, 90.0, nlat)

 lat!0 = "lat"
 lat&lat = lat

 ntim = 1440
 tim = fspan(0.5, 1439.5, ntim)

 sol2d = new((/ntim, nlat/), float)
 tim2d = conform(sol2d, tim, 0)
 lat2d = conform(sol2d, lat, 1) * deg2rad

;printVarSummary(tim2d)
;printVarSummary(lat2d)

 ts = fspan(0.5, 11.5, 12)
 ts = ts/12.0
 declin = -23.5*cos(2.0*pi*ts)

 print(ts)
 print(declin)

 data12 = new((/12,dimsizes(lat)/),float)

 do n = 0, 11
    data12(n,:) = get_sol_rad(lat, lat2d, tim2d, declin(n))
 end do

 plot = gen_plot(lat, data12)

