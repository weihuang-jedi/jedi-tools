; This file still has to be loaded manually
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 

;************************************************
; Read the file
;************************************************
 in    = addfile("sst.mnmean.nc","r")
 TS    = in->sst
 sst   = TS@scale_factor * tofloat(TS)
 copy_VarAtts(TS, sst)
 copy_VarCoords(TS, sst)
 dims = dimsizes(sst)
;************************************************
; create plot
;************************************************
 pixel = 2048
 wks_type = "x11"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"sst")

 res                      = True               ; plot mods desired
 res@tiMainString         = "Explicit Contour Levels"

 res@cnFillOn             = True               ; turn on color fill
;res@cnFillPalette        = "gui_default"      ; set color map
 res@cnLinesOn            = False              ; turn off contour lines

 res@gsnAddCyclic         = True
;res@lbOrientation        = "vertical"         ; vertical label bars

 res@cnLevelSelectionMode = "ExplicitLevels"  ; set explicit contour levels
 res@cnLevels             = fspan(-10.0, 10.0, 21)

;res@mpFillOn             = False              ; turn off gray continents
 res@mpCenterLonF         = 180                ; Centers the plot at 180 

 sst_yn = dim_avg_n_Wrap(sst,0)

 do n = 0, 11
    m = n + 1
    if(0 .eq. mod(m, 12)) then
       res@tiMainString = "Monthly SST: 12"
    else
       res@tiMainString = "Monthly SST: " + mod(m, 12)
    end if

    sst_mn = dim_avg_n_Wrap(sst(n::12, :, :),0)
    sst_mn = sst_mn - sst_yn

    plot = gsn_csm_contour_map(wks, sst_mn, res)   ; create plot
 end do

