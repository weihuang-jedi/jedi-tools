!-------------------------------------------------------------

MODULE namelist_module

  implicit none

  integer, parameter :: nml_unit = 7
  integer, parameter :: maxobs = 7
  integer, parameter :: maxskipvars = 10
  integer, parameter :: maxkeptvars = 10

  character(len=1024) :: filename
  character(len=1024) :: output_flnm

  character(len=10)   :: date_time

  integer                 :: numobs
  real, dimension(maxobs) :: lat, lon, prs, tmp, omb, obserr
  character(len=20), dimension(maxobs) :: LaunchTime

  integer                 :: numskipvars, numkeptvars
  character(len=128), dimension(maxskipvars) :: skipvars, keptvars

contains
  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: i, rc

    ! Namelist definition.
    namelist /control_param/ filename, output_flnm, date_time, &
                             numobs, lat, lon, prs, tmp, omb, obserr, &
                             numskipvars, skipvars, &
                             numkeptvars, keptvars, &
                             LaunchTime

    filename = 'sondes_obs_2021010900.nc4'
    output_flnm = 'created_sondes_obs_2021010900.nc4'

    numobs = 7
    lat = (/40.60365,  21.802921, -0.5194437, -0.5194437, -0.5194437, -22.767132, -41.418915/)
    lon = (/170.51949, 170.51947, 170.51947,  170.51947,  170.51947,  170.51947,  170.51949/)
    prs = (/85747.271, 70101.424, 1834.69811, 52426.7194, 93019.1515, 25504.4058, 11484.4299/)
    tmp = (/247.061,   220.781,   259.181,    192.099,    274.478,    209.436,    232.713/)

    do i = 1, maxobs
      omb(i) = 1.0
      obserr(i) = 1.5
    end do

    numskipvars = 5
    skipvars(1) = 'eastward_wind'
    skipvars(2) = 'northward_wind'
    skipvars(3) = 'virtual_temperature'
    skipvars(4) = 'specific_humidity'
    skipvars(5) = 'surface_pressure'

    numkeptvars = 1
    keptvars(1) = 'air_temperature'

    do i = 1, maxobs
      LaunchTime(i) = '2021-01-09T00:00:00Z'
    end do

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

    print *, 'numobs = ', numobs
    print *, 'lat = ', lat(1:numobs)
    print *, 'lon = ', lon(1:numobs)
    print *, 'prs = ', prs(1:numobs)
    print *, 'tmp = ', tmp(1:numobs)
    print *, 'omb = ', omb(1:numobs)

    print *, ' '
    print *, 'numskipvars = ', numskipvars
    do i = 1, numskipvars
      skipvars(i) = adjustl(skipvars(i))
     !print *, 'skipvars(', i, ') = <', trim(skipvars(i)), '>'
    end do

    print *, ' '
    print *, 'numkeptvars = ', numkeptvars
    do i = 1, numkeptvars
      keptvars(i) = adjustl(keptvars(i))
     !print *, 'keptvars(', i, ') = <', trim(keptvars(i)), '>'
    end do

    close(nml_unit)
  end subroutine read_namelist

END MODULE namelist_module

