;Standard Deviation of x(i), i = 0, ..., n-1

;x_avg = sum(x(i))/n

;xd(i) = x(i) - x_avg

;sdv = sqrt(sum(xd(i))/(n-1))

;corelation coefficient between x, and y

;cc = sum((xd(i)/sdv_x)*(yd(i)/sdv_y))/(n-1)

 sst_file = addfile("sst.mean.nc","r")
 SSTshort = sst_file->sst
 sst = SSTshort@scale_factor * tofloat(SSTshort) + SSTshort@add_offset
 copy_VarAtts(SSTshort, sst)
 copy_VarCoords(SSTshort, sst)

 slp_file = addfile("slp.mean.nc","r")
 SLPshort = slp_file->slp
 slp = SLPshort@scale_factor * tofloat(SLPshort) + SLPshort@add_offset
 copy_VarAtts(SLPshort, slp)
 copy_VarCoords(SLPshort, slp)
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
 
;res@cnLevelSelectionMode = "ExplicitLevels" ; use explicit levels
;res@cnLevels             = ispan(-8,8,1) ; set the contour levels
;res@cnLevels             = (/-10.0, -8.0, -6.0, -4.0, -2.0, -1.0, -0.5, 0.0, \
;                               0.5,  1.0,  2.0,  4.0,  6.0,  8.0, 10.0/)
 res@cnLineLabelsOn       = False            ; do not use line labels
 res@cnFillOn             = True             ; color fill
 res@cnLinesOn            = False            ; do not draw contour lines
 res@cnFillPalette        = "BlueDarkRed18"

;res@tiMainString = "T/U @500hPa"            ; set the main title
 
 sres                      = True              ; set up a second resource list
 sres@gsnDraw              = False             ; do not draw the plot
 sres@gsnFrame             = False             ; do not advance the frame
;sres@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
;sres@cnLevels             = ispan(-4000,4000,100)   ; set the contour levels
;sres@cnLevels             = (/-40.0, -30.0, -20.0, -15.0, -10.0, -8.0, -6.0, -4.0, -2.0, -1.0, 0.0, \
;                                1.0,   2.0,   4.0,   6.0,   8.0, 10.0, 15.0, 20.0, 30.0, 40.0/)
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

    sst_mn = sst(n::12, :, :)
    slp_mn = slp(n::12, :, :)

    mdims = dimsizes(sst_mn)
    mt = mdims(0)

    printVarSummary(sst_mn)
    printVarSummary(slp_mn)

    do m = 0, mt - 1
       sst_mn(m, :, :) = sst_mn(m, :, :) - sst_yearly_avg(:, :)
       slp_mn(m, :, :) = slp_mn(m, :, :) - slp_yearly_avg(:, :)
    end do

    ccr = escorc_n(sst_mn, slp_mn, 0, 0)
    copy_VarCoords(sst_yearly_avg, ccr)

    printVarSummary(ccr)

   ;ccr = smth9(ccr, 0.50, -0.25, False)
    ccr = smth9(ccr, 0.50,  0.25, True)

   ;plot_ov = gsn_csm_contour_map(wks, slp_mn, sres)
   ;plot_ov = gsn_csm_contour_map(wks, ccr, sres)
    plot = gsn_csm_contour_map(wks, ccr, res)

    delete(sst_mn)
    delete(slp_mn)

    sst_mn = dim_avg_n_Wrap(sst(n::12, :, :),0)
    sst_mn = sst_mn - sst_yearly_avg

    slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)
    slp_mn = slp_mn - slp_yearly_avg

   ;plot = gsn_csm_contour_map(wks, sst_mn, res)
    plot_ov = gsn_csm_contour_map(wks, slp_mn, sres)

    delete(sst_mn)
    delete(slp_mn)

    draw(plot)
    draw(plot_ov)
    frame(wks)                                  ; advance the frame
 end do

