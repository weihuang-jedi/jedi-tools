;=================================================;
 fp  = addfile("slp.mon.mean.nc","r")
 slp = fp->slp
 dims = dimsizes(slp)

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
 resC@cnLevels             = fspan(980.0, 1040, 13)

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
 slp_yn  = dim_avg_n_Wrap(slp, 0)

 intv = 3

 resC@tiMainString = "SLP and WIND"

 plotC = gsn_csm_contour_map(wks, slp_yn, resC)
 plotV = gsn_csm_vector_map(wks, uwnd_yn(::intv, ::intv), vwnd_yn(::intv, ::intv), resV)

 overlay(plotC,plotV)
 draw(plotC)
 draw(plotV)
 frame(wks)

