!----------------------------------------------------------------------------------------
subroutine process(atm, ocn, ice, whole, flnm)
  
   use netcdf
   use grid_module

   implicit none

   type(gridtype),   intent(inout) :: atm, ocn, ice
   type(gridtype),   intent(inout) :: whole
   character(len=*), intent(inout) :: flnm

   integer :: rc

   print *, 'Enter process'
  
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

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title

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

   type(gridtype),   intent(inout) :: atm, ocn, ice
   type(gridtype),   intent(inout) :: whole
   character(len=*), intent(in)    :: flnm

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
   rc = nf90_def_dim(ncid, 'ocn_lay', ocn%ocn_nlay, whole%dimid_ocn_lay)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'ice_cat', ice%ice_ncat, whole%dimid_ice_cat)
   call check_status(rc)

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

   dimids(1) = whole%dimid_ocn_lay
!--Field atm ocn
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'ocn_lay', &
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

  !write ocn lay
   call nc_put1Dvar0(ncid, 'ocn_lay', ocn%ocn_lay, 1, ocn%ocn_nlay)

  !write ice cat
   call nc_put1Dvar0(ncid, 'ice_cat', ice%ice_cat, 1, ice%ice_ncat)

   print *, 'Leave create_file'
end subroutine create_file

!-------------------------------------------------------------------------------------
subroutine create_var_attr(grid, whole)

   use netcdf
   use namelist_module
   use grid_module
   use whole_module

   implicit none

   type(gridtype), intent(inout) :: grid
   type(gridtype), intent(inout) :: whole

   integer, dimension(6) :: dimids
   integer :: rc, nd, i, ncid
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates, varname

  !print *, 'Enter create_var_attr'

   missing_real = -1.0e38
   missing_int = -999999
   ncid = whole%fileid

   do i = 1, grid%nVars
      if(grid%vars(i)%nDims < 2) cycle

      dimids(1) = whole%dimid_lon
      dimids(2) = whole%dimid_lat

     !function nf90_inquire_attribute(ncid, varid, name, xtype, len, attnum)
     !function nf90_inq_attname(ncid, varid, attnum, name)

      rc = nf90_get_att(ncid, grid%varids(i), 'long_name', long_name)
      call check_status(rc)
      rc = nf90_get_att(ncid, grid%varids(i), 'units', units)
      call check_status(rc)
      rc = nf90_get_att(ncid, grid%varids(i), '_CoordinateAxes', coordinates)
      call check_status(rc)

      nd = grid%vars(i)%ndims
      if(3 == nd) then
         if('atm' == trim(grid%gridname) then
            if(whole%atm_nlev == grid%varids(i)%dimlen(3)) then
               coordinates = 'atm_lev lat lon'
            else if(whole%atm_nlay == grid%varids(i)%dimlen(3)) then
               coordinates = 'atm_lay lat lon'
            else if(whole%atm_nhor == grid%varids(i)%dimlen(3)) then
               coordinates = 'atm_hor lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%varids(i)%dimlen(3)
            end if
         else if('ocn' == trim(grid%gridname) then
            if(whole%ocn_nlay == grid%varids(i)%dimlen(3)) then
               coordinates = 'ocn_lay lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%varids(i)%dimlen(3)
            end if
         else if('ice' == trim(grid%gridname) then
            if(whole%ice_ncat == grid%varids(i)%dimlen(3)) then
               coordinates = 'ice_cat lat lon'
            else
               print *, 'File: ', __FILE__, ', line: ', __LINE__
               print *, 'Unknown dimlen: ', grid%varids(i)%dimlen(3)
            end if
         end if
      else if(nd /=2) then
         print *, 'File: ', __FILE__, ', line: ', __LINE__
         print *, 'Unknown ndims: ', nd
      end if

      write(varname, fmt='(3a)') trim(grid%gridname), '_', trim(grid%vars(i)%varname)
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
   use fv_grid_utils_module
   use whole_module

   implicit none

   type(gridtupe), intent(inout) :: grid
   type(gridtupe), intent(inout) :: whole

   integer :: i, n, rc, uv_count

   real, dimension(:,:,:), allocatable :: var2d
   real, dimension(:,:,:), allocatable :: var3d

  !print *, 'Enter process_file'

   allocate(var2d(whole%nlon, whole%nlat, 1))
   allocate(var3d(whole%nlon, whole%nlat, whole%nlev))

   uv_count = 0
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
     !print *, 'Var No. ', i, ': varid: ', grid%varids(i)

         if((trim(grid(n)%vars(i)%varname) == 'ps') .or. &
            (trim(grid(n)%vars(i)%varname) == 'phis')) then
            rc = nf90_get_var(grid(n)%fileid, grid(n)%varids(i), grid(n)%var2d)
            call check_status(rc)
         else if((trim(grid(n)%vars(i)%varname) == 'ua') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'va') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'u') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'v') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'W') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'delp') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'DZ') .or. &
                 (trim(grid(n)%vars(i)%varname) == 'T')) then
            rc = nf90_get_var(grid(n)%fileid, grid(n)%varids(i), grid(n)%var3d)
            call check_status(rc)
         end if
      end do

      if((trim(grid%vars(i)%varname) == 'ps') .or. &
         (trim(grid%vars(i)%varname) == 'phis')) then
         call interp2dvar(grid, whole, var2d)
        !call nc_put3Dvar(whole%ncid, trim(grid%vars(i)%varname), &
        !     var2d, 1, 1, whole%nlon, 1, whole%nlat, 1, 1)
         call nc_put3Dvar0(whole%ncid, trim(grid%vars(i)%varname), &
              var2d, 1, whole%nlon, 1, whole%nlat, 1, 1)
      else if((trim(grid%vars(i)%varname) == 'ua') .or. &
              (trim(grid%vars(i)%varname) == 'va') .or. &
              (trim(grid%vars(i)%varname) == 'u') .or. &
              (trim(grid%vars(i)%varname) == 'v') .or. &
              (trim(grid%vars(i)%varname) == 'W') .or. &
              (trim(grid%vars(i)%varname) == 'delp') .or. &
              (trim(grid%vars(i)%varname) == 'DZ') .or. &
              (trim(grid%vars(i)%varname) == 'T')) then
         if(use_uv_directly) then
            if((trim(grid%vars(i)%varname) == 'ua') .or. &
               (trim(grid%vars(i)%varname) == 'va')) then
               cycle
            end if

            if(trim(grid%vars(i)%varname) == 'u') then
               uv_count = uv_count + 1
            else if(trim(grid%vars(i)%varname) == 'v') then
               uv_count = uv_count + 1
            end if
         else
            if((trim(grid%vars(i)%varname) == 'u') .or. &
               (trim(grid%vars(i)%varname) == 'v')) then
               cycle
            end if
         end if

         if(use_uv_directly) then
            if((trim(grid%vars(i)%varname) == 'u') .or. &
               (trim(grid%vars(i)%varname) == 'v')) then
               if(1 == uv_count) then
                  cycle
               else if(2 == uv_count) then
                 !print *, 'Interpolate u/v here.'
                  uv_count = 0

                  do n = 1, 6
                     call cubed_to_whole(grid(n)%var3du, grid(n)%var3dv, grid(n)%u, grid(n)%var3d, &
                                          gridstruct(n), grid(n)%nx, grid(n)%ny, grid(n)%nz)
                  end do

                  call interp3dvar(grid, whole, var3d)
                  call nc_put3Dvar0(whole%ncid, 'v', &
                       var3d, 1, whole%nlon, 1, whole%nlat, 1, whole%nlev)
                  call copy_u2var3d(grid)
                  call interp3dvar(grid, whole, var3d)
                  call nc_put3Dvar0(whole%ncid, 'u', &
                       var3d, 1, whole%nlon, 1, whole%nlat, 1, whole%nlev)
                  cycle
               end if
            end if
         end if
         call interp3dvar(grid, whole, var3d)
        !call nc_put3Dvar(whole%ncid, trim(grid%vars(i)%varname), &
        !     var3d, 1, 1, whole%nlon, 1, whole%nlat, 1, whole%nlev)
         call nc_put3Dvar0(whole%ncid, trim(grid%vars(i)%varname), &
              var3d, 1, whole%nlon, 1, whole%nlat, 1, whole%nlev)
      end if
   end do

   deallocate(var2d)
   deallocate(var3d)

  !print *, 'Leave process_file'

end subroutine process_file

