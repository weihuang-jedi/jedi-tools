 slp_file = addfile("slp_since1961.nc","r")
 slp = slp_file->pressure
 dims = dimsizes(slp)

 olr_file = addfile("olr.mon.mean.nc","r")
 OS = olr_file->olr
 olr = OS@scale_factor * tofloat(OS) + OS@add_offset
 copy_VarAtts(OS, olr)
 copy_VarCoords(OS, olr)
;************************************************
 pixel = 2048
 wks_type = "x11"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"slp_olr")

 res = True
 res@mpFillOn     = False
 res@mpOutlineOn  = True	              ; turn the map outline on
 res@gsnDraw      =  False                   ; do not draw the plot
 res@gsnFrame     =  False                   ; do not advance the frame
 
 res@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
;res@cnLevels             = ispan(-40,40,2)   ; set the contour levels
 res@cnLevels             = (/-40.0, -30.0, -20.0, -15.0, -10.0, -8.0, -6.0, -4.0, -2.0, -1.0, 0.0, \
                                 1.0,   2.0,   4.0,   6.0,   8.0, 10.0, 15.0, 20.0, 30.0, 40.0/)
 res@cnLineLabelsOn       = False            ; do not use line labels
 res@cnFillOn             = True             ; color fill
 res@cnLinesOn            = False            ; do not draw contour lines
 res@cnFillPalette        = "BlueDarkRed18"

 res@tiMainString = "T/U @500hPa"            ; set the main title
 
 sres                      = True              ; set up a second resource list
 sres@gsnDraw              = False             ; do not draw the plot
 sres@gsnFrame             = False             ; do not advance the frame
 sres@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
 sres@cnLevels             = (/-64.0, -32.0, -16.0, -8.0, -4.0, -2.0, 0.0, \
                                 2.0,   4.0,   8.0, 16.0, 32.0, 64.0/)
 sres@cnFillOn             = False
 sres@cnLinesOn            = True
 sres@mpFillOn             = False
 sres@mpOutlineOn          = True	              ; turn the map outline on

 sres@gsnContourZeroLineThicknessF = 0       ; eliminates zero contour
 sres@gsnContourNegLineDashPattern = 1       ; sets negative contours to dash pattern 1

 slp_yearly_avg = dim_avg_n_Wrap(slp,0)
 olr_yearly_avg = dim_avg_n_Wrap(olr,0)

 do n = 0, 11
    m = n + 1
    if(0 .eq. mod(m, 12)) then
       res@tiMainString = "Monthly SLP/OLR: 12"
    else
       res@tiMainString = "Monthly SLP/OLR: " + mod(m, 12)
    end if

    slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)
    slp_mn = slp_mn - slp_yearly_avg

    plot = gsn_csm_contour_map(wks, slp_mn, res)

    olr_mn = dim_avg_n_Wrap(olr(n::12, :, :),0)
    olr_mn = olr_mn - olr_yearly_avg

    plot_ov = gsn_csm_contour_map(wks, olr_mn, sres)

    draw(plot)
    draw(plot_ov)
    frame(wks)                                  ; advance the frame
 end do

