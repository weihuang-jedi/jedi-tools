!----------------------------------------------------------------------------------------
subroutine generate_header(model, latlon, flnm)
  
   use netcdf
   use module_io
   use latlon_module

   implicit none

   type(modelgrid),  intent(inout) :: model
   type(latlongrid), intent(inout) :: latlon
   character(len=*), intent(in)    :: flnm

   integer :: rc

   print *, 'Enter generate_header'
   print *, 'flnm = ', trim(flnm)
  
   call create_coord(model, latlon, flnm)

   call create_var_attr(model, latlon)

  !End define mode.
   rc = nf90_enddef(latlon%ncid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", latlon%ncid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
        "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

   print *, 'Leave generate_header'

end subroutine generate_header

!----------------------------------------------------------------------------------------
subroutine closefile(latlon)

   use netcdf
   use latlon_module
   use module_io, only : check_status

   implicit none

   type(latlongrid), intent(inout)             :: latlon

   integer :: i, j, n, rc

   rc =  nf90_close(latlon%ncid)
   call check_status(rc)
   print *, 'Finished Write to file: ', trim(latlon%filename)

end subroutine closefile

!----------------------------------------------------------------------------------------
subroutine interp2latlongrid(model, latlon)

   use netcdf
   use module_io
   use latlon_module

   implicit none

   type(modelgrid),  intent(inout) :: model
   type(latlongrid), intent(inout) :: latlon

  !print *, 'Enter interp2latlongrid'

   call process(model, latlon)

end subroutine interp2latlongrid

!---------------------------------------------------------------------------
subroutine create_global_attr(ncid, filename, title, type)

   implicit none

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title, type

  !print *, 'Enter create_global_attr'

 ! ----put global attributes----
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))
   call nc_putGlobalCharAttr(ncid, 'grid_type', trim(type))

end subroutine create_global_attr

!----------------------------------------------------------------------------------------
subroutine create_coord(model, latlon, flnm)

   use netcdf
   use latlon_module
   use module_io

   implicit none

   type(modelgrid),  intent(inout) :: model
   type(latlongrid), intent(inout) :: latlon
   character(len=*), intent(in)    :: flnm

   integer :: i, nd, rc, ncid

   integer, dimension(2) :: dimids

   real, dimension(1) :: hor

   logical :: fileExists

  !print *, 'Enter create_coord'
  !print *, 'flnm = ', trim(flnm)
  !print *, 'nt = ', nt
  !print *, 'time(1:nt) = ', time(1:nt)

  !print *, 'latlon%nlon = ',  latlon%nlon
  !print *, 'latlon%nlat = ',  latlon%nlat
  !print *, 'latlon%nlev = ',  latlon%nlev
  !print *, 'latlon%nlay = ',  latlon%nlay

   latlon%filename = trim(flnm)

   allocate(latlon%lev(latlon%nlev))

   do i = 1, latlon%nlev
      latlon%lev(i) = real(i-1)
   end do

   allocate(latlon%lay(latlon%nlay))

   do i = 1, latlon%nlay
      latlon%lay(i) = real(i-1)
   end do

   hor(1) = 0.0

   rc = nf90_noerr

   latlon%dimidt = -1

  !Create the file. 
   inquire(file=trim(flnm), exist=fileExists)
   if (fileExists) then
     !call nf90_open(filePath, NF90_WRITE, ncid)
      open(unit=1234, iostat=rc, file=trim(flnm), status='old')
      if(rc == 0) close(1234, status='delete')
   end if

  !rc = nf90_create(trim(flnm), NF90_CLOBBER, ncid)
   rc = nf90_create(trim(flnm), NF90_NETCDF4, ncid)
   call check_status(rc)

   latlon%ncid = ncid
  !print *, 'ncid = ', ncid

   rc = nf90_def_dim(ncid, 'lon', latlon%nlon, latlon%dimidx)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'lat', latlon%nlat, latlon%dimidy)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'lev', latlon%nlev, latlon%dimidz)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'lay', latlon%nlay, latlon%dimidl)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'hor', 1, latlon%dimidh)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'Time', NF90_UNLIMITED, latlon%dimidt)
   call check_status(rc)

   call create_global_attr(ncid, flnm, 'FV3 to Lat-Lon Grid', 'Lat-Lon Grid')

   dimids(1) = latlon%dimidx
   nd = 1
!--Field lon
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lon", &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   dimids(1) = latlon%dimidy
!--Field lat
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lat", &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = latlon%dimidz
!--Field lev
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lev", &
                      "Altitude Coordinate", &
                      "top_down", &
                      "Altitude" )

   dimids(1) = latlon%dimidl
!--Field lay
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "lay", &
                      "Layer Coordinate", &
                      "top_down", &
                      "Altitude" )

   dimids(1) = latlon%dimidt
!--Field time
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL8, &
                      "Time", &
                      "Time Coordinate", &
                      "time level", &
                      "Time" )

   !write lon
   call nc_put1Dvar0(ncid, 'lon', latlon%lon, 1, latlon%nlon)

   !write lat
   call nc_put1Dvar0(ncid, 'lat', latlon%lat, 1, latlon%nlat)

   !write lev
   call nc_put1Dvar0(ncid, 'lev', latlon%lev, 1, latlon%nlev)

   !write time
  !call nc_put1Ddbl0(ncid, 'Time', time, 1, latlon%time)

  !print *, 'Leave create_coord'
end subroutine create_coord

!-------------------------------------------------------------------------------------
subroutine create_var_attr(model, latlon)

   use netcdf
   use module_io
   use latlon_module

   implicit none

   type(modelgrid),  intent(inout) :: model
   type(latlongrid), intent(inout) :: latlon

   integer, dimension(4) :: dimids
   integer :: rc, nd, i
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates

  !print *, 'Enter create_var_attr'

   missing_real = -1.0e38
   missing_int = -999999

   do i = 1, model%nVars
      long_name = 'unknown'
      units = 'unknown'
      coordinates = 'Time lev lat lon'
      dimids(1) = latlon%dimidx
      dimids(2) = latlon%dimidy
      dimids(3) = latlon%dimidz
      dimids(4) = latlon%dimidt
      nd = 4

      long_name = trim(model%vars(i)%varname)
      units = 'm'

      call nc_putAttr(latlon%ncid, nd, dimids, NF90_REAL, &
                      trim(model%vars(i)%varname), &
                      trim(long_name), trim(units), &
                      trim(coordinates), missing_real)
   end do

end subroutine create_var_attr

!----------------------------------------------------------------------------------------
subroutine process(model, latlon)

   use netcdf
   use module_io
   use latlon_module

   implicit none

   type(modelgrid),  intent(inout) :: model
   type(latlongrid), intent(inout) :: latlon
!  real, dimension(latlon%nlon, latlon%nlat, latlon%nlev), intent(out) :: var3d

   integer :: i, j, k, n, ik, jk, m
   real :: w

!  do jk = 1, latlon%nlat
!  do ik = 1, latlon%nlon
!     do k = 1, latlon%nlev
!        var3d(ik, jk, k) = 0.0
!     end do
!
!     do m = 1, latlon%npnt
!        n = latlon%tile(ik, jk, m)
!        i = latlon%ilon(ik, jk, m)
!        j = latlon%jlat(ik, jk, m)
!        w = latlon%wgt(ik, jk, m)
!
!        do k = 1, latlon%nlev
!           var3d(ik, jk, k) = var3d(ik, jk, k) + w*model%var3d(i, j, k)
!        end do
!     end do
!  end do
!  end do

end subroutine process

