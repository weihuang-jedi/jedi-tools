!--------------------------------------------------------------------
PROGRAM concatefiles

   use namelist_module
   use grid_module

   IMPLICIT NONE

   type(gridtype) :: atm, ocn, ice

   integer :: n
   logical :: last

   call read_namelist('input.nml')

   if(num_types < 1) then
      print *, 'num_types must great than 0. eg. must have at least 1 type.'
      stop 111
   end if

   if(use_uv_directly) then
      call initialize_tilespec(spec, trim(griddirname), trim(grid_type))
   end if

   call initialize_latlongrid(nlon, nlat, npnt, latlon)

   do n = 1, num_types
     !print *, 'dirname: <', trim(dirname), &
     !         '>, data_types(', n, ') = <', trim(data_types(n)), '>'
      call initialize_tilegrid(types(n)%tile, trim(dirname), trim(data_types(n)))

      if(trim(data_types(n)) == 'fv_core.res.tile') then
         latlon%nlev = types(n)%tile(1)%nz
      else if(trim(data_types(n)) == 'sfc_data.tile') then
         latlon%nlay = types(n)%tile(1)%nz
      end if
   end do

   if(generate_weights) then
      call generate_weight(types(1)%tile, latlon)
      call write_latlongrid(latlon, wgt_flnm)
   else
      call read_weights(latlon, wgt_flnm)

      if(use_uv_directly) then
         do n = 1, 6
            call grid_utils_init(spec(n), gridstruct(n), &
                                 types(1)%tile(n)%nx, types(1)%tile(n)%ny)
         end do
      end if

      do n = 1, num_types
         last = (n == num_types)
        !print *, 'n = ', n
        !print *, 'last = ', last
         call generate_header(n, types(n)%tile, latlon, &
                              trim(data_types(n)), output_flnm, last)
      end do

      do n = 1, num_types
         call interp2latlongrid(trim(data_types(n)), spec, gridstruct, &
                                types(n)%tile, latlon)
      end do

      if(use_uv_directly) then
         do n = 1, 6
            call grid_utils_exit(gridstruct(n))
         end do
      end if
   end if

   do n = 1, num_types
      call finalize_tilegrid(types(n)%tile)
   end do

   call finalize_latlongrid(latlon)

   if(use_uv_directly) then
      call finalize_tilespec(spec)
   end if

END PROGRAM concatefiles

