 sst_file = addfile("sst.mnmean.nc","r")
 SSTshort = sst_file->sst
 sst = SSTshort@scale_factor * tofloat(SSTshort)
 copy_VarAtts(SSTshort, sst)
 copy_VarCoords(SSTshort, sst)

 slp_file = addfile("slp.mon.mean.nc","r")
 slp = slp_file->slp
 dims = dimsizes(slp)
 
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
 
 res@cnLevelSelectionMode = "ExplicitLevels" ; use explicit levels
;res@cnLevels             = ispan(-8,8,1) ; set the contour levels
 res@cnLevels             = (/-10.0, -8.0, -6.0, -4.0, -2.0, -1.0, -0.5, 0.0, \
                                0.5,  1.0,  2.0,  4.0,  6.0,  8.0, 10.0/)
 res@cnLineLabelsOn       = False            ; do not use line labels
 res@cnFillOn             = True             ; color fill
 res@cnLinesOn            = False            ; do not draw contour lines
 res@cnFillPalette        = "BlueDarkRed18"

 res@tiMainString = "T/U @500hPa"            ; set the main title
 
 sres                      = True              ; set up a second resource list
 sres@gsnDraw              = False             ; do not draw the plot
 sres@gsnFrame             = False             ; do not advance the frame
 sres@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
;sres@cnLevels             = ispan(-40,40,2)   ; set the contour levels
 sres@cnLevels             = (/-40.0, -30.0, -20.0, -15.0, -10.0, -8.0, -6.0, -4.0, -2.0, -1.0, 0.0, \
                                 1.0,   2.0,   4.0,   6.0,   8.0, 10.0, 15.0, 20.0, 30.0, 40.0/)
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

 do n = 1, 11, 3
    res@tiMainString = "Monthly SST/SLP: " + month_names(n)

    sst_mn = dim_avg_n_Wrap(sst(n::12, :, :),0)
    sst_mn = sst_mn - sst_yearly_avg

    plot = gsn_csm_contour_map(wks, sst_mn, res)

    slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)
    slp_mn = slp_mn - slp_yearly_avg

    plot_ov = gsn_csm_contour_map(wks, slp_mn, sres)

    draw(plot)
    draw(plot_ov)
    frame(wks)                                  ; advance the frame
 end do

