;----------------------------------------------------------
 external INTERP_TOOL "./wei_tools.so"
;----------------------------------------------------------
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;----------------------------------------------------------
;cmap  = read_colormap_file("gui_default")
;ncmap = dimsizes(cmap(:,0))

;----------------------------------------------------------
 res = True                                    ; plot mods desired
;res@mpMinLatF                 = 60                           ; minimum lat to plot
;res@mpCenterLonF              = 180
 res@mpFillOn                  = False

 res@gsnDraw                   = False              ; Do not draw plot
 res@gsnFrame                  = False              ; Do not advance frame

 res@cnInfoLabelOn             = False            ; turn off cn info label
;res@cnFillPalette             = cmap(:ncmap-3,:) ; skip last two colors

 res@cnFillOn                  = True
 res@cnLevelSelectionMode      = "ManualLevels"     ; set manual contour levels
;res@cnMinLevelValF            = 27200
;res@cnMaxLevelValF            = 31600
;res@cnLevelSpacingF           = 100

 res@gsnScalarContour          = True              ; vectors over scalars
 res@vcRefMagnitudeF           = 20.0              ; vec magnitude
 res@vcRefLengthF              = 0.04              ; size of ref vector
;res@vcLineArrowColor          = "white"           ; white vectors
 res@vcLineArrowColor          = "green"           ; green vectors
 res@vcMinDistanceF            = 0.02              ; thins arrows near pole
 res@vcGlyphStyle              = "CurlyVector"     ; turns on curley vectors

 res@vcRefAnnoArrowLineColor   = "green"       ; black ref vector
 res@vcRefAnnoArrowUseVecColor = False

 res@lbLabelBarOn              = False            ; turn off individual cb's

 r = 287.058			; unit(J kg-1 K-1)

 hminmax = (/(/45000.0, 50000.0, 200.0/), \     ; 100Pa
             (/40000.0, 45000.0, 200.0/), \     ; 200Pa
             (/35000.0, 41000.0, 200.0/), \     ; 300Pa
             (/33500.0, 37000.0, 100.0/), \     ; 500Pa
             (/31000.0, 34500.0, 100.0/), \     ; 700Pa
             (/29000.0, 32000.0, 100.0/), \     ; 1000Pa
             (/24500.0, 27000.0, 100.0/), \     ; 2000Pa
             (/22000.0, 24500.0, 100.0/), \     ; 3000Pa
             (/19000.0, 21000.0, 100.0/), \     ; 5000Pa
             (/17000.0, 19000.0, 100.0/), \     ; 7000Pa
             (/15000.0, 17000.0, 100.0/), \     ; 10000Pa
             (/13500.0, 15500.0, 100.0/), \     ; 12500Pa
             (/12500.0, 14500.0, 100.0/), \     ; 15000Pa
             (/11500.0, 13500.0, 100.0/), \     ; 17500Pa
             (/10500.0, 12500.0, 100.0/), \     ; 20000Pa
             (/10000.0, 12000.0, 100.0/), \     ; 22500Pa
             (/ 9000.0, 11000.0,  50.0/), \     ; 25000Pa
             (/ 8000.0, 10000.0,  50.0/), \     ; 30000Pa
             (/ 7000.0,  8000.0,  50.0/), \     ; 35000Pa
             (/ 6000.0,  8000.0,  50.0/), \     ; 40000Pa
             (/ 5000.0,  7000.0,  50.0/), \     ; 45000Pa
             (/ 4500.0,  6000.0,  50.0/), \     ; 50000Pa
             (/ 4200.0,  5200.0,  50.0/), \     ; 55000Pa
             (/ 3500.0,  4500.0,  40.0/), \     ; 60000Pa
             (/ 3000.0,  3800.0,  40.0/), \     ; 65000Pa
             (/ 2480.0,  3200.0,  40.0/), \     ; 70000Pa
             (/ 2000.0,  2680.0,  40.0/), \     ; 75000Pa
             (/ 1800.0,  2400.0,  20.0/), \     ; 77500Pa
             (/ 1500.0,  2160.0,  20.0/), \     ; 80000Pa
             (/ 1300.0,  1900.0,  20.0/), \     ; 82500Pa
             (/ 1100.0,  1660.0,  20.0/), \     ; 85000Pa
             (/  800.0,  1500.0,  20.0/), \     ; 87500Pa
             (/  600.0,  1200.0,  20.0/), \     ; 90000Pa
             (/  440.0,  1000.0,  20.0/), \     ; 92500Pa
             (/  220.0,   780.0,  20.0/), \     ; 95000Pa
             (/   20.0,   560.0,  20.0/), \     ; 97500Pa
             (/ -180.0,   360.0,  20.0/)/)     ; 100000Pa
  
;----------------------------------------------------------
 flnms = new((/12/), string)
 do n = 1, 12
   flnms(n-1) = "pgbh00.gdas.2015" + sprinti("%0.2d", n) + ".00Z.grib2"
   print("File " + n + ": " + flnms(n-1))
 end do

 f = addfiles(flnms, "r")

 varname = "hgt"

;----------------------------------------------------------
 h = f[0]->HGT_P8_L100_GLL0
 h = h(:,::-1,:)
;printVarSummary(h)

 hdims = dimsizes(h)
;print("h dims: " + hdims)

;initial_time = str_split(u@initial_time, "/ (:)")
;case_name = "plot_" + initial_time(2) + "_" + initial_time(0)

;---------------------------------------------------------
 lon = h&lon_0
 lat = h&lat_0
 prs = h&lv_ISBL0

 nlev = dimsizes(prs)
 nlat = dimsizes(lat)
 nlon = dimsizes(lon)

;----------------------------------------------------------
 nlev = 30
 do lvl = 1, nlev-1, 2

    res@cnMinLevelValF  = hminmax(lvl, 0)
    res@cnMaxLevelValF  = hminmax(lvl, 1)
    res@cnLevelSpacingF = hminmax(lvl, 2)

    print("hminmax(" + lvl + ", :) = " + hminmax(lvl, :))

    pixel = 2048
   ;pixel = 1024
    wks_type = "png"
    wks_type@wkWidth = pixel
    wks_type@wkHeight = pixel
    nh_img_name = "plot_NH_" + varname + "_2015_at_" + prs(lvl) + "Pa"
    nh_wks = gsn_open_wks(wks_type, nh_img_name)
    sh_img_name = "plot_SH_" + varname + "_2015_at_" + prs(lvl) + "Pa"
    sh_wks = gsn_open_wks(wks_type, sh_img_name)
   
   ;----------------------------------------------------------
    nh_plot = new(12, graphic)
    sh_plot = new(12, graphic)

   ;----------------------------------------------------------
    do n = 1, 12
       print("Lvl: " + lvl + ", Month: " + n)

       u = f[n-1]->UGRD_P8_L100_GLL0
       v = f[n-1]->VGRD_P8_L100_GLL0
       h = f[n-1]->HGT_P8_L100_GLL0

      ;printVarSummary(u)

       u = u(:,::-1,:)
       v = v(:,::-1,:)
       h = h(:,::-1,:)
      ;printVarSummary(u)
   
      ;----------------------------------------------------------
       lon = h&lon_0
       lat = h&lat_0
       prs = h&lv_ISBL0

       nlev = dimsizes(prs)
       nlat = dimsizes(lat)
       nlon = dimsizes(lon)

;----------------------------------------------------------
       h2d = h(lvl, :, :)
       u2d = u(lvl, :, :)
       v2d = v(lvl, :, :)

       print("Lvl: " + lvl + ", Month: " + n + ", min: " + min(h2d) + ", max: " + max(h2d))

       res@gsnPolar             = "NH"               ; specify the hemisphere

       nh_plot(n-1) = gsn_csm_vector_scalar_map_polar(nh_wks, u2d, v2d, h2d, res)

       res@gsnPolar             = "SH"               ; specify the hemisphere

       sh_plot(n-1) = gsn_csm_vector_scalar_map_polar(sh_wks, u2d, v2d, h2d, res)

      ;plot(n-1) = gsn_csm_contour_map_polar(wks, h2d, res) ; create plot object
      ;plot(n-1) = ZeroNegDashLineContour (plot(n-1))    ; Make negative cn lines dash
    end do

   ;panel them together
    pres = True
   ;pres@gsnPanelYWhiteSpacePercent = 5           ; increase white space around
    pres@gsnMaximize                = True        ; fill the page

    pres@gsnFrame              = False                  ; don't advance panel plot
    pres@gsnPanelLabelBar      = True                   ; add common colorbar
   ;pres@gsnPanelMainString    = "Geopotential Height"
    pres@txString              = "Geopotential Height " + prs(lvl) + "Pa"
    pres@gsnPanelBottom        = 0.05                   ; add space at bottom
    pres@gsnPanelFigureStringsBackgroundFillColor = "blue"
    pres@gsnPanelFigureStringsFontHeightF = 0.01
    pres@gsnPanelFigureStrings = (/"Jan", "Feb", "Mar", "Apr", "May", "Jun", \
                                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/) ; add strings to panel
    pres@amJust                = "TopLeft"

    pres@cnLevelSelectionMode  = "ManualLevels"     ; set manual contour levels
    pres@cnMinLevelValF        = hminmax(lvl, 0)
    pres@cnMaxLevelValF        = hminmax(lvl, 1)
    pres@cnLevelSpacingF       = hminmax(lvl, 2)

    gsn_panel(nh_wks, nh_plot, (/4,3/), pres)              ; create panel plot
    gsn_panel(sh_wks, sh_plot, (/4,3/), pres)              ; create panel plot

    txres               = True
    txres@txFontHeightF = 0.005

    foot_note = "Figure 1: NH geoptential height at " + prs(lvl) + "Pa"
    gsn_text_ndc(nh_wks, foot_note, 0.5, 0.02, txres)
    frame(nh_wks)
  
    delete(nh_wks)
    delete(nh_plot)

    foot_note = "Figure 1: SH geoptential height at " + prs(lvl) + "Pa"
    gsn_text_ndc(sh_wks, foot_note, 0.5, 0.02, txres)
    frame(sh_wks)

    delete(sh_wks)
    delete(sh_plot)
 end do

