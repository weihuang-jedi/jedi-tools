!----------------------------------------------------------------------------------------
subroutine process(atm, ocn, ice, whole, flnm)
  
   use netcdf
   use grid_module

   implicit none

   type(gridtype),   intent(in)  :: atm, ocn, ice
   type(gridtype),   intent(out) :: whole
   character(len=*), intent(in)  :: flnm

   integer :: rc

   print *, 'Enter process'
   print *, 'flnm: ', trim(flnm)
  
   call create_file(atm, ocn, ice, whole, trim(flnm))
  
   call create_var_attr(atm, whole)
   call create_var_attr(ocn, whole)
   call create_var_attr(ice, whole)

  !End define mode.
   rc = nf90_enddef(whole%fileid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", whole%fileid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

   call process_file(atm, whole)
   call process_file(ocn, whole)
   call process_file(ice, whole)

   print *, 'Leave process'

end subroutine process

!---------------------------------------------------------------------------
subroutine create_global_attr(ncid, filename, title)

   implicit none

   integer,          intent(in) :: ncid
   character(len=*), intent(in) :: filename, title

  !print *, 'Enter create_global_attr'

 ! ----put global attributes----
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))

end subroutine create_global_attr

!----------------------------------------------------------------------------------------
subroutine create_file(atm, ocn, ice, whole, flnm)

   use netcdf
   use grid_module

   implicit none

   type(gridtype),   intent(in)  :: atm, ocn, ice
   type(gridtype),   intent(out) :: whole
   character(len=*), intent(in)  :: flnm

   integer :: i, nd, rc, ncid

   integer, dimension(2) :: dimids

   logical :: fileExists

   print *, 'Enter create_file'
   print *, 'flnm = ', trim(flnm)

   whole%filename = trim(flnm)

   rc = nf90_noerr

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

   whole%fileid = ncid
   print *, 'ncid = ', ncid

   rc = nf90_def_dim(ncid, 'lon', atm%nlon, whole%dimid_lon)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'lat', atm%nlat, whole%dimid_lat)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'atm_lev', atm%atm_nlev, whole%dimid_atm_lev)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'atm_lay', atm%atm_nlay, whole%dimid_atm_lay)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'atm_hor', atm%atm_nhor, whole%dimid_atm_hor)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'ocn_lev', ocn%ocn_nlev, whole%dimid_ocn_lev)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'ice_cat', ice%ice_ncat, whole%dimid_ice_cat)
   call check_status(rc)

   whole%nlon = atm%nlon
   whole%nlat = atm%nlat
   whole%atm_nlev = atm%atm_nlev
   whole%atm_nlay = atm%atm_nlay
   whole%atm_nhor = atm%atm_nhor
   whole%ocn_nlev = ocn%ocn_nlev
   whole%ice_ncat = ice%ice_ncat

  !print *, 'ice%ice_ncat = ', ice%ice_ncat
  !print *, 'ice%ice_cat = ', ice%ice_cat

   print *, 'whole%dimid_lon = ', whole%dimid_lon
   print *, 'whole%dimid_lat = ', whole%dimid_lat
   print *, 'whole%dimid_atm_lev = ', whole%dimid_atm_lev
   print *, 'whole%dimid_atm_lay = ', whole%dimid_atm_lay
   print *, 'whole%dimid_atm_hor = ', whole%dimid_atm_hor
   print *, 'whole%dimid_ocn_lev = ', whole%dimid_ocn_lev
   print *, 'whole%dimid_ice_cat = ', whole%dimid_ice_cat

   call create_global_attr(ncid, trim(flnm), 'Atmosphere, Ocean and Ice combined data')

   dimids(1) = whole%dimid_lon
   nd = 1
!--Field lon
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lon', &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   dimids(1) = whole%dimid_lat
!--Field lat
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lat', &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = whole%dimid_atm_lev
!--Field atm lev
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'atm_lev', &
                      "Atmosphere Level Coordinate", &
                      "top_down", &
                      "Altitude" )

   dimids(1) = whole%dimid_atm_lay
!--Field atm lay
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'atm_lay', &
                      "Atmosphere Layer Coordinate", &
                      "atm_top_down", &
                      "Altitude" )

   dimids(1) = whole%dimid_atm_hor
!--Field atm hor
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "atm_hor", &
                      "Atmosphere Horizontal Coordinate", &
                      "atm_one_lev", &
                      "Horizontal" )

   dimids(1) = whole%dimid_ocn_lev
!--Field atm ocn
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'ocn_lev', &
                      "Ocean Layer Coordinate", &
                      "ocn_downward", &
                      "Layer" )

   dimids(1) = whole%dimid_ice_cat
!--Field ice cat
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'ice_cat', &
                      "Ice Catalog Coordinate", &
                      "ice_catalog", &
                      "Catalog" )

  !print *, 'whole%dimid_lon = ', whole%dimid_lon
  !print *, 'atm%lon = ', atm%lon

  !write lon
   call nc_put1Dvar0(ncid, 'lon', atm%lon, 1, atm%nlon)

  !write lat
   call nc_put1Dvar0(ncid, 'lat', atm%lat, 1, atm%nlat)

  !write atm lev
   call nc_put1Dvar0(ncid, 'atm_lev', atm%atm_lev, 1, atm%atm_nlev)

  !write atm lay
   call nc_put1Dvar0(ncid, 'atm_lay', atm%atm_lay, 1, atm%atm_nlay)

  !write atm hor
   call nc_put1Dvar0(ncid, 'atm_hor', atm%atm_hor, 1, atm%atm_nhor)

  !print *, 'ocn%dimid_ocn_lev = ', ocn%dimid_ocn_lev
  !print *, 'ocn%ocn_lev = ', ocn%ocn_lev

  !write ocn lev
   call nc_put1Dvar0(ncid, 'ocn_lev', ocn%ocn_lev, 1, ocn%ocn_nlev)

  !print *, 'whole%dimid_ice_cat = ', whole%dimid_ice_cat
  !print *, 'ice%ice_cat = ', ice%ice_cat

  !write ice cat
   call nc_put1Dvar0(ncid, 'ice_cat', ice%ice_cat, 1, ice%ice_ncat)

   print *, 'Leave create_file'
end subroutine create_file

!-------------------------------------------------------------------------------------
subroutine create_var_attr(grid, whole)

   use netcdf
   use namelist_module
   use grid_module

   implicit none

   type(gridtype), intent(in)    :: grid
   type(gridtype), intent(inout) :: whole

   integer, dimension(6) :: dimids
   integer :: rc, nd, i, ncid
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates, varname

   print *, 'Enter create_var_attr'
   print *, 'grid%gridname: ', trim(grid%gridname)


   print *, 'whole%dimid_lon = ', whole%dimid_lon
   print *, 'whole%dimid_lat = ', whole%dimid_lat
   print *, 'whole%dimid_atm_lev = ', whole%dimid_atm_lev
   print *, 'whole%dimid_atm_lay = ', whole%dimid_atm_lay
   print *, 'whole%dimid_atm_hor = ', whole%dimid_atm_hor
   print *, 'whole%dimid_ocn_lev = ', whole%dimid_ocn_lev
   print *, 'whole%dimid_ice_cat = ', whole%dimid_ice_cat

   missing_real = -1.0e38
   missing_int = -999999
   ncid = grid%fileid

   do i = 1, grid%nVars
      if(grid%vars(i)%nDims < 2) cycle

      print *, 'Var No. ', i, ': varname: ', trim(grid%vars(i)%varname)
      print *, 'Var No. ', i, ': ndims = ', grid%vars(i)%ndims

      dimids(1) = whole%dimid_lon
      dimids(2) = whole%dimid_lat

     !function nf90_inquire_attribute(ncid, varid, name, xtype, len, attnum)
     !function nf90_inq_attname(ncid, varid, attnum, name)

      rc = nf90_get_att(ncid, grid%varids(i), 'long_name', long_name)
      call check_status(rc)
      rc = nf90_get_att(ncid, grid%varids(i), 'units', units)
      call check_status(rc)

     !if('ocn' /= trim(grid%gridname)) then
     !   rc = nf90_get_att(ncid, grid%varids(i), '_CoordinateAxes', coordinates)
     !   call check_status(rc)
     !end if

      nd = grid%vars(i)%ndims
      if(3 == nd) then
         if('atm' == trim(grid%gridname)) then
            if(grid%atm_nlev == grid%vars(i)%dimlen(3)) then
               dimids(3) = whole%dimid_atm_lev
               coordinates = 'atm_lev lat lon'
            else if(grid%atm_nlay == grid%vars(i)%dimlen(3)) then
               dimids(3) = whole%dimid_atm_lay
               coordinates = 'atm_lay lat lon'
            else if(grid%atm_nhor == grid%vars(i)%dimlen(3)) then
               dimids(3) = whole%dimid_atm_hor
               coordinates = 'atm_hor lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%vars(i)%dimlen(3)
            end if
         else if('ocn' == trim(grid%gridname)) then
            if(grid%ocn_ntime == grid%vars(i)%dimlen(3)) then
               nd = 2
               coordinates = 'lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%vars(i)%dimlen(3)
            end if
         else if('ice' == trim(grid%gridname)) then
            if(grid%ice_ncat == grid%vars(i)%dimlen(3)) then
               coordinates = 'ice_cat lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%vars(i)%dimlen(3)
            end if
         end if
      else if(4 == nd) then
         if('ocn' == trim(grid%gridname)) then
            if(grid%ocn_nlev == grid%vars(i)%dimlen(3)) then
               nd = 3
               dimids(3) = whole%dimid_ocn_lev
               coordinates = 'ocn_lev lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%vars(i)%dimlen(3)
            end if
         end if
      else if(nd /=2) then
         print *, 'File: ', __FILE__, ', line: ', __LINE__
         print *, 'Unknown ndims: ', nd
      end if

      write(varname, fmt='(3a)') trim(grid%gridname), '_', trim(grid%vars(i)%varname)

      print *, 'varname: ', trim(varname)
      print *, 'dimids = ', dimids(1:nd)

      call nc_putAttr(whole%fileid, nd, dimids, NF90_REAL, &
                      trim(varname), trim(long_name), trim(units), &
                      trim(coordinates), missing_real)
   end do

   print *, 'Leave create_var_attr'

end subroutine create_var_attr

!----------------------------------------------------------------------------------------
subroutine process_file(grid, whole)

   use netcdf
   use namelist_module
   use grid_module

   implicit none

   type(gridtype), intent(inout) :: grid
   type(gridtype), intent(inout) :: whole

   real, dimension(:,:), allocatable :: var2d
   real, dimension(:,:,:), allocatable :: var3d

   character(len=80) :: varname

   integer :: i, rc

   print *, 'Enter process_file'
   print *, 'Processing ', trim(grid%gridname)

   allocate(var2d(whole%nlon, whole%nlat))

   do i = 1, grid%nVars
     !rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
     !         ndims=grid%vars(i)%nDims, natts=grid%vars(i)%nAtts)
     !call check_status(rc)

     !print *, 'Var No. ', i, ': ndims = ', grid%vars(i)%nDims

     !rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
     !         name=grid%vars(i)%varname)
     !call check_status(rc)

      if(grid%vars(i)%nDims < 2) cycle

      print *, 'Var No. ', i, ': name: ', trim(grid%vars(i)%varname)
      print *, 'Var No. ', i, ': varid: ', grid%varids(i)

      write(varname, fmt='(3a)') trim(grid%gridname), '_', trim(grid%vars(i)%varname)

      if(2 == grid%vars(i)%nDims) then
         rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
         call check_status(rc)
         print *, 'Write var: ', trim(varname)
         call nc_put2Dvar0(whole%fileid, trim(varname), &
              var2d, 1, whole%nlon, 1, whole%nlat)
      else if(3 == grid%vars(i)%nDims) then
         if('ocn' == trim(grid%gridname)) then
            rc = nf90_get_var(grid%fileid, grid%varids(i), var2d)
            call check_status(rc)
            print *, 'Write var: ', trim(varname)
            call nc_put2Dvar0(whole%fileid, trim(varname), &
                 var2d, 1, whole%nlon, 1, whole%nlat)
         else
            if(allocated(var3d)) deallocate(var3d)

            allocate(var3d(whole%nlon, whole%nlat, grid%vars(i)%dimlen(3)))

            rc = nf90_get_var(grid%fileid, grid%varids(i), var3d)
            call check_status(rc)
            print *, 'Write var: ', trim(varname)
            call nc_put3Dvar0(whole%fileid, trim(varname), &
                              var3d, 1, whole%nlon, 1, whole%nlat, &
                              1, grid%vars(i)%dimlen(3))
         end if
      else if(4 == grid%vars(i)%nDims) then
         if('ocn' == trim(grid%gridname)) then
            if(allocated(var3d)) deallocate(var3d)

            allocate(var3d(whole%nlon, whole%nlat, grid%vars(i)%dimlen(3)))

            rc = nf90_get_var(grid%fileid, grid%varids(i), var3d)
            call check_status(rc)
            print *, 'Write var: ', trim(varname)
            call nc_put3Dvar0(whole%fileid, trim(varname), &
                              var3d, 1, whole%nlon, 1, whole%nlat, &
                              1, grid%vars(i)%dimlen(3))
         else
            print *, 'File: ', __FILE__, ', line: ', __LINE__
            print *, 'Unprocessed ndims: ', grid%vars(i)%nDims
         end if
      else
         print *, 'File: ', __FILE__, ', line: ', __LINE__
         print *, 'Unprocessed ndims: ', grid%vars(i)%nDims
      end if
   end do

   deallocate(var2d)
   if(allocated(var3d)) deallocate(var3d)

  !print *, 'Leave process_file'

end subroutine process_file

