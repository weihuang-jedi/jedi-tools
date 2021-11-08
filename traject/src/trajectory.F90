!--------------------------------------------------------------------
PROGRAM trajectory

   use module_namelist
   use module_model
   use module_trajectory

   IMPLICIT NONE

   type(modelgrid)  :: model
   type(trajectorytype) :: traject

   integer :: n

   call read_namelist('input.nml')

   call initialize_modelgrid(model, trim(filename))

   call initialize_trajectory(model, traject)

   call create_header(traject, output_flnm)

   call output_trajectory(traject, 0, dt)

   do n = 1, 2
      call advance_trajectory(model, traject, dt)
      call output_trajectory(traject, n, dt)
   end do

   call finalize_trajectory(traject)

   call finalize_modelgrid(model)

END PROGRAM trajectory

