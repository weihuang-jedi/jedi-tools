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
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! svn propset svn:keywords "URL Rev Author Date Id"
! $URL: file:///data/zhuming/.vdras_source_code/SVN_REPOSITORY/VDRAS/trunk/vdras/io/netcdf4/nc_put5Dvar.F90 $
! $Rev: 144 $
! $Author: huangwei $
! $Date: 2010-11-15 10:33:52 -0700 (Mon, 15 Nov 2010) $
! $Id: nc_put5Dvar.F90 144 2010-11-15 17:33:52Z huangwei $
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine nc_put5Dvar(ncid, var_name, v5d, nrec, &
                      m1s, m1e, m2s, m2e, m3s, m3e, m4s, m4e, m5s, m5e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nrec
   integer, intent(in) :: m1s, m1e, m2s, m2e, m3s, m3e, m4s, m4e, m5s, m5e
   character(len=*), intent(in) :: var_name
   real, dimension(m1s:m1e, m2s:m2e, m3s:m3e, m4s:m4e, m5s:m5e), intent(in) :: v5d
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   integer, dimension(5) :: start, count
   start(1) = m1s
   start(2) = m2s
   start(3) = m3s
   start(4) = m4s
   start(5) = m5s
! start(6) = nrec
   count(1) = m1e - m1s + 1
   count(2) = m2e - m2s + 1
   count(3) = m3e - m3s + 1
   count(4) = m4e - m4s + 1
   count(5) = m5e - m5s + 1
! count(6) = 1
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put5Dvar.F90", ">, line: ", 49
      stop
   end if
   status = nf90_put_var(ncid,varid,v5d,start=start,count=count)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(a, 6i6)') 'start=', start
      write(unit=0, fmt='(a, 6i6)') 'count=', count
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put5Dvar.F90", ">, line: ", 60
      stop
   end if
end subroutine nc_put5Dvar
