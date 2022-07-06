;----------------------------------------------------------
 external INTERP_TOOL "./wei_tools.so"
;----------------------------------------------------------
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;----------------------------------------------------------
;dir_name = "/Users/weihuang/scratch/data"
;filename = "gfs.t12z.pgrb2.1p00.f000"
;f = addfile(dir_name + "/" + filename + ".grb2", "r")

 f = addfile("pgbh00.gdas.201501.00Z.grib2", "r")

 u = f->UGRD_P8_L100_GLL0
 v = f->VGRD_P8_L100_GLL0
 w = f->VVEL_P8_L100_GLL0
 t = f->TMP_P8_L100_GLL0
 h = f->HGT_P8_L100_GLL0

 initial_time = str_split(u@initial_time, "/ (:)")
 print("initial_time = " + initial_time)
 case_name = "plot_" + initial_time(2) + "_" + initial_time(0)

;printVarSummary(u)

 u = u(:,::-1,:)
 v = v(:,::-1,:)
 w = w(:,::-1,:)
 t = t(:,::-1,:)
 h = h(:,::-1,:)
;printVarSummary(u)

;sfp = f->PRES_P0_L1_GLL0
;p80m = f->PRES_P0_L103_GLL0
;slp = f->PRMSL_P8_L101_GLL0

;printVarSummary(h)
;printMinMax(h, True)

;print("h&lv_ISBL0: " + h&lv_ISBL0)
;print("h&lat_0: " + h&lat_0)
;print("h&lon_0: " + h&lon_0)

 hdims = dimsizes(h)
;print("h dims: " + hdims)

;----------------------------------------------------------
 pixel = 2048
;pixel = 1024
 wks_type = "png"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type, case_name)

;----------------------------------------------------------
 plot = new(6, graphic)
 res = True                                    ; plot mods desired
;res@mpMinLatF            = 60                           ; minimum lat to plot
;res@mpCenterLonF         = 180
 res@mpFillOn             = False

 res@cnFillOn             = True
;res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
;res@cnMinLevelValF       = 27200
;res@cnMaxLevelValF       = 31600
;res@cnLevelSpacingF      = 100
 res@gsnDraw              = False              ; Do not draw plot
 res@gsnFrame             = False              ; Do not advance frame

 res@gsnScalarContour     = True              ; vectors over scalars
 res@vcRefMagnitudeF      = 20.0              ; vec magnitude
 res@vcRefLengthF         = 0.04              ; size of ref vector
;res@vcLineArrowColor     = "white"           ; white vectors
 res@vcLineArrowColor     = "green"           ; green vectors
 res@vcMinDistanceF       = 0.02              ; thins arrows near pole
 res@vcGlyphStyle         = "CurlyVector"     ; turns on curley vectors

 res@vcRefAnnoArrowLineColor   = "black"       ; black ref vector
 res@vcRefAnnoArrowUseVecColor = False

;----------------------------------------------------------
 lon = h&lon_0
 lat = h&lat_0
 prs = h&lv_ISBL0
 r = 287.058			; unit(J kg-1 K-1)

 nlev = dimsizes(prs)
 nlat = dimsizes(lat)
 nlon = dimsizes(lon)

 hgt = fspan(1000.0, 40000, 40)
 nhl = dimsizes(hgt)
 p3p = t
 do n = 0, nlev - 1
    p3p(n, :, :) = (/prs(n)/)
 end do

;----------------------------------------------------------
 tmpv = h(0, :, :)
 p2d = h(0, :, :)
 t2d = t(0, :, :)
 u2d = u(0, :, :)
 v2d = v(0, :, :)
 do n = 1, nhl - 2, 2
    INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, \
                                        p3p, h, hgt(n), p2d)
    copy_VarCoords(tmpv, p2d)
    p2d@long_name = "Pressure"
    p2d@units = "Pa"
    printVarSummary(p2d)
    INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, \
                                        t, h, hgt(n), t2d)
    rho2d = p2d/(r*t2d)
    copy_VarCoords(tmpv, rho2d)
    rho2d@long_name = "Density"
    rho2d@units = "kg/M^3"
    printVarSummary(rho2d)
    INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, \
                                        u, h, hgt(n), u2d)
    INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, \
                                        v, h, hgt(n), v2d)
    copy_VarCoords(tmpv, u2d)
    copy_VarCoords(tmpv, v2d)
    printVarSummary(u2d)
    printVarSummary(v2d)

   ;----------------------------------------------------------
    print("hgt(" + n + ")=" + hgt(n))
    printMinMax(p2d, True)
    printMinMax(t2d, True)
    printMinMax(rho2d, True)
    printMinMax(u2d, True)
    printMinMax(v2d, True)
   ;----------------------------------------------------------
    tgrdx = u2d
    tgrdy = v2d
    tgrdx@long_name = "T gradient x-component"
    tgrdx@units = "J/(Kg M)"
    tgrdy@long_name = "T gradient y-component"
    tgrdy@units = "J/(Kg M)"
    INTERP_TOOL::calculate_gradient(nlon, nlat, t2d, lon, lat, tgrdx, tgrdy)
    tgrdx = r*tgrdx
    tgrdy = r*tgrdy
    copy_VarCoords(tmpv, tgrdy)
    copy_VarCoords(tmpv, tgrdx)
    printMinMax(tgrdx, True)
    printMinMax(tgrdy, True)
   ;print("tgrdy = " + tgrdy(:, 0))
    printVarSummary(tgrdx)
    printVarSummary(tgrdy)
   ;----------------------------------------------------------
    rgrdx = u2d
    rgrdy = v2d
    rgrdx@long_name = "Rho gradient x-component"
    rgrdx@units = "J/(Kg M)"
    rgrdy@long_name = "Rho gradient y-component"
    rgrdy@units = "J/(Kg M)"
    INTERP_TOOL::calculate_gradient(nlon, nlat, log(rho2d), lon, lat, rgrdx, rgrdy)
    rgrdx = r*t2d*rgrdx
    rgrdy = r*t2d*rgrdy
    copy_VarCoords(tmpv, rgrdy)
    copy_VarCoords(tmpv, rgrdx)
    printMinMax(rgrdx, True)
    printMinMax(rgrdy, True)
   ;print("rgrdy = " + rgrdy(:, 0))
    printVarSummary(rgrdx)
    printVarSummary(rgrdy)
   ;----------------------------------------------------------
   ;first plot
    res@tiMainString         = "NH PRES at " + hgt(n) + "m"
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(0) = gsn_csm_vector_scalar_map_polar(wks, u2d, v2d, p2d, res)
   ;plot(0) = gsn_csm_contour_map_polar(wks, h2d, res) ; create plot object
   ;plot(0) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;second plot
    res@tiMainString         = "NH TEMP at " + hgt(n) + "m"
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(1) = gsn_csm_vector_scalar_map_polar(wks, u2d, v2d, t2d, res)
   ;plot(1) = gsn_csm_vector_scalar_map_polar(wks, -tgrdy, tgrdx, t2d, res)
   ;plot(1) = gsn_csm_contour_map_polar(wks, t2d, res) ; create plot object
   ;plot(1) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;third plot
    res@tiMainString         = "NH RHO at " + hgt(n) + "m"
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(2) = gsn_csm_vector_scalar_map_polar(wks, u2d, v2d, rho2d, res)
   ;plot(2) = gsn_csm_vector_scalar_map_polar(wks, -rgrdy, rgrdx, rho2d, res)
   ;plot(2) = gsn_csm_contour_map_polar(wks, rho2d, res) ; create plot object
   ;plot(2) = ZeroNegDashLineContour (plot(2))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;fouth plot
    res@tiMainString = "SH PRES at " + hgt(n) + "m"
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(3) = gsn_csm_vector_scalar_map_polar(wks, u2d, v2d, p2d, res)
   ;plot(3) = gsn_csm_contour_map_polar(wks, h2d, res)  ; create plot object
   ;plot(3) = ZeroNegDashLineContour (plot(3))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;fifth plot
    res@tiMainString = "SH TEMP at " + hgt(n) + "m"
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(4) = gsn_csm_vector_scalar_map_polar(wks, u2d, v2d, t2d, res)
   ;plot(4) = gsn_csm_vector_scalar_map_polar(wks, -tgrdy, tgrdx, t2d, res)
   ;plot(4) = gsn_csm_contour_map_polar(wks, t2d, res)  ; create plot object
   ;plot(4) = ZeroNegDashLineContour (plot(4))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;sixth plot
    res@tiMainString = "SH RHO at " + hgt(n) + "m"
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(5) = gsn_csm_vector_scalar_map_polar(wks, u2d, v2d, rho2d, res)
   ;plot(5) = gsn_csm_vector_scalar_map_polar(wks, -rgrdy, rgrdx, rho2d, res)
   ;plot(5) = gsn_csm_contour_map_polar(wks, rho2d, res)  ; create plot object
   ;plot(5) = ZeroNegDashLineContour (plot(5))    ; Make negative cn lines dash
   ;panel them together
    pres = True
   ;pres@gsnPanelYWhiteSpacePercent = 5           ; increase white space around
    pres@gsnMaximize                = True        ; fill the page
    gsn_panel(wks,plot,(/2,3/),pres)              ; create panel plot
 end do

