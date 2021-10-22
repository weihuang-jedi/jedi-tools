module latlon_module

  use netcdf
  use tile_module

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: latlongrid
  public :: initialize_latlongrid
  public :: finalize_latlongrid
  public :: generate_weight

  !-----------------------------------------------------------------------

  type latlongrid
     integer                               :: nlon, nlat, npnt
     integer, dimension(:),    allocatable :: lon, lat, pnt
     real,    dimension(:, :), allocatable :: pos
     integer, dimension(:, :, :), allocatable :: tile
     integer, dimension(:, :, :), allocatable :: ilon, jlat
     real,    dimension(:, :, :), allocatable :: wgt
  end type latlongrid

  !-----------------------------------------------------------------------

contains

  !-----------------------------------------------------------------------

  subroutine initialize_latlongrid(nlon, nlat, npnt, latlon)

    implicit none

    integer,          intent(in)  :: nlon, nlat, npnt
    type(latlongrid), intent(out) :: latlon

    integer :: i, j, k
    real :: dlon, dlat

    dlon = 360.0/nlon
    dlat = 180.0/(nlat - 1)

    latlon%nlon = nlon
    latlon%nlat = nlat
    latlon%npnt = npnt

    allocate(latlon%pos(nlon, nlat))
    allocate(latlon%tile(nlon, nlat, npnt))
    allocate(latlon%ilon(nlon, nlat, npnt))
    allocate(latlon%jlat(nlon, nlat, npnt))
    allocate(latlon%wgt(nlon, nlat, npnt))

    allocate(latlon%lon(nlon))
    allocate(latlon%lat(nlat))
    allocate(latlon%pnt(npnt))
    
    do i = 1, nlon
      latlon%lon(i) = dlon*real(i-1)
    end do
    
    do j = 1, nlat
      latlon%lat(j) = dlat*real(j-1) - 90.0
      do i = 1, nlon
        latlon%pos(i, j) = -1.0

        do k = 1, npnt
          latlon%tile(i, j, k) = 0
          latlon%ilon(i, j, k) = 0
          latlon%jlat(i, j, k) = 0
          latlon%wgt(i, j, k) = 0.0
        end do
      end do
    end do
    
    do i = 1, npnt
      latlon%pnt(i) = real(i)
    end do

  end subroutine initialize_latlongrid

  !----------------------------------------------------------------------
  subroutine finalize_latlongrid(latlon)

    implicit none

    type(latlongrid), intent(inout) :: latlon

    deallocate(latlon%lon)
    deallocate(latlon%lat)
    deallocate(latlon%pnt)

    deallocate(latlon%pos)
    deallocate(latlon%tile)
    deallocate(latlon%ilon)
    deallocate(latlon%jlat)
    deallocate(latlon%wgt)

  end subroutine finalize_latlongrid

  !----------------------------------------------------------------------
  subroutine generate_weight(tile, latlon)

    implicit none

    type(tilegrid), dimension(6), intent(inout) :: tile
    type(latlongrid), intent(inout) :: latlon

    integer :: i, j, n, nt, k
    integer, parameter  :: np = 4
    real, dimension(np) :: x, y, dist
    integer, dimension(np) :: ix, jy, t
    real :: minlat, maxlat, minlon, maxlon
    real :: xp, yp, dlon, dlat, left, rite
    integer :: ilonbgn, ilonend, jlatbgn, jlatend
    integer :: istart, iend, jstart, jend
    integer, dimension(6) :: ordered_tile_list

    dlon = 360.0/latlon%nlon
    dlat = 180.0/(latlon%nlat - 1)

    print *, 'dlon, dlat = ', dlon, dlat

    !--Create a list that work in order.
    ordered_tile_list(1) = 1
    ordered_tile_list(2) = 2
    ordered_tile_list(3) = 4
    ordered_tile_list(4) = 5
    ordered_tile_list(5) = 3
    ordered_tile_list(6) = 6

    call corner_cases(tile, latlon)

    call edge_cases(tile, latlon)

    do nt = 1, 6
       n = ordered_tile_list(nt)

       do k = 1, np
          t(k) = n
       end do

       do j = 1, tile(n)%ny
       do i = 1, tile(n)%nx
          call fill_xy(np, x, y, ix, jy, i, j, tile(n)%lat, tile(n)%lon)

          if((n == 3) .or. (n == 6)) then
            if((i == 1) .and. (j == 1)) then
              call fill_poles(n, tile, latlon)
            end if
          end if

          call process_poly(latlon, dlat, dlon, np, np, x, y, ix, jy, t)
       end do
       end do
    end do

    !Check pos info
    do j = 1, latlon%nlat
    do i = 1, latlon%nlon
       if(latlon%pos(i,j) < 0.0) then
          print *, 'i,j,latlon%pos(i,j) = ', i,j,latlon%pos(i,j)
       end if
    end do
    end do

  end subroutine generate_weight

  !----------------------------------------------------------------------
  subroutine fill_xy(n, x, y, ix, jy, ic, jc, lat, lon)

    implicit none

    integer,               intent(in)  :: n, ic, jc
    real, dimension(n),    intent(out) :: x, y
    integer, dimension(n), intent(out) :: ix, jy
    real, dimension(:, :), intent(in)  :: lat, lon

    x(1) = lon(ic, jc)
    y(1) = lat(ic, jc)

    x(2) = lon(ic+1, jc)
    y(2) = lat(ic+1, jc)

    x(3) = lon(ic+1, jc+1)
    y(3) = lat(ic+1, jc+1)

    x(4) = lon(ic, jc+1)
    y(4) = lat(ic, jc+1)

    ix(1) = ic
    jy(1) = jc

    ix(2) = ic+1
    jy(2) = jc

    ix(3) = ic+1
    jy(3) = jc+1

    ix(4) = ic
    jy(4) = jc+1

  end subroutine fill_xy

  !----------------------------------------------------------------------
  subroutine fill_poles(n, tile, latlon)

    implicit none

    integer,                      intent(in)    :: n
    type(tilegrid), dimension(6), intent(in)    :: tile
    type(latlongrid),             intent(inout) :: latlon

    integer, parameter  :: np = 4
    real, dimension(np) :: x, y, dist
    integer, dimension(np) :: ix, jy
    integer :: i, j, ic, jc, k
    real :: xp, yp

    if((n == 3) .or. (n ==6)) then
      ic = tile(n)%nx/2
      jc = tile(n)%ny/2

      call fill_xy(np, x, y, ix, jy, ic, jc, tile(n)%lat, tile(n)%lon)

     !print *, 'Tile ', n, ', lon = ', x
     !print *, 'Tile ', n, ', lat = ', y

      if(n == 3) then
        j = latlon%nlat
        do i = 1, latlon%nlon
           latlon%pos(i,j) = real(n)
        end do
      else
        j = 1
        do i = 1, latlon%nlon
           latlon%pos(i,j) = real(n)
        end do
      end if

      yp = latlon%lat(j)
      do i = 1, latlon%nlon
         xp = latlon%lon(i)
         do k = 1, np
            latlon%tile(i,j,k) = n
            latlon%ilon(i,j,k) = ix(k)
            latlon%jlat(i,j,k) = jy(k)
            call distance(yp, xp, y(k), x(k), latlon%wgt(i,j,k))
         end do
         call weighting(np, np, latlon%wgt(i,j,:))
      end do
    end if

  end subroutine fill_poles

  !----------------------------------------------------------------------
  subroutine corner_cases(tile, latlon)

    implicit none

    type(tilegrid), dimension(6), intent(inout) :: tile
    type(latlongrid), intent(inout) :: latlon

    integer :: n, k, ik, jk
    integer, parameter  :: np = 4
    real, dimension(np) :: x, y, dist
    integer, dimension(np) :: ix, jy, t
    real :: minlat, maxlat, minlon, maxlon
    real :: xp, yp, dlon, dlat, left, rite
    integer :: ilonbgn, ilonend, jlatbgn, jlatend
    integer :: istart, iend, jstart, jend
    integer, dimension(6) :: ordered_tile_list
    integer :: mp

    dlon = 360.0/latlon%nlon
    dlat = 180.0/(latlon%nlat - 1)

    mp = 3

    do n = 1, 8
      select case (n)
        case (1)
          !--1, 5, 6 corner 1
          t(1) = 1
          x(1) = tile(1)%lon(1, 1)
          y(1) = tile(1)%lat(1, 1)
          ix(1) = 1
          jy(1) = 1

          t(2) = 5
          x(2) = tile(5)%lon(tile(5)%nx, tile(5)%ny)
          y(2) = tile(5)%lat(tile(5)%nx, tile(5)%ny)
          ix(2) = tile(5)%nx
          jy(2) = tile(5)%ny

          t(3) = 6
          x(3) = tile(6)%lon(1, tile(6)%ny)
          y(3) = tile(6)%lat(1, tile(6)%ny)
          ix(3) = 1
          jy(3) = tile(6)%ny
        case (2)
          !--1, 5, 3 corner 2
          t(1) = 1
          x(1) = tile(1)%lon(1, tile(1)%ny)
          y(1) = tile(1)%lat(1, tile(1)%ny)
          ix(1) = 1
          jy(1) = tile(1)%ny

          t(2) = 5
          x(2) = tile(5)%lon(1, tile(5)%ny)
          y(2) = tile(5)%lat(1, tile(5)%ny)
          ix(2) = 1
          jy(2) = tile(5)%ny

          t(3) = 3
          x(3) = tile(3)%lon(1, tile(3)%ny)
          y(3) = tile(3)%lat(1, tile(3)%ny)
          ix(3) = 1
          jy(3) = tile(3)%ny
        case (3)
          !--2, 1, 6 corner 3
          t(1) = 2
          x(1) = tile(2)%lon(1, 1)
          y(1) = tile(2)%lat(1, 1)
          ix(1) = 1
          jy(1) = 1

          t(2) = 1
          x(2) = tile(1)%lon(tile(1)%nx, 1)
          y(2) = tile(1)%lat(tile(1)%nx, 1)
          ix(2) = tile(1)%nx
          jy(2) = 1

          t(3) = 6
          x(3) = tile(6)%lon(tile(6)%nx, tile(6)%ny)
          y(3) = tile(6)%lat(tile(6)%nx, tile(6)%ny)
          ix(3) = tile(6)%nx
          jy(3) = tile(6)%ny
        case (4)
          !--2, 1, 3 corner 4
          t(1) = 2
          x(1) = tile(2)%lon(1, tile(1)%ny)
          y(1) = tile(2)%lat(1, tile(1)%ny)
          ix(1) = 1
          jy(1) = tile(1)%ny
      
          t(2) = 1
          x(2) = tile(1)%lon(tile(1)%nx, tile(1)%ny)
          y(2) = tile(1)%lat(tile(1)%nx, tile(1)%ny)
          ix(2) = tile(1)%nx
          jy(2) = tile(1)%ny

          t(3) = 3
          x(3) = tile(3)%lon(1, 1)
          y(3) = tile(3)%lat(1, 1)
          ix(3) = 1
          jy(3) = 1
        case (5)
          !--4, 2, 6 corner 5
          t(1) = 4
          x(1) = tile(4)%lon(tile(4)%nx, 1)
          y(1) = tile(4)%lat(tile(4)%nx, 1)
          ix(1) = tile(4)%nx
          jy(1) = 1

          t(2) = 2
          x(2) = tile(2)%lon(tile(2)%nx, 1)
          y(2) = tile(2)%lat(tile(2)%nx, 1)
          ix(2) = tile(1)%nx 
          jy(2) = 1

          t(3) = 6
          x(3) = tile(6)%lon(tile(6)%nx, 1)
          y(3) = tile(6)%lat(tile(6)%nx, 1)
          ix(3) = tile(6)%nx
          jy(3) = 1
        case (6)
          !--4, 2, 3 corner 6
          t(1) = 4
          x(1) = tile(4)%lon(1, 1)
          y(1) = tile(4)%lat(1, 1)
          ix(1) = 1
          jy(1) = 1

          t(2) = 2
          x(2) = tile(2)%lon(tile(2)%nx, tile(2)%ny)
          y(2) = tile(2)%lat(tile(2)%nx, tile(2)%ny)
          ix(2) = tile(2)%nx
          jy(2) = tile(2)%ny

          t(3) = 3
          x(3) = tile(3)%lon(tile(3)%nx, 1)
          y(3) = tile(3)%lat(tile(3)%nx, 1)
          ix(3) = tile(3)%nx
          jy(3) = 1
        case (7)
          !--5, 4, 6 corner 7
          t(1) = 5
          x(1) = tile(5)%lon(tile(5)%nx, 1)
          y(1) = tile(5)%lat(tile(5)%nx, 1)
          ix(1) = tile(5)%nx
          jy(1) = 1

          t(2) = 4
          x(2) = tile(4)%lon(tile(4)%nx, tile(4)%ny)
          y(2) = tile(4)%lat(tile(4)%nx, tile(4)%ny)
          ix(2) = tile(4)%nx
          jy(2) = tile(4)%ny

          t(3) = 6
          x(3) = tile(6)%lon(1, 1)
          y(3) = tile(6)%lat(1, 1)
          ix(3) = 1
          jy(3) = 1
        case (8)
          !--5, 4, 3 corner 8
          t(1) = 5
          x(1) = tile(5)%lon(1, 1)
          y(1) = tile(5)%lat(1, 1)
          ix(1) = 1
          jy(1) = 1

          t(2) = 4
          x(2) = tile(4)%lon(1, tile(4)%ny)
          y(2) = tile(4)%lat(1, tile(4)%ny)
          ix(2) = 1
          jy(2) = tile(4)%ny

          t(3) = 3
          x(3) = tile(3)%lon(tile(3)%nx, tile(3)%ny)
          y(3) = tile(3)%lat(tile(3)%nx, tile(3)%ny)
          ix(3) = tile(3)%nx
          jy(3) = tile(3)%ny
      end select

      t(4) = t(1)
      x(4) = x(1)
      y(4) = y(1)
      ix(4) = ix(1)
      jy(4) = jy(1)

     !print *, 'corner ', n, ', t = ', t(1:3)
     !print *, 'corner ', n, ', x = ', x(1:3)
     !print *, 'corner ', n, ', y = ', y(1:3)
     !print *, 'corner ', n, ', ix = ', ix(1:3)
     !print *, 'corner ', n, ', jy = ', jy(1:3)

      call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
    end do

  end subroutine corner_cases

  !----------------------------------------------------------------------
  subroutine edge_cases(tile, latlon)

    implicit none

    type(tilegrid), dimension(6), intent(inout) :: tile
    type(latlongrid), intent(inout) :: latlon

    integer :: i, j, n, k, ik, jk
    integer, parameter  :: np = 4
    real, dimension(np) :: x, y, dist
    integer, dimension(np) :: ix, jy, t
    real :: minlat, maxlat, minlon, maxlon
    real :: xp, yp, dlon, dlat, left, rite
    integer :: ilonbgn, ilonend, jlatbgn, jlatend
    integer :: mp

    dlon = 360.0/latlon%nlon
    dlat = 180.0/(latlon%nlat - 1)

    mp = np

    do n = 1, 12
      select case (n)
        case (1)
          !--1, 2 edge 1
          do j = 1, tile(1)%ny-1
            jk = j
            do ik = 1, 2
              t(ik) = 1
              x(ik) = tile(1)%lon(tile(1)%nx, jk)
              y(ik) = tile(1)%lat(tile(1)%nx, jk)
              ix(ik) = tile(1)%nx
              jy(ik) = jk+ik
              jk = jk + 1
            end do

            jk = j
            do ik = 3, 4
              t(ik) = 2
              x(ik) = tile(2)%lon(1, jk)
              y(ik) = tile(2)%lat(1, jk)
              ix(ik) = 1
              jy(ik) = jk+ik
              jk = jk + 1
            end do

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (2)
          !--2, 4 edge 2
          do j = 1, tile(2)%ny-1
            jk = j
            do ik = 1, 2
              t(ik) = 2
              x(ik) = tile(2)%lon(tile(2)%nx, jk)
              y(ik) = tile(2)%lat(tile(2)%nx, jk)
              ix(ik) = tile(1)%nx
              jy(ik) = jk+ik
              jk = jk + 1
            end do

            jk = tile(4)%ny+1-j
            do ik = 3, 4
              t(ik) = 4
              x(ik) = tile(4)%lon(jk, 1)
              y(ik) = tile(4)%lat(jk, 1)
              ix(ik) = jk+ik
              jy(ik) = 1
              jk = jk - 1
            end do

           !print *, 'n = ', n, ', j = ', j
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (3)
          !--4, 5 edge 3
          do j = 1, tile(1)%ny-1
            jk = tile(4)%ny+1-j
            do ik = 1, 2
              t(ik) = 4
              x(ik) = tile(4)%lon(jk, tile(4)%nx)
              y(ik) = tile(4)%lat(jk, tile(4)%nx)
              ix(ik) = tile(4)%nx
              jy(ik) = jk
              jk = jk - 1
            end do

            jk = tile(5)%ny+1-j
            do ik = 3, 4
              t(ik) = 5
              x(ik) = tile(5)%lon(jk, 1)
              y(ik) = tile(5)%lat(jk, 1)
              ix(ik) = jk
              jy(ik) = 1
              jk = jk - 1
            end do

           !print *, 'n = ', n, ', j = ', j
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (4)
          !--5, 1 edge 4
          do j = 1, tile(1)%ny-1
            jk = tile(5)%ny+1-j
            do ik = 1, 2
              t(ik) = 5
              x(ik) = tile(5)%lon(jk, tile(5)%nx)
              y(ik) = tile(5)%lat(jk, tile(5)%nx)
              ix(ik) = jk
              jy(ik) = tile(5)%nx
              jk = jk - 1
            end do

            jk = j
            do ik = 3, 4
              t(ik) = 1
              x(ik) = tile(1)%lon(1, jk)
              y(ik) = tile(1)%lat(1, jk)
              ix(ik) = 1
              jy(ik) = jk
              jk = jk + 1
            end do

           !print *, 'n = ', n, ', j = ', j
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (5)
          !--6, 1 edge 5
          do i = 1, tile(6)%nx-1
            ik = i
            do jk = 1, 2
              t(jk) = 6
              x(jk) = tile(6)%lon(ik, tile(6)%ny)
              y(jk) = tile(6)%lat(ik, tile(6)%ny)
              ix(jk) = ik
              jy(jk) = tile(6)%ny
              ik = ik + 1
            end do

            ik = i
            do jk = 3, 4
              t(jk) = 1
              x(jk) = tile(1)%lon(ik, 1)
              y(jk) = tile(1)%lat(ik, 1)
              ix(jk) = ik
              jy(jk) = 1
              ik = ik + 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (6)
          !--6, 2 edge 6
          do i = 1, tile(6)%nx-1
            ik = tile(6)%ny+1-i
            do jk = 1, 2
              t(jk) = 6
              x(jk) = tile(6)%lon(tile(6)%nx, ik)
              y(jk) = tile(6)%lat(tile(6)%nx, ik)
              ix(jk) = tile(6)%nx
              jy(jk) = ik
              ik = ik - 1
            end do

            ik = i
            do jk = 3, 4
              t(jk) = 2
              x(jk) = tile(2)%lon(ik, 1)
              y(jk) = tile(2)%lat(ik, 1)
              ix(jk) = ik
              jy(jk) = 1
              ik = ik + 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (7)
          !--6, 4 edge 7
          do i = 1, tile(6)%nx-1
            ik = i
            do jk = 1, 2
              t(jk) = 6
              x(jk) = tile(6)%lon(ik, 1)
              y(jk) = tile(6)%lat(ik, 1)
              ix(jk) = ik
              jy(jk) = 1
              ik = ik + 1
            end do

            ik = tile(4)%ny + 1 - i
            do jk = 3, 4
              t(jk) = 4
              x(jk) = tile(4)%lon(tile(4)%nx, ik)
              y(jk) = tile(4)%lat(tile(4)%nx, ik)
              ix(jk) = tile(4)%nx
              jy(jk) = ik
              ik = ik - 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (8)
          !--6, 5 edge 8
          do i = 1, tile(6)%nx-1
            ik = i
            do jk = 1, 2
              t(jk) = 6
              x(jk) = tile(6)%lon(1, ik)
              y(jk) = tile(6)%lat(1, ik)
              ix(jk) = 1
              jy(jk) = ik
              ik = ik + 1
            end do

            ik = i
            do jk = 3, 4
              t(jk) = 5
              x(jk) = tile(5)%lon(tile(5)%nx, ik)
              y(jk) = tile(5)%lat(tile(5)%nx, ik)
              ix(jk) = tile(5)%nx
              jy(jk) = ik
              ik = ik + 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (9)
          !--3, 1 edge 9
          do i = 1, tile(3)%nx-1
            ik = i
            do jk = 1, 2
              t(jk) = 3
              x(jk) = tile(3)%lon(ik, tile(3)%ny)
              y(jk) = tile(3)%lat(ik, tile(3)%ny)
              ix(jk) = ik
              jy(jk) = tile(3)%ny
              ik = ik + 1
            end do

            ik = i
            do jk = 3, 4
              t(jk) = 1
              x(jk) = tile(1)%lon(ik, tile(1)%ny)
              y(jk) = tile(1)%lat(ik, tile(1)%ny)
              ix(jk) = ik
              jy(jk) = tile(1)%ny
              ik = ik + 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (10)
          !--3, 2 edge 10
          do i = 1, tile(6)%nx-1
            ik = tile(3)%ny+1-i
            do jk = 1, 2
              t(jk) = 3
              x(jk) = tile(3)%lon(tile(3)%nx, ik)
              y(jk) = tile(3)%lat(tile(3)%nx, ik)
              ix(jk) = tile(3)%nx
              jy(jk) = ik
              ik = ik - 1
            end do

            ik = i
            do jk = 3, 4
              t(jk) = 2
              x(jk) = tile(2)%lon(ik, tile(2)%ny)
              y(jk) = tile(2)%lat(ik, tile(2)%ny)
              ix(jk) = ik
              jy(jk) = tile(2)%ny
              ik = ik + 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (11)
          !--3, 4 edge 11
          do i = 1, tile(3)%nx-1
            ik = i
            do jk = 1, 2
              t(jk) = 3
              x(jk) = tile(3)%lon(ik, 1)
              y(jk) = tile(3)%lat(ik, 1)
              ix(jk) = ik
              jy(jk) = 1
              ik = ik + 1
            end do

            ik = tile(4)%ny + 1 - i
            do jk = 3, 4
              t(jk) = 4
              x(jk) = tile(4)%lon(1, ik)
              y(jk) = tile(4)%lat(1, ik)
              ix(jk) = 1
              jy(jk) = ik
              ik = ik - 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case (12)
          !--3, 5 edge 8
          do i = 1, tile(3)%nx-1
            ik = i
            do jk = 1, 2
              t(jk) = 3
              x(jk) = tile(3)%lon(1, ik)
              y(jk) = tile(3)%lat(1, ik)
              ix(jk) = 1
              jy(jk) = ik
              ik = ik + 1
            end do

            ik = i
            do jk = 3, 4
              t(jk) = 5
              x(jk) = tile(5)%lon(1, ik)
              y(jk) = tile(5)%lat(1, ik)
              ix(jk) = 1
              jy(jk) = ik
              ik = ik + 1
            end do

           !print *, 'n = ', n, ', i = ', i
           !print *, '  t = ', t
           !print *, '  ix = ', ix
           !print *, '  jy = ', jy
           !print *, '  x = ', x
           !print *, '  y = ', y

            call process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)
          end do
        case default
          print *, 'File: ', __FILE__, ', line: ', __LINE__
          print *, 'Edge n = ', n, ' not processed'
      end select
    end do

  end subroutine edge_cases

  !----------------------------------------------------------------------
  subroutine process_poly(latlon, dlat, dlon, np, mp, x, y, ix, jy, t)

    implicit none

    type(latlongrid), intent(inout) :: latlon
    real, intent(in) :: dlon, dlat
    integer, intent(in)  :: np, mp
    real, dimension(np), intent(in) :: x, y
    integer, dimension(np), intent(in) :: ix, jy, t

    real, dimension(np) :: dist
    real :: minlat, maxlat, minlon, maxlon
    real :: xp, yp, left, rite
    integer :: ik, jk, k
    integer :: ilonbgn, ilonend, jlatbgn, jlatend

    call get_index(dlat, dlon, np, mp, x, y, &
                   ilonbgn, ilonend, jlatbgn, jlatend, &
                   minlat, maxlat, minlon, maxlon)

    do jk = jlatbgn, jlatend
       yp = latlon%lat(jk)
       if((yp < minlat) .or. (yp > maxlat)) then
         continue
       end if

       if((ilonbgn < 120) .and. (ilonend > 240)) then
          do ik = 1, ilonbgn+1
             xp = latlon%lon(ik)
             left = maxlon - 360.0
             rite = minlon

             if((xp > left) .and. (xp <= rite)) then
                if(latlon%pos(ik,jk) < 0.0) then
                   latlon%pos(ik,jk) = real(t(1))
                   do k = 1, latlon%npnt
                      latlon%tile(ik,jk,k) = t(k)
                      latlon%ilon(ik,jk,k) = ix(k)
                      latlon%jlat(ik,jk,k) = jy(k)
                      call distance(yp, xp, y(k), x(k), latlon%wgt(ik,jk,k))
                   end do
                   do k = mp+1, latlon%npnt
                      latlon%wgt(ik,jk,k) = 0.0
                   end do
                   call weighting(latlon%npnt, mp, latlon%wgt(ik,jk,:))
               !else
               !   print *, 'xp, yp = ', xp, yp
               !   print *, 'Multiple in grid: ik,jk = ', ik,jk
               !   print *, 'x = ', x 
               !   print *, 'y = ', y
               !   print *, 'minlat, maxlat, minlon, maxlon = ', minlat, maxlat, minlon, maxlon
               !   print *, 'ilonbgn, ilonend, jlatbgn, jlatend = ', ilonbgn, ilonend, jlatbgn, jlatend
                end if
             end if
          end do

          do ik = ilonend-1, latlon%nlon
             xp = latlon%lon(ik)
             left = maxlon
             rite = minlon + 360.0

             if((xp >= left) .and. (xp < rite)) then
                if(latlon%pos(ik,jk) < 0.0) then
                   latlon%pos(ik,jk) = real(t(1))
                   do k = 1, latlon%npnt
                      latlon%tile(ik,jk,k) = t(k)
                      latlon%ilon(ik,jk,k) = ix(k)
                      latlon%jlat(ik,jk,k) = jy(k)
                      call distance(yp, xp, y(k), x(k), latlon%wgt(ik,jk,k))
                   end do
                   do k = mp+1, latlon%npnt
                      latlon%wgt(ik,jk,k) = 0.0
                   end do
                   call weighting(latlon%npnt, mp, latlon%wgt(ik,jk,:))
               !else
               !   print *, 'xp, yp = ', xp, yp
               !   print *, 'Multiple in grid: ik,jk = ', ik,jk
               !   print *, 'x = ', x
               !   print *, 'y = ', y
               !   print *, 'minlat, maxlat, minlon, maxlon = ', minlat, maxlat, minlon, maxlon
               !   print *, 'ilonbgn, ilonend, jlatbgn, jlatend = ', ilonbgn, ilonend, jlatbgn, jlatend
                end if
             end if
          end do
       else
          do ik = ilonbgn, ilonend
             xp = latlon%lon(ik)

             if((xp >= minlon) .and. (xp < maxlon)) then
                if(latlon%pos(ik,jk) < 0.0) then
                   latlon%pos(ik,jk) = real(t(1))
                   do k = 1, latlon%npnt
                      latlon%tile(ik,jk,k) = t(k)
                      latlon%ilon(ik,jk,k) = ix(k)
                      latlon%jlat(ik,jk,k) = jy(k)
                      call distance(yp, xp, y(k), x(k), latlon%wgt(ik,jk,k))
                   end do
                   do k = mp+1, latlon%npnt
                      latlon%wgt(ik,jk,k) = 0.0
                   end do
                   call weighting(latlon%npnt, mp, latlon%wgt(ik,jk,:))
               !else
               !   print *, 'xp, yp = ', xp, yp
               !   print *, 'Multiple in grid: ik,jk = ', ik,jk
               !   print *, 'x = ', x
               !   print *, 'y = ', y
               !   print *, 'minlat, maxlat, minlon, maxlon = ', minlat, maxlat, minlon, maxlon
               !   print *, 'ilonbgn, ilonend, jlatbgn, jlatend = ', ilonbgn, ilonend, jlatbgn, jlatend
                end if
             end if
          end do
       end if
    end do

  end subroutine process_poly

  !----------------------------------------------------------------------
  subroutine distance(xlat1, xlon1, xlat2, xlon2, dist)

    implicit none

    real, intent(in)  :: xlat1, xlon1, xlat2, xlon2
    real, intent(out) :: dist

    real :: lat1, lon1, lat2, lon2, dlon, dlat

    real :: deg2arc, ang, sindlat, sindlon
    deg2arc = 3.1415926536/180.0

    lat1 = xlat1 * deg2arc
    lat2 = xlat2 * deg2arc
    lon1 = xlon1 * deg2arc
    lon2 = xlon2 * deg2arc

    dlon = lon2 - lon1
    dlat = lat2 - lat1
    sindlat = sin(0.5*dlat)
    sindlon = sin(0.5*dlon)
    ang = sindlat * sindlat + cos(lat1) * cos(lat2) * sindlon * sindlon
   !dist = 2.0 * atan2(sqrt(ang), sqrt(1.0-ang))
    dist = 2.0 * asin(min(1.0,sqrt(ang)))

  end subroutine distance

  !----------------------------------------------------------------------
  subroutine weighting(n, m, dist)

    implicit none

    integer, intent(in)  :: n, m
    real, dimension(n), intent(inout) :: dist

    real, dimension(n) :: wgt

    real :: total, factor
    integer :: k

    total = 0.0
    if(m > 1) then
      factor = float(m - 1)
    else
      factor = 1.0
    end if
    
    do k = 1, m
       total = total + dist(k)
    end do

    do k = 1, m
       dist(k) = (total - dist(k)) / (factor * total)
    end do

  end subroutine weighting

  !----------------------------------------------------------------------
  subroutine get_minmax(minlat, maxlat, minlon, maxlon, x, y, np, m)

    implicit none

    real, intent(out) :: minlat, maxlat, minlon, maxlon
    integer, intent(in) :: np, m
    real, dimension(np)  :: x, y

    integer :: n

    minlon = x(1)
    maxlon = x(1)
    minlat = y(1)
    maxlat = y(1)

    do n = 2, m
       if(minlon > x(n)) minlon = x(n)
       if(maxlon < x(n)) maxlon = x(n)
       if(minlat > y(n)) minlat = y(n)
       if(maxlat < y(n)) maxlat = y(n)
    end do

  end subroutine get_minmax
        
  !----------------------------------------------------------------------
  subroutine get_index(dlat, dlon, np, m, x, y, &
                       ilonbgn, ilonend, jlatbgn, jlatend, &
                       minlat, maxlat, minlon, maxlon)

    implicit none

    real, intent(in) :: dlat, dlon
    integer, intent(in) :: np, m
    real, dimension(np)  :: x, y
    integer, intent(out) :: ilonbgn, ilonend, jlatbgn, jlatend
    real, intent(out) :: minlat, maxlat, minlon, maxlon

    call get_minmax(minlat, maxlat, minlon, maxlon, x, y, np, m)

    ilonbgn = int(minlon/dlon) + 1
    ilonend = int(maxlon/dlon + 0.001) + 1

    jlatbgn = int((minlat+90.0)/dlat) + 1
    jlatend = int((maxlat+90.0)/dlat + 0.001) + 1

  end subroutine get_index

end module latlon_module

