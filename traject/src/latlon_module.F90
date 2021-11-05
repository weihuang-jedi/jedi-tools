module latlon_module

  use netcdf
  use module_io

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: latlongrid
  public :: initialize_latlongrid
  public :: finalize_latlongrid

  !-----------------------------------------------------------------------

  type latlongrid
     character(len=1024)                   :: filename
     integer                               :: ncid
     integer                               :: dimidx, dimidy, dimidz, &
                                              dimidl, dimidh, dimidt
     integer                               :: nlon, nlat, nlev, nlay, npnt
     integer, dimension(:),    allocatable :: lon, lat, lev, lay, pnt
     integer, dimension(:, :), allocatable :: counter
     integer, dimension(:, :, :), allocatable :: tile
     integer, dimension(:, :, :), allocatable :: ilon, jlat
     real,    dimension(:, :, :), allocatable :: dist, wgt
     real,    dimension(:, :), allocatable :: pos
  end type latlongrid

  !-----------------------------------------------------------------------

contains

 !-----------------------------------------------------------------------
  subroutine initialize_latlongrid(latlon)

    implicit none

    type(latlongrid), intent(out) :: latlon

    integer :: i, j, k

    print *, 'enter initialize_latlongrid'

    print *, 'leave initialize_latlongrid'

  end subroutine initialize_latlongrid

 !----------------------------------------------------------------------
  subroutine finalize_latlongrid(latlon)

    implicit none

    type(latlongrid), intent(inout) :: latlon

  end subroutine finalize_latlongrid

end module latlon_module

