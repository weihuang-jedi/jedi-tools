!-------------------------------------------------------------

MODULE module_namelist

  implicit none

  integer, parameter :: nml_unit = 7

  CHARACTER(LEN=1024) :: program_name
  character(len=1024) :: filename
  character(len=1024) :: output_flnm
  integer :: numbstep
  real    :: dt
  logical :: debug_on

contains

  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: rc

    ! Namelist definition.
    namelist /control_param/ program_name, filename, &
                             numbstep, dt, &
                             output_flnm, debug_on

    program_name = 'Interpolate FV3 to regular Lat-Lon Grid'

    filename = '/work2/noaa/gsienkf/weihuang/tools/weiinterp/grid_latlon.nc'

    output_flnm = 'trajectory.nc'

    numbstep = 1

    dt = 60.0

    debug_on = .false.

    ! Check whether file exists.
    inquire(file=file_path, iostat=rc)

    if(rc /= 0) then
      write(unit=0, fmt='(3a)') 'Error: input file "', &
                             trim(file_path), '" does not exist.'
      return
    end if

    ! Open and read Namelist file.
    open(action='read', file=file_path, iostat=rc, unit=nml_unit)
    read(nml=control_param, iostat=rc, unit=nml_unit)

    if(rc /= 0) then
      write(unit=0, fmt='(a)') 'Error: invalid Namelist format.'
    end if

    close(nml_unit)

   !print *, 'filename: ', trim(filename)

  end subroutine read_namelist

END MODULE module_namelist

