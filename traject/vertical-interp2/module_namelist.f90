/* Copyright (C) 1991-2012 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */
/* This header is separate from features.h so that the compiler can
   include it implicitly at the start of every compilation.  It must
   not itself include <features.h> or any other header that includes
   <features.h> because the implicit include comes before any feature
   test macros that may be defined in a source file before it first
   explicitly includes a system header.  GCC knows the name of this
   header in order to preinclude it.  */
/* We do support the IEC 559 math functionality, real and complex.  */
/* wchar_t uses ISO/IEC 10646 (2nd ed., published 2011-03-15) /
   Unicode 6.0.  */
/* We do not support C11 <threads.h>.  */
!-------------------------------------------------------------
MODULE namelist_module
  implicit none
  integer, parameter :: nml_unit = 7
  character(len=1024) :: program_name, input_flnm, output_flnm
  integer :: nalt
  real :: dz
  logical :: debug_on
contains
  subroutine read_namelist(file_path)
    implicit none
   !Reads Namelist from given file.
    character(len=*), intent(in) :: file_path
    integer :: rc
   !Namelist definition.
    namelist /control_param/ program_name, input_flnm, &
                             output_flnm, nalt, dz, debug_on
    program_name = 'Vertical Interpolation'
    input_flnm = '../data/gfs_4_20210101_0000_000.nc'
    output_flnm = 'verticalheight.nc'
    nalt = 101
    dz = 500.0
    debug_on = .false.
   !Check whether file exists.
    inquire(file=file_path, iostat=rc)
    if(rc /= 0) then
      write(unit=0, fmt='(3a)') 'Error: input file <', &
                                 trim(file_path), '> does not exist.'
      return
    end if
   !Open and read Namelist file.
    open(action='read', file=file_path, iostat=rc, unit=nml_unit)
    read(nml=control_param, iostat=rc, unit=nml_unit)
    if(rc /= 0) then
      write(unit=0, fmt='(a)') 'Error: invalid Namelist format.'
    end if
    close(nml_unit)
  end subroutine read_namelist
END MODULE namelist_module
