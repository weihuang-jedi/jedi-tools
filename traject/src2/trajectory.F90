!--------------------------------------------------------------------
PROGRAM trajectory

   use module_namelist
   use module_model
   use module_trajectory

   IMPLICIT NONE

   type(modelgrid)  :: model0, model1, model
   type(trajectorytype) :: traject
   character(len=1024)  :: filename
   logical              :: nomoredata

   integer :: it, n, numbsteps
   real :: pt, ct, fac

   call read_namelist('input.nml')

   call get_filename(filename)

   call initialize_modelgrid(model0, trim(filename))

   call initialize_trajectory(model0, traject, height)

   call create_header(traject, output_flnm)

   call output_trajectory(traject, 0, 0.0)

   numbsteps = (frequency+0.5)/dt

   print *, 'frequency, dt, numbsteps = ', frequency, dt, numbsteps
   print *, 'height = ', height

   ct = 0.0
   pt = 0.0
   it = 1
   nomoredata = .false.
   do while(.not. nomoredata)
     print *, 'it = ', it, ', mod(it, 2) = ', mod(it, 2)

     call advance_time(nomoredata)
     call get_filename(filename)

     if(1 == it) then
        call initialize_modelgrid(model1, trim(filename))
     else
        if(0 == mod(it, 2)) then
           call setup_modelgrid(model0, trim(filename))
        else
           call setup_modelgrid(model1, trim(filename))
        end if
     end if

      do n = 1, numbsteps
         fac = ct / frequency
         if(1 == mod(it, 2)) then
            call set_modelgrid(model0, model1, model, fac)
         else
            call set_modelgrid(model1, model0, model, fac)
         end if
         call advance_trajectory(model, traject, dt)
         fac = ct+pt
         call output_trajectory(traject, n, fac)
         ct = ct + dt
      end do
  
      ct = 0.0
      pt = pt + frequency
      it = it + 1
   end do

   call finalize_trajectory(traject)

   call finalize_modelgrid(model0)
   call finalize_modelgrid(model1)

END PROGRAM trajectory

