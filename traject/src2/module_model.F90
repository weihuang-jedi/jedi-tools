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
  public :: set_modelgrid
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
     integer                            :: nlon, nlat, nalt, ntim
     real,    dimension(:), allocatable :: lon, lat, alt
     integer, dimension(:), allocatable :: varids
     integer, dimension(:), allocatable :: dimids
     integer, dimension(:), allocatable :: dimlen
     character(len=128), dimension(:), allocatable :: dimnames

     real(kind=8), dimension(:), allocatable :: time

     real, dimension(:, :), allocatable    :: slp, ter, prate, pw, tsk, tsl
     real, dimension(:, :, :), allocatable :: u, v, w, t, p, rh, q

     type(vartype), dimension(:), allocatable :: vars

     real :: dlon, dlat
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
   !print *, 'fileid: ', model%fileid

    rc = nf90_inquire(model%fileid, model%nDims, model%nVars, &
                      model%nGlobalAtts, model%unlimdimid)
    call check_status(rc)
    print *, 'nVars: ', model%nVars
    print *, 'nDims: ', model%nDims

   !Allocate memory.
    if(.not. allocated(model%dimids)) allocate(model%dimids(model%nDims))
    if(.not. allocated(model%dimlen)) allocate(model%dimlen(model%nDims))
    if(.not. allocated(model%dimnames)) allocate(model%dimnames(model%nDims))

    rc = nf90_inq_dimids(model%fileid, model%nDims, model%dimids, include_parents)
    call check_status(rc)

    print *, 'dimids: ', model%dimids

    do n = 1, model%nDims
       rc = nf90_inquire_dimension(model%fileid, model%dimids(n), dimname, dimlen)
       call check_status(rc)
      !print *, 'Dim No. ', n, ': ', trim(dimname), ', dimlen=', dimlen

       if(trim(dimname) == 'lon') then
          model%nlon = dimlen
       else if(trim(dimname) == 'lat') then
          model%nlat = dimlen
       else if(trim(dimname) == 'alt') then
          model%nalt = dimlen
       end if

       model%dimlen(n) = dimlen
       model%dimnames(n) = trim(dimname)
    end do

   !Allocate memory.
    if(.not. allocated(model%varids)) allocate(model%varids(model%nVars))
    if(.not. allocated(model%vars)) allocate(model%vars(model%nVars))

    rc = nf90_inq_varids(model%fileid, model%nVars, model%varids)
    call check_status(rc)

   !print *, 'nvars = ', model%nVars, ', varids: ', model%varids

    do n = 1, model%nVars
       rc = nf90_inquire_variable(model%fileid, model%varids(n), &
                                  ndims=model%vars(n)%nDims, natts=model%vars(n)%nAtts)
       call check_status(rc)
      !print *, 'Var No. ', n, ': ndims = ', model%vars(n)%nDims

       if(.not. allocated(model%vars(n)%dimids)) allocate(model%vars(n)%dimids(model%vars(n)%nDims))
       if(.not. allocated(model%vars(n)%dimlen)) allocate(model%vars(n)%dimlen(model%vars(n)%nDims))
       if(.not. allocated(model%vars(n)%dimnames)) allocate(model%vars(n)%dimnames(model%vars(n)%nDims))

       rc = nf90_inquire_variable(model%fileid, model%varids(n), &
                                  dimids=model%vars(n)%dimids)
       call check_status(rc)
      !print *, 'Var No. ', n, ': model%vars(n)%dimids = ', model%vars(n)%dimids

       rc = nf90_inquire_variable(model%fileid, model%varids(n), &
                name=model%vars(n)%varname)
       call check_status(rc)
      !print *, 'Var No. ', n, ': ', trim(model%vars(n)%varname)

       if(trim(model%vars(n)%varname) == 'lon') then
          if(.not. allocated(model%lon)) allocate(model%lon(model%nlon))
          rc = nf90_get_var(model%fileid, model%varids(n), model%lon)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'lat') then
          if(.not. allocated(model%lat)) allocate(model%lat(model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(n), model%lat)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'alt') then
          print *, 'Var No. ', n, ': ', trim(model%vars(n)%varname)
          if(.not. allocated(model%alt)) allocate(model%alt(model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%alt)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'U') then
          if(.not. allocated(model%u)) allocate(model%u(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%u)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'V') then
          if(.not. allocated(model%v)) allocate(model%v(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%v)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'W') then
          if(.not. allocated(model%w)) allocate(model%w(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%w)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'T') then
          if(.not. allocated(model%t)) allocate(model%t(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%t)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'P') then
          if(.not. allocated(model%p)) allocate(model%p(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%p)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'Q') then
          if(.not. allocated(model%q)) allocate(model%q(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%q)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'RH') then
          if(.not. allocated(model%rh)) allocate(model%rh(model%nlon, model%nlat, model%nalt))
          rc = nf90_get_var(model%fileid, model%varids(n), model%rh)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'PW') then
          if(.not. allocated(model%pw)) allocate(model%pw(model%nlon, model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(n), model%pw)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'TER') then
          if(.not. allocated(model%ter)) allocate(model%ter(model%nlon, model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(n), model%ter)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'SLP') then
          if(.not. allocated(model%slp)) allocate(model%slp(model%nlon, model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(n), model%slp)
          call check_status(rc)
       else if(trim(model%vars(n)%varname) == 'TSK') then
          if(.not. allocated(model%tsk)) allocate(model%tsk(model%nlon, model%nlat))
          rc = nf90_get_var(model%fileid, model%varids(n), model%tsk)
          call check_status(rc)
       end if

       do k = 1, model%vars(n)%ndims
          nk = model%vars(n)%dimids(k)
          model%vars(n)%dimnames(k) = trim(model%dimnames(nk))
          model%vars(n)%dimlen(k) = model%dimlen(nk)
       end do
    end do

   !model%dlon = 360.0/model%nlon
   !model%dlat = 180.0/(model%nlat - 1)

    model%dlon = model%lon(2) - model%lon(1)
    model%dlat = model%lat(2) - model%lat(1)

    print *, 'Leave initialize_modelgrid'

    rc = nf90_close(model%fileid)
    call check_status(rc)

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

    if(allocated(model%lon)) deallocate(model%lon)
    if(allocated(model%lat)) deallocate(model%lat)
    if(allocated(model%alt)) deallocate(model%alt)

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
    if(allocated(model%q)) deallocate(model%q)
    if(allocated(model%rh)) deallocate(model%rh)
    if(allocated(model%pw)) deallocate(model%pw)
    if(allocated(model%ter)) deallocate(model%ter)
    if(allocated(model%slp)) deallocate(model%slp)
    if(allocated(model%tsk)) deallocate(model%tsk)

  end subroutine finalize_modelgrid

  !----------------------------------------------------------------------
  subroutine set_modelgrid(model0, model1, model, fac)
  
    implicit none

    type(modelgrid), intent(in)    :: model0, model1
    type(modelgrid), intent(inout) :: model
    real,            intent(in)    :: fac

    integer :: i, j, k

   !write(unit=*, fmt='(2(a,f6.3))') '(1.0-fac)=', (1.0-fac), ', fac=', fac

   !$omp parallel do default(none) &
   !$omp shared(model, model0, model1, fac) &
   !$omp private(i, j, k)
    do j = 1, model%nlat
    do k = 1, model%nalt
    do i = 1, model%nlon
       model%u(i,j,k) = (1.0-fac)*model0%u(i,j,k) + fac*model1%u(i,j,k)
       model%v(i,j,k) = (1.0-fac)*model0%v(i,j,k) + fac*model1%v(i,j,k)
       model%w(i,j,k) = (1.0-fac)*model0%w(i,j,k) + fac*model1%w(i,j,k)
    end do
    end do
    end do

  end subroutine set_modelgrid

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

