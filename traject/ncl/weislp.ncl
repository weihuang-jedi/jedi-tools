;--------------------------------------------------
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;--------------------------------------------------
 data_dir = "/Users/weihuang/work/research/"
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
 minslp = 5.0*(toint(min(slp))/5)
 maxslp = 5.0*(toint(max(slp))/5)
 wks  = gsn_open_wks("x11", "example_plot")
 plot = new(2,graphic)
 res = True                                    ; plot mods desired
 res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
;res@cnMinLevelValF       = minslp
;res@cnMaxLevelValF       = maxslp
;res@cnLevelSpacingF      =   5.               ; set contour spacing
 res@cnMinLevelValF       = -40.0
 res@cnMaxLevelValF       =  40.0
 res@cnLevelSpacingF      =   5.               ; set contour spacing

 res@cnFillOn             = True               ; turn on color fill
;res@cnFillPalette        = "gui_default"      ; set color map
;res@cnLinesOn            = False              ; turn off contour lines

;res@gsnCenterString      = "300 mb"           ; plot center string
;res@gsnDraw              = False              ; Do not draw plot
;res@gsnFrame             = False              ; Do not advance frame
 res@gsnMaximize          = True               ; fill the page

;--------------------------------------------------
 slp_yn = dim_avg_n_Wrap(slp, 0)
 nskip = 50*12
 do n = 0, 11, 1
   ;slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)
    slp_mn = slp(n+nskip, :, :) - slp_yn
    copy_VarCoords(slp_yn, slp_mn)
   ;****************
   ;first plot
    res@tiMainString         = "NH Mean SLP (since 1961) " + month_names(n)
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(0) = gsn_csm_contour_map_polar(wks, slp_mn, res) ; create plot object
   ;plot(0) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash

   ;****************
   ;second plot
    res@tiMainString = "SH Mean SLP (since 1961) " + month_names(n)
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(1) = gsn_csm_contour_map_polar(wks, slp_mn, res)  ; create plot object
   ;plot(1) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash
 end do

