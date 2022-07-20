!-------------------------------------------------------------

MODULE module_namelist

  implicit none

  integer, parameter :: nml_unit = 7

  CHARACTER(LEN=1024) :: datadir
  character(len=1024) :: output_flnm

  real    :: dt, height, frequency
  logical :: debug_on

  integer :: start_year, start_month, start_day, start_hour
  integer :: end_year, end_month, end_day, end_hour
  integer :: current_year, current_month, current_day, current_hour
  integer :: interval_hour

  integer, dimension(12) :: days_in_month

contains

  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: n, rc

    ! Namelist definition.
    namelist /control_param/ datadir, dt, height, interval_hour, &
                             output_flnm, debug_on, &
                             start_year, start_month, start_day, start_hour, &
                             end_year, end_month, end_day, end_hour

    days_in_month = (/31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/)

    datadir = './data'

    output_flnm = 'trajectory.nc'

    dt = 60.0
    height = 5000.0

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

   !write(unit=6, nml=control_param)

    current_year  = start_year
    current_month = start_month
    current_day   = start_day
    current_hour  = start_hour

    frequency = 3600.0*interval_hour

  end subroutine read_namelist

!-----------------------------------------------------------------------
  subroutine get_filename(filename)
     implicit none
     character(len=1024), intent(out) :: filename
     
     write(filename, fmt='(2a, i4, a, 2(i0.2), a, i0.2, a)') &
       trim(datadir), '/vh_', current_year, '_', &
       current_month, current_day, '_', current_hour, '.nc'

     print *, 'filename: ', trim(filename)

  end subroutine get_filename

!-----------------------------------------------------------------------
  subroutine advance_time(nomoredata)
    implicit none
    logical, intent(out) :: nomoredata

   !print *, 'start_year, start_month, start_day, start_hour =', &
   !          start_year, start_month, start_day, start_hour
   !print *, 'current_year, current_month, current_day, current_hour =', &
   !          current_year, current_month, current_day, current_hour
   !print *, 'end_year, end_month, end_day, end_hour =', &
   !          end_year, end_month, end_day, end_hour

    if((current_year == end_year) .and. &
       (current_month == end_month) .and. &
       (current_day == end_day) .and. &
       (current_hour == end_hour)) then
       nomoredata = .true.
       return
    end if

    current_hour = current_hour + interval_hour

    if(0 == mod(current_year, 4)) then
      days_in_month(2) = 29
      if(0 == mod(current_year, 100)) then
        days_in_month(2) = 28
        if(0 == mod(current_year, 400)) then
          days_in_month(2) = 29
        end if
      end if
    end if

    if(current_hour >= 24) then
      current_hour = current_hour - 24
      current_day  = current_day + 1
      if(current_day > days_in_month(current_month)) then
        current_day = 1
        current_month = current_month + 1
        if(current_month > 12) then
          current_month = 1
          current_year = current_year + 1
        end if
      end if
    end if

    nomoredata = .false.

  end subroutine advance_time

END MODULE module_namelist

