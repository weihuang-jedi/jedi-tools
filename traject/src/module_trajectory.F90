module module_trajectory

  use netcdf
  use module_model

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: trajectorytype
  public :: initialize_trajectory
  public :: finalize_trajectory

  !-----------------------------------------------------------------------

  type trajectorytype
     character(len=1024)                :: filename
     integer                            :: ncid
     integer                            :: dimidlon, dimidlat, dimidalt, &
                                           dimidtime
     real(kind=8), dimension(2)         :: time

     integer, dimension(:, :, :), allocatable :: x, y, z
  end type trajectorytype

  !-----------------------------------------------------------------------

contains

 !-----------------------------------------------------------------------
  subroutine initialize_trajectory(model, trajectory)

    implicit none

    type(modelgrid),      intent(in)  :: model
    type(trajectorytype), intent(out) :: trajectory

    integer :: i, j, k

    allocate(trajectory%x(model%nlon, model%nlat, model%nlev))
    allocate(trajectory%y(model%nlon, model%nlat, model%nlev))
    allocate(trajectory%z(model%nlon, model%nlat, model%nlev))

    do k = 1, model%nlev
    do j = 1, model%nlat
    do i = 1, model%nlon
       trajectory%x(i,j,k) = model%lon(i)
       trajectory%y(i,j,k) = model%lat(j)
       trajectory%z(i,j,k) = 0.5*(model%z(i, j, k) + model%z(i, j, k+1))
    end do
    end do
    end do

  end subroutine initialize_trajectory

 !----------------------------------------------------------------------
  subroutine finalize_trajectory(trajectory)

    implicit none

    type(trajectorytype), intent(inout) :: trajectory

    deallocate(trajectory%x)
    deallocate(trajectory%y)
    deallocate(trajectory%z)

  end subroutine finalize_trajectory

end module module_trajectory

