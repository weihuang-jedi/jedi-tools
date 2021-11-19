module fv_grid_utils_mod

 use fv_grid_mod

 implicit none

 private

 real, parameter::  big_number=1.d8
 real, parameter:: tiny_number=1.d-8

 public cos_angle
 public latlon2xyz, unit_vect_latlon,  &
        cubed_to_latlon, v_prod
 public mid_pt_cart, vect_cross, grid_utils_init, &
        inner_prod, normalize_vect, get_latlon_vector

 contains

 subroutine grid_utils_init(gridstruct, nx, ny, nz)

   implicit none

!> Initialize 2D memory and geometrical factors
   type(fv_grid_type), intent(inout) :: gridstruct
   integer,            intent(in)    :: nx, ny, nz
!
! Super (composite) grid:
 
!     9---4---8
!     |       |
!     1   5   3
!     |       |
!     6---2---7
 
   real grid3(3,nx+1,ny+1)
   real p1(3), p2(3), p3(3), p4(3), pp(3), ex(3), ey(3), e1(3), e2(3)
   real pp1(2), pp2(2), pp3(2)

   integer i, j, k, n, ip

  !----------------------------------------------------------------------------------

   allocate(gridstruct%grid(nx, ny, 2))
   allocate(gridstruct%agrid(nx, ny, 2))

   allocate(gridstruct%ec1(3, nx, ny))
   allocate(gridstruct%ec2(3, nx, ny))

   allocate(gridstruct%a11(nx, ny))
   allocate(gridstruct%a12(nx, ny))
   allocate(gridstruct%a21(nx, ny))
   allocate(gridstruct%a22(nx, ny))

   allocate(gridstruct%cos_sg(nx, ny, 9))
   allocate(gridstruct%sin_sg(nx, ny, 9))

   allocate(gridstruct%vlon(nx, ny, 3))
   allocate(gridstruct%vlat(nx, ny, 3))

   gridstruct%cos_sg(:,:,:) =  big_number
   gridstruct%sin_sg(:,:,:) = tiny_number
  !----------------------------------------------------------------------------------

   do j=1, ny+1
   do i=1, nx+1
      call latlon2xyz(gridstruct%grid(i,j,1:2), grid3(1:3,i,j))
   enddo
   enddo

   call get_center_vect( nx, ny, grid3, gridstruct%ec1, gridstruct%ec2 )

   do j=1, ny
   do i=1, nx+1
      call mid_pt_cart( gridstruct%grid(i,j,1:2), gridstruct%grid(i,j+1,1:2), pp)
      if (i==1) then
         call latlon2xyz( gridstruct%agrid(i,j,1:2), p1)
         call vect_cross(p2, pp, p1)
      elseif(i==nx+1) then
         call latlon2xyz( gridstruct%agrid(i-1,j,1:2), p1)
         call vect_cross(p2, p1, pp)
      else
         call latlon2xyz( gridstruct%agrid(i-1,j,1:2), p3)
         call latlon2xyz( gridstruct%agrid(i,  j,1:2), p1)
         call vect_cross(p2, p3, p1)
      endif
   enddo
   enddo

   do j=1, ny+1
   do i=1, nx
      call mid_pt_cart(gridstruct%grid(i,j,1:2), gridstruct%grid(i+1,j,1:2), pp)
      if (j==1) then
         call latlon2xyz( gridstruct%agrid(i,j,1:2), p1)
         call vect_cross(p2, pp, p1)
      elseif (j==ny+1) then
         call latlon2xyz( gridstruct%agrid(i,j-1,1:2), p1)
         call vect_cross(p2, p1, pp)
      else 
         call latlon2xyz( gridstruct%agrid(i,j  ,1:2), p1)
         call latlon2xyz( gridstruct%agrid(i,j-1,1:2), p3)
         call vect_cross(p2, p3, p1)
      endif
   enddo
   enddo

!--------------------------------------------------------------------------------------------------
!     9---4---8
!     |       |
!     1   5   3
!     |       |
!     6---2---7

    do j=1, ny
    do i=1, nx
      ! Testing using spherical formular: exact if coordinate lines are along great circles
      ! SW corner:
       gridstruct%cos_sg(i,j,6) = cos_angle( grid3(1,i,j), grid3(1,i+1,j), grid3(1,i,j+1) )

      ! SE corner:
       gridstruct%cos_sg(i,j,7) = -cos_angle( grid3(1,i+1,j), grid3(1,i,j), grid3(1,i+1,j+1) )

      ! NE corner:
       gridstruct%cos_sg(i,j,8) = cos_angle( grid3(1,i+1,j+1), grid3(1,i+1,j), grid3(1,i,j+1) )

      ! NW corner:
       gridstruct%cos_sg(i,j,9) = -cos_angle( grid3(1,i,j+1), grid3(1,i,j), grid3(1,i+1,j+1) )

      ! No averaging -----
       call latlon2xyz(gridstruct%agrid(i,j,1:2), p3)   ! righ-hand system consistent with grid3
       call mid_pt3_cart(grid3(1,i,j), grid3(1,i,j+1), p1)

       gridstruct%cos_sg(i,j,1) = cos_angle( p1, p3, grid3(1,i,j+1) )
       call mid_pt3_cart(grid3(1,i,j), grid3(1,i+1,j), p1)

       gridstruct%cos_sg(i,j,2) = cos_angle( p1, grid3(1,i+1,j), p3 )
       call mid_pt3_cart(grid3(1,i+1,j), grid3(1,i+1,j+1), p1)
       gridstruct%cos_sg(i,j,3) = cos_angle( p1, p3, grid3(1,i+1,j) )

       call mid_pt3_cart(grid3(1,i,j+1), grid3(1,i+1,j+1), p1)
       gridstruct%cos_sg(i,j,4) = cos_angle( p1, grid3(1,i,j+1), p3 )

      ! Center point:
      ! Using center_vect: [ec1, ec2]
       gridstruct%cos_sg(i,j,5) = inner_prod( gridstruct%ec1(1:3,i,j), gridstruct%ec2(1:3,i,j) )
    enddo
    enddo

    do ip=1,9
    do j=i,ny
    do i=1,nx
       gridstruct%sin_sg(i,j,ip) = min(1.0, sqrt(max(0., 1.-gridstruct%cos_sg(i,j,ip)**2)))
    enddo
    enddo
    enddo

   !Initialize cubed_sphere to lat-lon transformation:
    call init_cubed_to_latlon( gridstruct, nx, ny )

end subroutine grid_utils_init


real function inner_prod(v1, v2)
   real,intent(in):: v1(3), v2(3)
   real :: vp1(3), vp2(3), prod16
   integer k
      
   do k=1,3
      vp1(k) = real(v1(k))
      vp2(k) = real(v2(k))
   enddo
   prod16 = vp1(1)*vp2(1) + vp1(2)*vp2(2) + vp1(3)*vp2(3)
   inner_prod = prod16

end function inner_prod


!>@brief The subroutine 'latlon2xyz' maps (lon, lat) to (x,y,z)
 subroutine latlon2xyz(p, e)

 real, intent(in) :: p(2)
 real, intent(out):: e(3)

    e(1) = cos(p(2)) * cos(p(1))
    e(2) = cos(p(2)) * sin(p(1))
    e(3) = sin(p(2))

 end subroutine latlon2xyz


!>@brief The subroutine 'vect_cross' performs cross products
!! of 3D vectors: e = P1 X P2
 subroutine vect_cross(e, p1, p2)
 real, intent(in) :: p1(3), p2(3)
 real, intent(out):: e(3)

      e(1) = p1(2)*p2(3) - p1(3)*p2(2)
      e(2) = p1(3)*p2(1) - p1(1)*p2(3)
      e(3) = p1(1)*p2(2) - p1(2)*p2(1)

 end subroutine vect_cross

 subroutine get_center_vect( nx, ny, pp, u1, u2 )
    integer, intent(in):: nx, ny
    real, dimension(3,nx+1,ny+1), intent(in)  :: pp
    real, dimension(3,nx,ny),     intent(out) :: u1, u2

! Local:
    integer i,j,k
    real p1(3), p2(3), pc(3), p3(3)

    do j=1,ny
       do i=1,nx
#ifdef OLD_VECT
          do k=1,3
             u1(k,i,j) = pp(k,i+1,j)+pp(k,i+1,j+1) - pp(k,i,j)-pp(k,i,j+1)
             u2(k,i,j) = pp(k,i,j+1)+pp(k,i+1,j+1) - pp(k,i,j)-pp(k,i+1,j)
          enddo
          call normalize_vect( u1(1,i,j) )
          call normalize_vect( u2(1,i,j) )
#else
          call cell_center3(pp(1,i,j), pp(1,i+1,j), pp(1,i,j+1), pp(1,i+1,j+1), pc)
! e1:
          call mid_pt3_cart(pp(1,i,j),   pp(1,i,j+1),   p1)
          call mid_pt3_cart(pp(1,i+1,j), pp(1,i+1,j+1), p2)
          call vect_cross(p3, p2, p1)
          call vect_cross(u1(1,i,j), pc, p3)
          call normalize_vect( u1(1,i,j) )
! e2:
          call mid_pt3_cart(pp(1,i,j),   pp(1,i+1,j),   p1)
          call mid_pt3_cart(pp(1,i,j+1), pp(1,i+1,j+1), p2)
          call vect_cross(p3, p2, p1)
          call vect_cross(u2(1,i,j), pc, p3)
          call normalize_vect( u2(1,i,j) )
#endif
       enddo
    enddo

 end subroutine get_center_vect


!>@brief The subroutine 'normalize_vect' makes 'e' a unit vector.
 subroutine normalize_vect(e)

 real, intent(inout):: e(3)
 real:: pdot
 integer k

    pdot = e(1)**2 + e(2)**2 + e(3)**2
    pdot = sqrt( pdot ) 

    do k=1,3
       e(k) = e(k) / pdot
    enddo

 end subroutine normalize_vect


 subroutine mid_pt3_cart(p1, p2, e)
       real, intent(IN)  :: p1(3), p2(3)
       real, intent(OUT) :: e(3)
!
       real:: q1(3), q2(3)
       real:: dd, e1, e2, e3
       integer k

       do k=1,3
          q1(k) = p1(k)
          q2(k) = p2(k)
       enddo

       e1 = q1(1) + q2(1)
       e2 = q1(2) + q2(2)
       e3 = q1(3) + q2(3)

       dd = sqrt( e1**2 + e2**2 + e3**2 )
       e1 = e1 / dd
       e2 = e2 / dd
       e3 = e3 / dd

       e(1) = e1
       e(2) = e2
       e(3) = e3

 end subroutine mid_pt3_cart



 subroutine mid_pt_cart(p1, p2, e3)
    real, intent(IN)  :: p1(2), p2(2)
    real, intent(OUT) :: e3(3)
!-------------------------------------
    real e1(3), e2(3)

    call latlon2xyz(p1, e1)
    call latlon2xyz(p2, e2)
    call mid_pt3_cart(e1, e2, e3)

 end subroutine mid_pt_cart

 !>@brief The subroutine 'intersect' calculates the intersection of two great circles.       
 !>@details input:                                                           
 !> a1, a2,  -   pairs of points on sphere in cartesian coordinates  
 !> b1, b2       defining great circles                              
 !> radius   -   radius of the sphere                                                                                                
 !> output:                                                          
 !> x_inter  -   nearest intersection point of the great circles     
 !> local_a  -   true if x1 between (a1, a2)                         
 !> local_b  -   true if x1 between (b1, b2)                                        
 !>@date July 2006                                                 
 !>@version: 0.1        
 subroutine intersect(a1,a2,b1,b2,radius,x_inter,local_a,local_b)

    real, dimension(3), intent(in)  :: a1, a2, b1, b2
    real, intent(in) :: radius
    real, dimension(3), intent(out) :: x_inter
    logical, intent(out) :: local_a,local_b
    !------------------------------------------------------------------!
    ! local variables                                                  !
    !------------------------------------------------------------------!
    real :: a2_xy, b1_xy, b2_xy, a2_xz, b1_xz, b2_xz,                   &
            b1_xyz, b2_xyz, length
    !------------------------------------------------------------------!
    ! calculate intersection point                                     !
    !------------------------------------------------------------------!
    a2_xy=a2(1)*a1(2)-a2(2)*a1(1)
    b1_xy=b1(1)*a1(2)-b1(2)*a1(1)
    b2_xy=b2(1)*a1(2)-b2(2)*a1(1)

    a2_xz=a2(1)*a1(3)-a2(3)*a1(1)
    b1_xz=b1(1)*a1(3)-b1(3)*a1(1)
    b2_xz=b2(1)*a1(3)-b2(3)*a1(1)

    b1_xyz=b1_xy*a2_xz-b1_xz*a2_xy
    b2_xyz=b2_xy*a2_xz-b2_xz*a2_xy

    if (b1_xyz==0.0d0) then
       x_inter(:)=b1(:)
    elseif (b2_xyz==0.0d0) then
       x_inter(:)=b2(:)
    else
       x_inter(:)=b2(:)-b1(:)*b2_xyz/b1_xyz
       length=sqrt(x_inter(1)*x_inter(1)+x_inter(2)*x_inter(2)+x_inter(3)*x_inter(3))
       x_inter(:)=radius/length*x_inter(:)
    endif
    !------------------------------------------------------------------!
    ! check if intersection is between pairs of points on sphere       !
    !------------------------------------------------------------------!
    call get_nearest()
    call check_local(a1,a2,local_a)
    call check_local(b1,b2,local_b)

  contains
    !------------------------------------------------------------------!
    subroutine get_nearest()
      real, dimension(3) :: center, dx
      real :: dist1,dist2

      center(:)=0.25*(a1(:)+a2(:)+b1(:)+b2(:))
      dx(:)=+x_inter(:)-center(:)
      dist1=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
      dx(:)=-x_inter(:)-center(:)
      dist2=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)

      if (dist2<dist1) x_inter(:)=-x_inter(:)

    end subroutine get_nearest
    !------------------------------------------------------------------!
    subroutine check_local(x1,x2,local)
      real, dimension(3), intent(in) :: x1,x2
      logical, intent(out) :: local

      real, dimension(3) :: dx
      real :: dist, dist1, dist2

      dx(:)=x1(:)-x2(:)
      dist=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
    
      dx(:)=x1(:)-x_inter(:)
      dist1=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
      dx(:)=x2(:)-x_inter(:)
      dist2=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)

      if (dist1<=dist .and. dist2<=dist) then
         local=.true.
      else
         local=.false.
      endif
      
    end subroutine check_local
    !------------------------------------------------------------------!
  end subroutine intersect
 
 !>@brief The subroutine 'intersect_cross' calculates the intersection of two great circles.       
 !>@details input:                                                           
 !> a1, a2,  -   pairs of points on sphere in cartesian coordinates  
 !> b1, b2       defining great circles                              
 !> radius   -   radius of the sphere                                
 !>                                                                  
 !> output:                                                          
 !> x_inter  -   nearest intersection point of the great circles     
 !> local_a  -   true if x1 between (a1, a2)                         
 !> local_b  -   true if x1 between (b1, b2)     
 subroutine intersect_cross(a1,a2,b1,b2,radius,x_inter,local_a,local_b)
  
    real, dimension(3), intent(in)  :: a1, a2, b1, b2
    real, intent(in) :: radius
    real, dimension(3), intent(out) :: x_inter
    logical, intent(out) :: local_a,local_b
    real, dimension(3) :: v1, v2

    !> A great circle is the intersection of a plane through the center
    !! of the sphere with the sphere. That plane is specified by a
    !! vector v1, which is the cross product of any two vectors lying
    !! in the plane; here, we use position vectors, which are unit
    !! vectors lying in the plane and rooted at the center of the
    !! sphere. 
    !> The intersection of two great circles is where the the
    !! intersection of the planes, a line, itself intersects the
    !! sphere. Since the planes are defined by perpendicular vectors
    !! v1, v2 respectively, the intersecting line is perpendicular
    !! to both v1 and v2, and so lies along the cross product of v1
    !! and v2.
    !> The two intersection points of the great circles is therefore +/- v1 x v2.
    call vect_cross(v1, a1, a2)
    call vect_cross(v2, b1, b2)

    v1 = v1/sqrt(v1(1)**2 + v1(2)**2 + v1(3)**2)
    v2 = v2/sqrt(v2(1)**2 + v2(2)**2 + v2(3)**2)
    call vect_cross(x_inter, v1, v2)

    !Normalize
    x_inter = x_inter/sqrt(x_inter(1)**2 + x_inter(2)**2 + x_inter(3)**2)

    ! check if intersection is between pairs of points on sphere 
    call get_nearest()
    call check_local(a1,a2,local_a)
    call check_local(b1,b2,local_b)

  contains
    subroutine get_nearest()
      real, dimension(3) :: center, dx
      real :: dist1,dist2

      center(:)=0.25*(a1(:)+a2(:)+b1(:)+b2(:))
      dx(:)=+x_inter(:)-center(:)
      dist1=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
      dx(:)=-x_inter(:)-center(:)
      dist2=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)

      if (dist2<dist1) x_inter(:)=-x_inter(:)

    end subroutine get_nearest

    subroutine check_local(x1,x2,local)
      real, dimension(3), intent(in) :: x1,x2
      logical, intent(out) :: local

      real, dimension(3) :: dx
      real :: dist, dist1, dist2

      dx(:)=x1(:)-x2(:)
      dist=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
    
      dx(:)=x1(:)-x_inter(:)
      dist1=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
      dx(:)=x2(:)-x_inter(:)
      dist2=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)

      if (dist1<=dist .and. dist2<=dist) then
         local=.true.
      else
         local=.false.
      endif
      
    end subroutine check_local
    !------------------------------------------------------------------!
  end subroutine intersect_cross



!------------------------------------------------------------------
subroutine unit_vect_latlon(pp, elon, elat)
  real, intent(IN)  :: pp(2)
  real, intent(OUT) :: elon(3), elat(3)

  real:: lon, lat
  real:: sin_lon, cos_lon, sin_lat, cos_lat

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

real function v_prod(v1, v2)
real v1(3), v2(3)

  v_prod = v1(1)*v2(1) + v1(2)*v2(2) + v1(3)*v2(3)

end function v_prod

subroutine init_cubed_to_latlon( gridstruct, nx, ny )
  
  implicit none

  type(fv_grid_type), intent(INOUT) :: gridstruct
  integer,            intent(in)    :: nx, ny

  integer i, j

 !Local pointers
  real :: z11, z12, z21, z22

  do j=1, ny
  do i=1, nx
     call unit_vect_latlon(gridstruct%agrid(i,j,1:2), gridstruct%vlon(i,j,1:3), gridstruct%vlat(i,j,1:3))
  enddo
  enddo

  do j=1, ny
  do i=1, nx
     z11 = v_prod(gridstruct%ec1(1:3,i,j), gridstruct%vlon(i,j,1:3))
     z12 = v_prod(gridstruct%ec1(1:3,i,j), gridstruct%vlat(i,j,1:3))
     z21 = v_prod(gridstruct%ec2(1:3,i,j), gridstruct%vlon(i,j,1:3))
     z22 = v_prod(gridstruct%ec2(1:3,i,j), gridstruct%vlat(i,j,1:3))

    !-------------------------------------------------------------------------
     gridstruct%a11(i,j) =  0.5d0*z22 / gridstruct%sin_sg(i,j,5)
     gridstruct%a12(i,j) = -0.5d0*z12 / gridstruct%sin_sg(i,j,5)
     gridstruct%a21(i,j) = -0.5d0*z21 / gridstruct%sin_sg(i,j,5)
     gridstruct%a22(i,j) =  0.5d0*z11 / gridstruct%sin_sg(i,j,5)
  enddo
  enddo

end subroutine init_cubed_to_latlon

!---------------------------------------------------------------
subroutine cubed_to_latlon(u, v, ua, va, gridstruct, nx, ny, nz)

  implicit none

  integer, intent(in) :: nx, ny, nz
  type(fv_grid_type), intent(IN) :: gridstruct
  real, dimension(nx, ny+1, nz), intent(inout) :: u
  real, dimension(nx+1, ny, nz), intent(inout) :: v
  real, dimension(nx, ny, nz),   intent(out)   :: ua, va

!--------------------------------------------------------------
! Local 
  real, dimension(nx, ny+1) :: wu
  real, dimension(nx+1, ny) :: wv
  real, dimension(nx)       :: u1, v1

  integer i, j, k

!$OMP parallel do default(none) &
!$OMP shared(nx,ny,nz,u,dx,v,dy,ua,va,a11,a12,a21,a22) &
!$OMP private(u1, v1, wu, wv)
  do k=1,nz
     do j=1, ny+1
     do i=1, nx
        wu(i,j) = u(i,j,k)*gridstruct%dx(i,j)
     enddo
     enddo

     do j=1, ny
     do i=1, nx+1
        wv(i,j) = v(i,j,k)*gridstruct%dy(i,j)
     enddo
     enddo

     do j=1, ny
     do i=1, nx
       !Co-variant to Co-variant "vorticity-conserving" interpolation
        u1(i) = 2.*(wu(i,j) + wu(i,j+1)) / (gridstruct%dx(i,j)+gridstruct%dx(i,j+1))
        v1(i) = 2.*(wv(i,j) + wv(i+1,j)) / (gridstruct%dy(i,j)+gridstruct%dy(i+1,j))

       !Cubed (cell center co-variant winds) to lat-lon:
        ua(i,j,k) = gridstruct%a11(i,j)*u1(i) + gridstruct%a12(i,j)*v1(i)
        va(i,j,k) = gridstruct%a21(i,j)*u1(i) + gridstruct%a22(i,j)*v1(i)
     enddo
     enddo
  enddo

end subroutine cubed_to_latlon


!>@brief The subroutine 'cell_center3' gets the center position of a cell.
 subroutine cell_center3(p1, p2, p3, p4, ec)
         real , intent(IN)  :: p1(3), p2(3), p3(3), p4(3)
         real , intent(OUT) :: ec(3)
! Local
         real dd
         integer k

         do k=1,3
            ec(k) = p1(k) + p2(k) + p3(k) + p4(k)
         enddo
         dd = sqrt( ec(1)**2 + ec(2)**2 + ec(3)**2 )

         do k=1,3
            ec(k) = ec(k) / dd
         enddo

 end subroutine cell_center3


 real function cos_angle(p1, p2, p3)
! As spherical_angle, but returns the cos(angle)
!       p3
!       ^  
!       |  
!       | 
!       p1 ---> p2
!
 real, intent(in):: p1(3), p2(3), p3(3)

 real:: e1(3), e2(3), e3(3)
 real:: px, py, pz
 real:: qx, qy, qz
 real:: angle, ddd
 integer n

  do n=1,3
     e1(n) = p1(n)
     e2(n) = p2(n)
     e3(n) = p3(n)
  enddo

!-------------------------------------------------------------------
! Page 41, Silverman's book on Vector Algebra; spherical trigonmetry
!-------------------------------------------------------------------
! Vector P:= e1 X e2
   px = e1(2)*e2(3) - e1(3)*e2(2) 
   py = e1(3)*e2(1) - e1(1)*e2(3) 
   pz = e1(1)*e2(2) - e1(2)*e2(1) 

! Vector Q: e1 X e3
   qx = e1(2)*e3(3) - e1(3)*e3(2) 
   qy = e1(3)*e3(1) - e1(1)*e3(3) 
   qz = e1(1)*e3(2) - e1(2)*e3(1) 

! ddd = sqrt[ (P*P) (Q*Q) ]
   ddd = sqrt( (px**2+py**2+pz**2)*(qx**2+qy**2+qz**2) )
   if ( ddd > 0.d0 ) then
        angle = (px*qx+py*qy+pz*qz) / ddd 
   else
        angle = 1.d0
   endif
   cos_angle = angle

 end function cos_angle

 subroutine get_latlon_vector(pp, elon, elat)
    real, intent(IN)  :: pp(2)
    real, intent(OUT) :: elon(3), elat(3)

    elon(1) = -SIN(pp(1))
    elon(2) =  COS(pp(1))
    elon(3) =  0.0
    elat(1) = -SIN(pp(2))*COS(pp(1))
    elat(2) = -SIN(pp(2))*SIN(pp(1))
!!! RIGHT_HAND
    elat(3) =  COS(pp(2))
! Left-hand system needed to be consistent with rest of the codes
!   elat(3) = -COS(pp(2))

 end subroutine get_latlon_vector

end module fv_grid_utils_mod
  
