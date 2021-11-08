module module_trajectory

  use netcdf
  use module_model

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: trajectorytype
  public :: initialize_trajectory
  public :: advance_trajectory
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
    trajectory%ny = model%nlat
    trajectory%nz = model%nlev

    allocate(trajectory%x(trajectory%nx, trajectory%ny, trajectory%nz))
    allocate(trajectory%y(trajectory%nx, trajectory%ny, trajectory%nz))
    allocate(trajectory%z(trajectory%nx, trajectory%ny, trajectory%nz))

   !print *, 'model%lon = ', model%lon
   !print *, 'model%lat = ', model%lat

    do k = 1, trajectory%nz
    do j = 1, trajectory%ny
    do i = 1, trajectory%nx
       trajectory%x(i,j,k) = model%lon(i)
       trajectory%y(i,j,k) = model%lat(j)
       trajectory%z(i,j,k) = 0.5*(model%z(i, j, k) + model%z(i, j, k+1))
    end do
    end do
    end do

   !print *, 'trajectory%y(1,j,1) = ', trajectory%y(1,:,1)

  end subroutine initialize_trajectory

 !----------------------------------------------------------------------
  subroutine finalize_trajectory(trajectory)

    use netcdf
    use module_model, only : check_status

    implicit none

    type(trajectorytype), intent(inout) :: trajectory

    integer :: rc

    deallocate(trajectory%x)
    deallocate(trajectory%y)
    deallocate(trajectory%z)

    rc =  nf90_close(trajectory%ncid)
    call check_status(rc)

  end subroutine finalize_trajectory

 !-----------------------------------------------------------------------
  integer function get_vertical_index(model, mi, mj, z)

    implicit none

    type(modelgrid), intent(in) :: model
    integer,         intent(in) :: mi, mj
    real,            intent(in) :: z
    integer                     :: mk

    integer :: k

    if(z >= model%z(mi, mj, 1)) then
       mk = 1
    else if(z <= model%z(mi, mj, model%nlev+1)) then
       mk = model%nlev
    else
       do k = 1, model%nlev
          if(z <= model%z(mi, mj, k) .and. z > model%z(mi, mj, k+1)) then
             mk = k
             exit
          end if
       end do
    end if

    get_vertical_index = mk

  end function get_vertical_index

 !-----------------------------------------------------------------------
  subroutine advance_trajectory(model, trajectory, dt)

    implicit none

    type(modelgrid),      intent(in)    :: model
    type(trajectorytype), intent(inout) :: trajectory
    real,                 intent(in)    :: dt

    real, parameter :: er = 6378000.0
   !real, parameter :: pi = 3.1415926535897932
    real, parameter :: pi = 3.1416

    real :: arc2deg, deg2arc, dlon, dlat, dz, z
    integer :: i, j, k
    integer :: mi, mj, mk

    arc2deg = 180.0/pi
    deg2arc = pi/180.0

    do k = 1, trajectory%nz
    do j = 1, trajectory%ny
    do i = 1, trajectory%nx
       z = trajectory%z(i,j,k)
       mi = int(trajectory%x(i,j,k)/model%dlon) + 1
       mj = int((trajectory%y(i,j,k)+90.0)/model%dlat) + 1
       mk = get_vertical_index(model, mi, mj, z)
       if(abs(trajectory%y(i,j,k)) > 89.5) then
          dlon = 0.0
       else
          dlon = dt*model%u(mi,mj,mk)/(er*cos(trajectory%y(i,j,k)*deg2arc))
       end if
       dlat = dt*model%v(mi,mj,mk)/er
       dz = dt*model%w(mi,mj,mk)

       trajectory%x(i,j,k) = trajectory%x(i,j,k) + dlon*arc2deg
       trajectory%y(i,j,k) = trajectory%y(i,j,k) + dlat*arc2deg
       trajectory%z(i,j,k) = trajectory%z(i,j,k) + dz

       if(trajectory%z(i,j,k) > model%z(mi, mj, 1)) then
          trajectory%z(i,j,k) = model%z(mi, mj, 1)
       else if(trajectory%z(i,j,k) < model%z(mi, mj, model%nlev+1)) then
          trajectory%z(i,j,k) = model%z(mi, mj, model%nlev+1)
       end if
    end do
    end do
    end do

  end subroutine advance_trajectory

end module module_trajectory

