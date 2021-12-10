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
!---------------------------------------------------
subroutine nc_put3Dvar(ncid, var_name, v3d, nrec, &
                       m1s, m1e, m2s, m2e, m3s, m3e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nrec
   integer, intent(in) :: m1s, m1e, m2s, m2e, m3s, m3e
   character(len=*), intent(in) :: var_name
   real, dimension(m1s:m1e, m2s:m2e, m3s:m3e), intent(in) :: v3d
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   integer, dimension(4) :: start, count
   start(1) = m1s
   start(2) = m2s
   start(3) = m3s
   start(4) = nrec
   count(1) = m1e - m1s + 1
   count(2) = m2e - m2s + 1
   count(3) = m3e - m3s + 1
   count(4) = 1
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put3Dvar.F90", ">, line: ", 37
      stop
   end if
   status = nf90_put_var(ncid,varid,v3d,start=start,count=count)
   if(status /= nf90_noerr) then
          write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put3Dvar.F90", ">, line: ", 46
      stop
   end if
end subroutine nc_put3Dvar
!---------------------------------------------------
subroutine nc_put3Dvar0(ncid, var_name, v3d, &
                        m1s, m1e, m2s, m2e, m3s, m3e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid
   integer, intent(in) :: m1s, m1e, m2s, m2e, m3s, m3e
   character(len=*), intent(in) :: var_name
   real, dimension(m1s:m1e, m2s:m2e, m3s:m3e), intent(in) :: v3d
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   integer, dimension(3) :: start, count
   start(1) = m1s
   start(2) = m2s
   start(3) = m3s
   count(1) = m1e - m1s + 1
   count(2) = m2e - m2s + 1
   count(3) = m3e - m3s + 1
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put3Dvar.F90", ">, line: ", 86
      stop
   end if
   status = nf90_put_var(ncid,varid,v3d,start=start,count=count)
   if(status /= nf90_noerr) then
          write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put3Dvar.F90", ">, line: ", 95
      stop
   end if
end subroutine nc_put3Dvar0
!---------------------------------------------------
subroutine nc_put3Dvar1(ncid, var_name, v2d, nrec, &
                        m1s, m1e, m2s, m2e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nrec
   integer, intent(in) :: m1s, m1e, m2s, m2e
   character(len=*), intent(in) :: var_name
   real, dimension(m1s:m1e, m2s:m2e), intent(in) :: v2d
 ! Variable id
   integer :: varid
 ! Return status
   integer :: status
   integer, dimension(3) :: start, count
   start(1) = m1s
   start(2) = m2s
   start(3) = nrec
   count(1) = m1e - m1s + 1
   count(2) = m2e - m2s + 1
   count(3) = 1
   status = nf90_inq_varid(ncid, var_name, varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get id for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put3Dvar.F90", ">, line: ", 135
      stop
   end if
   status = nf90_put_var(ncid,varid,v2d,start=start,count=count)
   if(status /= nf90_noerr) then
          write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_put3Dvar.F90", ">, line: ", 144
      stop
   end if
end subroutine nc_put3Dvar1
