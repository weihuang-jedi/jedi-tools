module fv_grid_utils_mod

 use fv_grid_mod

 implicit none

 private

 real, parameter::  big_number=1.d8
 real, parameter:: tiny_number=1.d-8

 public cos_angle
 public latlon2xyz, unit_vect_latlon,  &
        cubed_to_latlon, c2l_ord2, &
        v_prod, get_unit_vect2
 public mid_pt_sphere,  mid_pt_cart, vect_cross, grid_utils_init, &
        spherical_angle, cell_center2, get_area, inner_prod, &
        cart_to_latlon, intp_great_circle, normalize_vect, &
        spherical_linear_interpolation, get_latlon_vector

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
 
      real(kind=8) grid3(3,nx, ny)
      real(kind=8) p1(3), p2(3), p3(3), p4(3), pp(3), ex(3), ey(3), e1(3), e2(3)
      real(kind=8) pp1(2), pp2(2), pp3(2)
      real(kind=8) sin2
      integer i, j, k, n, ip

     !Local pointers
      real(kind=8), pointer, dimension(:,:,:) :: agrid, grid
      real(kind=8), pointer, dimension(:,:) :: area, area_c
      real(kind=8), pointer, dimension(:,:) :: sina, cosa, dx, dy, dxc, dyc, dxa, dya
      real, pointer, dimension(:,:) :: del6_u, del6_v
      real, pointer, dimension(:,:) :: divg_u, divg_v
      real, pointer, dimension(:,:) :: cosa_u, cosa_v, cosa_s
      real, pointer, dimension(:,:) :: sina_u, sina_v
      real, pointer, dimension(:,:) :: rsin_u, rsin_v
      real, pointer, dimension(:,:) :: rsina, rsin2
      real, pointer, dimension(:,:,:) :: sin_sg, cos_sg
      real(kind=8), pointer, dimension(:,:,:) :: ee1, ee2, ec1, ec2
      real(kind=8), pointer, dimension(:,:,:,:) :: ew, es
      real(kind=8), pointer, dimension(:,:,:) :: en1, en2
!     real(kind=8), pointer, dimension(:,:) :: eww, ess
      logical, pointer :: sw_corner, se_corner, ne_corner, nw_corner

!--- pointers to higher-order precision quantities
      agrid => gridstruct%agrid_64
      grid  => gridstruct%grid_64
      area    => gridstruct%area_64
      area_c  => gridstruct%area_c_64
      dx     => gridstruct%dx_64
      dy     => gridstruct%dy_64
      dxc    => gridstruct%dxc_64
      dyc    => gridstruct%dyc_64
      dxa    => gridstruct%dxa_64
      dya    => gridstruct%dya_64
      sina   => gridstruct%sina_64
      cosa   => gridstruct%cosa_64

      divg_u => gridstruct%divg_u
      divg_v => gridstruct%divg_v

      del6_u => gridstruct%del6_u
      del6_v => gridstruct%del6_v

      cosa_u => gridstruct%cosa_u
      cosa_v => gridstruct%cosa_v
      cosa_s => gridstruct%cosa_s
      sina_u => gridstruct%sina_u
      sina_v => gridstruct%sina_v
      rsin_u => gridstruct%rsin_u
      rsin_v => gridstruct%rsin_v
      rsina => gridstruct%rsina
      rsin2 => gridstruct%rsin2
      ee1 => gridstruct%ee1
      ee2 => gridstruct%ee2
      ec1 => gridstruct%ec1
      ec2 => gridstruct%ec2
      ew => gridstruct%ew
      es => gridstruct%es
      sin_sg => gridstruct%sin_sg
      cos_sg => gridstruct%cos_sg
      en1 => gridstruct%en1
      en2 => gridstruct%en2

      sw_corner => gridstruct%sw_corner
      se_corner => gridstruct%se_corner
      ne_corner => gridstruct%ne_corner
      nw_corner => gridstruct%nw_corner

     !----------------------------------------------------------------------------------
      cos_sg(:,:,:) =  big_number
      sin_sg(:,:,:) = tiny_number

      sw_corner = .true.
      se_corner = .true.
      ne_corner = .true.
      nw_corner = .true.

     if ( .not. Atm%gridstruct%bounded_domain ) then
     call fill_corners(grid(:,:,1), nx+1, ny+1, FILL=XDir, BGRID=.true.)
     call fill_corners(grid(:,:,2), nx+1, ny+1, FILL=XDir, BGRID=.true.)
     end if

     do j=1, ny+1
     do i=1, nx+1
        call latlon2xyz(grid(i,j,1:2), grid3(1,i,j))
     enddo
     enddo

     call get_center_vect( npx, npy, grid3, ec1, ec2, Atm%bd )

     do j=1, ny
        do i=1, nx+1
           call mid_pt_cart( grid(i,j,1:2), grid(i,j+1,1:2), pp)
           if (i==1) then
              call latlon2xyz( agrid(i,j,1:2), p1)
              call vect_cross(p2, pp, p1)
           elseif(i==nx+1) then
              call latlon2xyz( agrid(i-1,j,1:2), p1)
              call vect_cross(p2, p1, pp)
           else
              call latlon2xyz( agrid(i-1,j,1:2), p3)
              call latlon2xyz( agrid(i,  j,1:2), p1)
              call vect_cross(p2, p3, p1)
           endif

           call vect_cross(ew(1:3,i,j,1), p2, pp)
           call normalize_vect(ew(1:3,i,j,1))
!---
           call vect_cross(p1, grid3(1,i,j), grid3(1,i,j+1))
           call vect_cross(ew(1:3,i,j,2), p1, pp)
           call normalize_vect(ew(1:3,i,j,2))
        enddo
     enddo

     do j=1, ny+1
        do i=1, nx
           call mid_pt_cart(grid(i,j,1:2), grid(i+1,j,1:2), pp)
           if (j==1) then
              call latlon2xyz( agrid(i,j,1:2), p1)
              call vect_cross(p2, pp, p1)
           elseif (j==ny+1) then
              call latlon2xyz( agrid(i,j-1,1:2), p1)
              call vect_cross(p2, p1, pp)
           else 
              call latlon2xyz( agrid(i,j  ,1:2), p1)
              call latlon2xyz( agrid(i,j-1,1:2), p3)
              call vect_cross(p2, p3, p1)
           endif

           call vect_cross(es(1:3,i,j,2), p2, pp)
           call normalize_vect(es(1:3,i,j,2))
!---
           call vect_cross(p3, grid3(1,i,j), grid3(1,i+1,j))
           call vect_cross(es(1:3,i,j,1), p3, pp)
           call normalize_vect(es(1:3,i,j,1))
        enddo
     enddo

!     9---4---8
!     |       |
!     1   5   3
!     |       |
!     6---2---7

      do j=jsd,jed
         do i=isd,ied
! Testing using spherical formular: exact if coordinate lines are along great circles
! SW corner:
            cos_sg(i,j,6) = cos_angle( grid3(1,i,j), grid3(1,i+1,j), grid3(1,i,j+1) )
! SE corner:
            cos_sg(i,j,7) = -cos_angle( grid3(1,i+1,j), grid3(1,i,j), grid3(1,i+1,j+1) )
! NE corner:
            cos_sg(i,j,8) = cos_angle( grid3(1,i+1,j+1), grid3(1,i+1,j), grid3(1,i,j+1) )
! NW corner:
            cos_sg(i,j,9) = -cos_angle( grid3(1,i,j+1), grid3(1,i,j), grid3(1,i+1,j+1) )
! No averaging -----
            call latlon2xyz(agrid(i,j,1:2), p3)   ! righ-hand system consistent with grid3
               call mid_pt3_cart(grid3(1,i,j), grid3(1,i,j+1), p1)
            cos_sg(i,j,1) = cos_angle( p1, p3, grid3(1,i,j+1) )
               call mid_pt3_cart(grid3(1,i,j), grid3(1,i+1,j), p1)
            cos_sg(i,j,2) = cos_angle( p1, grid3(1,i+1,j), p3 )
               call mid_pt3_cart(grid3(1,i+1,j), grid3(1,i+1,j+1), p1)
            cos_sg(i,j,3) = cos_angle( p1, p3, grid3(1,i+1,j) )
               call mid_pt3_cart(grid3(1,i,j+1), grid3(1,i+1,j+1), p1)
            cos_sg(i,j,4) = cos_angle( p1, grid3(1,i,j+1), p3 )
! Center point:
! Using center_vect: [ec1, ec2]
            cos_sg(i,j,5) = inner_prod( ec1(1:3,i,j), ec2(1:3,i,j) )
         enddo
      enddo

      do ip=1,9
      do j=i,ny
      do i=1,nx
         sin_sg(i,j,ip) = min(1.0, sqrt( max(0., 1.-cos_sg(i,j,ip)**2) ) )
      enddo
      enddo
      enddo

! For AAM correction:
     do j=1,ny
        do i=1,nx+1
           pp1(:) = grid(i  ,j ,1:2)
           pp2(:) = grid(i,j+1 ,1:2)
           call mid_pt_sphere(pp1, pp2, pp3)
           call get_unit_vect2(pp1, pp2, e2)
           call get_latlon_vector(pp3, ex, ey)
           gridstruct%l2c_v(i,j) = cos(pp3(2)) * inner_prod(e2, ex)
        enddo
     enddo

     do j=js,je+1
        do i=is,ie
           pp1(:) = grid(i,  j,1:2)
           pp2(:) = grid(i+1,j,1:2)
           call mid_pt_sphere(pp1, pp2, pp3)
           call get_unit_vect2(pp1, pp2, e1)
           call get_latlon_vector(pp3, ex, ey)
           gridstruct%l2c_u(i,j) = cos(pp3(2)) * inner_prod(e1, ex)
        enddo
     enddo


   if ( non_ortho ) then
           cosa_u = big_number
           cosa_v = big_number
           cosa_s = big_number
           sina_u = big_number
           sina_v = big_number
           rsin_u = big_number
           rsin_v = big_number
           rsina  = big_number
           rsin2  = big_number
           cosa = big_number
           sina = big_number

        do j=js,je+1
           do i=is,ie+1
! unit vect in X-dir: ee1
              if (i==1 .and. .not. Atm%gridstruct%bounded_domain) then
                  call vect_cross(pp, grid3(1,i,  j), grid3(1,i+1,j))
              elseif(i==npx .and. .not. Atm%gridstruct%bounded_domain) then
                  call vect_cross(pp, grid3(1,i-1,j), grid3(1,i,  j))
              else
                  call vect_cross(pp, grid3(1,i-1,j), grid3(1,i+1,j))
              endif
              call vect_cross(ee1(1:3,i,j), pp, grid3(1:3,i,j))
              call normalize_vect( ee1(1:3,i,j) )

! unit vect in Y-dir: ee2
              if (j==1 .and. .not. Atm%gridstruct%bounded_domain) then
                  call vect_cross(pp, grid3(1:3,i,j  ), grid3(1:3,i,j+1))
              elseif(j==npy .and. .not. Atm%gridstruct%bounded_domain) then
                  call vect_cross(pp, grid3(1:3,i,j-1), grid3(1:3,i,j  ))
              else
                  call vect_cross(pp, grid3(1:3,i,j-1), grid3(1:3,i,j+1))
              endif
              call vect_cross(ee2(1:3,i,j), pp, grid3(1:3,i,j))
              call normalize_vect( ee2(1:3,i,j) )

              cosa(i,j) = 0.5*(cos_sg(i-1,j-1,8)+cos_sg(i,j,6))
              sina(i,j) = 0.5*(sin_sg(i-1,j-1,8)+sin_sg(i,j,6))
           enddo
        enddo

!     9---4---8
!     |       |
!     1   5   3
!     |       |
!     6---2---7
      do j=jsd,jed
         do i=isd+1,ied
            cosa_u(i,j) = 0.5*(cos_sg(i-1,j,3)+cos_sg(i,j,1))
            sina_u(i,j) = 0.5*(sin_sg(i-1,j,3)+sin_sg(i,j,1))
!           rsin_u(i,j) =  1. / sina_u(i,j)**2
            rsin_u(i,j) =  1. / max(tiny_number, sina_u(i,j)**2)
         enddo
      enddo
      do j=jsd+1,jed
         do i=isd,ied
            cosa_v(i,j) = 0.5*(cos_sg(i,j-1,4)+cos_sg(i,j,2))
            sina_v(i,j) = 0.5*(sin_sg(i,j-1,4)+sin_sg(i,j,2))
!           rsin_v(i,j) =  1. / sina_v(i,j)**2
            rsin_v(i,j) =  1. / max(tiny_number, sina_v(i,j)**2)
         enddo
      enddo
     
      do j=jsd,jed
         do i=isd,ied
            cosa_s(i,j) = cos_sg(i,j,5)
!           rsin2(i,j) = 1. / sin_sg(i,j,5)**2
            rsin2(i,j) = 1. / max(tiny_number, sin_sg(i,j,5)**2)
         enddo
      enddo

!------------------------------------
! Set special sin values at edges:
!------------------------------------
      do j=js,je+1
         do i=is,ie+1
            if ( i==npx .and. j==npy .and. .not. Atm%gridstruct%bounded_domain) then
            else if ( ( i==1 .or. i==npx .or. j==1 .or. j==npy ) .and. .not. Atm%gridstruct%bounded_domain ) then
                 rsina(i,j) = big_number
            else
!                rsina(i,j) = 1. / sina(i,j)**2
                 rsina(i,j) = 1. / max(tiny_number, sina(i,j)**2)
            endif
         enddo
      enddo

      do j=jsd,jed
         do i=is,ie+1
            if ( (i==1 .or. i==npx)  .and. .not. Atm%gridstruct%bounded_domain ) then
!                rsin_u(i,j) = 1. / sina_u(i,j)
                 rsin_u(i,j) = 1. / sign(max(tiny_number,abs(sina_u(i,j))), sina_u(i,j))
            endif
         enddo
      enddo

      do j=js,je+1
         do i=isd,ied
            if ( (j==1 .or. j==npy) .and. .not. Atm%gridstruct%bounded_domain ) then
!                rsin_v(i,j) = 1. / sina_v(i,j)
                 rsin_v(i,j) = 1. / sign(max(tiny_number,abs(sina_v(i,j))), sina_v(i,j))
            endif
         enddo
      enddo

#ifdef USE_NORM_VECT
!-------------------------------------------------------------
! Make normal vect at face edges after consines are computed:
!-------------------------------------------------------------
! for old d2a2c_vect routines
      if (.not. Atm%gridstruct%bounded_domain) then
         do j=js-1,je+1
            if ( is==1 ) then
               i=1
               call vect_cross(ew(1,i,j,1), grid3(1,i,j+1), grid3(1,i,j)) 
               call normalize_vect( ew(1,i,j,1) )
            endif
            if ( (ie+1)==npx ) then
               i=npx
               call vect_cross(ew(1,i,j,1), grid3(1,i,j+1), grid3(1,i,j)) 
               call normalize_vect( ew(1,i,j,1) )
            endif
         enddo

         if ( js==1 ) then
            j=1
            do i=is-1,ie+1
               call vect_cross(es(1,i,j,2), grid3(1,i,j),grid3(1,i+1,j)) 
               call normalize_vect( es(1,i,j,2) )
            enddo
         endif
         if ( (je+1)==npy ) then
            j=npy
            do i=is-1,ie+1
               call vect_cross(es(1,i,j,2), grid3(1,i,j),grid3(1,i+1,j)) 
               call normalize_vect( es(1,i,j,2) )
            enddo
         endif
      endif
#endif

! For omega computation:
! Unit vectors:
     do j=js,je+1
        do i=is,ie
           call vect_cross(en1(1:3,i,j), grid3(1,i,j), grid3(1,i+1,j))
           call normalize_vect( en1(1:3,i,j) )
        enddo
     enddo
     do j=js,je
        do i=is,ie+1
           call vect_cross(en2(1:3,i,j), grid3(1,i,j+1), grid3(1,i,j)) 
           call normalize_vect( en2(1:3,i,j) )
        enddo
     enddo
!-------------------------------------------------------------
! Make unit vectors for the coordinate extension:
!-------------------------------------------------------------
 

! Initialize cubed_sphere to lat-lon transformation:
     call init_cubed_to_latlon( gridstruct, agrid, nx, ny, nz )

!32-bit versions of the data
      gridstruct%grid   = gridstruct%grid_64
      gridstruct%agrid  = gridstruct%agrid_64
      gridstruct%area   = gridstruct%area_64
      gridstruct%area_c = gridstruct%area_c_64
      gridstruct%dx     = gridstruct%dx_64
      gridstruct%dy     = gridstruct%dy_64
      gridstruct%dxa    = gridstruct%dxa_64
      gridstruct%dya    = gridstruct%dya_64
      gridstruct%dxc    = gridstruct%dxc_64
      gridstruct%dyc    = gridstruct%dyc_64
      gridstruct%cosa   = gridstruct%cosa_64
      gridstruct%sina   = gridstruct%sina_64

!--- deallocate the higher-order gridstruct arrays
      deallocate ( gridstruct%area_c_64 )
      deallocate ( gridstruct%dxa_64 )
      deallocate ( gridstruct%dya_64 )
      deallocate ( gridstruct%dxc_64 )
      deallocate ( gridstruct%dyc_64 )
      deallocate ( gridstruct%cosa_64 )
      deallocate ( gridstruct%sina_64 )

      nullify(agrid)
      nullify(grid)
      nullify(area)
      nullify(area_c)
      nullify(dx)
      nullify(dy)
      nullify(dxc)
      nullify(dyc)
      nullify(dxa)
      nullify(dya)
      nullify(sina)
      nullify(cosa)

      nullify(cosa_u)
      nullify(cosa_v)
      nullify(cosa_s)
      nullify(sina_u)
      nullify(sina_v)
      nullify(rsin_u)
      nullify(rsin_v)
      nullify(rsina)
      nullify(rsin2)
      nullify(ee1)
      nullify(ee2)
      nullify(ec1)
      nullify(ec2)
      nullify(ew)
      nullify(es)
      nullify(sin_sg)
      nullify(cos_sg)
      nullify(en1)
      nullify(en2)

end subroutine grid_utils_init


real function inner_prod(v1, v2)
   real(kind=8),intent(in):: v1(3), v2(3)
   real (f_p) :: vp1(3), vp2(3), prod16
   integer k
      
   do k=1,3
      vp1(k) = real(v1(k),kind=f_p)
      vp2(k) = real(v2(k),kind=f_p)
   enddo
   prod16 = vp1(1)*vp2(1) + vp1(2)*vp2(2) + vp1(3)*vp2(3)
   inner_prod = prod16

end function inner_prod


!>@brief The subroutine 'latlon2xyz' maps (lon, lat) to (x,y,z)
 subroutine latlon2xyz(p, e, id)

 real(kind=8), intent(in) :: p(2)
 real(kind=8), intent(out):: e(3)
 integer, optional, intent(in):: id !< id=0 do nothing; id=1, right_hand

 integer n
 real (f_p):: q(2)
 real (f_p):: e1, e2, e3

    do n=1,2
       q(n) = p(n)
    enddo

    e1 = cos(q(2)) * cos(q(1))
    e2 = cos(q(2)) * sin(q(1))
    e3 = sin(q(2))
!-----------------------------------
! Truncate to the desired precision:
!-----------------------------------
    e(1) = e1
    e(2) = e2
    e(3) = e3

 end subroutine latlon2xyz

!>@brief The subroutine 'mirror_xyz' computes the mirror image of p0(x0, y0, z0)
!! as p(x, y, z) given the "mirror" as defined by p1(x1, y1, z1), p2(x2, y2, z2), 
!! and the center of the sphere.
 subroutine mirror_xyz(p1, p2, p0, p)
!-------------------------------------------------------------------------------
! for k=1,2,3 (x,y,z)
!
! p(k) = p0(k) - 2 * [p0(k) .dot. NB(k)] * NB(k)
!
! where 
!       NB(k) = p1(k) .cross. p2(k)         ---- direction of NB is imaterial
!       the normal unit vector to the "mirror" plane
!-------------------------------------------------------------------------------

 real(kind=8), intent(in) :: p1(3), p2(3), p0(3)
 real(kind=8), intent(out):: p(3)
!
 real(kind=8):: x1, y1, z1, x2, y2, z2, x0, y0, z0
 real(kind=8) nb(3)
 real(kind=8) pdot
 integer k

 call vect_cross(nb, p1, p2)
    pdot = sqrt(nb(1)**2+nb(2)**2+nb(3)**2)
 do k=1,3
    nb(k) = nb(k) / pdot
 enddo

 pdot = p0(1)*nb(1) + p0(2)*nb(2) + p0(3)*nb(3)
 do k=1,3
    p(k) = p0(k) - 2.d0*pdot*nb(k)
 enddo

 end subroutine mirror_xyz 


 subroutine cart_to_latlon(np, q, xs, ys)
! vector version of cart_to_latlon1
  integer, intent(in):: np
  real(kind=8), intent(inout):: q(3,np)
  real(kind=8), intent(inout):: xs(np), ys(np)
! local
  real(kind=8), parameter:: esl=1.d-10
  real (f_p):: p(3)
  real (f_p):: dist, lat, lon
  integer i,k

  do i=1,np
     do k=1,3
        p(k) = q(k,i)
     enddo
     dist = sqrt(p(1)**2 + p(2)**2 + p(3)**2)
     do k=1,3
        p(k) = p(k) / dist
     enddo

     if ( (abs(p(1))+abs(p(2)))  < esl ) then
          lon = real(0.,kind=f_p)
     else
          lon = atan2( p(2), p(1) )   ! range [-pi,pi]
     endif

     if ( lon < 0.) lon = real(2.,kind=f_p)*pi + lon
! RIGHT_HAND system:
     lat = asin(p(3))
     
     xs(i) = lon
     ys(i) = lat
! q Normalized:
     do k=1,3
        q(k,i) = p(k)
     enddo
  enddo

 end  subroutine cart_to_latlon

!>@brief The subroutine 'vect_cross' performs cross products
!! of 3D vectors: e = P1 X P2
 subroutine vect_cross(e, p1, p2)
 real(kind=8), intent(in) :: p1(3), p2(3)
 real(kind=8), intent(out):: e(3)

      e(1) = p1(2)*p2(3) - p1(3)*p2(2)
      e(2) = p1(3)*p2(1) - p1(1)*p2(3)
      e(3) = p1(1)*p2(2) - p1(2)*p2(1)

 end subroutine vect_cross

 subroutine get_center_vect( npx, npy, pp, u1, u2, bd )
   type(fv_grid_bounds_type), intent(IN) :: bd
    integer, intent(in):: npx, npy
    real(kind=8), intent(in) :: pp(3,bd%isd:bd%ied+1,bd%jsd:bd%jed+1)
    real(kind=8), intent(out):: u1(3,bd%isd:bd%ied,  bd%jsd:bd%jed)
    real(kind=8), intent(out):: u2(3,bd%isd:bd%ied,  bd%jsd:bd%jed)
! Local:
    integer i,j,k
    real(kind=8) p1(3), p2(3), pc(3), p3(3)

    integer :: isd, ied, jsd, jed

      isd = bd%isd
      ied = bd%ied
      jsd = bd%jsd
      jed = bd%jed

    do j=jsd,jed
       do i=isd,ied
        if ( (i<1       .and. j<1  )     .or. (i>(npx-1) .and. j<1) .or.  &
             (i>(npx-1) .and. j>(npy-1)) .or. (i<1       .and. j>(npy-1))) then
             u1(1:3,i,j) = 0.d0
             u2(1:3,i,j) = 0.d0
        else
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
        endif
       enddo
    enddo

 end subroutine get_center_vect


 subroutine get_unit_vect2( e1, e2, uc )
   real(kind=8), intent(in) :: e1(2), e2(2)
   real(kind=8), intent(out):: uc(3) !< unit vector e1--->e2
! Local:
   real(kind=8), dimension(3):: pc, p1, p2, p3

! RIGHT_HAND system:
   call latlon2xyz(e1, p1)
   call latlon2xyz(e2, p2)

   call mid_pt3_cart(p1, p2,  pc)
   call vect_cross(p3, p2, p1)
   call vect_cross(uc, pc, p3)
   call normalize_vect( uc )

 end subroutine get_unit_vect2

 subroutine get_unit_vect3( p1, p2, uc )
   real(kind=8), intent(in) :: p1(3), p2(3)
   real(kind=8), intent(out):: uc(3)
! Local:
   real(kind=8), dimension(3):: pc, p3

   call mid_pt3_cart(p1, p2,  pc)
   call vect_cross(p3, p2, p1)
   call vect_cross(uc, pc, p3)
   call normalize_vect( uc )

 end subroutine get_unit_vect3

!>@brief The subroutine 'normalize_vect' makes 'e' a unit vector.
 subroutine normalize_vect(e)

 real(kind=8), intent(inout):: e(3)
 real(f_p):: pdot
 integer k

    pdot = e(1)**2 + e(2)**2 + e(3)**2
    pdot = sqrt( pdot ) 

    do k=1,3
       e(k) = e(k) / pdot
    enddo

 end subroutine normalize_vect


 subroutine intp_great_circle(beta, p1, p2, x_o, y_o)
 real(kind=8), intent(in)::  beta  !< [0,1]
 real(kind=8), intent(in)::  p1(2), p2(2)
 real(kind=8), intent(out):: x_o, y_o !< between p1 and p2 along GC
!------------------------------------------
    real(kind=8):: pm(2)
    real(kind=8):: e1(3), e2(3), e3(3)
    real(kind=8):: s1, s2, s3, dd, alpha

      call latlon2xyz(p1, e1)
      call latlon2xyz(p2, e2)

       alpha = 1.d0 - beta

       s1 = alpha*e1(1) + beta*e2(1)
       s2 = alpha*e1(2) + beta*e2(2)
       s3 = alpha*e1(3) + beta*e2(3)

       dd = sqrt( s1**2 + s2**2 + s3**2 )

       e3(1) = s1 / dd
       e3(2) = s2 / dd
       e3(3) = s3 / dd

      call cart_to_latlon(1, e3, pm(1), pm(2))

      x_o = pm(1)
      y_o = pm(2)

 end subroutine intp_great_circle

!>@brief The subroutine 'spherical_linear_interpolation' interpolates along the great circle connecting points p1 and p2.
!>@details The routine uses the formula taken from <http://en.wikipedia.org/wiki/Slerp> 
!! and is attributed to Glenn Davis based on a concept by Ken Shoemake.
 subroutine spherical_linear_interpolation(beta, p1, p2, pb)

 real(kind=8), intent(in)::  beta    !< [0,1]
 real(kind=8), intent(in)::  p1(2), p2(2)
 real(kind=8), intent(out):: pb(2)   !< between p1 and p2 along GC
!------------------------------------------
 real(kind=8):: pm(2)
 real(kind=8):: e1(3), e2(3), eb(3)
 real(kind=8):: dd, alpha, omg
 
 if ( abs(p1(1) - p2(1)) < 1.d-8 .and. abs(p1(2) - p2(2)) < 1.d-8) then
    call mpp_error(WARNING, 'spherical_linear_interpolation was passed two colocated points.')
    pb = p1
    return
 end if

 call latlon2xyz(p1, e1)
 call latlon2xyz(p2, e2)

 dd = sqrt( e1(1)**2 + e1(2)**2 + e1(3)**2 )
 
 e1(1) = e1(1) / dd
 e1(2) = e1(2) / dd
 e1(3) = e1(3) / dd

 dd = sqrt( e2(1)**2 + e2(2)**2 + e2(3)**2 )
 
 e2(1) = e2(1) / dd
 e2(2) = e2(2) / dd
 e2(3) = e2(3) / dd

 alpha = 1.d0 - beta

 omg = acos( e1(1)*e2(1) + e1(2)*e2(2) + e1(3)*e2(3) )

 if ( abs(omg) < 1.d-5 ) then
    print*, 'spherical_linear_interpolation: ', omg, p1, p2
    call mpp_error(FATAL, 'spherical_linear_interpolation: interpolation not well defined between antipodal points')
 end if

 eb(1) = sin( beta*omg )*e2(1) + sin(alpha*omg)*e1(1)
 eb(2) = sin( beta*omg )*e2(2) + sin(alpha*omg)*e1(2)
 eb(3) = sin( beta*omg )*e2(3) + sin(alpha*omg)*e1(3)

 eb(1) = eb(1) / sin(omg)
 eb(2) = eb(2) / sin(omg)
 eb(3) = eb(3) / sin(omg)

 call cart_to_latlon(1, eb, pb(1), pb(2))

 end subroutine spherical_linear_interpolation

 subroutine mid_pt_sphere(p1, p2, pm)
      real(kind=8) , intent(IN)  :: p1(2), p2(2)
      real(kind=8) , intent(OUT) :: pm(2)
!------------------------------------------
      real(kind=8) e1(3), e2(3), e3(3)

      call latlon2xyz(p1, e1)
      call latlon2xyz(p2, e2)
      call mid_pt3_cart(e1, e2, e3)
      call cart_to_latlon(1, e3, pm(1), pm(2))

 end subroutine mid_pt_sphere



 subroutine mid_pt3_cart(p1, p2, e)
       real(kind=8), intent(IN)  :: p1(3), p2(3)
       real(kind=8), intent(OUT) :: e(3)
!
       real (f_p):: q1(3), q2(3)
       real (f_p):: dd, e1, e2, e3
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
    real(kind=8), intent(IN)  :: p1(2), p2(2)
    real(kind=8), intent(OUT) :: e3(3)
!-------------------------------------
    real(kind=8) e1(3), e2(3)

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

    real(kind=8), dimension(3), intent(in)  :: a1, a2, b1, b2
    real(kind=8), intent(in) :: radius
    real(kind=8), dimension(3), intent(out) :: x_inter
    logical, intent(out) :: local_a,local_b
    !------------------------------------------------------------------!
    ! local variables                                                  !
    !------------------------------------------------------------------!
    real(kind=8) :: a2_xy, b1_xy, b2_xy, a2_xz, b1_xz, b2_xz,                   &
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
      real(kind=8), dimension(3) :: center, dx
      real(kind=8) :: dist1,dist2

      center(:)=0.25*(a1(:)+a2(:)+b1(:)+b2(:))
      dx(:)=+x_inter(:)-center(:)
      dist1=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
      dx(:)=-x_inter(:)-center(:)
      dist2=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)

      if (dist2<dist1) x_inter(:)=-x_inter(:)

    end subroutine get_nearest
    !------------------------------------------------------------------!
    subroutine check_local(x1,x2,local)
      real(kind=8), dimension(3), intent(in) :: x1,x2
      logical, intent(out) :: local

      real(kind=8), dimension(3) :: dx
      real(kind=8) :: dist, dist1, dist2

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
  
    real(kind=8), dimension(3), intent(in)  :: a1, a2, b1, b2
    real(kind=8), intent(in) :: radius
    real(kind=8), dimension(3), intent(out) :: x_inter
    logical, intent(out) :: local_a,local_b
    real(kind=8), dimension(3) :: v1, v2

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
      real(kind=8), dimension(3) :: center, dx
      real(kind=8) :: dist1,dist2

      center(:)=0.25*(a1(:)+a2(:)+b1(:)+b2(:))
      dx(:)=+x_inter(:)-center(:)
      dist1=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)
      dx(:)=-x_inter(:)-center(:)
      dist2=dx(1)*dx(1)+dx(2)*dx(2)+dx(3)*dx(3)

      if (dist2<dist1) x_inter(:)=-x_inter(:)

    end subroutine get_nearest

    subroutine check_local(x1,x2,local)
      real(kind=8), dimension(3), intent(in) :: x1,x2
      logical, intent(out) :: local

      real(kind=8), dimension(3) :: dx
      real(kind=8) :: dist, dist1, dist2

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
  real(kind=8), intent(IN)  :: pp(2)
  real(kind=8), intent(OUT) :: elon(3), elat(3)

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

real(kind=8) function v_prod(v1, v2)
real(kind=8) v1(3), v2(3)

  v_prod = v1(1)*v2(1) + v1(2)*v2(2) + v1(3)*v2(3)

end function v_prod

subroutine init_cubed_to_latlon( gridstruct, agrid, nx, ny )
  
  implicit none

  type(fv_grid_type), intent(INOUT), target :: gridstruct
  real(kind=8),  intent(in) :: agrid(nx,ny,2)

  integer i, j

  integer :: is,  ie,  js,  je

 !Local pointers
  real, pointer, dimension(:,:) :: a11, a12, a21, a22
  real, pointer, dimension(:,:) :: z11, z12, z21, z22
  real(kind=8), pointer, dimension(:,:,:) :: vlon, vlat
  real(kind=8), pointer, dimension(:,:,:) :: ee1, ee2, ec1, ec2

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

 subroutine expand_cell(q1, q2, q3, q4, a1, a2, a3, a4, fac)
! Util for land model (for BW)
!
!        4----3
!        |  . |
!        1----2
!
      real(kind=8), intent(in):: q1(2), q2(2), q3(2), q4(2)
      real(kind=8), intent(in):: fac    ! expansion factor: outside: > 1
                                ! fac = 1: qq1 returns q1
                                ! fac = 0: qq1 returns the center position
      real(kind=8), intent(out):: a1(2), a2(2), a3(2), a4(2)
! Local
      real(kind=8) qq1(3), qq2(3), qq3(3), qq4(3)
      real(kind=8) p1(3), p2(3), p3(3), p4(3)
      real(kind=8) ec(3)
      real(f_p):: dd, d1, d2, d3, d4
      integer k

! Transform to (x,y,z)
      call latlon2xyz(q1, p1)
      call latlon2xyz(q2, p2)
      call latlon2xyz(q3, p3)
      call latlon2xyz(q4, p4)

! Get center position:
      do k=1,3
         ec(k) = p1(k) + p2(k) + p3(k) + p4(k)
      enddo
      dd = sqrt( ec(1)**2 + ec(2)**2 + ec(3)**2 )

      do k=1,3
         ec(k) = ec(k) / dd   ! cell center position
      enddo

! Perform the "extrapolation" in 3D (x-y-z) 
      do k=1,3
         qq1(k) = ec(k) + fac*(p1(k)-ec(k)) 
         qq2(k) = ec(k) + fac*(p2(k)-ec(k)) 
         qq3(k) = ec(k) + fac*(p3(k)-ec(k)) 
         qq4(k) = ec(k) + fac*(p4(k)-ec(k)) 
      enddo

!--------------------------------------------------------
! Force the points to be on the sphere via normalization
!--------------------------------------------------------
      d1 = sqrt( qq1(1)**2 + qq1(2)**2 + qq1(3)**2 )
      d2 = sqrt( qq2(1)**2 + qq2(2)**2 + qq2(3)**2 )
      d3 = sqrt( qq3(1)**2 + qq3(2)**2 + qq3(3)**2 )
      d4 = sqrt( qq4(1)**2 + qq4(2)**2 + qq4(3)**2 )
      do k=1,3
         qq1(k) = qq1(k) / d1
         qq2(k) = qq2(k) / d2
         qq3(k) = qq3(k) / d3
         qq4(k) = qq4(k) / d4
      enddo

!----------------------------------------
! Transform back to lat-lon coordinates:
!----------------------------------------

      call cart_to_latlon(1, qq1, a1(1), a1(2))
      call cart_to_latlon(1, qq2, a2(1), a2(2))
      call cart_to_latlon(1, qq3, a3(1), a3(2))
      call cart_to_latlon(1, qq4, a4(1), a4(2))

 end subroutine expand_cell


 subroutine cell_center2(q1, q2, q3, q4, e2)
      real(kind=8) , intent(in ) :: q1(2), q2(2), q3(2), q4(2)
      real(kind=8) , intent(out) :: e2(2)
! Local
      real(kind=8) p1(3), p2(3), p3(3), p4(3)
      real(kind=8) ec(3)
      real(kind=8) dd
      integer k

      call latlon2xyz(q1, p1)
      call latlon2xyz(q2, p2)
      call latlon2xyz(q3, p3)
      call latlon2xyz(q4, p4)

      do k=1,3
         ec(k) = p1(k) + p2(k) + p3(k) + p4(k)
      enddo
      dd = sqrt( ec(1)**2 + ec(2)**2 + ec(3)**2 )

      do k=1,3
         ec(k) = ec(k) / dd
      enddo

      call cart_to_latlon(1, ec, e2(1), e2(2))

 end subroutine cell_center2

!>@brief The subroutine 'cell_center3' gets the center position of a cell.
 subroutine cell_center3(p1, p2, p3, p4, ec)
         real(kind=8) , intent(IN)  :: p1(3), p2(3), p3(3), p4(3)
         real(kind=8) , intent(OUT) :: ec(3)
! Local
         real (kind=8)dd
         integer k

         do k=1,3
            ec(k) = p1(k) + p2(k) + p3(k) + p4(k)
         enddo
         dd = sqrt( ec(1)**2 + ec(2)**2 + ec(3)**2 )

         do k=1,3
            ec(k) = ec(k) / dd
         enddo

 end subroutine cell_center3



 real(kind=8) function get_area(p1, p4, p2, p3, radius)
!-----------------------------------------------
 real(kind=8), intent(in), dimension(2):: p1, p2, p3, p4
 real(kind=8), intent(in), optional:: radius
!-----------------------------------------------
 real(kind=8) e1(3), e2(3), e3(3)
 real(kind=8) ang1, ang2, ang3, ang4

! S-W: 1
       call latlon2xyz(p1, e1)   ! p1
       call latlon2xyz(p2, e2)   ! p2
       call latlon2xyz(p4, e3)   ! p4
       ang1 = spherical_angle(e1, e2, e3)
!----
! S-E: 2
!----
       call latlon2xyz(p2, e1)
       call latlon2xyz(p3, e2)
       call latlon2xyz(p1, e3)
       ang2 = spherical_angle(e1, e2, e3)
!----
! N-E: 3
!----
       call latlon2xyz(p3, e1)
       call latlon2xyz(p4, e2)
       call latlon2xyz(p2, e3)
       ang3 = spherical_angle(e1, e2, e3)
!----
! N-W: 4
!----
       call latlon2xyz(p4, e1)
       call latlon2xyz(p3, e2)
       call latlon2xyz(p1, e3)
       ang4 = spherical_angle(e1, e2, e3)

       if ( present(radius) ) then
            get_area = (ang1 + ang2 + ang3 + ang4 - 2.*pi) * radius**2
       else
            get_area = ang1 + ang2 + ang3 + ang4 - 2.*pi
       endif

 end function get_area


 real(kind=8) function spherical_angle(p1, p2, p3)
 
!           p3
!         /
!        /
!       p1 ---> angle
!         \
!          \
!           p2

 real(kind=8) p1(3), p2(3), p3(3)

 real (f_p):: e1(3), e2(3), e3(3)
 real (f_p):: px, py, pz
 real (f_p):: qx, qy, qz
 real (f_p):: angle, ddd
 integer n

  do n=1,3
     e1(n) = p1(n)
     e2(n) = p2(n)
     e3(n) = p3(n)
  enddo

!-------------------------------------------------------------------
! Page 41, Silverman's book on Vector Algebra; spherical trigonmetry
!-------------------------------------------------------------------
! Vector P:
   px = e1(2)*e2(3) - e1(3)*e2(2) 
   py = e1(3)*e2(1) - e1(1)*e2(3) 
   pz = e1(1)*e2(2) - e1(2)*e2(1) 
! Vector Q:
   qx = e1(2)*e3(3) - e1(3)*e3(2) 
   qy = e1(3)*e3(1) - e1(1)*e3(3) 
   qz = e1(1)*e3(2) - e1(2)*e3(1) 

   ddd = (px*px+py*py+pz*pz)*(qx*qx+qy*qy+qz*qz)

   if ( ddd <= 0.0d0 ) then
        angle = 0.d0
   else
        ddd = (px*qx+py*qy+pz*qz) / sqrt(ddd)
        if ( abs(ddd)>1.d0) then
             angle = 2.d0*atan(1.0)    ! 0.5*pi
           !FIX (lmh) to correctly handle co-linear points (angle near pi or 0)
           if (ddd < 0.d0) then
              angle = 4.d0*atan(1.0d0) !should be pi
           else
              angle = 0.d0 
           end if
        else
             angle = acos( ddd )
        endif
   endif

   spherical_angle = angle

 end function spherical_angle


 real(kind=8) function cos_angle(p1, p2, p3)
! As spherical_angle, but returns the cos(angle)
!       p3
!       ^  
!       |  
!       | 
!       p1 ---> p2
!
 real(kind=8), intent(in):: p1(3), p2(3), p3(3)

 real (f_p):: e1(3), e2(3), e3(3)
 real (f_p):: px, py, pz
 real (f_p):: qx, qy, qz
 real (f_p):: angle, ddd
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

 subroutine invert_matrix(n, a, x)
  integer, intent (in) :: n
  integer :: i,j,k
  real(kind=8), intent (inout), dimension (n,n):: a
  real(kind=8), intent (out), dimension (n,n):: x   !< inverted maxtrix
  real(kind=8), dimension (n,n) :: b
  integer indx(n)
 
  do i = 1, n
     do j = 1, n
        b(i,j) = 0.0
     end do
  end do

  do i = 1, n
     b(i,i) = 1.0
  end do
 
  call elgs (a,n,indx)
 
  do i = 1, n-1
     do j = i+1, n
        do k = 1, n
           b(indx(j),k) = b(indx(j),k) - a(indx(j),i)*b(indx(i),k)
        end do
     end do
  end do
 
  do i = 1, n
     x(n,i) = b(indx(n),i)/a(indx(n),n)
     do j = n-1, 1, -1
        x(j,i) = b(indx(j),i)
        do k = j+1, n
           x(j,i) = x(j,i)-a(indx(j),k)*x(k,i)
        end do
        x(j,i) =  x(j,i)/a(indx(j),j)
     end do
  end do

 end subroutine invert_matrix
 
!>@brief The subroutine 'elgs' performs the partial-pivoting gaussian elimination.
!>@details a(n,n) is the original matrix in the input and transformed matrix
!! plus the pivoting element ratios below the diagonal in the output.
 subroutine elgs (a,n,indx)
  integer, intent (in) :: n
  integer :: i,j,k,itmp
  integer, intent (out), dimension (n) :: indx
  real(kind=8), intent (inout), dimension (n,n) :: a
!
  real(kind=8) :: c1, pie, pi1, pj
  real(kind=8), dimension (n) :: c
 
  do i = 1, n
     indx(i) = i
  end do
!
! find the rescaling factors, one from each row
!
  do i = 1, n
     c1= 0.0
     do j = 1, n
        c1 = max(c1,abs(a(i,j)))
     end do
     c(i) = c1
  end do
!
! search the pivoting (largest) element from each column
!
  do j = 1, n-1
     pi1 = 0.0
     do i = j, n
        pie = abs(a(indx(i),j))/c(indx(i))
        if (pie > pi1) then
            pi1 = pie
            k   = i
        endif
     end do
!
! interchange the rows via indx(n) to record pivoting order
!
    itmp    = indx(j)
    indx(j) = indx(k)
    indx(k) = itmp
    do i = j+1, n
       pj  = a(indx(i),j)/a(indx(j),j)
!
! record pivoting ratios below the diagonal
!
       a(indx(i),j) = pj
!
! modify other elements accordingly
!
       do k = j+1, n
          a(indx(i),k) = a(indx(i),k)-pj*a(indx(j),k)
       end do
     end do
  end do
 
 end subroutine elgs

 subroutine get_latlon_vector(pp, elon, elat)
 real(kind=8), intent(IN)  :: pp(2)
 real(kind=8), intent(OUT) :: elon(3), elat(3)

         elon(1) = -SIN(pp(1))
         elon(2) =  COS(pp(1))
         elon(3) =  0.0
         elat(1) = -SIN(pp(2))*COS(pp(1))
         elat(2) = -SIN(pp(2))*SIN(pp(1))
!!! RIGHT_HAND
         elat(3) =  COS(pp(2))
! Left-hand system needed to be consistent with rest of the codes
!        elat(3) = -COS(pp(2))

 end subroutine get_latlon_vector

end module fv_grid_utils_mod
  
