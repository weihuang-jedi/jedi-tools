!--------------------------------------------------------------------
PROGRAM trajectory

   use module_namelist
   use module_model
   use module_trajectory

   IMPLICIT NONE

   type(modelgrid)  :: model0, model1, model
   type(trajectorytype) :: traject

   integer :: i, n, numbsteps
   real :: pt, ct, fac

   call read_namelist('input.nml')

   if(numbfiles < 2) then
      print *, 'We need two or more data files. Stop'
      stop 999
   end if

   call initialize_modelgrid(model0, trim(filelist(1)))

   call initialize_trajectory(model0, traject, height)

   call create_header(traject, output_flnm)

   call output_trajectory(traject, 0, 0)

   numbsteps = 60.0*frequency/dt

   print *, 'numbfiles = ', numbfiles
   print *, 'frequency, dt, numbsteps = ', frequency, dt, numbsteps
   print *, 'height = ', height

   ct = 0.0
   pt = 0.0
   do i = 2, numbfiles
      if(i > 2) then
         call initialize_modelgrid(model0, trim(filelist(i-1)))
      end if
      call initialize_modelgrid(model1, trim(filelist(i)))

      do n = 1, numbsteps
         fac = ct / (60.0*frequency)
         call set_modelgrid(model0, model1, model, fac)
         call advance_trajectory(model, traject, dt)
         fac = ct+pt
         call output_trajectory(traject, n, fac)
         ct = ct + dt
      end do

     !if(i < numbfiles) then
        !call copy_modelgrid(model1, model0)
         call finalize_modelgrid(model0)
         call finalize_modelgrid(model1)
     !end if
  
      ct = 0.0
      pt = pt+60*frequency
   end do

   call finalize_trajectory(traject)

  !call finalize_modelgrid(model0)
  !call finalize_modelgrid(model1)

END PROGRAM trajectory

