!--------------------------------------------------------------------
PROGRAM trajectory

   use module_namelist
   use module_model
   use module_trajectory

   IMPLICIT NONE

   type(modelgrid)  :: model
   type(trajectorytype) :: traject

   call read_namelist('input.nml')

   call initialize_modelgrid(model, trim(filename))

   call initialize_trajectory(model, traject)

   call generate_header(model, traject, output_flnm)

   call calculate_trajectory(model, traject)

   call finalize_modelgrid(model)

   call closefile(traject)
   call finalize_trajectory(traject)

END PROGRAM trajectory

