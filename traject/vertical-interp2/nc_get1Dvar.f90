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
subroutine nc_get1Dvar(ncid, var_name, var, nrec, &
                       nzs, nze)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nrec
   integer, intent(in) :: nzs, nze
   character(len = *), intent(in) :: var_name
   real*4, dimension(nzs:nze), intent(out) :: var
   integer, dimension(2) :: start, count
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(3a, i4)') &
            "Stop in file: <", "nc_get1Dvar.F90", ">, line: ", 29
       stop
   end if
   start(1) = nzs
   start(2) = nrec
   count(1) = nze - nzs + 1
   count(2) = 1
   status = nf90_get_var(ncid,varid,var,start=start,count=count)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to read: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(3a, i4)') &
            "Stop in file: <", "nc_get1Dvar.F90", ">, line: ", 44
       stop
   end if
end subroutine nc_get1Dvar
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine nc_get1Dvar0(ncid, var_name, var, nzs, nze)
   use netcdf
   implicit none
   integer, intent(in) :: ncid
   integer, intent(in) :: nzs, nze
   character(len = *), intent(in) :: var_name
   real*4, dimension(nzs:nze), intent(out) :: var
   integer, dimension(1) :: start, count
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(3a, i4)') &
            "Stop in file: <", "nc_get1Dvar.F90", ">, line: ", 77
       stop
   end if
   start(1) = nzs
   count(1) = nze - nzs + 1
   status = nf90_get_var(ncid,varid,var,start=start,count=count)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to read: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(3a, i4)') &
            "Stop in file: <", "nc_get1Dvar.F90", ">, line: ", 90
       stop
   end if
end subroutine nc_get1Dvar0
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine nc_get1Ddbl0(ncid, var_name, var, nzs, nze)
   use netcdf
   implicit none
   integer, intent(in) :: ncid
   integer, intent(in) :: nzs, nze
   character(len = *), intent(in) :: var_name
   real(kind=8), dimension(nzs:nze), intent(out) :: var
   integer, dimension(1) :: start, count
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(3a, i4)') &
            "Stop in file: <", "nc_get1Dvar.F90", ">, line: ", 123
       stop
   end if
   start(1) = nzs
   count(1) = nze - nzs + 1
   status = nf90_get_var(ncid,varid,var,start=start,count=count)
   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to read: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
       write(unit=0, fmt='(3a, i4)') &
            "Stop in file: <", "nc_get1Dvar.F90", ">, line: ", 136
       stop
   end if
end subroutine nc_get1Ddbl0
