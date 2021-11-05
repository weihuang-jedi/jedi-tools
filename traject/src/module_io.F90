!-----------------------------------------------------------------------
!  The model module read both model specification, and model data.
!-----------------------------------------------------------------------

module module_io

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

    integer :: i, k, ik, rc
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

    do i = 1, model%nDims
       rc = nf90_inquire_dimension(model%fileid, model%dimids(i), dimname, dimlen)
       call check_status(rc)
       print *, 'Dim No. ', i, ': ', trim(dimname), ', dimlen=', dimlen

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

       model%dimlen(i) = dimlen
       model%dimnames(i) = trim(dimname)
    end do

   !Allocate memory.
    allocate(model%varids(model%nVars))
    allocate(model%vars(model%nVars))

    rc = nf90_inq_varids(model%fileid, model%nVars, model%varids)
    call check_status(rc)

    print *, 'nvars = ', model%nVars, ', varids: ', model%varids

    do i = 1, model%nVars
       rc = nf90_inquire_variable(model%fileid, model%varids(i), &
                                  ndims=model%vars(i)%nDims, natts=model%vars(i)%nAtts)
       call check_status(rc)
       print *, 'Var No. ', i, ': ndims = ', model%vars(i)%nDims

       allocate(model%vars(i)%dimids(model%vars(i)%nDims))
       allocate(model%vars(i)%dimlen(model%vars(i)%nDims))
       allocate(model%vars(i)%dimnames(model%vars(i)%nDims))

       rc = nf90_inquire_variable(model%fileid, model%varids(i), &
                                  dimids=model%vars(i)%dimids)
       call check_status(rc)
       print *, 'Var No. ', i, ': model%vars(i)%dimids = ', model%vars(i)%dimids

       rc = nf90_inquire_variable(model%fileid, model%varids(i), &
                name=model%vars(i)%varname)
       call check_status(rc)
       print *, 'Var No. ', i, ': ', trim(model%vars(i)%varname)

      !rc = nf90_inquire_variable(model%fileid, model%varids(i), &
      !         model%vars(i)%varname, model%vars(i)%xtype, &
      !         model%vars(i)%ndims, model%vars(i)%dimids, &
      !         model%vars(i)%nAtts, model%vars(i)%contiguous, &
      !         model%vars(i)%chunksizes, model%vars(i)%deflate_level, &
      !         model%vars(i)%shuffle, model%vars(i)%fletcher32, &
      !         model%vars(i)%endianness)
      !call check_status(rc)

       if(trim(model%vars(i)%varname) == 'lon') then
          allocate(model%lon(model%nlon))
          rc = nf90_get_var(model%fileid, model%varids(i), model%lon)
       else if(trim(model%vars(i)%varname) == 'lat') then
          allocate(model%lat(model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(i), model%lat)
       else if(trim(model%vars(i)%varname) == 'lev') then
          allocate(model%lev(model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(i), model%lev)
       else if(trim(model%vars(i)%varname) == 'Time') then
          if(.not. allocated(model%time)) allocate(model%time(model%ntim))
          rc = nf90_get_var(model%fileid, model%varids(i), model%time)
       else if(trim(model%vars(i)%varname) == 'hor') then
          if(.not. allocated(model%hor)) allocate(model%hor(model%nhor))
          rc = nf90_get_var(model%fileid, model%varids(i), model%hor)
       else if(trim(model%vars(i)%varname) == 'ua') then
          allocate(model%u(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(i), model%u)
       else if(trim(model%vars(i)%varname) == 'ua') then
          allocate(model%v(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(i), model%v)
       else if(trim(model%vars(i)%varname) == 'W') then
          allocate(model%w(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(i), model%w)
       else if(trim(model%vars(i)%varname) == 'T') then
          allocate(model%t(model%nlon, model%nlat, model%nlev))
          rc = nf90_get_var(model%fileid, model%varids(i), model%t)
       else if(trim(model%vars(i)%varname) == 'DZ') then
          allocate(model%dz(model%nlon, model%nlat, model%nlev))
          allocate(model%z(model%nlon, model%nlat, model%nlev+1))
          rc = nf90_get_var(model%fileid, model%varids(i), model%dz)
       else if(trim(model%vars(i)%varname) == 'delp') then
          allocate(model%delp(model%nlon, model%nlat, model%nlev))
          allocate(model%p(model%nlon, model%nlat, model%nlev+1))
          rc = nf90_get_var(model%fileid, model%varids(i), model%delp)
       end if

       call check_status(rc)

       do k = 1, model%vars(i)%ndims
          ik = model%vars(i)%dimids(k)
          model%vars(i)%dimnames(k) = trim(model%dimnames(ik))
          model%vars(i)%dimlen(k) = model%dimlen(ik)
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

end module module_io

