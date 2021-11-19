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

!------------------------------------------------------------------
subroutine unit_vect_latlon(pp, elon, elat)
  real(kind=R_GRID), intent(IN)  :: pp(2)
  real(kind=R_GRID), intent(OUT) :: elon(3), elat(3)

  real (f_p):: lon, lat
  real (f_p):: sin_lon, cos_lon, sin_lat, cos_lat

  lon = pp(1)
  lat = pp(2)

  sin_lon = sin(lon)
  cos_lon = cos(lon)
  sin_lat = sin(lat)
  cos_lat = cos(lat)

  elon(1) = -sin_lon
  elon(2) =  cos_lon
  elon(3) =  0.d0

  elat(1) = -sin_lat*cos_lon
  elat(2) = -sin_lat*sin_lon
  elat(3) =  cos_lat

end subroutine unit_vect_latlon

real(kind=R_GRID) function v_prod(v1, v2)
real(kind=R_GRID) v1(3), v2(3)

  v_prod = v1(1)*v2(1) + v1(2)*v2(2) + v1(3)*v2(3)

end function v_prod

subroutine init_cubed_to_latlon( gridstruct, agrid, nx, ny )
  
  implicit none

  type(fv_grid_type), intent(INOUT), target :: gridstruct
  real(kind=R_GRID),  intent(in) :: agrid(nx,ny,2)

  integer i, j

  integer :: is,  ie,  js,  je

 !Local pointers
  real, pointer, dimension(:,:) :: a11, a12, a21, a22
  real, pointer, dimension(:,:) :: z11, z12, z21, z22
  real(kind=R_GRID), pointer, dimension(:,:,:) :: vlon, vlat
  real(kind=R_GRID), pointer, dimension(:,:,:) :: ee1, ee2, ec1, ec2

  vlon => gridstruct%vlon
  vlat => gridstruct%vlat
  a11  => gridstruct%a11
  a12  => gridstruct%a12
  a21  => gridstruct%a21
  a22  => gridstruct%a22
  z11  => gridstruct%z11
  z12  => gridstruct%z12
  z21  => gridstruct%z21
  z22  => gridstruct%z22
  ee1  => gridstruct%ee1
  ee2  => gridstruct%ee2
  ec1  => gridstruct%ec1
  ec2  => gridstruct%ec2

  do j=1, ny
  do i=1, nx
     call unit_vect_latlon(agrid(i,j,1:2), vlon(i,j,1:3), vlat(i,j,1:3))
  enddo
  enddo

  do j=1, ny
  do i=1, nx
     z11(i,j) = v_prod(ec1(1:3,i,j), vlon(i,j,1:3))
     z12(i,j) = v_prod(ec1(1:3,i,j), vlat(i,j,1:3))
     z21(i,j) = v_prod(ec2(1:3,i,j), vlon(i,j,1:3))
     z22(i,j) = v_prod(ec2(1:3,i,j), vlat(i,j,1:3))

    !-------------------------------------------------------------------------
     a11(i,j) =  0.5d0*z22(i,j) / gridstruct%sin_sg(i,j,5)
     a12(i,j) = -0.5d0*z12(i,j) / gridstruct%sin_sg(i,j,5)
     a21(i,j) = -0.5d0*z21(i,j) / gridstruct%sin_sg(i,j,5)
     a22(i,j) =  0.5d0*z11(i,j) / gridstruct%sin_sg(i,j,5)
  enddo
  enddo

end subroutine init_cubed_to_latlon

