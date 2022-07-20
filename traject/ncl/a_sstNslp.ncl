;--------------------------------------------------
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;--------------------------------------------------
 data_dir = "/Users/weihuang/work/research/"
 flnm = "sst.mnmean.nc"
 f = addfile(data_dir + flnm, "r")
 TS = f->sst
 sst = TS@scale_factor * tofloat(TS)
 copy_VarAtts(TS, sst)
 copy_VarCoords(TS, sst)
 dims = dimsizes(sst)
;--------------------------------------------------
 flnm = "slp_since1961.nc"
 f = addfile(data_dir + flnm, "r")
 slp = f->pressure
 dims = dimsizes(slp)
;--------------------------------------------------
 month_names = (/"January", "Febrary",  "March", \
                 "April",   "May",      "June", \
                 "July",    "August",   "September", \
                 "October", "November", "December"/)
;--------------------------------------------------
 wks  = gsn_open_wks("x11", "example_plot")
 plot = new(2,graphic)
;--------------------------------------------------
 tres = True                                    ; plot mods desired
 tres@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
;minsst = 5.0*(toint(min(sst))/5)
;maxsst = 5.0*(toint(max(sst))/5)
;tres@cnMinLevelValF       = minsst
;tres@cnMaxLevelValF       = maxsst
;tres@cnLevelSpacingF      =   5.               ; set contour spacing
 tres@cnMinLevelValF       = -12.0
 tres@cnMaxLevelValF       =  12.0
 tres@cnLevelSpacingF      =   1.               ; set contour spacing

 tres@cnFillOn             = True               ; turn on color fill
;tres@cnFillPalette        = "gui_default"      ; set color map
;tres@cnLinesOn            = False              ; turn off contour lines

 tres@gsnDraw              = False              ; Do not draw plot
 tres@gsnFrame             = False              ; Do not advance frame
 tres@gsnMaximize          = True               ; fill the page

;--------------------------------------------------
 pres = True                                    ; plot mods desired
 pres@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
;minslp = 5.0*(toint(min(slp))/5)
;maxslp = 5.0*(toint(max(slp))/5)
;pres@cnMinLevelValF       = minslp
;pres@cnMaxLevelValF       = maxslp
;pres@cnLevelSpacingF      =   5.               ; set contour spacing
 pres@cnMinLevelValF       = -40.0
 pres@cnMaxLevelValF       =  40.0
 pres@cnLevelSpacingF      =   5.               ; set contour spacing

 pres@cnFillOn             = True               ; turn on color fill
;pres@cnFillPalette        = "gui_default"      ; set color map
;pres@cnLinesOn            = False              ; turn off contour lines

 pres@gsnDraw              = False              ; Do not draw plot
 pres@gsnFrame             = False              ; Do not advance frame
 pres@gsnMaximize          = True               ; fill the page

;--------------------------------------------------
;panel them together
 nres = True
 nres@gsnPanelYWhiteSpacePercent = 5           ; increase white space around
;indiv. plots in panel
 nres@gsnMaximize                = True        ; fill the page

;--------------------------------------------------
;printVarSummary(sst)
 sst_yn = dim_avg_n_Wrap(sst, 0)
;printVarSummary(sst_yn)
 iskip = 30*12

 slp_yn = dim_avg_n_Wrap(slp, 0)
 jskip = 50*12

 do n = 0, 11, 3
   ;sst_mn = dim_avg_n_Wrap(sst(n::12, :, :),0)
    sst_mn = sst(n+iskip, :, :) - sst_yn
    copy_VarCoords(sst_yn, sst_mn)

   ;slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)
    slp_mn = slp(n+jskip, :, :) - slp_yn
    copy_VarCoords(slp_yn, slp_mn)

   ;****************
   ;first plot
    tres@tiMainString         = "NH Mean SST " + month_names(n)
    tres@gsnPolar             = "NH"
    plot(0) = gsn_csm_contour_map_polar(wks, sst_mn, tres)
   ;plot(0) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash

   ;****************
   ;second plot
    pres@tiMainString         = "NH Mean SLP " + month_names(n)
    pres@gsnPolar             = "NH"               
    plot(1) = gsn_csm_contour_map_polar(wks, slp_mn, pres) 
   ;plot(1) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash

    gsn_panel(wks, plot, (/1,2/), nres)              ; create panel plot

   ;****************
   ;first plot
    tres@tiMainString = "SH Mean SST " + month_names(n)
    tres@gsnPolar = "SH"                           ; specify the hemisphere
    plot(0) = gsn_csm_contour_map_polar(wks, sst_mn, tres)  ; create plot object
   ;plot(0) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash

   ;****************
   ;second plot
    pres@tiMainString = "SH Mean SLP (since 1961) " + month_names(n)
    pres@gsnPolar = "SH"                           ; specify the hemisphere
    plot(1) = gsn_csm_contour_map_polar(wks, slp_mn, pres)  ; create plot object
   ;plot(1) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash

    gsn_panel(wks, plot, (/1,2/), nres)              ; create panel plot
 end do

