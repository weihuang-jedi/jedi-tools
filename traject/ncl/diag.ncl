;----------------------------------------------------------
 external INTERP_TOOL "./wei_tools.so"
;----------------------------------------------------------
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;----------------------------------------------------------
 undef("print_p_var_min_max")
 procedure print_p_var_min_max(vn:string, v:float, prs:float, nlev:integer)
 begin
    print("")
    print(vn + " p-level min max = (/ \")
    do n = 0, nlev - 1
       print("   /" + min(v(n,:,:)) + ", " + max(v(n,:,:)) + "/, \     ; " + prs(n) + "Pa")
    end do
    print("/")
    print("")
 end

;----------------------------------------------------------
 undef("print_h_var_min_max")
 procedure print_h_var_min_max(vn:string, v:float, \
                               nlon:integer, nlat:integer, nlev:integer, \
                               h:float, hgt:float, nhl:integer)
 local v2d
 begin
    print("")
    print(vn + " h-level min max = (/ \")
    v2d = v(0, :, :)
    do n = 0, nhl - 1
       INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, \
                                           v, h, hgt(n), v2d)
       print("   /" + min(v2d) + ", " + max(v2d) + "/, \      ; " + hgt(n) + " m")
    end do
    print("/")
    print("")
 end 

;----------------------------------------------------------
 undef("print_h_grad_min_max")
 procedure print_h_grad_min_max(vn:string, v:float, factor:float, \
                                nlon:integer, nlat:integer, nlev:integer, \
                                h:float, hgt:float, nhl:integer, \
                                lon:float, lat:float)
 local grdx, grdy, v2d
 begin
    print("")
    print(vn + " h-level gradient min max = (/ \")
    v2d = v(0, :, :)
    grdx = v(0, :, :)
    grdy = v(0, :, :)
    do n = 0, nhl - 1
       INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, v, h, hgt(n), v2d)
       INTERP_TOOL::calculate_gradient(nlon, nlat, v2d, lon, lat, grdx, grdy)
       grdx = factor*grdx
       grdy = factor*grdy
       print("grd x:" + min(grdx) + ", " + max(grdx) \
         + ", grd y:" + min(grdy) + ", " + max(grdy) + "   ; " + hgt(n) + " m")
    end do
    print("/")
    print("")
 end

;----------------------------------------------------------
;dir_name = "/Users/weihuang/scratch/data"
;filename = "gfs.t12z.pgrb2.1p00.f000"
;f = addfile(dir_name + "/" + filename + ".grb2", "r")

 f = addfile("pgbh00.gdas.201501.00Z.grib2", "r")

 u = f->UGRD_P8_L100_GLL0
 v = f->VGRD_P8_L100_GLL0
 w = f->VVEL_P8_L100_GLL0
 t = f->TMP_P8_L100_GLL0
 h = f->HGT_P8_L100_GLL0

;printVarSummary(u)

 u = u(:,::-1,:)
 v = v(:,::-1,:)
 w = w(:,::-1,:)
 t = t(:,::-1,:)
 h = h(:,::-1,:)
;printVarSummary(u)

;ter = f->HGT_P0_L1_GLL0

;sfp = f->PRES_P0_L1_GLL0
;p80m = f->PRES_P0_L103_GLL0
;slp = f->PRMSL_P0_L101_GLL0

;printVarSummary(ter)
;printMinMax(ter, True)

;printVarSummary(h)
;printMinMax(h, True)

;print("h&lv_ISBL0: " + h&lv_ISBL0)
;print("h&lat_0: " + h&lat_0)
;print("h&lon_0: " + h&lon_0)

 hdims = dimsizes(h)
;print("h dims: " + hdims)

;----------------------------------------------------------
 lon = h&lon_0
 lat = h&lat_0
 prs = h&lv_ISBL0

 nlev = dimsizes(prs)
 nlat = dimsizes(lat)
 nlon = dimsizes(lon)

 hgt = fspan(1000.0, 40000, 40)
 nhl = dimsizes(hgt)
 p3p = t

 do n = 0, nlev - 1
    p3p(n, :, :) = (/prs(n)/)
 end do

;----------------------------------------------------------
 r = 287.058

 print_p_var_min_max("h", h, prs, nlev)
 print_p_var_min_max("t", t, prs, nlev)
 print_p_var_min_max("u", u, prs, nlev)
 print_p_var_min_max("v", v, prs, nlev)

 spd = sqrt(u^2 + v^2)
 print_p_var_min_max("spd", spd, prs, nlev)

 rho = p3p/(r*t)
 print_p_var_min_max("rho", rho, prs, nlev)

 print_h_var_min_max("p", p3p, nlon, nlat, nlev, h, hgt, nhl)
 print_h_var_min_max("t", t, nlon, nlat, nlev, h, hgt, nhl)
 print_h_var_min_max("u", u, nlon, nlat, nlev, h, hgt, nhl)
 print_h_var_min_max("v", v, nlon, nlat, nlev, h, hgt, nhl)
 print_h_var_min_max("rho", rho, nlon, nlat, nlev, h, hgt, nhl)

;print_h_grad_min_max("R.grd(T)", t, r, nlon, nlat, nlev, h, hgt, nhl, lon, lat)

;printVarSummary(rho)

 t2d = v(0, :, :)
 p2d = v(0, :, :)
 r2d = v(0, :, :)
 grdTx = v(0, :, :)
 grdTy = v(0, :, :)
 grdRHOx = v(0, :, :)
 grdRHOy = v(0, :, :)

 sumTx = hgt
 sumTy = hgt
 sumRHOx = hgt
 sumRHOy = hgt

 print("")
 print("grdient of R.grd(T), and R.T.grd(ln(rho)) at h-level gradient min max:")
 do n = 0, nhl - 1
    INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, p3p, h, hgt(n), p2d)
    INTERP_TOOL::vertical_interp2height(nlon, nlat, nlev, t, h, hgt(n), t2d)
    INTERP_TOOL::calculate_gradient(nlon, nlat, t2d, lon, lat, grdTx, grdTy)
    grdTx = r*grdTx
    grdTy = r*grdTy
    rho2d = p2d/(r*t2d)
    lnrho = log(rho2d)
    INTERP_TOOL::calculate_gradient(nlon, nlat, lnrho, lon, lat, grdRHOx, grdRHOy)
    grdRHOx = r*t2d*grdRHOx
    grdRHOy = r*t2d*grdRHOy
    print("grdTx:" + min(grdTx) + ", " + max(grdTx) \
      + ", grdRHOx:" + min(grdRHOx) + ", " + max(grdRHOx) \
      + ", grdTy:" + min(grdTy) + ", " + max(grdTy) \
      + ", grdRHOy:" + min(grdRHOy) + ", " + max(grdRHOy) + "   ; " + hgt(n) + " m")

    sumTx(n) = sum(abs(grdTx))
    sumTy(n) = sum(abs(grdTy))
    sumRHOx(n) = sum(abs(grdRHOx))
    sumRHOy(n) = sum(abs(grdRHOy))
 end do

 print("")
 print("sum of R.grd(T), and R.T.grd(ln(rho)) at h-level:")
 do n = 0, nhl - 1
    print("sumTx:" + sumTx(n) + ", sumRHOx:" + sumRHOx(n) \
      + ", sumTy:" + sumTy(n) \
      + ", sumRHOy:" + sumRHOy(n) + "   ; " + hgt(n) + " m")
 end do

