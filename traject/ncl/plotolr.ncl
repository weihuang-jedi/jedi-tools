; This file still has to be loaded manually
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 

;************************************************
; Read the file
;************************************************
 in    = addfile("olr.mon.mean.nc","r")
 OS    = in->olr
 olr   = OS@scale_factor * tofloat(OS) + OS@add_offset
 copy_VarAtts(OS, olr)
 copy_VarCoords(OS, olr)
 dims = dimsizes(olr)
;************************************************
; create plot
;************************************************
 pixel = 2048
 wks_type = "x11"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"olr")

 res                      = True               ; plot mods desired
 res@tiMainString         = "Explicit Contour Levels"

 res@cnFillOn             = True               ; turn on color fill
 res@cnFillPalette        = "gui_default"      ; set color map
 res@cnLinesOn            = False              ; turn off contour lines

 res@gsnAddCyclic         = True
;res@lbOrientation       = "vertical"         ; vertical label bars

;res@cnLevelSelectionMode = "ExplicitLevels"  ; set explicit contour levels
;res@cnLevels           = (/-2.0, -1.0, 0.0, 5.0, 10.0, 15.0, 20.0, \
;                           25.0, 28.0, 29.0, 30.0, 30.5, 31.0/)

;res@mpFillOn            = False              ; turn off gray continents
 res@mpCenterLonF         = 180                ; Centers the plot at 180 

 do n = 0, 11
    m = n + 1
    if(0 .eq. mod(m, 12)) then
       res@tiMainString = "Monthly OLR: 12"
    else
       res@tiMainString = "Monthly OLR: " + mod(m, 12)
    end if

    olr_mn = dim_avg_n_Wrap(olr(n::12, :, :),0)

    plot = gsn_csm_contour_map(wks, olr_mn, res)   ; create plot
 end do

