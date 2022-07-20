!-------------------------------------------------------------
MODULE namelist_module

  implicit none

  integer, parameter :: nml_unit = 7

  CHARACTER(LEN=1024) :: program_name
  character(len=1024) :: atmname, ocnname, icename
  character(len=1024) :: output_flnm
  logical :: debug_on

contains
  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: rc

    ! Namelist definition.
    namelist /control_param/ program_name, atmname, ocnname, icename, &
                             output_flnm, debug_on

    program_name = 'Combine atm, ocn, and ice into one whole file'

    atmname = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'
    ocnname = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'
    icename = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'

    output_flnm = 'combined.nc'

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

   !print *, 'dirname: ', trim(dirname)
   !print *, 'data_types(1): ', trim(data_types(1))
   !print *, 'nlon, nlat, npnt = ', nlon, nlat, npnt

  end subroutine read_namelist

END MODULE namelist_module

