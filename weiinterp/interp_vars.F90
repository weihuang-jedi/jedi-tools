!----------------------------------------------------------------------------------------

subroutine interp2latlongrid(tile, latlon, flnm)

   use netcdf
   use tile_module
   use latlon_module

   implicit none

   type(tilegrid), dimension(6), intent(inout) :: tile
   type(latlongrid), intent(inout)             :: latlon
   character(len=*), intent(in)                :: flnm

   integer :: ncid, dimidx, dimidy, dimidz, dimidh, dimidt
   integer :: i, j, n, status

   real, dimension(:,:,:), allocatable :: var2d
   real, dimension(:,:,:), allocatable :: var3d

   real, dimension(latlon%nlon) :: lon
   real, dimension(latlon%nlat) :: lat
   real, dimension(latlon%nlev) :: lev

   real,         dimension(1)   :: hor

   real :: dlon, dlat

   status = nf90_noerr

   n = 0
   dimidt = -1

   !Create the file. 
   status = nf90_create(trim(flnm), NF90_CLOBBER, ncid)
   call check_status(status)

   dlon = 360.0/latlon%nlon
   dlat = 180.0/(latlon%nlat - 1)

   do i = 1, latlon%nlon
     latlon%lon(i) = dlon*real(i-1)
     lon(i) = dlon*real(i-1)
   end do

   do j = 1, latlon%nlat
     latlon%lat(j) = dlat*real(j-1) - 90.0
     lat(j) = dlat*real(j-1) - 90.0
   end do

   latlon%nlev = tile(1)%nz

   allocate(latlon%lev(latlon%nlev))

   do i = 1, latlon%nlev
      latlon%lev(i) = real(i-1)
      lev(i) = real(i-1)
   end do

   hor(1) = 0.0

  !print *, 'latlon%lon = ',  latlon%lon
  !print *, 'latlon%lat = ',  latlon%lat
  !print *, 'latlon%lev = ',  latlon%lev

   print *, 'latlon%nlon = ',  latlon%nlon
   print *, 'latlon%nlat = ',  latlon%nlat
   print *, 'latlon%nlev = ',  latlon%nlev
   
   status = nf90_def_dim(ncid, 'lon', latlon%nlon, dimidx)
   call check_status(status)
   status = nf90_def_dim(ncid, 'lat', latlon%nlat, dimidy)
   call check_status(status)
   status = nf90_def_dim(ncid, 'lev', latlon%nlev, dimidz)
   call check_status(status)
   status = nf90_def_dim(ncid, 'hor', 1, dimidh)
   call check_status(status)
   status = nf90_def_dim(ncid, 'Time', NF90_UNLIMITED, dimidt)
   call check_status(status)

   call create_global_attr(ncid, flnm, 'FV3 to Lat-Lon Grid', 'Lat-Lon Grid')

   call create_var_attr(tile, ncid, dimidx, dimidy, dimidz, dimidh, dimidt)

   !write lon
  !call nc_put1Dvar0(ncid, 'lon', latlon%lon, 1, latlon%nlon)
   call nc_put1Dvar0(ncid, 'lon', lon, 1, latlon%nlon)

   !write lat
  !call nc_put1Dvar0(ncid, 'lat', latlon%lat, 1, latlon%nlat)
   call nc_put1Dvar0(ncid, 'lat', lat, 1, latlon%nlat)

   !write lev
  !call nc_put1Dvar0(ncid, 'lev', latlon%lev, 1, latlon%nlev)
   call nc_put1Dvar0(ncid, 'lev', lev, 1, latlon%nlev)

   !write hor
   call nc_put1Dvar0(ncid, 'hor', hor, 1, 1)

   !write time
  !call nc_put1Dvar0(ncid, 'Time', latlon%lev, 1, latlon%nlev)
   call nc_put1Ddbl0(ncid, 'Time', tile(1)%time, 1, tile(1)%nt)

   allocate(var2d(latlon%nlon, latlon%nlat, 1))
   allocate(var3d(latlon%nlon, latlon%nlat, latlon%nlev))

   do i = 1, tile(1)%nVars
      status = nf90_inquire_variable(tile(1)%fileid, tile(1)%varids(i), &
               ndims=tile(1)%vars(i)%nDims, natts=tile(1)%vars(i)%nAtts)
      call check_status(status)

     !print *, 'Var No. ', i, ': ndims = ', tile(1)%vars(i)%nDims

      status = nf90_inquire_variable(tile(1)%fileid, tile(1)%varids(i), &
               dimids=tile(1)%vars(i)%dimids)
      call check_status(status)

      status = nf90_inquire_variable(tile(1)%fileid, tile(1)%varids(i), &
               name=tile(1)%vars(i)%name)
      call check_status(status)

      if(tile(1)%vars(i)%nDims < 2) cycle

      do n = 1, 6
         status = nf90_inquire_variable(tile(n)%fileid, tile(n)%varids(i), &
                  name=tile(n)%vars(i)%name)
         call check_status(status)

        !print *, 'Tile ', n, ', Var ', i, ': ', trim(tile(1)%vars(i)%name)

         if((trim(tile(n)%vars(i)%name) == 'ps') .or. &
            (trim(tile(n)%vars(i)%name) == 'phis')) then
            status = nf90_get_var(tile(n)%fileid, tile(n)%varids(i), tile(n)%var2d)
            call check_status(status)
         else if((trim(tile(n)%vars(i)%name) == 'ua') .or. &
                 (trim(tile(n)%vars(i)%name) == 'va') .or. &
                 (trim(tile(n)%vars(i)%name) == 'W') .or. &
                 (trim(tile(n)%vars(i)%name) == 'delp') .or. &
                 (trim(tile(n)%vars(i)%name) == 'DZ') .or. &
                 (trim(tile(n)%vars(i)%name) == 'T')) then
            status = nf90_get_var(tile(n)%fileid, tile(n)%varids(i), tile(n)%var3d)
            call check_status(status)
         end if
      end do

      if((trim(tile(1)%vars(i)%name) == 'ps') .or. &
         (trim(tile(1)%vars(i)%name) == 'phis')) then
         call interp2dvar(tile, latlon, var2d)
         call nc_put3Dvar(ncid, trim(tile(1)%vars(i)%name), &
              var2d, 1, 1, latlon%nlon, 1, latlon%nlat, 1, 1)
      else if((trim(tile(1)%vars(i)%name) == 'ua') .or. &
              (trim(tile(1)%vars(i)%name) == 'va') .or. &
              (trim(tile(1)%vars(i)%name) == 'W') .or. &
              (trim(tile(1)%vars(i)%name) == 'delp') .or. &
              (trim(tile(1)%vars(i)%name) == 'DZ') .or. &
              (trim(tile(1)%vars(i)%name) == 'T')) then
         call interp3dvar(tile, latlon, var3d)
         call nc_put3Dvar(ncid, trim(tile(1)%vars(i)%name), &
              var3d, 1, 1, latlon%nlon, 1, latlon%nlat, 1, latlon%nlev)
      end if
   end do

   deallocate(var2d)
   deallocate(var3d)

   status =  nf90_close(ncid)
   call check_status(status)
   print *, 'Finished Write to file: ', trim(flnm)

end subroutine interp2latlongrid

!-------------------------------------------------------------------------------------
subroutine create_var_attr(tile, ncid, dimid_nx, dimid_ny, dimid_nz, dimid_nh, dimid_nt)

   use netcdf
   use tile_module

   implicit none

   type(tilegrid), dimension(6), intent(inout) :: tile
   integer, intent(in) :: ncid
   integer, intent(in) :: dimid_nx, dimid_ny, dimid_nz, dimid_nh, dimid_nt

   integer, dimension(6) :: dimids
   integer :: status, nd, i
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates

   missing_real = -1.0e38
   missing_int = -999999

   dimids(1) = dimid_nx
   nd = 1
!--Field lon
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lon", &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   dimids(1) = dimid_ny
   nd = 1
!--Field lat
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lat", &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = dimid_nz
   nd = 1
!--Field lev
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lev", &
                      "Altitude Coordinate", &
                      "top_down", &
                      "Altitude" )

   dimids(1) = dimid_nh
   nd = 1
!--Field hor
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "hor", &
                      "Horizontal Coordinate", &
                      "one_level", &
                      "Horizontal" )

   dimids(1) = dimid_nt
   nd = 1
!--Field time
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL8, &
                      "Time", &
                      "Time Coordinate", &
                      "time level", &
                      "Time" )

   do i = 1, tile(1)%nVars
      if((trim(tile(1)%vars(i)%name) == 'xaxis_1') .or. &
         (trim(tile(1)%vars(i)%name) == 'xaxis_2') .or. &
         (trim(tile(1)%vars(i)%name) == 'yaxis_1') .or. &
         (trim(tile(1)%vars(i)%name) == 'yaxis_2') .or. &
         (trim(tile(1)%vars(i)%name) == 'zaxis_1') .or. &
         (trim(tile(1)%vars(i)%name) == 'u') .or. &
         (trim(tile(1)%vars(i)%name) == 'v') .or. &
         (trim(tile(1)%vars(i)%name) == 'Time')) then
         cycle
      end if

      long_name = 'unknown'
      units = 'unknown'
      coordinates = 'Time lev lat lon'
      dimids(1) = dimid_nx
      dimids(2) = dimid_ny
      dimids(3) = dimid_nz
      dimids(4) = dimid_nt
      nd = 4

      long_name = trim(tile(1)%vars(i)%name)
      if((trim(tile(1)%vars(i)%name) == 'ps') .or. &
         (trim(tile(1)%vars(i)%name) == 'phis')) then
         dimids(3) = dimid_nh
         coordinates = 'Time hor lat lon'
         if(trim(tile(1)%vars(i)%name) == 'ps') then
            long_name = 'surface_pressure'
            units = 'Pa'
         else if(trim(tile(1)%vars(i)%name) == 'phis') then
            long_name = 'surface_geopotential_height'
            units = 'm'
         end if
      else if((trim(tile(1)%vars(i)%name) == 'ua') .or. &
              (trim(tile(1)%vars(i)%name) == 'va') .or. &
              (trim(tile(1)%vars(i)%name) == 'W') .or. &
              (trim(tile(1)%vars(i)%name) == 'delp') .or. &
              (trim(tile(1)%vars(i)%name) == 'DZ') .or. &
              (trim(tile(1)%vars(i)%name) == 'T')) then
         if(trim(tile(1)%vars(i)%name) == 'ua') then
            long_name = 'eastward_wind'
            units = 'm/s'
         else if(trim(tile(1)%vars(i)%name) == 'va') then
            long_name = 'northward_wind'
            units = 'm/s'
         else if(trim(tile(1)%vars(i)%name) == 'T') then
            long_name = 'air_temperature'
            units = 'K'
         end if
      end if

      call nc_putAttr(ncid, nd, dimids, NF90_REAL, &
                      trim(tile(1)%vars(i)%name), &
                      trim(long_name), trim(units), &
                      trim(coordinates), missing_real)
   end do

!--End define mode.
   status = nf90_enddef(ncid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", ncid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

end subroutine create_var_attr

!---------------------------------------------------------------------------
subroutine create_global_attr(ncid, filename, title, type)

   implicit none

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title, type

 ! ----put global attributes----
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))
   call nc_putGlobalCharAttr(ncid, 'grid_type', trim(type))

  !call nc_putGlobalIntAttr(ncid, 'WRF_for_first_guess', iwrf)

  !call nc_putGlobalRealAttr(ncid, 'top_height',bdytop)

end subroutine create_global_attr

!----------------------------------------------------------------------
subroutine interp2dvar(tile, latlon, var2d)

  use tile_module
  use latlon_module

  implicit none

  type(tilegrid), dimension(6), intent(in) :: tile
  type(latlongrid), intent(in) :: latlon
  real, dimension(latlon%nlon, latlon%nlat, 1), intent(out) :: var2d

  integer :: i, j, n, ik, jk, m
  real :: w

  do jk = 1, latlon%nlat
  do ik = 1, latlon%nlon
     var2d(ik, jk, 1) = 0.0

     do m = 1, latlon%npnt
        n = latlon%tile(ik, jk, m)
        i = latlon%ilon(ik, jk, m)
        j = latlon%jlat(ik, jk, m)
        w = latlon%wgt(ik, jk, m)

        var2d(ik, jk, 1) = var2d(ik, jk, 1) + w*tile(n)%var2d(i, j)
     end do
  end do
  end do

end subroutine interp2dvar

!----------------------------------------------------------------------
subroutine interp3dvar(tile, latlon, var3d)

  use tile_module
  use latlon_module

  implicit none

  type(tilegrid), dimension(6), intent(in) :: tile
  type(latlongrid), intent(in) :: latlon
  real, dimension(latlon%nlon, latlon%nlat, latlon%nlev), intent(out) :: var3d

  integer :: i, j, k, n, ik, jk, m
  real :: w

  do jk = 1, latlon%nlat
  do ik = 1, latlon%nlon
     do k = 1, latlon%nlev
        var3d(ik, jk, k) = 0.0
     end do

     do m = 1, latlon%npnt
        n = latlon%tile(ik, jk, m)
        i = latlon%ilon(ik, jk, m)
        j = latlon%jlat(ik, jk, m)
        w = latlon%wgt(ik, jk, m)

        do k = 1, latlon%nlev
           var3d(ik, jk, k) = var3d(ik, jk, k) + w*tile(n)%var3d(i, j, k)
        end do
     end do
  end do
  end do

end subroutine interp3dvar

