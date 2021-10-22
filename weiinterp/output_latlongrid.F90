!----------------------------------------------------------------------------------------

subroutine write_latlongrid(latlon, flnm)

   use netcdf
   use latlon_module
   use tile_module, only : check_status

   implicit none

   type(latlongrid), intent(in) :: latlon
   character(len=*), intent(in) :: flnm

   integer :: ncid, dimidx, dimidy, dimidp

   real, dimension(:), allocatable :: lon, lat, pnt

   integer :: i, j, n, status
   real :: dlon, dlat

   status = nf90_noerr

   n = 0

   !Create the file. 
   status = nf90_create(trim(flnm), NF90_CLOBBER, ncid)
   call check_status(status)

  !print *, 'latlon%lon = ',  latlon%lon
  !print *, 'latlon%lat = ',  latlon%lat
  !print *, 'latlon%pnt = ',  latlon%pnt

   allocate(lon(latlon%nlon))
   allocate(lat(latlon%nlat))
   allocate(pnt(latlon%npnt))

   dlon = 360.0/latlon%nlon
   dlat = 180.0/(latlon%nlat-1)

   do i = 1, latlon%nlon
    !lon(i) = dlon*real(i-1)
     lon(i) = latlon%lon(i)
   end do

   do j = 1, latlon%nlat
    !lat(j) = dlat*real(j-1) - 90.0
     lat(j) = latlon%lat(j)
   end do

   do i = 1, latlon%npnt
    !pnt(i) = real(i)
     pnt(i) = latlon%pnt(i)
   end do
   
   status = nf90_def_dim(ncid, 'lon', latlon%nlon, dimidx)
   call check_status(status)
   status = nf90_def_dim(ncid, 'lat', latlon%nlat, dimidy)
   call check_status(status)
   status = nf90_def_dim(ncid, 'pnt', latlon%npnt, dimidp)
   call check_status(status)

   call write_global_attr(ncid, flnm, 'Weight of Grid', 'Lat-Lon')

   call write_var_attr(ncid, dimidx, dimidy, dimidp)

   !write lon
  !call nc_put1Dvar0(ncid, 'lon', latlon%lon, 1, latlon%nlon)
   call nc_put1Dvar0(ncid, 'lon', lon, 1, latlon%nlon)

   !write lat
  !call nc_put1Dvar0(ncid, 'lat', latlon%lat, 1, latlon%nlat)
   call nc_put1Dvar0(ncid, 'lat', lat, 1, latlon%nlat)

   !write pnt
  !call nc_put1Dvar0(ncid, 'pnt', latlon%pnt, 1, latlon%npnt)
   call nc_put1Dvar0(ncid, 'pnt', pnt, 1, latlon%npnt)

   !--write pos
   call nc_put2Dvar0(ncid, 'pos', latlon%pos, 1, latlon%nlon, 1, latlon%nlat)

   !--write tile
   call nc_put3Dint0(ncid, 'tile', latlon%tile, 1, latlon%nlon, &
                     1, latlon%nlat, 1, latlon%npnt)

   !--write ilon
   call nc_put3Dint0(ncid, 'ilon', latlon%ilon, 1, latlon%nlon, &
                     1, latlon%nlat, 1, latlon%npnt)

   !--write jlat
   call nc_put3Dint0(ncid, 'jlat', latlon%jlat, 1, latlon%nlon, &
                     1, latlon%nlat, 1, latlon%npnt)

   !--write wgt
   call nc_put3Dvar0(ncid, 'wgt', latlon%wgt, 1, latlon%nlon, &
                     1, latlon%nlat, 1, latlon%npnt)

   status =  nf90_close(ncid)
   call check_status(status)
  !print *, 'Finished Write to file: ', trim(flnm)

   deallocate(lon)
   deallocate(lat)
   deallocate(pnt)

end subroutine write_latlongrid

!-------------------------------------------------------------------------------------
subroutine write_var_attr(ncid, dimid_nx, dimid_ny, dimid_np)

   use netcdf

   implicit none

   integer, intent(in) :: ncid
   integer, intent(in) :: dimid_nx, dimid_ny, dimid_np

   integer, dimension(3) :: dimids
   integer :: status, nd
   integer :: missing_int
   real    :: missing_real

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

   dimids(1) = dimid_np
   nd = 1
!--Field pnt
   call nc_putAxisAttr(ncid, nd, dimids, NF90_REAL, &
                      "pnt", &
                      "Points for Weighting", &
                      "unitless", &
                      "Point" )

   dimids(1) = dimid_nx
   dimids(2) = dimid_ny
   nd = 2

!--Field 1, pos
   call nc_putAttr(ncid, nd, dimids, NF90_REAL, &
                   "pos", &
                   "Postion in Tile", &
                   "unitless", &
                   "lat lon", &
                   missing_real)

   dimids(1) = dimid_nx
   dimids(2) = dimid_ny
   dimids(3) = dimid_np
   nd = 3

!--Field 2, tile
   call nc_putAttr(ncid, nd, dimids, NF90_INT, &
                   "tile", &
                   "Tile Number of Grid", &
                   "unitless", &
                   "pnt lat lon", &
                   missing_int)

!--Field 3, ilon
   call nc_putAttr(ncid, nd, dimids, NF90_INT, &
                   "ilon", &
                   "Index of Longitude", &
                   "unitless", &
                   "pnt lat lon", &
                   missing_int)

!--Field 4, jlat
   call nc_putAttr(ncid, nd, dimids, NF90_INT, &
                   "jlat", &
                   "Index of Latitude", &
                   "unitless", &
                   "pnt lat lon", &
                   missing_int)

!--Field 5, wgt
   call nc_putAttr(ncid, nd, dimids, NF90_REAL, &
                   "wgt", &
                   "Weight of Grids", &
                   "unitless", &
                   "pnt lat lon", &
                   missing_real)

!--End define mode.
   status = nf90_enddef(ncid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(a,i6,a)') "Problem to enddef ncid: <", ncid, ">."
      write(unit=0, fmt='(2a)') "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

end subroutine write_var_attr

!---------------------------------------------------------------------------
subroutine write_global_attr(ncid, filename, title, type)

   implicit none

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title, type

 ! ----put global attributes----
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))
   call nc_putGlobalCharAttr(ncid, 'grid_type', trim(type))

  !call nc_putGlobalIntAttr(ncid, 'WRF_for_first_guess', iwrf)

  !call nc_putGlobalRealAttr(ncid, 'top_height',bdytop)

end subroutine write_global_attr

