!----------------------------------------------------------------------------------------

subroutine write_trajectory(trajectory, flnm)

   use netcdf
   use module_trajectory
   use module_model, only : check_status

   implicit none

   type(trajectorytype), intent(inout) :: trajectory
   character(len=*), intent(in) :: flnm

   real, dimension(1:trajectory%nx) :: lon
   real, dimension(1:trajectory%ny) :: lat
   real, dimension(1:trajectory%nz) :: alt
   real, dimension(1)               :: time

   integer :: i, j, k, rc
   logical :: fileExists

   do i = 1, trajectory%nx
      lon(i) = trajectory%x(i,1,1)
   end do

   do j = 1, trajectory%ny
      lat = trajectory%y(1,j,1)
   end do

   do k = 1, trajectory%nx
      alt = trajectory%z(1,1,k)
   end do

   time(1) = 0.0

   rc = nf90_noerr

  !Create the file. 
   inquire(file=trim(flnm), exist=fileExists)
   if (fileExists) then
      open(unit=1234, iostat=rc, file=trim(flnm), status='old')
      if(rc == 0) close(1234, status='delete')
   end if

  !rc = nf90_create(trim(flnm), NF90_CLOBBER, trajectory%ncid)
   rc = nf90_create(trim(flnm), NF90_NETCDF4, trajectory%ncid)
   call check_status(rc)

   print *, 'trajectory%ncid = ', trajectory%ncid

   rc = nf90_def_dim(trajectory%ncid, 'lon', trajectory%nx, trajectory%dimidx)
   call check_status(rc)
   rc = nf90_def_dim(trajectory%ncid, 'lat', trajectory%ny, trajectory%dimidy)
   call check_status(rc)
   rc = nf90_def_dim(trajectory%ncid, 'alt', trajectory%nz, trajectory%dimidz)
   call check_status(rc)
   rc = nf90_def_dim(trajectory%ncid, 'time', NF90_UNLIMITED, trajectory%dimidt)
   call check_status(rc)

   print *, 'dimidx = ', trajectory%dimidx
   print *, 'dimidy = ', trajectory%dimidy
   print *, 'dimidz = ', trajectory%dimidz
   print *, 'dimidt = ', trajectory%dimidt

   call write_global_attr(trajectory%ncid, flnm, 'Trajectory', 'Start from model grid')

   call write_var_attr(trajectory)

  !End define mode.
   rc = nf90_enddef(trajectory%ncid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", trajectory%ncid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

  !write lon
   call nc_put1Dvar0(trajectory%ncid, 'lon', lon, 1, trajectory%nx)

  !write lat
   call nc_put1Dvar0(trajectory%ncid, 'lat', lat, 1, trajectory%ny)

  !write alt
   call nc_put1Dvar0(trajectory%ncid, 'alt', alt, 1, trajectory%nz)

  !write time
  !call nc_put1Dvar0(trajectory%ncid, 'time', time, 1, 1)

   rc =  nf90_close(trajectory%ncid)

   print *, 'nf90_close rc = ', rc
   print *, 'nf90_noerr = ', nf90_noerr

   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to close ncid: <", trajectory%ncid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

   print *, 'Finished Write to file: ', trim(flnm)

end subroutine write_trajectory

!-------------------------------------------------------------------------------------
subroutine write_var_attr(trajectory)

   use netcdf
   use module_trajectory

   implicit none

   type(trajectorytype), intent(in) :: trajectory

   integer, dimension(6) :: dimids
   integer :: rc, nd
   integer :: missing_int
   real    :: missing_real

   missing_real = -1.0e38
   missing_int = -999999

   dimids(1) = trajectory%dimidx
   nd = 1
!--Field lon
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "lon", &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   dimids(1) = trajectory%dimidy
   nd = 1
!--Field lat
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "lat", &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = trajectory%dimidz
   nd = 1
!--Field pnt
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "alt", &
                      "Altitude Coordinate", &
                      "meter", &
                      "Altitude" )

   dimids(1) = trajectory%dimidt
   nd = 1
!--Field time
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "time", &
                      "Time", &
                      "seconds", &
                      "Time" )

   dimids(1) = trajectory%dimidx
   dimids(2) = trajectory%dimidy
   dimids(3) = trajectory%dimidz
   dimids(4) = trajectory%dimidt
   nd = 4

!--Field x
   call nc_putAttrInt(trajectory%ncid, nd, dimids, NF90_REAL, &
                   "x", &
                   "Longitude of Trajectory", &
                   "degree_east", &
                   "pnt lat lon", &
                   missing_int)

!--Field y
   call nc_putAttrInt(trajectory%ncid, nd, dimids, NF90_REAL, &
                   "y", &
                   "Latitude of Trajectory", &
                   "degree_north", &
                   "time alt lat lon", &
                   missing_int)

!--Field z
   call nc_putAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                   "z", &
                   "Altitude of Trajectory", &
                   "meter", &
                   "time alt lat lon", &
                   missing_real)

end subroutine write_var_attr

!---------------------------------------------------------------------------
subroutine write_global_attr(ncid, filename, title, gridtype)

   implicit none

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title, gridtype

  !output global attributes
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))
   call nc_putGlobalCharAttr(ncid, 'grid_type', trim(gridtype))

end subroutine write_global_attr

