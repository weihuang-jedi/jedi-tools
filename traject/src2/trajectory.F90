!--------------------------------------------------------------------
PROGRAM trajectory

   use module_namelist
   use module_model
   use module_trajectory

   IMPLICIT NONE

   type(modelgrid)  :: model0, model1, model
   type(trajectorytype) :: traject

   integer :: i, n, numbsteps
   real :: ct, fac

   call read_namelist('input.nml')

   call initialize_modelgrid(model0, trim(filelist(1)))

  !call initialize_trajectory(model0, traject, height)

  !call create_header(traject, output_flnm, numbstep, dt)

  !call output_trajectory(traject, 0, dt)

   numbsteps = 60.0*frequency/dt

   print *, 'frequency, dt, numbsteps = ', frequency, dt, numbsteps

   ct = 0.0
   do i = 2, numbfiles
      if(2 == i) then
         call initialize_modelgrid(model1, trim(filelist(i)))
      end if

      fac = ct / (60.0*frequency)

     !do n = 1, numbstep
     !   call set_modelgrid(model0, model1, model, fac)
     !   call advance_trajectory(model, traject, dt)
     !   call output_trajectory(traject, n, dt)
         ct = ct + dt
     !end do

      if(i < numbfiles) then
         call copy_modelgrid(model1, model0)
      end if
  
      ct = 0.0
   end do

  !call finalize_trajectory(traject)

   call finalize_modelgrid(model0)
   if(1 < numbfiles) then
      call finalize_modelgrid(model1)
   end if

END PROGRAM trajectory

