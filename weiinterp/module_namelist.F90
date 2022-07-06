!-------------------------------------------------------------

MODULE namelist_module

  implicit none

  integer, parameter :: nml_unit = 7
  integer, parameter :: max_types = 5

  CHARACTER(LEN=1024) :: program_name
  character(len=1024) :: dirname
  character(len=1024) :: output_flnm, wgt_flnm, prefix
  character(len=1024) :: griddirname
  character(len=128)  :: grid_type
  character(len=128), dimension(max_types) :: data_types
  integer :: nlat, nlon, npnt, num_types
  integer :: debug_level
  logical :: generate_weights, debug_on, has_prefix, use_uv_directly

contains
  subroutine read_namelist(file_path)
    implicit none

    !! Reads Namelist from given file.
    character(len=*),  intent(in)  :: file_path
    integer :: rc

    ! Namelist definition.
    namelist /control_param/ program_name, dirname, &
                             output_flnm, wgt_flnm, &
                             nlat, nlon, npnt, &
                             num_types, data_types, &
                             generate_weights, prefix, &
                             griddirname, grid_type, &
                             debug_on, debug_level, &
                             has_prefix, use_uv_directly

    program_name = 'Interpolate FV3 to regular Lat-Lon Grid'

    dirname = '/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/analysis.getkf.80members.36procs.uvTq/increment/'

    griddirname = '/work/noaa/gsienkf/weihuang/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/'
    grid_type = 'C96_grid.tile'

    output_flnm = 'latlon_grid.nc'
    wgt_flnm = 'weights.nc'
    prefix = 'None'

    has_prefix = .false.
    use_uv_directly = .false.

    nlon = 360
    nlat = 180
    npnt = 4
    num_types = 1

    data_types(1) = 'fv_core.res.tile'

    generate_weights = .false.
    debug_on = .false.
    debug_level = 0

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

