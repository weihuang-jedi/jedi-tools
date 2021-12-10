!----------------------------------------------------------------------------------------
subroutine interpolation(grid, flnm, nalt, dz)
  
   use netcdf
   use module_grid

   implicit none

   type(gfsgrid),    intent(inout) :: grid
   character(len=*), intent(in)    :: flnm
   integer,          intent(in)    :: nalt
   real,             intent(in)    :: dz

   integer :: i, rc

   print *, 'Enter interpolation'
   print *, 'flnm = ', trim(flnm)
  
   grid%nalt = nalt
   allocate(grid%alt(grid%nalt))

   do i = 1, grid%nalt
      grid%alt(i) = real(i-1)*dz
   end do

   call create_coord(grid, flnm)

   call create_var_attr(grid)

  !End define mode.
   rc = nf90_enddef(grid%ncid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", grid%ncid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

   print *, 'before process'
   call process(grid)
   print *, 'after process'

   print *, 'Leave interpolation'

end subroutine interpolation

!---------------------------------------------------------------------------
subroutine create_global_attr(ncid, filename, title)

   implicit none

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title

  !put global attributes
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))

end subroutine create_global_attr

!----------------------------------------------------------------------------------------
subroutine create_coord(grid, flnm)

   use netcdf
   use module_grid

   implicit none

   type(gfsgrid),    intent(inout) :: grid
   character(len=*), intent(in)    :: flnm

   integer :: i, nd, rc, ncid

   integer, dimension(2) :: dimids

   logical :: fileExists

  !print *, 'Enter create_coord'
  !print *, 'flnm = ', trim(flnm)

  !print *, 'grid%nlon = ',  grid%nlon
  !print *, 'grid%nlat = ',  grid%nlat
  !print *, 'grid%npre = ',  grid%npre

  !print *, 'grid%lon = ',  grid%lon
  !print *, 'grid%lat = ',  grid%lat
  !print *, 'grid%pre = ',  grid%pre

   rc = nf90_noerr

   grid%output_flnm = trim(flnm)

  !Create the file. 
   inquire(file=trim(flnm), exist=fileExists)
   if (fileExists) then
      open(unit=1234, iostat=rc, file=trim(flnm), status='old')
      if(rc == 0) close(1234, status='delete')
   end if

   rc = nf90_create(trim(flnm), NF90_NETCDF4, ncid)
   call check_status(rc)

   grid%ncid = ncid
  !print *, 'ncid = ', ncid

   rc = nf90_def_dim(ncid, 'lon', grid%nlon, grid%dimidlon)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'lat', grid%nlat, grid%dimidlat)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'alt', grid%nalt, grid%dimidalt)
   call check_status(rc)

   call create_global_attr(ncid, flnm, 'Data in Height level')

   dimids(1) = grid%dimidlon
   nd = 1
!--Field lon
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lon', &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   dimids(1) = grid%dimidlat
!--Field lat
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lat', &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = grid%dimidalt
!--Field alt
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'alt', &
                      "Altitude Coordinate", &
                      "m", &
                      "Altitude" )

  !write lon
   call nc_put1Dvar0(ncid, 'lon', grid%lon, 1, grid%nlon)

  !write lat
   call nc_put1Dvar0(ncid, 'lat', grid%lat, 1, grid%nlat)

  !write alt
   call nc_put1Dvar0(ncid, 'alt', grid%alt, 1, grid%nalt)

  !print *, 'Leave create_coord'
end subroutine create_coord

!-------------------------------------------------------------------------------------
subroutine create_var_attr(grid)

   use netcdf
   use module_grid

   implicit none

   type(gfsgrid), intent(inout) :: grid

   integer, dimension(6) :: dimids, chunksize
   integer :: rc, nd, i
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates

   print *, 'Enter create_var_attr'

   missing_real = -1.0e38
   missing_int = -999999

   print *, 'grid%nVars = ', grid%nVars

   chunksize(1) = grid%nlon
   chunksize(2) = grid%nlat
   chunksize(3) = grid%nalt

   do i = 1, grid%nVars
      if(grid%vars(i)%nDims < 2) then
         cycle
      end if

      long_name = trim(grid%vars(i)%varname)
      units = 'unknown'
      coordinates = 'alt lat lon'
      dimids(1) = grid%dimidlon
      dimids(2) = grid%dimidlat
      dimids(3) = grid%dimidalt
      nd = 3

      if('TMP_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Ground or water surface temperature'
         units = 'K'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'TSK', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('TMP_P0_L102_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Sea Level Air Temperature'
         units = 'K'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'TSL', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('PWAT_P0_L200_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Precipitable water'
         units = 'kg m-2'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'PW', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('PRATE_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Precipitation rate'
         units = 'kg m-2 s-1'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'PRATE', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('PRMSL_P0_L101_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Mean sea level'
         units = 'Pa'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'SLP', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('HGT_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Terrain Height'
         units = 'gpm'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'TER', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('TMP_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Temperature'
         units = 'K'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'T', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%temp)
         call check_status(rc)
         call t2rho(grid)
      else if('HGT_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Pressure'
         units = 'Pa'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'P', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%hgt)
         call check_status(rc)
      else if('SPFH_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Specific humidity'
         units = 'kg kg-1'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'Q', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('RH_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Relative humidity'
         units = '%'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'RH', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('UGRD_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'U-component of wind'
         units = 'm s-1'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'U', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('VGRD_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'V-component of wind'
         units = 'm s-1'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'V', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('VVEL_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'W-component of wind'
         units = 'm s-1'
         call nc_putAttrWithChunking(grid%ncid, nd, dimids, chunksize, NF90_REAL, &
                         'W', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else
         cycle
      end if

      print *, 'Var No. ', i, ': name: ', trim(grid%vars(i)%varname)
   end do

   print *, 'Leave create_var_attr'

end subroutine create_var_attr

!-------------------------------------------------------------------------------------
subroutine create_var_attr_nochunking(grid)

   use netcdf
   use module_grid

   implicit none

   type(gfsgrid), intent(inout) :: grid

   integer, dimension(6) :: dimids
   integer :: rc, nd, i
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates

   print *, 'Enter create_var_attr'

   missing_real = -1.0e38
   missing_int = -999999

   print *, 'grid%nVars = ', grid%nVars

   do i = 1, grid%nVars
      if(grid%vars(i)%nDims < 2) then
         cycle
      end if

      long_name = trim(grid%vars(i)%varname)
      units = 'unknown'
      coordinates = 'alt lat lon'
      dimids(1) = grid%dimidlon
      dimids(2) = grid%dimidlat
      dimids(3) = grid%dimidalt
      nd = 3

      if('TMP_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Ground or water surface temperature'
         units = 'K'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'TSK', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('TMP_P0_L102_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Sea Level Air Temperature'
         units = 'K'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'TSL', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('PWAT_P0_L200_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Precipitable water'
         units = 'kg m-2'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'PW', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('PRATE_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Precipitation rate'
         units = 'kg m-2 s-1'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'PRATE', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('PRMSL_P0_L101_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Mean sea level'
         units = 'Pa'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'SLP', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('HGT_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         coordinates = 'lat lon'
         nd = 2
         long_name = 'Terrain Height'
         units = 'gpm'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'TER', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('TMP_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Temperature'
         units = 'K'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'T', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%temp)
         call check_status(rc)
         call t2rho(grid)
      else if('HGT_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Pressure'
         units = 'Pa'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'P', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%hgt)
         call check_status(rc)
      else if('SPFH_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Specific humidity'
         units = 'kg kg-1'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'Q', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('RH_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'Relative humidity'
         units = '%'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'RH', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('UGRD_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'U-component of wind'
         units = 'm s-1'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'U', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('VGRD_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'V-component of wind'
         units = 'm s-1'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'V', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else if('VVEL_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         long_name = 'W-component of wind'
         units = 'm s-1'
         call nc_putAttr(grid%ncid, nd, dimids, NF90_REAL, &
                         'W', trim(long_name), trim(units), &
                         trim(coordinates), missing_real)
      else
         cycle
      end if

      print *, 'Var No. ', i, ': name: ', trim(grid%vars(i)%varname)
   end do

   print *, 'Leave create_var_attr'

end subroutine create_var_attr_nochunking

!----------------------------------------------------------------------------------------
subroutine process(grid)

   use netcdf
   use module_grid

   implicit none

   type(gfsgrid), intent(inout) :: grid

   integer :: i, n, rc

   real, dimension(:,:), allocatable :: var2d
   real, dimension(:,:,:), allocatable :: var3d

   print *, 'Enter process'

   allocate(var2d(grid%nlon, grid%nlat))
   allocate(var3d(grid%nlon, grid%nlat, grid%nalt))

   do i = 1, grid%nVars
      if(grid%vars(i)%nDims < 2) cycle

      rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
               name=grid%vars(i)%varname)
      call check_status(rc)

      if('TMP_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         call flip(grid, var2d)
         call nc_put2Dvar0(grid%ncid, 'TSK', &
                           var2d, 1, grid%nlon, 1, grid%nlat)
      else if('TMP_P0_L102_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         call flip(grid, var2d)
         call nc_put2Dvar0(grid%ncid, 'TSL', &
                           var2d, 1, grid%nlon, 1, grid%nlat)
      else if('PWAT_P0_L200_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         call flip(grid, var2d)
         call nc_put2Dvar0(grid%ncid, 'PW', &
                           var2d, 1, grid%nlon, 1, grid%nlat)
      else if('PRATE_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         call flip(grid, var2d)
         call nc_put2Dvar0(grid%ncid, 'PRATE', &
                           var2d, 1, grid%nlon, 1, grid%nlat)
      else if('PRMSL_P0_L101_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         call flip(grid, var2d)
         call nc_put2Dvar0(grid%ncid, 'SLP', &
                           var2d, 1, grid%nlon, 1, grid%nlat)
      else if('HGT_P0_L1_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         call flip(grid, var2d)
         call nc_put2Dvar0(grid%ncid, 'TER', &
                           var2d, 1, grid%nlon, 1, grid%nlat)
      else if('HGT_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         call z2p(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'P', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%nalt)
      else if('TMP_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%var3d)
         call check_status(rc)
         call v2z(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'T', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%nalt)
      else if('SPFH_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%var3d)
         call check_status(rc)
         call v2z(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'Q', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%nalt)
      else if('RH_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%var3d)
         call check_status(rc)
         call v2z(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'RH', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%nalt)
      else if('UGRD_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%var3d)
         call check_status(rc)
         call v2z(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'U', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%nalt)
      else if('VGRD_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%var3d)
         call check_status(rc)
         call v2z(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'V', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%nalt)
      else if('VVEL_P0_L100_GLL0' == trim(grid%vars(i)%varname)) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), grid%var3d)
         call check_status(rc)
         call omega2w(grid)
         call v2z(grid, var3d)
         call nc_put3Dvar0(grid%ncid, 'W', &
                           var3d, 1, grid%nlon, 1, grid%nlat, 1, grid%npre)
      else
         cycle
      end if

      print *, 'Var No. ', i, ': name: ', trim(grid%vars(i)%varname)

   end do

   deallocate(var2d)
   deallocate(var3d)

   print *, 'Leave process'
end subroutine process

!----------------------------------------------------------------------
subroutine hgt2z(grid)

  use module_grid

  implicit none

  type(gfsgrid), intent(inout) :: grid

  integer :: i, j, k

  do k = 1, grid%npre
  do j = 1, grid%nlat
  do i = 1, grid%nlon
     grid%hgt(i,j,k) = grid%hgt(i,j,k)/9.8
  end do
  end do
  end do

end subroutine hgt2z

!----------------------------------------------------------------------
subroutine t2rho(grid)

  use module_grid

  implicit none

  type(gfsgrid), intent(inout) :: grid

  integer :: i, j, k

  do k = 1, grid%npre
  do j = 1, grid%nlat
  do i = 1, grid%nlon
     grid%temp(i,j,k) = grid%pre(k)/(287.0*grid%temp(i,j,k))
  end do
  end do
  end do

end subroutine t2rho

!----------------------------------------------------------------------
subroutine omega2w(grid)

  use module_grid

  implicit none

  type(gfsgrid), intent(inout) :: grid

  integer :: i, j, k

 !Note, grid%temp hold density now.
  do k = 1, grid%npre
  do j = 1, grid%nlat
  do i = 1, grid%nlon
     grid%var3d(i,j,k) = -grid%var3d(i,j,k)/(9.8*grid%temp(i,j,k))
  end do
  end do
  end do

end subroutine omega2w

!----------------------------------------------------------------------
subroutine z2p(grid, var3d)

  use module_grid

  implicit none

  type(gfsgrid), intent(in) :: grid
  real, dimension(grid%nlon, grid%nlat, grid%npre), intent(out) :: var3d

  integer :: i, j, k, n, jj

  real :: d, v

  do j = 1, grid%nlat
     jj = grid%nlat + 1 - j
  do i = 1, grid%nlon
     n = grid%npre - 1
  do k = 1, grid%npre
     if(grid%alt(k) <= grid%hgt(i,j,grid%npre)) then
        d = (grid%alt(k) - grid%hgt(i,j,grid%npre)) &
          / (grid%hgt(i,j,grid%npre-1) - grid%hgt(i,j,grid%npre))
        v = d*grid%pre(grid%npre-1) + (1.0-d)*grid%pre(grid%npre)
     else if(grid%alt(k) >= grid%hgt(i,j,1)) then
        d = (grid%alt(k) - grid%hgt(i,j,2)) &
          / (grid%hgt(i,j,1) - grid%hgt(i,j,2))
        v = d*grid%pre(1) + (1.0-d)*grid%pre(2)
     else
        do while (n > 1)
           if(grid%alt(k) <= grid%hgt(i,j,n)) then
              d = (grid%alt(k) - grid%hgt(i,j,n+1)) &
                 / (grid%hgt(i,j,n) - grid%hgt(i,j,n+1))
              v = d*grid%pre(n) + (1.0-d)*grid%pre(n+1)
              exit
           end if
           n = n - 1
        end do
     end if
     var3d(i, jj, k) = v
  end do
  end do
  end do

end subroutine z2p

!----------------------------------------------------------------------
subroutine v2z(grid, var3d)

  use module_grid

  implicit none

  type(gfsgrid), intent(in) :: grid
  real, dimension(grid%nlon, grid%nlat, grid%npre), intent(out) :: var3d

  integer :: i, j, k, n, jj

  real :: d, v

  do j = 1, grid%nlat
     jj =  grid%nlat + 1 - j
  do i = 1, grid%nlon
     n = grid%npre - 1
  do k = 1, grid%npre
     if(grid%alt(k) <= grid%hgt(i,j,grid%npre)) then
        v = grid%var3d(i, j, grid%npre)
     else if(grid%alt(k) >= grid%hgt(i,j,1)) then
        v = grid%var3d(i, j, 1)
     else
        do while (n >= 1)
           if(grid%alt(k) <= grid%hgt(i,j,n)) then
              d = (grid%alt(k) - grid%hgt(i,j,n+1)) &
                 / (grid%hgt(i,j,n) - grid%hgt(i,j,n+1))
              v = d*grid%var3d(i, j, n) &
                + (1.0-d)*grid%var3d(i, j, n+1)
              exit
           end if
           n = n - 1
        end do
     end if
     var3d(i, jj, k) = v
  end do
  end do
  end do

end subroutine v2z

!----------------------------------------------------------------------
subroutine flip(grid, var2d)

  use module_grid

  implicit none

  type(gfsgrid), intent(in) :: grid
  real, dimension(grid%nlon, grid%nlat), intent(inout) :: var2d

  integer :: i, j, jj, n

  real :: v

  n = grid%nlat/2

  do j = 1, n
     jj =  grid%nlat + 1 - j
     do i = 1, grid%nlon
        v = var2d(i, j)
        var2d(i, j) = var2d(i, jj)
        var2d(i, jj) = v
     end do
  end do

end subroutine flip

