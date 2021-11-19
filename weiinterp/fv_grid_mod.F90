module fv_grid_mod

  implicit none

  private
  public :: fv_grid_type

!>@brief The type 'fv_grid_type' is made up of grid-dependent information from fv_grid_tools and fv_grid_utils.
!>@details It should not contain any user options (that goes in a different structure) nor data which
!! is altered outside of those two modules.
  type fv_grid_type
     real(kind=8), allocatable, dimension(:,:,:) :: grid_64, agrid_64
     real(kind=8), allocatable, dimension(:,:) :: area_64, area_c_64
     real(kind=8), allocatable, dimension(:,:) :: sina_64, cosa_64
     real(kind=8), allocatable, dimension(:,:) :: dx_64, dy_64
     real(kind=8), allocatable, dimension(:,:) :: dxc_64, dyc_64
     real(kind=8), allocatable, dimension(:,:) :: dxa_64, dya_64

     real, allocatable, dimension(:,:,:) :: grid, agrid
     real, allocatable, dimension(:,:) :: area, area_c
     real, allocatable, dimension(:,:) :: rarea, rarea_c

     real, allocatable, dimension(:,:) :: sina, cosa
     real, allocatable, dimension(:,:,:) :: e1,e2
     real, allocatable, dimension(:,:) :: dx, dy
     real, allocatable, dimension(:,:) :: dxc, dyc
     real, allocatable, dimension(:,:) :: dxa, dya
     real, allocatable, dimension(:,:) :: rdx, rdy
     real, allocatable, dimension(:,:) :: rdxc, rdyc
     real, allocatable, dimension(:,:) :: rdxa, rdya

     ! Scalars:
     real(kind=8), allocatable :: edge_s(:)
     real(kind=8), allocatable :: edge_n(:)
     real(kind=8), allocatable :: edge_w(:)
     real(kind=8), allocatable :: edge_e(:)
     ! Vector:
     real(kind=8), allocatable :: edge_vect_s(:)
     real(kind=8), allocatable :: edge_vect_n(:)
     real(kind=8), allocatable :: edge_vect_w(:)
     real(kind=8), allocatable :: edge_vect_e(:)
     ! scalar:
     real(kind=8), allocatable :: ex_s(:)
     real(kind=8), allocatable :: ex_n(:)
     real(kind=8), allocatable :: ex_w(:)
     real(kind=8), allocatable :: ex_e(:)

     real, allocatable :: l2c_u(:,:), l2c_v(:,:)
     ! divergence Damping:
     real, allocatable :: divg_u(:,:), divg_v(:,:)    !
     ! del6 diffusion:
     real, allocatable :: del6_u(:,:), del6_v(:,:)    !
     ! Cubed_2_latlon:
     real, allocatable :: a11(:,:)
     real, allocatable :: a12(:,:)
     real, allocatable :: a21(:,:)
     real, allocatable :: a22(:,:)
     ! latlon_2_cubed:
     real, allocatable :: z11(:,:)
     real, allocatable :: z12(:,:)
     real, allocatable :: z21(:,:)
     real, allocatable :: z22(:,:)

!    real, allocatable :: w00(:,:)

     real, allocatable :: cosa_u(:,:)
     real, allocatable :: cosa_v(:,:)
     real, allocatable :: cosa_s(:,:)
     real, allocatable :: sina_u(:,:)
     real, allocatable :: sina_v(:,:)
     real, allocatable :: rsin_u(:,:)
     real, allocatable :: rsin_v(:,:)
     real, allocatable ::  rsina(:,:)
     real, allocatable ::  rsin2(:,:)
     real(kind=8), allocatable :: ee1(:,:,:)
     real(kind=8), allocatable :: ee2(:,:,:)
     real(kind=8), allocatable :: ec1(:,:,:)
     real(kind=8), allocatable :: ec2(:,:,:)
     real(kind=8), allocatable :: ew(:,:,:,:)
     real(kind=8), allocatable :: es(:,:,:,:)


     !- 3D Super grid to contain all geometrical factors --
     ! the 3rd dimension is 9
     real, allocatable :: sin_sg(:,:,:)
     real, allocatable :: cos_sg(:,:,:)
     !--------------------------------------------------

     ! Unit Normal vectors at cell edges:
     real(kind=8), allocatable :: en1(:,:,:)
     real(kind=8), allocatable :: en2(:,:,:)

     ! Extended Cubed cross-edge winds
     real, allocatable :: eww(:,:)
     real, allocatable :: ess(:,:)

     ! Unit vectors for lat-lon grid
     real(kind=8), allocatable :: vlon(:,:,:), vlat(:,:,:)
     real, allocatable :: fC(:,:), f0(:,:)

     integer, dimension(:,:,:), allocatable :: iinta, jinta, iintb, jintb

     !Scalar data
     integer :: npx_g, npy_g, ntiles_g ! global domain

     real(kind=8) :: global_area
     logical :: g_sum_initialized = .false. !< Not currently used but can be useful
     logical:: sw_corner, se_corner, ne_corner, nw_corner

     real(kind=8) :: da_min, da_max, da_min_c, da_max_c

     real  :: acapN, acapS

     logical :: latlon = .false.
     logical :: cubed_sphere = .false.
     logical :: have_south_pole = .false.
     logical :: have_north_pole = .false.
     logical :: stretched_grid = .false.

     logical :: square_domain = .false.

  end type fv_grid_type

end module fv_grid_mod

