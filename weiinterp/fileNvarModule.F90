module tile_module
  implicit none

  !-----------------------------------------------------------------------
  ! Define interfaces and attributes for module routines

  private
  public :: tilegrid

  !-----------------------------------------------------------------------

  !Define tile structure.

  type tilegrid
     character(len=1024)                                     :: filename
     logical,                 dimension(:),      allocatable :: check
     real,                    dimension(:),      allocatable :: var
     integer                                                 :: ncoords
     integer                                                 :: nx
     integer                                                 :: ny
     integer                                                 :: ncfileid
     integer                                                 :: ncvarid
     integer                                                 :: ncdimid
     integer                                                 :: ncstatus
  end type tilegrid

  !-----------------------------------------------------------------------

contains

  !=======================================================================

  subroutine initialize_tilegrid(tile, dirname)

    ! Define variables passed to routine

    type(tilegrid), dimension(6), intent(out) :: tile
    character(len=1024),          intent(in)  :: dirname

  end subroutine initialize_tilegrid

end module tile_module

