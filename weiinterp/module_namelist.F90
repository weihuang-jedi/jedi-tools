!-------------------------------------------------------------

MODULE namelist_module

  implicit none

  integer, parameter :: nml_unit = 7

  CHARACTER(LEN=1024) :: program_name
  character(len=1024) :: dirname, prefix
  character(len=1024) :: output_flnm, wgt_flnm
  integer :: nlat, nlon, npnt
  logical :: generate_weights, debug_on

contains
  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: rc

    ! Namelist definition.
    namelist /control_param/ program_name, dirname, prefix, &
                             output_flnm, wgt_flnm, &
                             nlat, nlon, npnt, &
                             generate_weights

    program_name = 'Interpolate FV3 to regular Lat-Lon Grid'

   !if(generate_weights) then
   !  dirname = 'C96/'
   !  prefix = 'C96_grid_spec.tile'
   !else
      dirname = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'
      prefix = '20210109.000000.fv_core.res.tile'
   !end if

    output_flnm = 'latlon_grid.nc'
    wgt_flnm = 'weights.nc'

    nlon = 360
    nlat = 181
    npnt = 4

    generate_weights = .false.
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

    print *, 'dirname: ', trim(dirname)
    print *, 'prefix: ', trim(prefix)
    print *, 'nlon, nlat, npnt = ', nlon, nlat, npnt

  end subroutine read_namelist

END MODULE namelist_module
