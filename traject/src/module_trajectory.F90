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
     integer                            :: dimidx, dimidy, dimidz, dimidt
     integer                            :: nx, ny, nz, nt
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

    trajectory%nx = model%nlon
    trajectory%ny = model%nlon
    trajectory%nz = model%nlon

    allocate(trajectory%x(trajectory%nx, trajectory%ny, trajectory%nz))
    allocate(trajectory%y(trajectory%nx, trajectory%ny, trajectory%nz))
    allocate(trajectory%z(trajectory%nx, trajectory%ny, trajectory%nz))

    do k = 1, trajectory%nz
    do j = 1, trajectory%ny
    do i = 1, trajectory%nx
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

