!--------------------------------------------------------------------
PROGRAM trajectory

   use module_namelist
   use module_model
   use module_trajectory

   IMPLICIT NONE

   type(modelgrid)  :: model
   type(trajectorytype) :: trajectory

   call read_namelist('input.nml')

   call initialize_modelgrid(model, trim(filename))

   call initialize_trajectory(model, trajectory)

   call generate_header(model, trajectory, output_flnm)

   call calculate_trajectory(model, trajectory)

   call finalize_modelgrid(model)

   call closefile(trajectory)
   call finalize_trajectory(trajectory)

END PROGRAM trajectory

