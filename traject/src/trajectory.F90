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

   do n = 1, 2
      call output_trajectory(traject, n, dt)
      call advance_trajectory(model, traject, dt)
   end do

   call output_trajectory(traject, 3, dt)

   call finalize_modelgrid(model)

   call finalize_trajectory(traject)

END PROGRAM trajectory

