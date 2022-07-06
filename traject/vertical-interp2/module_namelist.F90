!-------------------------------------------------------------
MODULE namelist_module

  implicit none

  integer, parameter :: nml_unit = 7
  character(len=1024) :: program_name, input_flnm, output_flnm
  integer :: nalt
  real :: dz
  logical :: debug_on

contains
  subroutine read_namelist(file_path)
    implicit none

   !Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: rc

   !Namelist definition.
    namelist /control_param/ program_name, input_flnm, &
                             output_flnm, nalt, dz, debug_on

    program_name = 'Vertical Interpolation'

    input_flnm = '../data/gfs_4_20210101_0000_000.nc'

    output_flnm = 'verticalheight.nc'

    nalt = 101
    dz = 500.0

    debug_on = .false.

   !Check whether file exists.
    inquire(file=file_path, iostat=rc)

    if(rc /= 0) then
      write(unit=0, fmt='(3a)') 'Error: input file <', &
                                 trim(file_path), '> does not exist.'
      return
    end if

   !Open and read Namelist file.
    open(action='read', file=file_path, iostat=rc, unit=nml_unit)
    read(nml=control_param, iostat=rc, unit=nml_unit)

    if(rc /= 0) then
      write(unit=0, fmt='(a)') 'Error: invalid Namelist format.'
    end if

    close(nml_unit)

  end subroutine read_namelist

END MODULE namelist_module

