;====================================================
 f = addfile("verticalheight.nc","r")
 slp = f->SLP

 u = f->U
 v = f->V
 p = f->P
 t = f->T
 rh = f->RH
 pw = f->PW

 dims = dimsizes(p)

 nhgt = dims(0)
 nlat = dims(1)
 nlon = dims(2)

 print("nlon = " + nlon)
 print("nlat = " + nlat)
 print("nhgt = " + nhgt)

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
;resC@cnLevels             = fspan(980.0, 1040, 13)

 resV                  = True                      ; vector only resources
 resV@gsnDraw          = False                     ; don'd draw yet
 resV@gsnFrame         = False                     ; don't advance yet
 resV@mpFillOn         = False
 resV@mpOutlineOn      = True
 resV@vcRefMagnitudeF  = 5.0                       ; add a reference vector
 resV@vcRefLengthF     = 0.045                     ; what the ref length is
 resV@vcGlyphStyle     = "CurlyVector"             ; turn on curley vectors
 resV@vcLineArrowColor = "Black"

;--------------------------------------------------
 intv = 10

;resC@tiMainString = "SLP"
;slp = 0.01*slp
;plot = gsn_csm_contour_map(wks, slp, resC)
;draw(plot)
;frame(wks)

 resC@cnLevels = fspan(200.0, 310.0, 11)
 do n = 0, nhgt, intv
    resC@tiMainString = "UV and Temperature at " + (50*n) + "m"

    uh = u(n, :, :)
    vh = v(n, :, :)
    th = t(n, :, :)

    plotC = gsn_csm_contour_map(wks, th, resC)
    plotV = gsn_csm_vector_map(wks, uh(::intv, ::intv), vh(::intv, ::intv), resV)

    overlay(plotC,plotV)
    draw(plotC)
    draw(plotV)
    frame(wks)
 end do

