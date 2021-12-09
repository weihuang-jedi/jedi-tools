;=================================================;
 sst_file = addfile("sst.mnmean.nc","r")
 SSTshort = sst_file->sst
 sst = SSTshort@scale_factor * tofloat(SSTshort)
 copy_VarAtts(SSTshort, sst)
 copy_VarCoords(SSTshort, sst)

 fu = addfile("uwnd.mon.mean.nc","r")
 uwnd = fu->uwnd
 fv = addfile("vwnd.mon.mean.nc","r")
 vwnd = fv->vwnd
;=================================================;
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
 wks = gsn_open_wks(wks_type,"wind")
;gsn_define_colormap(wks,"BlueRed")
;gsn_define_colormap(wks,"gui_default")            ; choose colormap

 resC                  = True                      ; plot mods desired
 resC@tiMainString     = "Basic Vector/Scalar Plot"
 resC@cnFillOn         = True                      ; turn on color

 resC@gsnSpreadColors  = True                      ; use full colormap
 resC@cnLinesOn        = False
 resC@cnLineLabelsOn   = False                     ; no contour line labels
 resC@cnInfoLabelOn    = False                     ; no info label
 resC@gsnDraw          = False                     ; don't draw yet
 resC@gsnFrame         = False                     ; don't advance yet
 resC@cnLevelSelectionMode = "ExplicitLevels" ; use explicit levels
 resC@cnLevels             = (/-10.0, -8.0, -6.0, -4.0, -2.0,  0.0, \
                                 2.0,  4.0,  6.0,  8.0, 10.0, 12.0, \
                                14.0, 16.0, 18.0, 20.0, 22.0, 24.0, \
                                26.0, 28.0, 30.0, 32.0, 34.0, 36.0/)

 resV                  = True                      ; vector only resources
 resV@gsnDraw          = False                     ; don'd draw yet
 resV@gsnFrame         = False                     ; don't advance yet
 resV@mpFillOn         = False
 resV@mpOutlineOn      = True
 resV@vcRefMagnitudeF  = 5.0                       ; add a reference vector
 resV@vcRefLengthF     = 0.045                     ; what the ref length is
 resV@vcGlyphStyle     = "CurlyVector"             ; turn on curley vectors
 resV@vcLineArrowColor = "Black"

 uwnd_yn = dim_avg_n_Wrap(uwnd, 0)
 vwnd_yn = dim_avg_n_Wrap(vwnd, 0)
 sst_yn  = dim_avg_n_Wrap(sst, 0)

 intv = 3

 do n = 0, 11, 3
    resC@tiMainString = "Monthly WIND: " + month_names(n)

    uwnd_mn = uwnd(n, :, :)
    vwnd_mn = vwnd(n, :, :)
    sst_mn  =  sst(n, :, :)

   ;uwnd_mn = dim_avg_n_Wrap(uwnd(n::12, :, :), 0)
   ;vwnd_mn = dim_avg_n_Wrap(vwnd(n::12, :, :), 0)
   ;sst_mn  = dim_avg_n_Wrap(sst(n::12, :, :), 0)
   ;speed = sqrt(uwnd_mn^2+vwnd_mn^2)               

   ;uwnd_mn = uwnd_mn - uwnd_yn
   ;vwnd_mn = vwnd_mn - vwnd_yn
   ;sst_mn  =  sst_mn -  sst_yn

    plot = gsn_csm_contour_map(wks, sst_mn, resC)
    plotV = gsn_csm_vector_map(wks, uwnd_mn(::intv, ::intv), vwnd_mn(::intv, ::intv), resV)

    overlay(plot,plotV)
    draw(plot)
    draw(plotV)
    frame(wks)
 end do

