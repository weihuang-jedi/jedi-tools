;--------------------------------------------------
 f    = addfile("uwnd.mon.mean.nc","r")
 uwnd = f->uwnd
 dims = dimsizes(uwnd)
;--------------------------------------------------
 month_names = (/"January", "Febrary",  "March", \
                 "April",   "May",      "June", \
                 "July",    "August",   "September", \
                 "October", "November", "December"/)
;--------------------------------------------------
;pixel = 2048
 pixel = 1024
 wks_type = "x11"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"uwnd")
;gsn_define_colormap(wks,"BlueRed")

 res                      = True               ; plot mods desired
 res@tiMainString         = "Explicit Contour Levels"

 res@cnFillOn             = True               ; turn on color fill
;res@cnFillPalette        = "gui_default"      ; set color map
 res@cnLinesOn            = False              ; turn off contour lines

 res@gsnAddCyclic         = True
;res@lbOrientation       = "vertical"         ; vertical label bars

 res@cnLevelSelectionMode = "ExplicitLevels"  ; set explicit contour levels
 res@cnLevels           = (/-12.0, -10.0, -8.0, -6.0, -4.0, -2.0, -1.0,  -0.5, 0.0, \
                              0.5,   1.0,  2.0,  4.0,  6.0,  8.0, 10.0, 12.0/)

;res@mpFillOn            = False              ; turn off gray continents
 res@mpCenterLonF         = 180                ; Centers the plot at 180

 do n = 0, 11
   ;m = n + 1
   ;if(0 .eq. mod(m, 12)) then
   ;   res@tiMainString = "Monthly U-WIND: 12"
   ;else
   ;   res@tiMainString = "Monthly U-WIND: " + mod(m, 12)
   ;end if

    res@tiMainString = "Monthly U-WIND: " + month_names(n)

    uwnd_mn = dim_avg_n_Wrap(uwnd(n::12, :, :), 0)

    printVarSummary(uwnd_mn)
    printMinMax(uwnd_mn, True)

    plot = gsn_csm_contour_map(wks, uwnd_mn, res)   ; create plot
 end do

