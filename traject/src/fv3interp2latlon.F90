!--------------------------------------------------------------------
PROGRAM fv3interp2latlon

   use namelist_module
   use module_io
   use latlon_module

   IMPLICIT NONE

   type(modelgrid)  :: model
   type(latlongrid) :: latlon

   call read_namelist('input.nml')

   call initialize_latlongrid(latlon)

   call initialize_modelgrid(model, trim(filename))

   call generate_header(model, latlon, output_flnm)

   call interp2latlongrid(model, latlon)

   call finalize_modelgrid(model)

   call closefile(latlon)
   call finalize_latlongrid(latlon)

END PROGRAM fv3interp2latlon

