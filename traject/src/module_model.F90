!-----------------------------------------------------------------------
!  The model module read both model specification, and model data.
!-----------------------------------------------------------------------

module module_model

  use netcdf

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: vartype
  public :: modelgrid
  public :: initialize_modelgrid
  public :: finalize_modelgrid
  public :: check_status

  !-----------------------------------------------------------------------

  ! Define model structure.

  type vartype
     integer             :: varid
     character(len=1024) :: varname
     integer             :: xtype, ndims, nAtts
     integer, dimension(:), allocatable :: dimids
     integer, dimension(:), allocatable :: dimlen
     character(len=128), dimension(:), allocatable :: dimnames
  end type vartype

  type modelgrid
     character(len=1024)                :: filename
     integer                            :: fileid
     integer                            :: nDims, nVars, nGlobalAtts, unlimDimID
     integer                            :: nlon, nlat, nlev, nhor, ntim
     real,    dimension(:), allocatable :: lon, lat, lev, hor
     integer, dimension(:), allocatable :: varids
     integer, dimension(:), allocatable :: dimids
     integer, dimension(:), allocatable :: dimlen
     character(len=128), dimension(:), allocatable :: dimnames

     real(kind=8), dimension(:), allocatable :: time

     real, dimension(:, :, :), allocatable :: u, v, w, t, phis, dz, delp, p, z

     type(vartype), dimension(:), allocatable :: vars
  end type modelgrid

  !-----------------------------------------------------------------------

contains

  !-----------------------------------------------------------------------

  subroutine initialize_modelgrid(model, filename)

    implicit none

    type(modelgrid),  intent(out) :: model
    character(len=*), intent(in)  :: filename

    integer :: i, j, k, n, nk, rc
    integer :: include_parents, dimlen

    character(len=1024) :: dimname, varname

    print *, 'Enter initialize_modelgrid'
    print *, 'filename: <', trim(filename), '>'

    include_parents = 0

    model%filename = trim(filename)

    print *, 'open filename: ', trim(model%filename)
    rc = nf90_open(trim(model%filename), nf90_nowrite, model%fileid)
    call check_status(rc)
    print *, 'fileid: ', model%fileid

    rc = nf90_inquire(model%fileid, model%nDims, model%nVars, &
                      model%nGlobalAtts, model%unlimdimid)
    call check_status(rc)
    print *, 'nVars: ', model%nVars
    print *, 'nDims: ', model%nDims

   !Allocate memory.
    allocate(model%dimids(model%nDims))
    allocate(model%dimlen(model%nDims))
    allocate(model%dimnames(model%nDims))

    rc = nf90_inq_dimids(model%fileid, model%nDims, model%dimids, include_parents)
    call check_status(rc)

    print *, 'dimids: ', model%dimids

    do n = 1, model%nDims
       rc = nf90_inquire_dimension(model%fileid, model%dimids(n), dimname, dimlen)
       call check_status(rc)
       print *, 'Dim No. ', n, ': ', trim(dimname), ', dimlen=', dimlen

       if(trim(dimname) == 'lon') then
          model%nlon = dimlen
       else if(trim(dimname) == 'lat') then
          model%nlat = dimlen
       else if(trim(dimname) == 'lev') then
          model%nlev = dimlen
       else if(trim(dimname) == 'hor') then
          model%nhor = dimlen
       else if(trim(dimname) == 'time') then
          model%ntim = dimlen
       end if

       model%dimlen(n) = dimlen
       model%dimnames(n) = trim(dimname)
    end do

   !Allocate memory.
    allocate(model%varids(model%nVars))
    allocate(model%vars(model%nVars))

    rc = nf90_inq_varids(model%fileid, model%nVars, model%varids)
    call check_status(rc)

    print *, 'nvars = ', model%nVars, ', varids: ', model%varids

    do n = 1, model%nVars
       rc = nf90_inquire_variable(model%fileid, model%varids(n), &
                                  ndims=model%vars(n)%nDims, natts=model%vars(i)%nAtts)
       call check_status(rc)
       print *, 'Var No. ', n, ': ndims = ', model%vars(n)%nDims

       allocate(model%vars(n)%dimids(model%vars(n)%nDims))
       allocate(model%vars(n)%dimlen(model%vars(n)%nDims))
       allocate(model%vars(n)%dimnames(model%vars(n)%nDims))

       rc = nf90_inquire_variable(model%fileid, model%varids(n), &
                                  dimids=model%vars(n)%dimids)
       call check_status(rc)
       print *, 'Var No. ', n, ': model%vars(n)%dimids = ', model%vars(n)%dimids

       rc = nf90_inquire_variable(model%fileid, model%varids(n), &
                name=model%vars(n)%varname)
       call check_status(rc)
       print *, 'Var No. ', n, ': ', trim(model%vars(n)%varname)

      !rc = nf90_inquire_variable(model%fileid, model%varids(n), &
      !         model%vars(n)%varname, model%vars(n)%xtype, &
      !         model%vars(n)%ndims, model%vars(n)%dimids, &
      !         model%vars(n)%nAtts, model%vars(n)%contiguous, &
      !         model%vars(n)%chunksizes, model%vars(n)%deflate_level, &
      !         model%vars(n)%shuffle, model%vars(n)%fletcher32, &
      !         model%vars(n)%endianness)
      !call check_status(rc)

       if(trim(model%vars(n)%varname) == 'lon') then
          allocate(model%lon(model%nlon))
          rc = nf90_get_var(model%fileid, model%varids(n), model%lon)
       else if(trim(model%vars(n)%varname) == 'lat') then
          allocate(model%lat(model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(n), model%lat)
       else if(trim(model%vars(n)%varname) == 'lev') then
          allocate(model%lev(model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(n), model%lev)
       else if(trim(model%vars(n)%varname) == 'Time') then
          if(.not. allocated(model%time)) allocate(model%time(model%ntim))
          rc = nf90_get_var(model%fileid, model%varids(n), model%time)
       else if(trim(model%vars(n)%varname) == 'hor') then
          if(.not. allocated(model%hor)) allocate(model%hor(model%nhor))
          rc = nf90_get_var(model%fileid, model%varids(n), model%hor)
       else if(trim(model%vars(n)%varname) == 'ua') then
          allocate(model%u(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(n), model%u)
       else if(trim(model%vars(n)%varname) == 'ua') then
          allocate(model%v(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(n), model%v)
       else if(trim(model%vars(n)%varname) == 'W') then
          allocate(model%w(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(n), model%w)
       else if(trim(model%vars(n)%varname) == 'T') then
          allocate(model%t(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(n), model%t)
       else if(trim(model%vars(n)%varname) == 'phis') then
          allocate(model%phis(model%nlon, model%nlat, model%nhor))
          rc = nf90_get_var(model%fileid, model%varids(n), model%phis)
       else if(trim(model%vars(n)%varname) == 'DZ') then
          allocate(model%dz(model%nlon, model%nlat, model%nlev))
          allocate(model%z(model%nlon, model%nlat, model%nlev+1))
          rc = nf90_get_var(model%fileid, model%varids(n), model%dz)
          do j = 1, model%nlat
          do i = 1, model%nlon
             model%z(i, j, model%nlev+1) = model%phis(i,j,1)
             do k = model%nlev, 1, -1
                model%z(i, j, k) = model%z(i, j, k+1) + model%dz(i, j, k)
             end do
          end do
          end do
       else if(trim(model%vars(n)%varname) == 'delp') then
          allocate(model%delp(model%nlon, model%nlat, model%nlev))
          allocate(model%p(model%nlon, model%nlat, model%nlev+1))
          rc = nf90_get_var(model%fileid, model%varids(n), model%delp)
          do j = 1, model%nlat
          do i = 1, model%nlon
             model%p(i, j, 1) = 100.0
             do k = 1, model%nlev
                model%p(i, j, k+1) = model%p(i, j, k) + model%delp(i, j, k)
             end do
          end do
          end do
       end if

       call check_status(rc)

       do k = 1, model%vars(n)%ndims
          nk = model%vars(n)%dimids(k)
          model%vars(n)%dimnames(k) = trim(model%dimnames(nk))
          model%vars(n)%dimlen(k) = model%dimlen(nk)
       end do
    end do

    print *, 'Leave initialize_modelgrid'

  end subroutine initialize_modelgrid

  !----------------------------------------------------------------------
  subroutine finalize_modelgrid(model)

    implicit none

    type(modelgrid), intent(inout) :: model

    integer :: i, rc

    if(allocated(model%varids)) deallocate(model%varids)
    if(allocated(model%dimids)) deallocate(model%dimids)
    if(allocated(model%dimlen)) deallocate(model%dimlen)
    if(allocated(model%dimnames)) deallocate(model%dimnames)
    if(allocated(model%time)) deallocate(model%time)
    if(allocated(model%lon)) deallocate(model%lon)
    if(allocated(model%lat)) deallocate(model%lat)
    if(allocated(model%lev)) deallocate(model%lev)
    if(allocated(model%hor)) deallocate(model%hor)
    if(allocated(model%time)) deallocate(model%time)

    do i = 1, model%nVars
       if(allocated(model%vars(i)%dimids)) &
          deallocate(model%vars(i)%dimids)
       if(allocated(model%vars(i)%dimlen)) &
          deallocate(model%vars(i)%dimlen)
       if(allocated(model%vars(i)%dimnames)) &
          deallocate(model%vars(i)%dimnames)
    end do

    if(allocated(model%vars)) deallocate(model%vars)
    if(allocated(model%u)) deallocate(model%u)
    if(allocated(model%v)) deallocate(model%v)
    if(allocated(model%w)) deallocate(model%w)
    if(allocated(model%t)) deallocate(model%t)
    if(allocated(model%p)) deallocate(model%p)
    if(allocated(model%z)) deallocate(model%z)
    if(allocated(model%delp)) deallocate(model%delp)
    if(allocated(model%dz)) deallocate(model%dz)
    if(allocated(model%phis)) deallocate(model%phis)

    rc = nf90_close(model%fileid)
    call check_status(rc)

  end subroutine finalize_modelgrid

  !----------------------------------------------------------------------
  subroutine check_status(rc)
    integer, intent(in) :: rc
    
    if(rc /= nf90_noerr) then 
      print *, trim(nf90_strerror(rc))
      print *, 'rc = ', rc, ', nf90_noerr = ', nf90_noerr
      stop 'in check_status'
    end if
  end subroutine check_status  

end module module_model

