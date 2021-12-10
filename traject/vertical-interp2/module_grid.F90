!-----------------------------------------------------------------------
!  The module grid read both specification, and data.
!-----------------------------------------------------------------------
module module_grid

  use netcdf

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: vartype
  public :: gfsgrid
  public :: initialize_grid
  public :: finalize_grid
  public :: check_status

  !-----------------------------------------------------------------------

  ! Define tile structure.

  type vartype
     integer             :: varid
     character(len=1024) :: varname
     integer             :: xtype, ndims, nAtts, deflate_level, endianness
     logical             :: contiguous, shuffle, fletcher32
     integer, dimension(:), allocatable :: dimids
     integer, dimension(:), allocatable :: dimlen
     character(len=128), dimension(:), allocatable :: dimnames
    !integer, dimension(:), allocatable :: chunksizes
  end type vartype

  type gfsgrid
     character(len=1024)                   :: input_flnm, output_flnm
     integer                               :: fileid, ncid, nDims, nVars
     integer                               :: nGlobalAtts, unlimdimid
     integer, dimension(:),    allocatable :: varids, dimids, dimlen
     character(len=128), dimension(:), allocatable :: dimnames

     integer                               :: dimidlon, dimidlat, dimidalt
     integer                               :: nlon, nlat, nalt, npre
     real, dimension(:),       allocatable :: lon, lat, alt, pre

     real, dimension(:, :, :), allocatable :: var3d, hgt, temp

     type(vartype), dimension(:), allocatable :: vars
  end type gfsgrid

contains

 !-----------------------------------------------------------------------
  subroutine initialize_grid(grid, flnm)

    implicit none

    type(gfsgrid),    intent(out) :: grid
    character(len=*), intent(in)  :: flnm

    integer :: i, k, rc
    integer :: ik, dimlen, include_parents

    character(len=1024) :: dimname, varname

   !print *, 'Enter initialize_grid'
   !print *, 'flnm: <', trim(flnm), '>'

    include_parents = 0

    grid%input_flnm = trim(flnm)
    rc = nf90_open(trim(grid%input_flnm), nf90_nowrite, grid%fileid)
    call check_status(rc)
   !print *, 'fileid: ', grid%fileid

    rc = nf90_inquire(grid%fileid, grid%nDims, grid%nVars, &
                      grid%nGlobalAtts, grid%unlimdimid)
    call check_status(rc)
   !print *, 'nVars: ', grid%nVars
   !print *, 'nDims: ', grid%nDims

    ! Allocate memory.
    allocate(grid%dimids(grid%nDims))
    allocate(grid%dimlen(grid%nDims))
    allocate(grid%dimnames(grid%nDims))

    rc = nf90_inq_dimids(grid%fileid, grid%nDims, grid%dimids, include_parents)
    call check_status(rc)

   !print *, 'dimids: ', grid%dimids
    grid%npre = 1

    do i = 1, grid%nDims
       rc = nf90_inquire_dimension(grid%fileid, grid%dimids(i), dimname, dimlen)
       call check_status(rc)
      !print *, 'Dim No. ', i, ': ', trim(dimname), ', dimlen=', dimlen

       if(trim(dimname) == 'lon_0') then
          grid%nlon = dimlen
       else if(trim(dimname) == 'lat_0') then
          grid%nlat = dimlen
       else if(trim(dimname) == 'lv_ISBL0') then
          grid%npre = dimlen
       end if

       grid%dimlen(i) = dimlen
       grid%dimnames(i) = trim(dimname)
    end do

    print *, 'grid%nlon = ', grid%nlon, ', grid%nlat = ', grid%nlat, &
           ', grid%npre = ', grid%npre

   !Allocate memory.
    allocate(grid%varids(grid%nVars))
    allocate(grid%vars(grid%nVars))

    allocate(grid%var3d(grid%nlon, grid%nlat, grid%npre))
    allocate(grid%hgt(grid%nlon, grid%nlat, grid%npre))
    allocate(grid%temp(grid%nlon, grid%nlat, grid%npre))

    rc = nf90_inq_varids(grid%fileid, grid%nVars, grid%varids)
    call check_status(rc)

   !print *, 'varids: ', grid%varids

    do i = 1, grid%nVars
       rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
                                  ndims=grid%vars(i)%nDims, natts=grid%vars(i)%nAtts)
       call check_status(rc)
      !print *, 'Var No. ', i, ': ndims = ', grid%vars(i)%nDims

       allocate(grid%vars(i)%dimids(grid%vars(i)%nDims))
       allocate(grid%vars(i)%dimlen(grid%vars(i)%nDims))
       allocate(grid%vars(i)%dimnames(grid%vars(i)%nDims))

       rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
                                  dimids=grid%vars(i)%dimids)
       call check_status(rc)
      !print *, 'Var No. ', i, ': grid%vars(i)%dimids = ', grid%vars(i)%dimids

       rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
                name=grid%vars(i)%varname)
       call check_status(rc)
      !print *, 'Var No. ', i, ': ', trim(grid%vars(i)%varname)

       if(trim(grid%vars(i)%varname) == 'lon_0') then
          allocate(grid%lon(grid%nlon))
          rc = nf90_get_var(grid%fileid, grid%varids(i), grid%lon)
          call check_status(rc)
       else if(trim(grid%vars(i)%varname) == 'lat_0') then
          allocate(grid%lat(grid%nlat))
          rc = nf90_get_var(grid%fileid, grid%varids(i), grid%lat)
          call check_status(rc)
       else if(trim(grid%vars(i)%varname) == 'lv_ISBL0') then
          allocate(grid%pre(grid%npre))
          rc = nf90_get_var(grid%fileid, grid%varids(i), grid%pre)
          call check_status(rc)
       end if

       do k = 1, grid%vars(i)%ndims
          ik = grid%vars(i)%dimids(k)
          grid%vars(i)%dimnames(k) = trim(grid%dimnames(ik))
          grid%vars(i)%dimlen(k) = grid%dimlen(ik)
       end do
    end do

    do i = 1, grid%nlat
       grid%lat(i) = -grid%lat(i)
    end do

   !print *, 'Leave initialize_grid'

  end subroutine initialize_grid

  !----------------------------------------------------------------------
  subroutine finalize_grid(grid)

    implicit none

    type(gfsgrid), intent(inout) :: grid

    integer :: i, rc

    if(allocated(grid%varids)) deallocate(grid%varids)
    if(allocated(grid%dimids)) deallocate(grid%dimids)
    if(allocated(grid%dimlen)) deallocate(grid%dimlen)
    if(allocated(grid%dimnames)) deallocate(grid%dimnames)
    if(allocated(grid%lon)) deallocate(grid%lon)
    if(allocated(grid%lat)) deallocate(grid%lat)
    if(allocated(grid%pre)) deallocate(grid%pre)

    do i = 1, grid%nVars
       if(allocated(grid%vars(i)%dimids)) &
          deallocate(grid%vars(i)%dimids)
       if(allocated(grid%vars(i)%dimlen)) &
          deallocate(grid%vars(i)%dimlen)
       if(allocated(grid%vars(i)%dimnames)) &
          deallocate(grid%vars(i)%dimnames)
    end do

    if(allocated(grid%vars)) deallocate(grid%vars)
    if(allocated(grid%hgt)) deallocate(grid%hgt)
    if(allocated(grid%temp)) deallocate(grid%temp)
    if(allocated(grid%var3d)) deallocate(grid%var3d)

    print *, 'close output_flnm: ', trim(grid%output_flnm)
    rc = nf90_close(grid%ncid)
    call check_status(rc)

    print *, 'close input_flnm: ', trim(grid%input_flnm)
    rc = nf90_close(grid%fileid)
    call check_status(rc)

  end subroutine finalize_grid

  !----------------------------------------------------------------------
  subroutine check_status(rc)
    integer, intent(in) :: rc
    
    if(rc /= nf90_noerr) then 
      print *, trim(nf90_strerror(rc))
      print *, 'rc = ', rc, ', nf90_noerr = ', nf90_noerr
      stop 'in check_status'
    end if
  end subroutine check_status  

end module module_grid

