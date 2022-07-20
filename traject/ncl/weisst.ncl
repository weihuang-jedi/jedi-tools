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
 month_names = (/"January", "Febrary",  "March", \
                 "April",   "May",      "June", \
                 "July",    "August",   "September", \
                 "October", "November", "December"/)
;--------------------------------------------------
 wks  = gsn_open_wks("x11", "example_plot")
 plot = new(2,graphic)
;--------------------------------------------------
 res = True                                    ; plot mods desired
 minsst = 5.0*(toint(min(sst))/5)
 maxsst = 5.0*(toint(max(sst))/5)
 res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
;res@cnMinLevelValF       = minsst
;res@cnMaxLevelValF       = maxsst
;res@cnLevelSpacingF      =   5.               ; set contour spacing
 res@cnMinLevelValF       = -12.0
 res@cnMaxLevelValF       =  12.0
 res@cnLevelSpacingF      =   1.               ; set contour spacing

 res@cnFillOn             = True               ; turn on color fill
;res@cnFillPalette        = "gui_default"      ; set color map
;res@cnLinesOn            = False              ; turn off contour lines

;res@gsnCenterString      = "300 mb"           ; plot center string
;res@gsnDraw              = False              ; Do not draw plot
;res@gsnFrame             = False              ; Do not advance frame
 res@gsnMaximize          = True               ; fill the page

;--------------------------------------------------
 printVarSummary(sst)
 sst_yn = dim_avg_n_Wrap(sst, 0)
 printVarSummary(sst_yn)
 nskip = 30*12
 do n = 0, 11, 3
   ;sst_mn = dim_avg_n_Wrap(sst(n::12, :, :),0)
    sst_mn = sst(n+nskip, :, :) - sst_yn
    copy_VarCoords(sst_yn, sst_mn)
   ;****************
   ;first plot
    res@tiMainString         = "NH Mean SST " + month_names(n)
    res@gsnPolar             = "NH"               ; specify the hemisphere
    plot(0) = gsn_csm_contour_map_polar(wks, sst_mn, res) ; create plot object
   ;plot(0) = ZeroNegDashLineContour (plot(0))    ; Make negative cn lines dash

   ;****************
   ;second plot
    res@tiMainString = "SH Mean SLP (since 1961) " + month_names(n)
    res@gsnPolar = "SH"                           ; specify the hemisphere
    plot(1) = gsn_csm_contour_map_polar(wks, sst_mn, res)  ; create plot object
   ;plot(1) = ZeroNegDashLineContour (plot(1))    ; Make negative cn lines dash
 end do

