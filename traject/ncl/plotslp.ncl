; This file still has to be loaded manually
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 

;************************************************
; Read the file
;************************************************
;f   = addfile("slp_since1961.nc","r")
 f   = addfile("slp.mean.nc","r")
 slp_short = f->slp
;slp:add_offset = 1197.65f ;
;slp:scale_factor = 0.01f ;
 slp = short2flt(slp_short)
 dims = dimsizes(slp)
;************************************************
; create plot
;************************************************
 pixel = 1024
 wks_type = "x11"
 wks_type@wkWidth = 1024
 wks_type@wkHeight = 512
 wks = gsn_open_wks(wks_type,"slp")

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

 res@gsnPolar   = "NH"                          ; specify the hemisphere
;plot = gsn_csm_contour_map_polar(wks,u,res)

 do n = 0, 11
    m = n + 1
    if(0 .eq. mod(m, 12)) then
       res@tiMainString = "Monthly SLP: 12"
    else
       res@tiMainString = "Monthly SLP: " + mod(m, 12)
    end if

    slp_mn = dim_avg_n_Wrap(slp(n::12, :, :),0)

    plot = gsn_csm_contour_map_polar(wks, slp_mn, res)   ; create plot
 end do

