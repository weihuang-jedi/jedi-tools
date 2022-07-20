!----------------------------------------------------------------------------------------
subroutine create_header(trajectory, flnm)

   use netcdf
   use module_trajectory
   use module_model, only : check_status

   implicit none

   type(trajectorytype), intent(inout) :: trajectory
   character(len=*), intent(in) :: flnm

   real, dimension(1:trajectory%nx) :: lon
   real, dimension(1:trajectory%ny) :: lat
   real, dimension(1)               :: time

   integer :: i, j, k, rc
   logical :: fileExists

   do i = 1, trajectory%nx
      lon(i) = trajectory%x(i,1)
   end do

   do j = 1, trajectory%ny
      lat(j) = trajectory%y(1,j)
   end do

  !print *, 'lon = ', lon
  !print *, 'lat = ', lat

   time(i) = 0.0

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

  !print *, 'trajectory%ncid = ', trajectory%ncid

   rc = nf90_def_dim(trajectory%ncid, 'time', NF90_UNLIMITED, trajectory%dimidt)
   call check_status(rc)
   rc = nf90_def_dim(trajectory%ncid, 'lon', trajectory%nx, trajectory%dimidx)
   call check_status(rc)
   rc = nf90_def_dim(trajectory%ncid, 'lat', trajectory%ny, trajectory%dimidy)
   call check_status(rc)

  !print *, 'dimidx = ', trajectory%dimidx
  !print *, 'dimidy = ', trajectory%dimidy
  !print *, 'dimidt = ', trajectory%dimidt

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

  !write time
   call nc_put1Dvar(trajectory%ncid, 'time', time, 1, 1, 1)

  !print *, 'Finished create file: ', trim(flnm)

end subroutine create_header

!-------------------------------------------------------------------------------------
subroutine write_var_attr(trajectory)

   use netcdf
   use module_trajectory

   implicit none

   type(trajectorytype), intent(in) :: trajectory

   integer, dimension(6) :: dimids, chunksize
   integer :: rc, nd
   integer :: missing_int
   real    :: missing_real

   missing_real = -1.0e38
   missing_int = -999999

   chunksize(1) = trajectory%nx
   chunksize(2) = trajectory%ny
   chunksize(3) = 1

   dimids(1) = trajectory%dimidx
   nd = 1
!--Field lon
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "lon", &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   nd = 1
!--Field lat
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "lat", &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = trajectory%dimidt
   nd = 1
!--Field time
   call nc_putAxisAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
                      "time", &
                      "time", &
                      "seconds", &
                      "time" )

   dimids(1) = trajectory%dimidx
   dimids(2) = trajectory%dimidy
   dimids(3) = trajectory%dimidt
   nd = 3

!--Field x
!  call nc_putAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
   call nc_putAttrWithChunking(trajectory%ncid, nd, dimids, chunksize, NF90_REAL, &
                   "x", &
                   "Longitude of Trajectory", &
                   "degree_east", &
                   "time lat lon", &
                   missing_real)

!--Field y
!  call nc_putAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
   call nc_putAttrWithChunking(trajectory%ncid, nd, dimids, chunksize, NF90_REAL, &
                   "y", &
                   "Latitude of Trajectory", &
                   "degree_north", &
                   "time lat lon", &
                   missing_real)

!--Field z
!  call nc_putAttr(trajectory%ncid, nd, dimids, NF90_REAL, &
   call nc_putAttrWithChunking(trajectory%ncid, nd, dimids, chunksize, NF90_REAL, &
                   "z", &
                   "Altitude of Trajectory", &
                   "meter", &
                   "time lat lon", &
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

!-------------------------------------------------------------------------------------
subroutine output_trajectory(trajectory, n, ct)

   use netcdf
   use module_trajectory

   implicit none

   type(trajectorytype), intent(in) :: trajectory
   integer, intent(in) :: n
   real, intent(in) :: ct

   integer :: rc, nd
   real, dimension(1:1) :: time

   real, dimension(trajectory%nx, trajectory%ny) :: var

  !print *, 'Enter output_trajectory'
  !print *, 'n = ', n
  !print *, 'trajectory%ncid = ', trajectory%ncid
  !print *, 'trajectory%nx = ', trajectory%nx
  !print *, 'trajectory%ny = ', trajectory%ny

   time(1) = ct
  !print *, 'output for time = ', time

   call nc_put1Dvar(trajectory%ncid, 'time', time, n+1, 1, 1)

   var = trajectory%x
   call nc_put2Dvar(trajectory%ncid, 'x', var, n+1, &
        1, trajectory%nx, 1, trajectory%ny)

   var = trajectory%y
   call nc_put2Dvar(trajectory%ncid, 'y', var, n+1, &
        1, trajectory%nx, 1, trajectory%ny)

   var = trajectory%z
   call nc_put2Dvar(trajectory%ncid, 'z', var, n+1, &
        1, trajectory%nx, 1, trajectory%ny)

  !print *, 'Leave output_trajectory'

end subroutine output_trajectory

