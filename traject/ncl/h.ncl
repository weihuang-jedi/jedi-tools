;----------------------------------------------------------
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;----------------------------------------------------------
;f = addfile("pgbh00.gdas.201501.00Z.grib2", "r")
 f = addfile("pgbh00.gdas.201501.00Z.nc", "r")

 u = f->UGRD_P8_L100_GLL0
 v = f->VGRD_P8_L100_GLL0
 t = f->TMP_P8_L100_GLL0
 h = f->HGT_P8_L100_GLL0

;ter = f->HGT_P0_L1_GLL0

;sfp = f->PRES_P0_L1_GLL0
;p80m = f->PRES_P0_L103_GLL0
;slp = f->PRMSL_P0_L101_GLL0

;printVarSummary(ter)
;printMinMax(ter, True)

;printVarSummary(h)
;printMinMax(h, True)

;print("h&lv_ISBL0: " + h&lv_ISBL0)
;print("h&lat_0: " + h&lat_0)
;print("h&lon_0: " + h&lon_0)

 hdims = dimsizes(h)
;print("h dims: " + hdims)

;----------------------------------------------------------
;pixel = 2048
 pixel = 1024
 wks_type = "x11"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"example")

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
 res@vcLineArrowColor     = "green"           ; white vectors
 res@vcMinDistanceF       = 0.02              ; thins arrows near pole
 res@vcGlyphStyle         = "CurlyVector"     ; turns on curley vectors

 res@vcRefAnnoArrowLineColor   = "black"       ; black ref vector
 res@vcRefAnnoArrowUseVecColor = False

;----------------------------------------------------------
 prs = h&lv_ISBL0
 r = 287.058			; unit(J kg-1 K-1)

 npl = dimsizes(prs)
 hgt = fspan(1000.0, 40000, 40)
 nhl = dimsizes(hgt)
 p3p = t
 do n = 0, npl - 1
    p3p(n, :, :) = (/prs(n)/)
 end do

;----------------------------------------------------------
 do n = 1, npl - 1, 2
    h2d = h(n, :, :)
    t2d = t(n, :, :)
    rho2d = prs(n)/(r*t2d)
    copy_VarCoords(t2d, rho2d)
   ;----------------------------------------------------------
   ;first plot
    res@tiMainString         = "NH GHT at " + prs(n)/100 + " Mb"
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(0) = gsn_csm_vector_scalar_map_polar(wks, u(n,:,:), v(n,:,:), h2d, res)
   ;plot(0) = gsn_csm_contour_map_polar(wks, h2d, res) ; create plot object
   ;plot(0) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;second plot
    res@tiMainString         = "NH TEMP at " + prs(n)/100 + " Mb"
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(1) = gsn_csm_vector_scalar_map_polar(wks, u(n,:,:), v(n,:,:), t2d, res)
   ;plot(1) = gsn_csm_contour_map_polar(wks, t2d, res) ; create plot object
   ;plot(1) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;third plot
    res@tiMainString         = "NH RHO at " + prs(n)/100 + " Mb"
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(2) = gsn_csm_vector_scalar_map_polar(wks, u(n,:,:), v(n,:,:), rho2d, res)
   ;plot(2) = gsn_csm_contour_map_polar(wks, rho2d, res) ; create plot object
   ;plot(2) = ZeroNegDashLineContour (plot(2))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;fouth plot
    res@tiMainString = "SH GHT at " + prs(n)/100 + " Mb"
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(3) = gsn_csm_vector_scalar_map_polar(wks, u(n,:,:), v(n,:,:), h2d, res)
   ;plot(3) = gsn_csm_contour_map_polar(wks, h2d, res)  ; create plot object
   ;plot(3) = ZeroNegDashLineContour (plot(3))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;fifth plot
    res@tiMainString = "SH TEMP at " + prs(n)/100 + " Mb"
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(4) = gsn_csm_vector_scalar_map_polar(wks, u(n,:,:), v(n,:,:), t2d, res)
   ;plot(4) = gsn_csm_contour_map_polar(wks, t2d, res)  ; create plot object
   ;plot(4) = ZeroNegDashLineContour (plot(4))    ; Make negative cn lines dash
   ;----------------------------------------------------------
   ;sixth plot
    res@tiMainString = "SH RHO at " + prs(n)/100 + " Mb"
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(5) = gsn_csm_vector_scalar_map_polar(wks, u(n,:,:), v(n,:,:), rho2d, res)
   ;plot(5) = gsn_csm_contour_map_polar(wks, rho2d, res)  ; create plot object
   ;plot(5) = ZeroNegDashLineContour (plot(5))    ; Make negative cn lines dash
   ;panel them together
    pres = True
   ;pres@gsnPanelYWhiteSpacePercent = 5           ; increase white space around
    pres@gsnMaximize                = True        ; fill the page
    gsn_panel(wks,plot,(/2,3/),pres)              ; create panel plot
 end do

