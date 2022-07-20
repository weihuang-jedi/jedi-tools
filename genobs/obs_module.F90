!-----------------------------------------------------------------------
!  The obs module read both obs specification, and obsd data.
!-----------------------------------------------------------------------

module obs_module

  use netcdf

  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: vartype
  public :: obsgrid
  public :: initialize_obsgrid
  public :: finalize_obsgrid
  public :: check_rc

  !-----------------------------------------------------------------------

  ! Define obs structure.

  type vartype
     integer             :: varid
     character(len=1024) :: varname
     integer             :: nDims, nAtts, xtype
     integer, dimension(:), allocatable :: dimids
  end type vartype

  type obsgrid
     character(len=1024)                   :: filename
     integer                               :: fileid
     integer                               :: nDims, nVars, nGlobalAtts, unlimDimID
     integer                               :: nvar, nlocs, nstring, ndatetime
     integer, dimension(:),    allocatable :: varids
     integer, dimension(:),    allocatable :: dimids

     type(vartype), dimension(:), allocatable :: vars
  end type obsgrid

  !-----------------------------------------------------------------------

contains

  !-----------------------------------------------------------------------

  subroutine initialize_obsgrid(obs, filename)

    implicit none

    type(obsgrid),    intent(out) :: obs
    character(len=*), intent(in)  :: filename

    integer :: i, rc
    integer :: include_parents, dimlen

    character(len=1024) :: dimname

    include_parents = 0

    write(obs%filename, fmt='(a)') trim(filename)
    print *, 'Open filename: ', trim(obs%filename)
    rc = nf90_open(trim(obs%filename), nf90_nowrite, obs%fileid)
    call check_rc(rc)

    rc= nf90_inquire(obs%fileid, obs%nDims, obs%nVars, &
             obs%nGlobalAtts, obs%unlimdimid)
    call check_rc(rc)
    print *, 'nVars: ', obs%nVars
    print *, 'nDims: ', obs%nDims
    print *, 'obs%nGlobalAtts: ', obs%nGlobalAtts

    ! Allocate memory.
    allocate(obs%dimids(obs%nDims))

    rc= nf90_inq_dimids(obs%fileid, obs%nDims, obs%dimids, include_parents)
    call check_rc(rc)

    print *, 'obs dimids: ', obs%dimids

    obs%nstring = 20
    obs%ndatetime = 50

    do i = 1, obs%nDims
      rc= nf90_inquire_dimension(obs%fileid, obs%dimids(i), dimname, dimlen)
      call check_rc(rc)
      print *, 'Dim No. ', i, ': ', trim(dimname), ', dimlen=', dimlen
      if(trim(dimname) == 'nvars') then
         obs%nvar = dimlen
      else if(trim(dimname) == 'nlocs') then
         obs%nlocs = dimlen
      else if(trim(dimname) == 'nstring') then
         obs%nstring = dimlen
      else if(trim(dimname) == 'ndatetime') then
         obs%ndatetime = dimlen
      end if
    end do

    ! Allocate memory.
    allocate(obs%varids(obs%nVars))

    ! Allocate memory.
    allocate(obs%vars(obs%nVars))

    rc= nf90_inq_varids(obs%fileid, obs%nVars, obs%varids)
    call check_rc(rc)

    print *, 'nvars = ', obs%nVars
   !print *, 'nvars = ', obs%nVars, ', varids: ', obs%varids

    do i = 1, obs%nVars
     !print *, 'obs%varids(', i, ') = ', obs%varids(i)

      rc= nf90_inquire_variable(obs%fileid, obs%varids(i), &
               name=obs%vars(i)%varname)
      call check_rc(rc)
     !print *, 'Var No. ', i, ': ', trim(obs%vars(i)%varname)

      rc= nf90_inquire_variable(obs%fileid, obs%varids(i), &
               ndims=obs%vars(i)%nDims, natts=obs%vars(i)%nAtts)
      call check_rc(rc)
     !print *, 'Var No. ', i, ': ndims = ', obs%vars(i)%nDims

      allocate(obs%vars(i)%dimids(obs%vars(i)%nDims))

      rc= nf90_inquire_variable(obs%fileid, obs%varids(i), &
               dimids=obs%vars(i)%dimids, xtype=obs%vars(i)%xtype)
      call check_rc(rc)

     !rc= nf90_inquire_variable(obs%fileid, obs%varids(i), &
     !         obs%vars(i)%varname, obs%vars(i)%xtype, &
     !         obs%vars(i)%ndims, obs%vars(i)%dimids, &
     !         obs%vars(i)%nAtts, obs%vars(i)%contiguous, &
     !         obs%vars(i)%chunksizes, obs%vars(i)%deflate_level, &
     !         obs%vars(i)%shuffle, obs%vars(i)%fletcher32, &
     !         obs%vars(i)%endianness)
     !call check_rc(rc)

     !function nf90_get_var(ncid, varid, values, start, count, stride, map)
     !integer,                         intent( in) :: ncid, varid
     !any valid type, scalar or array of any rank, &
     !                                 intent(out) :: values
     !integer, dimension(:), optional, intent( in) :: start, count, stride, map

     !if(trim(obs%vars(i)%varname) == 'grid_lont') then
     !   allocate(obs%lon(obs%nx, obs%ny))
     !   rc= nf90_get_var(obs%fileid, obs%varids(i), obs%lon)
     !   call check_rc(rc)
     !end if
    end do

    print *, 'Finished check original obs file.'

  end subroutine initialize_obsgrid

  !----------------------------------------------------------------------
  subroutine finalize_obsgrid(obs)

    implicit none

    type(obsgrid), intent(inout) :: obs

    integer :: i, rc

    if(allocated(obs%varids)) deallocate(obs%varids)
    if(allocated(obs%dimids)) deallocate(obs%dimids)

    do i = 1, obs%nVars
       if(allocated(obs%vars(i)%dimids)) &
          deallocate(obs%vars(i)%dimids)
    end do

    if(allocated(obs%vars)) deallocate(obs%vars)

    print *, 'close filename: ', trim(obs%filename)
    rc= nf90_close(obs%fileid)
    call check_rc(rc)

  end subroutine finalize_obsgrid

  !----------------------------------------------------------------------
  subroutine check_rc(rc)
    integer, intent(in) :: rc
    
    if(rc /= nf90_noerr) then 
      print *, trim(nf90_strerror(rc))
      stop 2
    end if
  end subroutine check_rc 

end module obs_module

