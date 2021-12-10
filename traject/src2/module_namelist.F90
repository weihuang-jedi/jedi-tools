!-------------------------------------------------------------

MODULE module_namelist

  implicit none

  integer, parameter :: nml_unit = 7
  integer, parameter :: maxfiles = 2000

  CHARACTER(LEN=1024) :: program_name
  character(len=1024) :: output_flnm

  character(len=1024), dimension(maxfiles) :: filelist
  integer :: numbfiles
  real    :: dt, height, frequency
  logical :: debug_on

contains

  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: n, rc

    ! Namelist definition.
    namelist /control_param/ program_name, filelist, &
                             dt, height, frequency, &
                             output_flnm, debug_on

    program_name = 'Interpolate FV3 to regular Lat-Lon Grid'

    numbfiles = 0

    do n = 1, maxfiles
       filelist(n) = 'Unknown'
    end do

    output_flnm = 'trajectory.nc'

    dt = 60.0
    height = 5000.0
    frequency = 720.0

    debug_on = .false.

    ! Check whether file exists.
    inquire(file=file_path, iostat=rc)

    if(rc /= 0) then
      write(unit=0, fmt='(3a)') 'Error: input file "', &
                             trim(file_path), '" does not exist.'
      return
    end if

   !write(unit=6, nml=control_param)

    ! Open and read Namelist file.
    open(action='read', file=file_path, iostat=rc, unit=nml_unit)
    read(nml=control_param, iostat=rc, unit=nml_unit)

    if(rc /= 0) then
      write(unit=0, fmt='(a)') 'Error: invalid Namelist format.'
    end if

    close(nml_unit)

    if(numbfiles < 1) then
       numbfiles = 0
       do n = 1, maxfiles
          if(trim(filelist(n)) /= 'Unknown') then
             numbfiles = numbfiles + 1
             print *, 'filelist(', n, '): ', trim(filelist(n))
          else
             exit
          end if
       end do
    end if

   !write(unit=6, nml=control_param)

  end subroutine read_namelist

END MODULE module_namelist

