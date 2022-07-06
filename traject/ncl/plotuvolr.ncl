;=================================================;
 olr_file = addfile("olr.mon.mean.nc","r")
 OS = olr_file->olr
 olr = OS@scale_factor * tofloat(OS) + OS@add_offset
 copy_VarAtts(OS, olr)
 copy_VarCoords(OS, olr)

;printVarSummary(olr)
;print("olr@lat = " + olr@lat)

 fu = addfile("uwnd.mon.mean.nc","r")
 uwnd = fu->uwnd
 fv = addfile("vwnd.mon.mean.nc","r")
 vwnd = fv->vwnd
;printVarSummary(vwnd)
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
 resC@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
 resC@cnLevels             = (/-64.0, -32.0, -16.0, -8.0, -4.0, -2.0, 0.0, \
                                 2.0,   4.0,   8.0, 16.0, 32.0, 64.0/)

 resV                  = True                      ; vector only resources
 resV@gsnDraw          = False                     ; don'd draw yet
 resV@gsnFrame         = False                     ; don't advance yet
 resV@mpFillOn         = False
 resV@mpOutlineOn      = True
 resV@vcRefMagnitudeF  = 2.0                       ; add a reference vector
 resV@vcRefLengthF     = 0.045                     ; what the ref length is
 resV@vcGlyphStyle     = "CurlyVector"             ; turn on curley vectors

 uwnd_yn = dim_avg_n_Wrap(uwnd, 0)
 vwnd_yn = dim_avg_n_Wrap(vwnd, 0)
 olr_yn  = dim_avg_n_Wrap(olr, 0)

 intv = 3

 do n = 0, 11, 3
    resC@tiMainString = "Monthly WIND: " + month_names(n)

    uwnd_mn = dim_avg_n_Wrap(uwnd(n::12, :, :), 0)
    vwnd_mn = dim_avg_n_Wrap(vwnd(n::12, :, :), 0)
    olr_mn  = dim_avg_n_Wrap(olr(n::12, :, :), 0)

    uwnd_mn = uwnd_mn - uwnd_yn
    vwnd_mn = vwnd_mn - vwnd_yn
    olr_mn  =  olr_mn -  olr_yn
    rolr_mn =  olr_mn(::-1, :)

    plot = gsn_csm_contour_map(wks, rolr_mn, resC)
    plotV = gsn_csm_vector_map(wks, uwnd_mn(::intv, ::intv), vwnd_mn(::intv, ::intv), resV)

    overlay(plot,plotV)
    draw(plot)
    draw(plotV)
    frame(wks)
 end do

