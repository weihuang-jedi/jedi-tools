;-----------------------------------------------------
; regrid_9.ncl
;
; Concepts illustrated:
;   - Reading a variable off a file and updating its meta data
;   - Interpolating from a global GAUSSIAN grid to a lower resolution
;   - Computing global areal mean values after computing the appropriate weights 
;   - Drawing color-filled contours over a cylindrical equidistant map
;   - Paneling three plots vertically on a page
;   - Creating a netCDF file
;-----------------------------------------------------
; User specified options
;-----------------------------------------------------
  PLOT    = True
  netCDF  = True 

  pltDir  = "./"       ; only used if PLOT=True, otherwise ignored
  pltName = "regrid"
 ;pltType = "png"      ; x11, ps, pdf, eps, png [v5.2.0]
  pltType = "x11"      ; x11, ps, pdf, eps, png [v5.2.0]

  ncDir   = "./"       ; only used if netCDF=True, otherwise ignored
  ncFil   = "regrided_1x1"
;-----------------------------------------------------
; read input file and set variables
;-----------------------------------------------------
   diri  = "/work2/noaa/gsienkf/weihuang/C96_psonly_delp/2020011006/"
   fili  = "sanl_2020011006_fhr06_ensmean.nc"

   f     = addfile(diri+fili, "r")
   x     = f->tmp(0,:,:,:)
   x@units = "K"

   printVarSummary(x)
   printMinMax(x, True)
;-----------------------------------------------------
; perform conservative remapping to two different grid resolutions
;-----------------------------------------------------
   opt      = False

   pfull = x&pfull
   lato = x&grid_yt
   lon = x&grid_xt
   lat = lato(::-1)
   x&grid_yt = lat(::-1)
   y = (/x(:,::-1,:)/)

   y!0   = "pfull"
   y!1   = "lat"
   y!2   = "lon"
   y&pfull = pfull 
   y&lat = lat 
   y&lon = lon 

   NLAT  =  180                              ; RES   = ""    
   MLON  =  360                              
   LAT   = latGlobeFo(NLAT, "LAT", "latitude", "degrees_north")
   LON   = lonGlobeFo(MLON, "LON", "longitude", "degrees_east" )
   z     = area_conserve_remap_Wrap (y&lon, y&lat, y, LON, LAT, opt)

   printVarSummary(z)
   printMinMax(z, True)

;-----------------------------------------------------
; For illustration, compute the global means of input and output grids
;-----------------------------------------------------
   NLATT159 = dimsizes(z&LAT)
   gwi = latGauWgt(NLATT159, "lat", "gaussian weights", "")
   gwo = latRegWgt(LAT, "double", 0)

  ;xAvgT159 = wgt_areaave(y, gwi, 1.0, 0) 
  ;xAvg  = wgt_areaave(z, gwo, 1.0, 0) 

  ;xAvgDiff = xAvg-xAvgT159

  ;print(xAvgT159+"  "+xAvg+"   "+xAvgDiff)

  ;eps  = 0.001
  ;if (max(abs(xAvgDiff)).lt.eps) then
  ;    print("area_conserve_remap: T159  => : SUCCESS")
  ;else
  ;    print("area_conserve_remap: T159  => : FAIL: maxDiff ="+max(abs(xAvgDiff)))
  ;end if

;-----------------------------------------------------
; Create plot ? 
;-----------------------------------------------------
   if (PLOT) then
       wks    = gsn_open_wks(pltType, pltDir+pltName)
   
       plot = new(2, "graphic")
     
       res                      = True     ; plot mods desired
       res@gsnDraw              = False    ; don't draw
       res@gsnFrame             = False    ; don't advance frame     
       res@cnFillOn             = True     ; turn on color fill
       res@cnFillPalette        = "amwg"   ; set color map
       res@cnLinesOn            = False    ; turn of contour lines
      ;res@cnFillMode           = "CellFill"           ; Cell Mode
       res@cnFillMode           = "RasterFill"         ; Raster Mode
       res@cnLinesOn            =  False       ; Turn off contour lines
       res@cnLineLabelsOn       =  False       ; Turn off contour lines
      ;res@cnLevelSelectionMode = "ExplicitLevels"              
      ;res@cnLevels             = (/550, 650, 750, 800, 850, 900, 925, 950, 975, 1000, 1013/)
       res@cnMissingValFillPattern = 0         ; make 'missing' black
       res@cnMissingValFillColor   = "black"
   
       res@lbLabelBarOn         = False    ; turn off individual cb's
     
       res@mpCenterLonF         = 210.     ; chage to 210
       res@mpFillOn             = False
   
       nt = 0

       res@gsnLeftString   = "T159: (256,516)"
      ;res@gsnCenterString = "Areal Mean="+sprintf("%6.5f", xAvgT159(nt))
       plot(0) = gsn_csm_contour_map(wks, y(0,:,:), res)

       res@gsnLeftString   = ": (90,180)"
      ;res@gsnCenterString = "Areal Mean="+sprintf("%6.5f", xAvg(nt))
       plot(1) = gsn_csm_contour_map(wks, z(0,:,:), res)

       resP = True
       resP@gsnMaximize         = True                ; make ps/eps/pdf large [no effect x11]
      ;resP@gsnPaperOrientation = "Portrait"          ; force portrait
       resP@gsnPanelLabelBar    = True                ; add common colorbar
       resP@lbLabelFontHeightF  = 0.0175              ; change font size
       resP@gsnPanelMainString  = "Conservative Remap: Gaussian-to-Fixed"
       gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot
   end if    ; PLOT
  
;-----------------------------------------------------
; Create netCDF ? ... Only do 
; Recommend to always create a 'time' dimension 
; Save only the interpolated CMORPH (uncomment to sabe "COMB")
;-----------------------------------------------------
   if (netCDF) then
   
       globeAtt              = 1
       globeAtt@title        = "Gaussian to lat/lon grid"    
       globeAtt@source_file  = fili
       globeAtt@creation_date= systemfunc ("date" )
     
       NCFILE = ncDir + ncFil +".nc"
       system ("/bin/rm -f " +  NCFILE)    ; remove any pre-exist file 
           
       ncdf   = addfile(NCFILE,"c")     
       fileattdef( ncdf, globeAtt )        ; create the global [file] attributes

       filedimdef(ncdf,"time",-1,True)     ; make time and UNLIMITED dimension      
                                           ; recommended  for most applications
       ncdf->t = z

   end if    ; netCDF

