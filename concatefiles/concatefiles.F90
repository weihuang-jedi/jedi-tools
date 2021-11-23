!--------------------------------------------------------------------
PROGRAM concatefiles

   use namelist_module
   use grid_module

   IMPLICIT NONE

   type(gridtype) :: atm, ocn, ice, whole

   call read_namelist('input.nml')

   call initialize_grid(atm, trim(atmname), 'atm')
   call initialize_grid(ocn, trim(ocnname), 'ocn')
   call initialize_grid(ice, trim(icename), 'ice')

   call generate_header(atm, ocn, ice, whole)

   call process(atm, ocn, ice, whole)

   call finalize_grid(atm)
   call finalize_grid(ocn)
   call finalize_grid(ice)

END PROGRAM concatefiles

