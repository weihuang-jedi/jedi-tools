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
 function gen_plot(lat, mls)
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
    res@xyMarkers         = (/12, 10, 8, 6, 4, 2, 2, 4, 6, 8, 10, 12/)
    res@xyMarkerColors   := (/"blue", "cyan", "green", "yellow", "orange", "red", \
                              "red", "orange", "yellow", "green", "cyan", "blue"/)

    res@tiMainString      = "Solar Radiation Reach the top of Atmosphere"

    plot = gsn_csm_xy (wks, lat, mls, res)

    return plot
 end

;-------------------------------------------------------------------------------
 undef("get_lat")
 function get_lat(nlat)
 begin
    delta = 180.0/nlat
    hdlt = 0.5*delta
    slat = -90.0 + hdlt
    elat =  90.0 - hdlt

    lat = fspan(slat, elat, nlat)

    lat!0 = "lat"
    lat&lat = lat

    return lat
 end

;-------------------------------------------------------------------------------
 undef("get_lon")
 function get_lon(nlon)
 begin
    delta = 360.0/nlon
    hdlt = 0.5*delta
    slon = hdlt
    elon = 360.0 - hdlt

    lon = fspan(slon, elon, nlon)

    lon!0 = "lon"
    lon&lon = lon

    return lon
 end

;-------------------------------------------------------------------------------
 undef("get_month_sol_lat")
 function get_month_sol_lat(lat)
 begin
    pi = 4.0*atan(1.0)
    deg2rad = pi/180.0

    nlat = dimsizes(lat)

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

    mls = new((/12,dimsizes(lat)/),float)

    do n = 0, 11
       mls(n,:) = get_sol_rad(lat, lat2d, tim2d, declin(n))
    end do

    return mls
 end

;-------------------------------------------------------------------------------
 undef("gen_yearly_solar")
 function gen_yearly_solar(nlat, nlon)
 begin
    ntim = 12

    tim = fspan(0.0, 11.0, ntim)
    tim!0 = "time"
    tim&time = tim

    lat = get_lat(nlat)
    lon = get_lon(nlon)
    mls = get_month_sol_lat(lat)

   ;plot = gen_plot(lat, mls)

    sol3d = new((/ntim, nlat, nlon/), float)

    do k = 0, ntim - 1
    do j = 0, nlat - 1
       sol3d(k,j,:) = mls(k,j)
    end do
    end do

    sol3d!0 = "time"
    sol3d!1 = "lat"
    sol3d!2 = "lon"

    sol3d&time = tim
    sol3d&lat = lat
    sol3d&lon = lon

    printVarSummary(sol3d)

    return sol3d
 end 

;-----------------------------------------------------------------------------------------

 sst_file = addfile("sst.mean.nc","r")
 SSTshort = sst_file->sst
 sst = SSTshort@scale_factor * tofloat(SSTshort) + SSTshort@add_offset
 copy_VarAtts(SSTshort, sst)
 copy_VarCoords(SSTshort, sst)

 slp_file = addfile("slp.mean.nc","r")
 SLPshort = slp_file->slp
 slp = SLPshort@scale_factor * tofloat(SLPshort) + SLPshort@add_offset
 copy_VarAtts(SLPshort, slp)
 copy_VarCoords(SLPshort, slp)
 ndims = dimsizes(slp)
 
 ntim = ndims(0)
 nlat = ndims(1)
 nlon = ndims(2)

 sol3d = gen_yearly_solar(nlat, nlon)

 sol = slp

 sol@long_name = "Solar Radiation at top of Atmosphere"
 sol@units     = "unknown"

 nt = 0

 do while(nt .lt. ntim)
    do n = 0, 11
       sol(nt, :, :) = sol3d(n, :, :)
       nt = nt + 1
       if(nt .ge. ntim) then
          break
       end if
    end do
 end do
 
;=================================================;
 month_names = (/"January", "Febrary",  "March", \
                 "April",   "May",      "June", \
                 "July",    "August",   "September", \
                 "October", "November", "December"/)
;************************************************
;pixel = 2048
 pixel = 1024
 wks_type = "x11"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"sst_slp")

 res = True
 res@mpFillOn     = False
 res@mpOutlineOn  = True	              ; turn the map outline on
 res@gsnDraw      =  False                   ; do not draw the plot
 res@gsnFrame     =  False                   ; do not advance the frame
 
;res@cnLevelSelectionMode = "ExplicitLevels" ; use explicit levels
;res@cnLevels             = ispan(-8,8,1) ; set the contour levels
;res@cnLevels             = (/-10.0, -8.0, -6.0, -4.0, -2.0, -1.0, -0.5, 0.0, \
;                               0.5,  1.0,  2.0,  4.0,  6.0,  8.0, 10.0/)
 res@cnLineLabelsOn       = False            ; do not use line labels
 res@cnFillOn             = True             ; color fill
 res@cnLinesOn            = False            ; do not draw contour lines
 res@cnFillPalette        = "BlueDarkRed18"

;res@tiMainString = "T/U @500hPa"            ; set the main title
 
 sres                      = True              ; set up a second resource list
 sres@gsnDraw              = False             ; do not draw the plot
 sres@gsnFrame             = False             ; do not advance the frame
;sres@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
;sres@cnLevels             = ispan(-4000,4000,100)   ; set the contour levels
;sres@cnLevels             = (/-40.0, -30.0, -20.0, -15.0, -10.0, -8.0, -6.0, -4.0, -2.0, -1.0, 0.0, \
;                                1.0,   2.0,   4.0,   6.0,   8.0, 10.0, 15.0, 20.0, 30.0, 40.0/)
 sres@cnFillOn             = False
 sres@cnLinesOn            = True
 sres@mpFillOn             = False
 sres@mpOutlineOn          = True	              ; turn the map outline on

;sres@cnLevelSelectionMode = "ManualLevels"  ; manual contour levels
;sres@cnMinLevelValF       = -4
;sres@cnMaxLevelValF       =  4
;sres@cnLevelSpacingF      =  0.25
 sres@gsnContourZeroLineThicknessF = 0       ; eliminates zero contour
 sres@gsnContourNegLineDashPattern = 1       ; sets negative contours to dash pattern 1

 sst_yearly_avg = dim_avg_n_Wrap(sst,0)
 slp_yearly_avg = dim_avg_n_Wrap(slp,0)
 sol_yearly_avg = dim_avg_n_Wrap(sol,0)

;printMinMax(sst_yearly_avg, True)
;printMinMax(slp_yearly_avg, True)
;printMinMax(sol_yearly_avg, True)

 res@tiMainString = "Corelation coefficient SST -> SOL: " + month_names(n)

;do n = 0, ntim - 1
;   sst(n, :, :) = sst(n, :, :) - sst_yearly_avg(:, :)
;   slp(n, :, :) = slp(n, :, :) - slp_yearly_avg(:, :)
;   sol(n, :, :) = sol(n, :, :) - sol_yearly_avg(:, :)
;end do

;printMinMax(sst, True)
;printMinMax(slp, True)
;printMinMax(sol, True)

;ccr = escorc_n(sst, slp, 0, 0)
;ccr = escorc_n(sst(0:ntim-2,:,:), slp(1:ntim-1,:,:), 0, 0)
;ccr = escorc_n(sol(0:ntim-2,:,:), slp(1:ntim-1,:,:), 0, 0)
 ccr = escorc_n(sol(0:ntim-2,:,:), sst(1:ntim-1,:,:), 0, 0)
;ccr = escorc_n(sol, sst, 0, 0)
 copy_VarCoords(sst_yearly_avg, ccr)

 printVarSummary(ccr)
 printMinMax(ccr, True)

;ccr = smth9(ccr, 0.50, -0.25, False)
;ccr = smth9(ccr, 0.50,  0.25, True)

;plot_ov = gsn_csm_contour_map(wks, slp_mn, sres)
;plot_ov = gsn_csm_contour_map(wks, ccr, sres)
 plot = gsn_csm_contour_map(wks, ccr, res)
;plot = gsn_csm_contour_map(wks, sol_mn(n, :, :), res)

;plot = gsn_csm_contour_map(wks, sst_mn, res)
;plot_ov = gsn_csm_contour_map(wks, slp_yearly_avg, sres)
 plot_ov = gsn_csm_contour_map(wks, sol_yearly_avg, sres)
;plot_ov = gsn_csm_contour_map(wks, sst_yearly_avg, sres)

 draw(plot)
 draw(plot_ov)
 frame(wks)                                  ; advance the frame

