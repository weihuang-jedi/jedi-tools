;*************************************************
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;************************************************
 data_dir = "/Users/weihuang/work/research/"
 flnm = "slp_since1961.nc"
 f = addfile(data_dir + flnm, "r")
 slp = f->pressure
 dims = dimsizes(slp)
;************************************************
; create plot
;************************************************
 wks  = gsn_open_wks("x11", "example_plot")
 plot = new(2,graphic)
 res = True                                    ; plot mods desired
;res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
;res@cnMinLevelValF       = -10.               ; set min contour level
;res@cnMaxLevelValF       =  35.               ; set max contour level
;res@cnLevelSpacingF      =   5.               ; set contour spacing
;res@gsnCenterString      = "300 mb"           ; plot center string
 res@gsnDraw              = False              ; Do not draw plot
 res@gsnFrame             = False              ; Do not advance frame

 n = 0
 slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)
;****************
; first plot
;****************
 res@tiMainString         = "NH Mean SLP since 1961"
 res@gsnPolar             = "NH"               ; specify the hemisphere
 plot(0) = gsn_csm_contour_map_polar(wks, slp_mn, res) ; create plot object
;plot(0) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash
;****************
; second plot
;****************
 res@tiMainString = "SH Mean SLP since 1961"
 res@gsnPolar = "SH"                           ; specify the hemisphere
 plot(1) = gsn_csm_contour_map_polar(wks, slp_mn, res)  ; create plot object
;plot(1) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash
;****************
; panel them together
;****************
 pres = True
;pres@gsnPanelYWhiteSpacePercent = 5           ; increase white space around
;indiv. plots in panel
 pres@gsnMaximize                = True        ; fill the page
 gsn_panel(wks,plot,(/2,1/),pres)              ; create panel plot

