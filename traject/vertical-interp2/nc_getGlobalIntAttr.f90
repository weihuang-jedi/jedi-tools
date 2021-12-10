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
!----------------------------------------------------------------------------------
subroutine nc_getGlobalIntAttr(ncid,desc,var)
   use netcdf
   implicit none
   integer, intent(in) :: ncid
   character(len=*), intent(in) :: desc
   integer, intent(out) :: var
   integer :: status
   status = nf90_get_att(ncid, NF90_GLOBAL, desc, var)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to get att: <", trim(desc), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(a, i6)') "ncid=", ncid
       write(unit=0, fmt='(a, i6)') "var=", var
       write(unit=0, fmt='(3a,i6)') "file: ", "nc_getGlobalIntAttr.F90", ", line: ", 23
       stop
   end if
end subroutine nc_getGlobalIntAttr
