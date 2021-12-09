;--------------------------------------------------------------
undef("get_density")
function get_density(sst, slp)
begin
;printVarSummary(sst)
;printVarSummary(slp)
;interpolate to new grid
;newsst = linint2(sst&lon,sst&lat,sst,True,slp&lon,slp&lat,0)

;print("sst&lat = " + sst&lat)
 lat = slp&lat(::-1)
;print("lat = " + lat)
;print("slp&lat = " + slp&lat)
 newlat = sst&lat(::-1)
;print("newlat = " + newlat)

 opt    = False
 newslp = area_conserve_remap_Wrap (slp&lon, lat, slp(:, ::-1), sst&lon, newlat, opt)

 newslp = newslp

 rGas = 287.04
 density = 100.0 * newslp / (rGas * (sst + 273.15))

 density!0   = "lat"
 density!1   = "lon"
 density&lat = newlat
 density&lon = sst&lon

;printVarSummary(density)

 return density
end

;--------------------------------------------------------------
 slp_file = addfile("slp.mon.mean.nc","r")
 slp = slp_file->slp

 sst_file = addfile("sst.mnmean.nc","r")
 SSTshort = sst_file->sst
 sst = SSTshort@scale_factor * tofloat(SSTshort)
 copy_VarAtts(SSTshort, sst)
 copy_VarCoords(SSTshort, sst)

 fu = addfile("uwnd.mon.mean.nc","r")
 uwnd = fu->uwnd
 fv = addfile("vwnd.mon.mean.nc","r")
 vwnd = fv->vwnd
;--------------------------------------------------------------
 month_names = (/"January", "Febrary",  "March", \
                 "April",   "May",      "June", \
                 "July",    "August",   "September", \
                 "October", "November", "December"/)
;--------------------------------------------------------------
;pixel = 2048
 pixel = 1024
 wks_type = "x11"
;wks_type = "png"
 wks_type@wkWidth = pixel
 wks_type@wkHeight = pixel
 wks = gsn_open_wks(wks_type,"SeasonalSSTandWind")
;gsn_define_colormap(wks,"BlueRed")
;gsn_define_colormap(wks,"gui_default")            ; choose colormap

;--------------------------------------------------------------
 resC                  = True                      ; plot mods desired
 resC@gsnDraw          = False                     ; don't draw yet
 resC@gsnFrame         = False                     ; don't advance yet
 resC@gsnSpreadColors  = True                      ; use full colormap

 resC@cnFillOn         = True                      ; turn on color
 resC@cnLinesOn        = False
 resC@cnLineLabelsOn   = False                     ; no contour line labels
 resC@cnInfoLabelOn    = False                     ; no info label

;resC@cnFillPalette        = "BlueDarkRed18"
;resC@cnFillPalette        = "MPL_PuRd"
;resC@cnFillPalette        = "MPL_seismic"
;resC@cnFillPalette        = "BlueWhiteRed"

 resC@cnLevelSelectionMode = "ExplicitLevels" ; use explicit levels
 resC@cnLevels             = fspan(-250.0, 250.0, 51)

 resV                  = True                      ; vector only resources
 resV@gsnDraw          = False                     ; don'd draw yet
 resV@gsnFrame         = False                     ; don't advance yet
 resV@mpFillOn         = False
 resV@mpOutlineOn      = True
 resV@vcRefMagnitudeF  = 5.0                       ; add a reference vector
 resV@vcRefLengthF     = 0.045                     ; what the ref length is
 resV@vcGlyphStyle     = "CurlyVector"             ; turn on curley vectors
 resV@vcLineArrowColor = "Black"
;resV@vcFillArrowsOn       = True
;resV@vcFillArrowFillColor = "White"
;resV@vcFillArrowEdgeColor = "Black"
;resV@vcFillArrowEdgeThicknessF = 3.0
;--------------------------------------------------------------
 intv = 3

 uwnd_yn = dim_avg_n_Wrap(uwnd, 0)
 vwnd_yn = dim_avg_n_Wrap(vwnd, 0)
 slp_yn  = dim_avg_n_Wrap(slp, 0)
 sst_yn  = dim_avg_n_Wrap(sst, 0)

;--------------------------------------------------------------

 rGas = 287.04
 den_yn = get_density(sst_yn, slp_yn)
 den_yn = rGas * sst_yn * log(den_yn)
 printVarSummary(den_yn)
 print("min(den_yn) = " + min(den_yn) + ", max(den_yn) = " + max(den_yn))

 do n = 1, 11, 2
    resC@tiMainString = "Monthly Wind and Density: " + month_names(n)

    uwnd_mn = dim_avg_n_Wrap(uwnd(n::12, :, :), 0)
    vwnd_mn = dim_avg_n_Wrap(vwnd(n::12, :, :), 0)
    slp_mn  = dim_avg_n_Wrap( slp(n::12, :, :), 0)
    sst_mn  = dim_avg_n_Wrap( sst(n::12, :, :), 0)

    den_mn = get_density(sst_mn, slp_mn)
    den_mn = rGas * sst_mn * log(den_mn)

   ;printVarSummary(den_mn)
   ;print("min(den_mn) = " + min(den_mn) + ", max(den_mn) = " + max(den_mn))

   ;uwnd_mn = uwnd_mn - uwnd_yn
   ;vwnd_mn = vwnd_mn - vwnd_yn
     den_mn =  den_mn -  den_yn

    den_mn!0   = "lat"
    den_mn!1   = "lon"
    den_mn&lat = sst&lat
    den_mn&lon = sst&lon

   ;printVarSummary(den_mn)
   ;print("min(den_mn) = " + min(den_mn) + ", max(den_mn) = " + max(den_mn))

   ;printVarSummary(den_mn)
   ;print("Monthly Density and WIND: " + month_names(n))
   ;print("min(den_mn) = " + min(den_mn) + ", max(den_mn) = " + max(den_mn))

    uwnd_mn@long_name = "Wind and Density"
    vwnd_mn@long_name = "Wind and Density"
     den_mn@long_name = "Wind and Density"

    uwnd_mn@units = "m/s & g/m~S~3~"
    vwnd_mn@units = "m/s & g/m~S~3~"
     den_mn@units = "m/s & g/m~S~3~"
    plotC = gsn_csm_contour_map(wks, den_mn, resC)
    plotV = gsn_csm_vector_map(wks, uwnd_mn(::intv, ::intv), vwnd_mn(::intv, ::intv), resV)

    overlay(plotC,plotV)
    draw(plotC)
    draw(plotV)
    frame(wks)
 end do

