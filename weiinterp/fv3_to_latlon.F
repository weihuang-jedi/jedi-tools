!---------------------------------------------------------------
subroutine cubed_to_latlon(u, v, ua, va, gridstruct, nx, ny, nz)

  implicit none

  integer, intent(in) :: nx, ny, nz
  type(fv_grid_type), intent(IN) :: gridstruct
  real, dimension((nx, ny+1, nz), intent(inout) :: u
  real, dimension((nx+1, ny, nz), intent(inout) :: v
  real, dimension((nx, ny, nz),   intent(out)   :: ua, va

!--------------------------------------------------------------
! Local 
  real, dimension(nx, ny+1) :: wu
  real, dimension(nx+1, ny) :: wv
  real, dimension(nx)       :: u1, v1

  integer i, j, k

  real, dimension(:,:), pointer :: a11, a12, a21, a22
  real, dimension(:,:), pointer :: dx, dy

  a11 => gridstruct%a11
  a12 => gridstruct%a12
  a21 => gridstruct%a21
  a22 => gridstruct%a22

  dx => gridstruct%dx
  dy => gridstruct%dy

!$OMP parallel do default(none) &
!$OMP shared(nx,ny,nz,u,dx,v,dy,ua,va,a11,a12,a21,a22) &
!$OMP private(u1, v1, wu, wv)
  do k=1,nz
     do j=1, ny+1
     do i=1, nx
        wu(i,j) = u(i,j,k)*dx(i,j)
     enddo
     enddo

     do j=1, ny
     do i=1, nx+1
        wv(i,j) = v(i,j,k)*dy(i,j)
     enddo
     enddo

     do j=1, ny
     do i=1, nx
       !Co-variant to Co-variant "vorticity-conserving" interpolation
        u1(i) = 2.*(wu(i,j) + wu(i,j+1)) / (dx(i,j)+dx(i,j+1))
        v1(i) = 2.*(wv(i,j) + wv(i+1,j)) / (dy(i,j)+dy(i+1,j))

       !Cubed (cell center co-variant winds) to lat-lon:
        ua(i,j,k) = a11(i,j)*u1(i) + a12(i,j)*v1(i)
        va(i,j,k) = a21(i,j)*u1(i) + a22(i,j)*v1(i)
     enddo
     enddo
  enddo

end subroutine cubed_to_latlon

