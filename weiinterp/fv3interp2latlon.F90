!--------------------------------------------------------------------
PROGRAM fv3interp2latlon

   use namelist_module
   use tile_module
   use latlon_module
   use fv_grid_utils_module

   IMPLICIT NONE

   type tiletype
      type(tilegrid), dimension(6) :: tile
   end type tiletype

   type(tilespec_type), dimension(6)    :: spec
   type(tiletype), dimension(max_types) :: types
   type(latlongrid)                     :: latlon
   type(fv_grid_type), dimension(6)     :: gridstruct

   integer :: n
   logical :: last

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   call read_namelist('input.nml')

   if(num_types < 1) then
      print *, 'num_types must great than 0. eg. must have at least 1 type.'
      stop 111
   end if

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   if(use_uv_directly) then
      call initialize_tilespec(spec, trim(griddirname), trim(grid_type))
   end if

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   call initialize_latlongrid(nlon, nlat, npnt, latlon)

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   do n = 1, num_types
      print *, 'dirname: <', trim(dirname), &
               '>, data_types(', n, ') = <', trim(data_types(n)), '>'
      call initialize_tilegrid(types(n)%tile, trim(dirname), trim(data_types(n)))

      if(trim(data_types(n)) == 'fv_core.res.tile') then
         latlon%nlev = types(n)%tile(1)%nz
      else if(trim(data_types(n)) == 'sfc_data.tile') then
         latlon%nlay = types(n)%tile(1)%nz
      end if
   end do

   print *, 'File: ', __FILE__, ', line: ', __LINE__
  !print *, 'latlon%nlev: ', latlon%nlev, ', latlon%nlay: ', latlon%nlay
   print *, 'generate_weights = ', generate_weights

   if(generate_weights) then
      call generate_weight(types(1)%tile, latlon)
      call write_latlongrid(latlon, wgt_flnm)
   else
      print *, 'File: ', __FILE__, ', line: ', __LINE__
      print *, 'wgt_flnm: ', trim(wgt_flnm)
      call read_weights(latlon, wgt_flnm)

      print *, 'File: ', __FILE__, ', line: ', __LINE__
      print *, 'use_uv_directly: ', use_uv_directly
      if(use_uv_directly) then
         do n = 1, 6
            print *, 'n = ', n
            call grid_utils_init(spec(n), gridstruct(n), &
                                 types(1)%tile(n)%nx, types(1)%tile(n)%ny)
         end do
      end if

      print *, 'File: ', __FILE__, ', line: ', __LINE__
      print *, 'num_types: ', num_types

      do n = 1, num_types
         last = (n == num_types)
         print *, 'n = ', n
         print *, 'last = ', last
         call generate_header(n, types(n)%tile, latlon, &
                              trim(data_types(n)), output_flnm, last)
      end do

      print *, 'File: ', __FILE__, ', line: ', __LINE__
      print *, 'num_types: ', num_types

      do n = 1, num_types
         call interp2latlongrid(trim(data_types(n)), spec, gridstruct, &
                                types(n)%tile, latlon)
      end do

      print *, 'File: ', __FILE__, ', line: ', __LINE__
      print *, 'use_uv_directly: ', use_uv_directly

      if(use_uv_directly) then
         do n = 1, 6
            call grid_utils_exit(gridstruct(n))
         end do
      end if
   end if

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   do n = 1, num_types
      call finalize_tilegrid(types(n)%tile)
   end do

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   call finalize_latlongrid(latlon)

   print *, 'File: ', __FILE__, ', line: ', __LINE__

   if(use_uv_directly) then
      call finalize_tilespec(spec)
   end if

   print *, 'File: ', __FILE__, ', line: ', __LINE__

END PROGRAM fv3interp2latlon

