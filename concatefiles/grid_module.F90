!-----------------------------------------------------------------------
!  The grid module read both grid specification, and grid data.
!-----------------------------------------------------------------------

module grid_module

  use namelist_module
  use netcdf

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: vartype
  public :: gridtype
  public :: initialize_grid
  public :: finalize_grid
  public :: check_status

  !-----------------------------------------------------------------------

  ! Define grid structure.

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

  type gridtype
     character(len=1024)                   :: filename, gridname
     integer                               :: fileid
     integer                               :: nDims, nVars, nGlobalAtts, unlimDimID
     integer                               :: nlat, nlon
     integer                               :: atm_nalt, atm_nlay, atm_nhor
     integer                               :: ocn_nlay
     integer                               :: ice_ncat
     integer, dimension(:),    allocatable :: varids
     integer, dimension(:),    allocatable :: dimids
     integer, dimension(:),    allocatable :: dimlen
     character(len=128), dimension(:),    allocatable :: dimnames

     real,    dimension(:),    allocatable :: lon, lat
     real,    dimension(:),    allocatable :: atm_lev, atm_lay, atm_hor
     real,    dimension(:),    allocatable :: ocn_lay
     real,    dimension(:),    allocatable :: ice_lay

     real, dimension(:),       allocatable :: var1d
     real, dimension(:, :),    allocatable :: var2d
     real, dimension(:, :, :), allocatable :: var3d

     type(vartype), dimension(:), allocatable :: vars
  end type gridtype


contains

 !-----------------------------------------------------------------------
  subroutine initialize_grid(grid, filename, gridname)

    implicit none

    type(gridtype),   intent(out) :: grid
    character(len=*), intent(in)  :: filename, gridname

    integer :: i, k, n, rc
    integer :: ik
    integer :: include_parents, dimlen

    character(len=1024) :: dimname, varname

    print *, 'Enter initialize_grid'
    print *, 'filename: <', trim(filename), '>'
    print *, 'gridname: <', trim(gridname), '>'

    include_parents = 0

    grid%filename = trim(filename)
    grid%gridname = trim(gridname)

    print *, 'open filename: ', trim(grid%filename)
    rc = nf90_open(trim(grid%filename), nf90_nowrite, grid%fileid)
    call check_status(rc)
    print *, 'fileid: ', grid%fileid

    rc = nf90_inquire(grid%fileid, grid%nDims, grid%nVars, &
                      grid%nGlobalAtts, grid%unlimdimid)
    call check_status(rc)
    print *, 'nVars: ', grid%nVars
    print *, 'nDims: ', grid%nDims

   !Allocate memory.
    allocate(grid%dimids(grid%nDims))
    allocate(grid%dimlen(grid%nDims))
    allocate(grid%dimnames(grid%nDims))

    rc = nf90_inq_dimids(grid%fileid, grid%nDims, grid%dimids, include_parents)
    call check_status(rc)

    print *, 'dimids: ', grid%dimids

    do i = 1, grid%nDims
       rc = nf90_inquire_dimension(grid%fileid, grid%dimids(i), dimname, dimlen)
       call check_status(rc)
       print *, 'Dim No. ', i, ': ', trim(dimname), ', dimlen=', dimlen

       if(trim(dimname) == 'lat') then
          grid%nlat = dimlen
       else if(trim(dimname) == 'lon') then
          grid%nlon = dimlen
       else
          if('atm' == trim(gridname)) then
             if(trim(dimname) == 'lev') then
                grid%atm_nlev = dimlen
             else if(trim(dimname) == 'layer') then
                grid%atm_nlay = dimlen
             else if(trim(dimname) == 'hor') then
                grid%atm_nhor = dimlen
             end if
          else if('ocn' == trim(gridname)) then
             if(trim(dimname) == 'lay') then
                grid%ocn_nlay = dimlen
             end if
          else if('ice' == trim(gridname)) then
             if(trim(dimname) == 'ncat') then
                grid%ice_ncat = dimlen
             end if
          end if
       end if

       grid%dimlen(i) = dimlen
       grid%dimnames(i) = trim(dimname)
    end do

    print *, 'grid%nlat = ', grid%nlat, ', grid%nlon = ', grid%nlon

   !Allocate memory.
    allocate(grid%varids(grid%nVars))
    allocate(grid%vars(grid%nVars))

    allocate(grid%var1d(grid%nx))
    allocate(grid%var2d(grid%nx, grid%ny))
    allocate(grid%var3d(grid%nx, grid%ny, grid%nz))

    rc = nf90_inq_varids(grid%fileid, grid%nVars, grid%varids)
    call check_status(rc)

   !print *, 'nvars = ', grid%nVars, ', varids: ', grid%varids

    do i = 1, grid%nVars
       rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
                                  ndims=grid%vars(i)%nDims, natts=grid%vars(i)%nAtts)
       call check_status(rc)
       print *, 'Var No. ', i, ': ndims = ', grid%vars(i)%nDims

       allocate(grid%vars(i)%dimids(grid%vars(i)%nDims))
       allocate(grid%vars(i)%dimlen(grid%vars(i)%nDims))
       allocate(grid%vars(i)%dimnames(grid%vars(i)%nDims))

       rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
                                  dimids=grid%vars(i)%dimids)
       call check_status(rc)
       print *, 'Var No. ', i, ': grid%vars(i)%dimids = ', grid%vars(i)%dimids

       rc = nf90_inquire_variable(grid%fileid, grid%varids(i), &
                                  name=grid%vars(i)%varname)
       call check_status(rc)
       print *, 'Var No. ', i, ': ', trim(grid%vars(i)%varname)

       if(trim(grid%vars(i)%varname) == 'lat') then
          if(allocated(grid%lat)) allocate(grid%lat(grid%nlat))
          rc = nf90_get_var(grid%fileid, grid%varids(i), grid%lat)
          call check_status(rc)
       else if(trim(grid%vars(i)%varname) == 'lon') then
          if(allocated(grid%lon)) allocate(grid%lon(grid%nlon))
          rc = nf90_get_var(grid%fileid, grid%varids(i), grid%lon)
          call check_status(rc)
       else
          if('atm' == trim(gridname)) then
             if(trim(grid%vars(i)%varname) == 'lev') then
                if(allocated(grid%atm_lev)) allocate(grid%atm_lev(grid%atm_nlev))
                rc = nf90_get_var(grid%fileid, grid%varids(i), grid%atm_lev)
                call check_status(rc)
             else if(trim(grid%vars(i)%varname) == 'layer') then
                if(allocated(grid%atm_lay)) allocate(grid%atm_lay(grid%atm_nlay))
                rc = nf90_get_var(grid%fileid, grid%varids(i), grid%atm_lay)
                call check_status(rc)
             else if(trim(grid%vars(i)%varname) == 'hor') then
                if(allocated(grid%atm_hor)) allocate(grid%atm_hor(grid%atm_nhor))
                rc = nf90_get_var(grid%fileid, grid%varids(i), grid%atm_hor)
                call check_status(rc)
             end if
          else if('ocn' == trim(gridname)) then
             if(trim(grid%vars(i)%varname) == 'lay') then
                if(allocated(grid%ocn_lay)) allocate(grid%ocn_lay(grid%ocn_nlay))
                rc = nf90_get_var(grid%fileid, grid%varids(i), grid%ocn_lay)
                call check_status(rc)
             end if
          else if('ice' == trim(gridname)) then
             if(trim(grid%vars(i)%varname) == 'ncat') then
                if(allocated(grid%ice_cat)) allocate(grid%ice_cat(grid%ice_ncat))
                rc = nf90_get_var(grid%fileid, grid%varids(i), grid%ice_cat)
                call check_status(rc)
             end if
          end if
       end if

       do k = 1, grid%vars(i)%ndims
          ik = grid%vars(i)%dimids(k)
          grid%vars(i)%dimnames(k) = trim(grid%dimnames(ik))
          grid%vars(i)%dimlen(k) = grid%dimlen(ik)
       end do
    end do

    print *, 'Leave initialize_grid'

  end subroutine initialize_grid

  !----------------------------------------------------------------------
  subroutine finalize_grid(grid)

    implicit none

    type(gridtype), intent(inout) :: grid

    integer :: i, rc

    if(allocated(grid%varids)) deallocate(grid%varids)
    if(allocated(grid%dimids)) deallocate(grid%dimids)
    if(allocated(grid%dimlen)) deallocate(grid%dimlen)
    if(allocated(grid%dimnames)) deallocate(grid%dimnames)

    if(allocated(grid%lon)) deallocate(grid%lon)
    if(allocated(grid%lat)) deallocate(grid%lat)

    if(allocated(grid%atm_lev)) deallocate(grid%atm_lev)
    if(allocated(grid%atm_lay)) deallocate(grid%atm_lay)
    if(allocated(grid%atm_hor)) deallocate(grid%atm_hor)
    if(allocated(grid%ocn_lay)) deallocate(grid%ocn_lay)
    if(allocated(grid%ice_cat)) deallocate(grid%ice_cat)

    do i = 1, grid%nVars
       if(allocated(grid%vars(i)%dimids)) &
          deallocate(grid%vars(i)%dimids)
       if(allocated(grid%vars(i)%dimlen)) &
          deallocate(grid%vars(i)%dimlen)
       if(allocated(grid%vars(i)%dimnames)) &
          deallocate(grid%vars(i)%dimnames)
    end do

    if(allocated(grid%vars)) deallocate(grid%vars)
    if(allocated(grid%var1d)) deallocate(grid%var1d)
    if(allocated(grid%var2d)) deallocate(grid%var2d)
    if(allocated(grid%var3d)) deallocate(grid%var3d)

    print *, 'close filename: ', trim(grid%filename)
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

end module grid_module

