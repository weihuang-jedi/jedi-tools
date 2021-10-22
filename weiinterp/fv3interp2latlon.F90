!--------------------------------------------------------------------
PROGRAM fv3interp2latlon

   use namelist_module
   use tile_module
   use latlon_module

   IMPLICIT NONE

   type(tilegrid), dimension(6) :: tile
   type(latlongrid)             :: latlon

   call read_namelist('input.nml')

   call initialize_tilegrid(tile, dirname, prefix)
   call initialize_latlongrid(nlon, nlat, npnt, latlon)

  !call output_tilegrid(tile)

   if(generate_weights) then
      call generate_weight(tile, latlon)
      call write_latlongrid(latlon, wgt_flnm)
   else
      call read_weights(latlon, wgt_flnm)
      call interp2latlongrid(tile, latlon, output_flnm)
   end if

   call finalize_latlongrid(latlon)
   call finalize_tilegrid(tile)

END PROGRAM fv3interp2latlon

