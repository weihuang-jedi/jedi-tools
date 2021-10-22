!--------------------------------------------------------------------
PROGRAM create_obs

   use namelist_module
   use obs_module

   implicit none

   type(obsgrid)       :: obs

   call read_namelist('input.nml')

   call initialize_obsgrid(obs, filename)

   call output_obs(obs, output_flnm)

   call finalize_obsgrid(obs)

END PROGRAM create_obs

