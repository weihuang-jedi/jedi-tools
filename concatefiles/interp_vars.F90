!----------------------------------------------------------------------------------------
subroutine generate_header(atm, ocn, ice, whole)
  
   use netcdf
   use grid_module

   implicit none

   type(gridtype), intent(inout) :: atm, ocn, ice
   type(gridtype), intent(inout) :: whole

   integer :: rc

   print *, 'Enter generate_header'
  
   call create_coord(atm, ocn, ice, whole)
  
   call create_fv_core_var_attr(grid, latlon)

   if(last) then
     !End define mode.
      rc = nf90_enddef(latlon%ncid)
      if(rc /= nf90_noerr) then
         write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", latlon%ncid, ">."
         write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(rc))
         write(unit=0, fmt='(3a, i4)') &
              "Stop in file: <", __FILE__, ">, line: ", __LINE__
         stop
      end if
   end if

  !print *, 'Leave generate_header'

end subroutine generate_header

!----------------------------------------------------------------------------------------
subroutine interp2latlongrid(gridtype, spec, gridstruct, grid, latlon)

   use netcdf
   use grid_module
   use fv_grid_utils_module
   use latlon_module

   implicit none

   character(len=*),                  intent(in)    :: gridtype
   type(gridspec_type), dimension(6), intent(in)    :: spec
   type(fv_grid_type), dimension(6), intent(in)     :: gridstruct
   type(gridgrid), dimension(6),      intent(inout) :: grid
   type(latlongrid),                  intent(inout) :: latlon

  !print *, 'Enter interp2latlongrid'
  !print *, 'gridtype = ', trim(gridtype)

   if('fv_core.res.grid' == trim(gridtype)) then
      call process_fv_core(spec, grid, gridstruct, latlon)
   else if('sfc_data.grid' == trim(gridtype)) then
      call process_sfc_data(grid, latlon)
   else if('fv_tracer.res.grid' == trim(gridtype)) then
      call process_fv_tracer(grid, latlon)
   else if('fv_srf_wnd.res.grid' == trim(gridtype)) then
      call process_fv_srf_wnd(grid, latlon)
   else if('phy_data.grid' == trim(gridtype)) then
      call process_phy_data(grid, latlon)
   end if

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

  !call nc_putGlobalIntAttr(ncid, 'WRF_for_first_guess', iwrf)

  !call nc_putGlobalRealAttr(ncid, 'top_height',bdytop)

end subroutine create_global_attr

!----------------------------------------------------------------------------------------
subroutine create_coord(nt, time, latlon, flnm)

   use netcdf
   use latlon_module
   use grid_module, only : check_status

   implicit none

   integer,          intent(in)              :: nt
   real(kind=8), dimension(1:nt), intent(in) :: time
   type(latlongrid), intent(inout)           :: latlon
   character(len=*), intent(in)              :: flnm

   integer :: i, nd, rc, ncid

   integer, dimension(2) :: dimids

   real, dimension(1) :: hor
   real, dimension(latlon%nlev) :: lev
   real, dimension(latlon%nlay) :: lay

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
      lev(i) = real(i-1)
   end do

   allocate(latlon%lay(latlon%nlay))

   do i = 1, latlon%nlay
      latlon%lay(i) = real(i-1)
      lay(i) = real(i-1)
   end do

   hor(1) = 0.0

  !print *, 'latlon%lon = ',  latlon%lon
  !print *, 'latlon%lat = ',  latlon%lat
  !print *, 'latlon%lev = ',  latlon%lev
  !print *, 'latlon%lay = ',  latlon%lay

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
   rc = nf90_def_dim(ncid, 'layer', latlon%nlay, latlon%dimidl)
   call check_status(rc)
   rc = nf90_def_dim(ncid, 'hor', 1, latlon%dimidh)
   call check_status(rc)
  !rc = nf90_def_dim(ncid, 'Time', NF90_UNLIMITED, latlon%dimidt)
  !call check_status(rc)

   call create_global_attr(ncid, flnm, 'FV3 to Lat-Lon Grid', 'Lat-Lon Grid')

   dimids(1) = latlon%dimidx
   nd = 1
!--Field lon
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lon', &
                      "Lontitude Coordinate", &
                      "degree_east", &
                      "Longitude" )

   dimids(1) = latlon%dimidy
!--Field lat
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lat', &
                      "Latitude Coordinate", &
                      "degree_north", &
                      "Latitude" )

   dimids(1) = latlon%dimidz
!--Field lev
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'lev', &
                      "Altitude Coordinate", &
                      "top_down", &
                      "Altitude" )

   dimids(1) = latlon%dimidl
!--Field lay
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      'layer', &
                      "Layer Coordinate", &
                      "top_down", &
                      "Altitude" )

   dimids(1) = latlon%dimidh
!--Field hor
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "hor", &
                      "Horizontal Coordinate", &
                      "one_lev", &
                      "Horizontal" )

   dimids(1) = latlon%dimidt
!--Field time
  !call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL8, &
  !                   "Time", &
  !                   "Time Coordinate", &
  !                   "time lev", &
  !                   "Time" )

  !write lon
   call nc_put1Dvar0(ncid, 'lon', latlon%lon, 1, latlon%nlon)

  !write lat
   call nc_put1Dvar0(ncid, 'lat', latlon%lat, 1, latlon%nlat)

  !write lev
  !call nc_put1Dvar0(ncid, 'lev', latlon%lev, 1, latlon%nlev)
   call nc_put1Dvar0(ncid, 'lev', lev, 1, latlon%nlev)

  !write lay
  !call nc_put1Dvar0(ncid, 'layer', latlon%lay, 1, latlon%nlay)
   call nc_put1Dvar0(ncid, 'layer', lay, 1, latlon%nlay)

  !write hor
   call nc_put1Dvar0(ncid, 'hor', hor, 1, 1)

  !write time
  !call nc_put1Ddbl0(ncid, 'Time', time, 1, nt)

  !print *, 'Leave create_coord'
end subroutine create_coord

!-------------------------------------------------------------------------------------
subroutine create_fv_core_var_attr(grid, latlon)

   use netcdf
   use namelist_module
   use grid_module
   use latlon_module

   implicit none

   type(gridgrid), dimension(6), intent(inout) :: grid
   type(latlongrid), intent(inout)             :: latlon

   integer, dimension(4) :: dimids
   integer :: rc, nd, i
   integer :: missing_int
   real    :: missing_real
   character(len=80) :: long_name, units, coordinates

  !print *, 'Enter create_fv_core_var_attr'

   missing_real = -1.0e38
   missing_int = -999999

   do i = 1, grid(1)%nVars
     !if((trim(grid(1)%vars(i)%varname) == 'xaxis_1') .or. &
     !   (trim(grid(1)%vars(i)%varname) == 'xaxis_2') .or. &
     !   (trim(grid(1)%vars(i)%varname) == 'yaxis_1') .or. &
     !   (trim(grid(1)%vars(i)%varname) == 'yaxis_2') .or. &
     !   (trim(grid(1)%vars(i)%varname) == 'zaxis_1') .or. &
     !   (trim(grid(1)%vars(i)%varname) == 'Time')) then
     !   cycle
     !end if

      if(grid(1)%vars(i)%nDims < 2) cycle

      long_name = 'unknown'
      units = 'unknown'
     !coordinates = 'Time lev lat lon'
      coordinates = 'lev lat lon'
      dimids(1) = latlon%dimidx
      dimids(2) = latlon%dimidy
      dimids(3) = latlon%dimidz
     !dimids(4) = latlon%dimidt
     !nd = 4
      nd = 3

      long_name = trim(grid(1)%vars(i)%varname)
      if((trim(grid(1)%vars(i)%varname) == 'ps') .or. &
         (trim(grid(1)%vars(i)%varname) == 'phis')) then
         dimids(3) = latlon%dimidh
         coordinates = 'hor lat lon'
         if(trim(grid(1)%vars(i)%varname) == 'ps') then
            long_name = 'surface_pressure'
            units = 'Pa'
         else if(trim(grid(1)%vars(i)%varname) == 'phis') then
            long_name = 'surface_geopotential_height'
            units = 'm'
         end if
      else if((trim(grid(1)%vars(i)%varname) == 'ua') .or. &
              (trim(grid(1)%vars(i)%varname) == 'va') .or. &
              (trim(grid(1)%vars(i)%varname) == 'u') .or. &
              (trim(grid(1)%vars(i)%varname) == 'v') .or. &
              (trim(grid(1)%vars(i)%varname) == 'W') .or. &
              (trim(grid(1)%vars(i)%varname) == 'delp') .or. &
              (trim(grid(1)%vars(i)%varname) == 'DZ') .or. &
              (trim(grid(1)%vars(i)%varname) == 'T')) then
         if(trim(grid(1)%vars(i)%varname) == 'T') then
            long_name = 'air_temperature'
            units = 'K'
         else if(trim(grid(1)%vars(i)%varname) == 'ua') then
            long_name = 'eastward_wind'
            units = 'm/s'
            if(use_uv_directly) then
               cycle
            end if
         else if(trim(grid(1)%vars(i)%varname) == 'va') then
            long_name = 'northward_wind'
            units = 'm/s'
            if(use_uv_directly) then
               cycle
            end if
         else if(trim(grid(1)%vars(i)%varname) == 'u') then
            long_name = 'eastward_wind'
            units = 'm/s'
            if(.not. use_uv_directly) then
               cycle
            end if
         else if(trim(grid(1)%vars(i)%varname) == 'v') then
            long_name = 'northward_wind'
            units = 'm/s'
            if(.not. use_uv_directly) then
               cycle
            end if
         end if
      end if

      call nc_putAttr(latlon%ncid, nd, dimids, NF90_REAL, &
                      trim(grid(1)%vars(i)%varname), &
                      trim(long_name), trim(units), &
                      trim(coordinates), missing_real)
   end do

  !print *, 'Leave create_fv_core_var_attr'

end subroutine create_fv_core_var_attr

!----------------------------------------------------------------------------------------
subroutine process_fv_core(spec, grid, gridstruct, latlon)

   use netcdf
   use namelist_module
   use grid_module
   use fv_grid_utils_module
   use latlon_module

   implicit none

   type(gridspec_type), dimension(6), intent(in)    :: spec
   type(gridgrid), dimension(6),      intent(inout) :: grid
   type(fv_grid_type), dimension(6),  intent(in)    :: gridstruct
   type(latlongrid),                  intent(inout) :: latlon

   integer :: i, n, rc, uv_count

   real, dimension(:,:,:), allocatable :: var2d
   real, dimension(:,:,:), allocatable :: var3d

  !print *, 'Enter process_fv_core'

   allocate(var2d(latlon%nlon, latlon%nlat, 1))
   allocate(var3d(latlon%nlon, latlon%nlat, latlon%nlev))

   uv_count = 0
   do i = 1, grid(1)%nVars
      rc = nf90_inquire_variable(grid(1)%fileid, grid(1)%varids(i), &
               ndims=grid(1)%vars(i)%nDims, natts=grid(1)%vars(i)%nAtts)
      call check_status(rc)

     !print *, 'Var No. ', i, ': ndims = ', grid(1)%vars(i)%nDims

     !rc = nf90_inquire_variable(grid(1)%fileid, grid(1)%varids(i), &
     !         dimids=grid(1)%vars(i)%dimids)
     !call check_status(rc)

      rc = nf90_inquire_variable(grid(1)%fileid, grid(1)%varids(i), &
               name=grid(1)%vars(i)%varname)
      call check_status(rc)

     !print *, 'Var No. ', i, ': name: ', trim(grid(1)%vars(i)%varname)
     !print *, 'Var No. ', i, ': varid: ', grid(1)%varids(i)

      if(grid(1)%vars(i)%nDims < 2) cycle

     !print *, 'P 1, Var No. ', i, ': name: ', trim(grid(1)%vars(i)%varname)

      do n = 1, 6
         rc = nf90_inquire_variable(grid(n)%fileid, grid(n)%varids(i), &
                  name=grid(n)%vars(i)%varname)
         call check_status(rc)

        !print *, 'Tile ', n, ', Var No. ', i, ': varid: ', grid(n)%varids(i)
        !print *, 'Tile ', n, ', Var ', i, ': ', trim(grid(n)%vars(i)%varname)

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
            if(use_uv_directly) then
               if(trim(grid(n)%vars(i)%varname) == 'u') then
                  rc = nf90_get_var(grid(n)%fileid, grid(n)%varids(i), grid(n)%var3du)
                  call check_status(rc)
                  cycle
               else if(trim(grid(n)%vars(i)%varname) == 'v') then
                  rc = nf90_get_var(grid(n)%fileid, grid(n)%varids(i), grid(n)%var3dv)
                  call check_status(rc)
                  cycle
               end if

               if(trim(grid(n)%vars(i)%varname) == 'ua') then
                  cycle
               else if(trim(grid(n)%vars(i)%varname) == 'va') then
                  cycle
               end if
            else
               if(trim(grid(n)%vars(i)%varname) == 'u') then
                  cycle
               else if(trim(grid(n)%vars(i)%varname) == 'v') then
                  cycle
               end if
            end if

            rc = nf90_get_var(grid(n)%fileid, grid(n)%varids(i), grid(n)%var3d)
            call check_status(rc)
         end if
      end do

     !print *, 'P 2, Var No. ', i, ': name: ', trim(grid(1)%vars(i)%varname)

      if((trim(grid(1)%vars(i)%varname) == 'ps') .or. &
         (trim(grid(1)%vars(i)%varname) == 'phis')) then
         call interp2dvar(grid, latlon, var2d)
        !call nc_put3Dvar(latlon%ncid, trim(grid(1)%vars(i)%varname), &
        !     var2d, 1, 1, latlon%nlon, 1, latlon%nlat, 1, 1)
         call nc_put3Dvar0(latlon%ncid, trim(grid(1)%vars(i)%varname), &
              var2d, 1, latlon%nlon, 1, latlon%nlat, 1, 1)
      else if((trim(grid(1)%vars(i)%varname) == 'ua') .or. &
              (trim(grid(1)%vars(i)%varname) == 'va') .or. &
              (trim(grid(1)%vars(i)%varname) == 'u') .or. &
              (trim(grid(1)%vars(i)%varname) == 'v') .or. &
              (trim(grid(1)%vars(i)%varname) == 'W') .or. &
              (trim(grid(1)%vars(i)%varname) == 'delp') .or. &
              (trim(grid(1)%vars(i)%varname) == 'DZ') .or. &
              (trim(grid(1)%vars(i)%varname) == 'T')) then
         if(use_uv_directly) then
            if((trim(grid(1)%vars(i)%varname) == 'ua') .or. &
               (trim(grid(1)%vars(i)%varname) == 'va')) then
               cycle
            end if

            if(trim(grid(1)%vars(i)%varname) == 'u') then
               uv_count = uv_count + 1
            else if(trim(grid(1)%vars(i)%varname) == 'v') then
               uv_count = uv_count + 1
            end if
         else
            if((trim(grid(1)%vars(i)%varname) == 'u') .or. &
               (trim(grid(1)%vars(i)%varname) == 'v')) then
               cycle
            end if
         end if

         if(use_uv_directly) then
            if((trim(grid(1)%vars(i)%varname) == 'u') .or. &
               (trim(grid(1)%vars(i)%varname) == 'v')) then
               if(1 == uv_count) then
                  cycle
               else if(2 == uv_count) then
                 !print *, 'Interpolate u/v here.'
                  uv_count = 0

                  do n = 1, 6
                     call cubed_to_latlon(grid(n)%var3du, grid(n)%var3dv, grid(n)%u, grid(n)%var3d, &
                                          gridstruct(n), grid(n)%nx, grid(n)%ny, grid(n)%nz)
                  end do

                  call interp3dvar(grid, latlon, var3d)
                  call nc_put3Dvar0(latlon%ncid, 'v', &
                       var3d, 1, latlon%nlon, 1, latlon%nlat, 1, latlon%nlev)
                  call copy_u2var3d(grid)
                  call interp3dvar(grid, latlon, var3d)
                  call nc_put3Dvar0(latlon%ncid, 'u', &
                       var3d, 1, latlon%nlon, 1, latlon%nlat, 1, latlon%nlev)
                  cycle
               end if
            end if
         end if
         call interp3dvar(grid, latlon, var3d)
        !call nc_put3Dvar(latlon%ncid, trim(grid(1)%vars(i)%varname), &
        !     var3d, 1, 1, latlon%nlon, 1, latlon%nlat, 1, latlon%nlev)
         call nc_put3Dvar0(latlon%ncid, trim(grid(1)%vars(i)%varname), &
              var3d, 1, latlon%nlon, 1, latlon%nlat, 1, latlon%nlev)
      end if
   end do

   deallocate(var2d)
   deallocate(var3d)

  !print *, 'Leave process_fv_core'

end subroutine process_fv_core

