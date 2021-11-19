module fv_grid_mod

  implicit none

  private
  public :: fv_grid_type

  type fv_grid_type
     real, allocatable, dimension(:,:,:) :: grid, agrid

     real, allocatable, dimension(:,:) :: dx, dy

    !Cubed_2_latlon:
     real, allocatable :: a11(:,:)
     real, allocatable :: a12(:,:)
     real, allocatable :: a21(:,:)
     real, allocatable :: a22(:,:)

     real, allocatable :: ec1(:,:,:)
     real, allocatable :: ec2(:,:,:)

    !- 3D Super grid to contain all geometrical factors --
    ! the 3rd dimension is 9
     real, allocatable :: sin_sg(:,:,:)
     real, allocatable :: cos_sg(:,:,:)
    !--------------------------------------------------

    !Unit vectors for lat-lon grid
     real, allocatable :: vlon(:,:,:)
     real, allocatable :: vlat(:,:,:)

  end type fv_grid_type

end module fv_grid_mod

