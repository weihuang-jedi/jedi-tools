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
subroutine nc_put1Dvar(ncid, var_name, v1d, nrec, &
                       m1s, m1e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nrec
   integer, intent(in) :: m1s, m1e
   character(len=*), intent(in) :: var_name
   real, dimension(m1s:m1e), intent(in) :: v1d
!--Variable id
   integer :: varid
!--Return Code
   integer :: rc
   integer :: start(2), length(2)
   start(1) = m1s
   start(2) = nrec
   length(1) = m1e - m1s + 1
   length(2) = 1
   rc = nf90_inq_varid(ncid, trim(var_name), varid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_put1Dvar.F90", ">, line: ", 34
      stop
   end if
   rc = nf90_put_var(ncid,varid,v1d,start=start,count=length)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_put1Dvar.F90", ">, line: ", 43
      stop
   end if
end subroutine nc_put1Dvar
!----------------------------------------------------------------------------------
subroutine nc_put1Dvar0(ncid, var_name, v1d, m1s, m1e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, m1s, m1e
   character(len=*), intent(in) :: var_name
   real, dimension(m1s:m1e), intent(in) :: v1d
!--Variable id
   integer :: varid
!--Return Code
   integer :: rc
   integer :: start(1), length(1)
   start(1) = m1s
   length(1) = m1e - m1s + 1
   rc = nf90_inq_varid(ncid, trim(var_name), varid)
  !print *, 'var_name=', trim(var_name)
  !print *, 'ncid,varid=', ncid,varid
  !print *, 'rc=', rc
  !print *, 'v1d=', v1d
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_put1Dvar.F90", ">, line: ", 83
      stop
   end if
   rc = nf90_put_var(ncid,varid,v1d,start=start,count=length)
  !rc = nf90_put_var(ncid,varid,v1d)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_put1Dvar.F90", ">, line: ", 93
      stop
   end if
end subroutine nc_put1Dvar0
!----------------------------------------------------------------------------------
subroutine nc_put1Ddbl0(ncid, var_name, v1d, m1s, m1e)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, m1s, m1e
   character(len=*), intent(in) :: var_name
   real(kind=8), dimension(m1s:m1e), intent(in) :: v1d
!--Variable id
   integer :: varid
!--Return Code
   integer :: rc
   integer :: start(1), length(1)
   start(1) = m1s
   length(1) = m1e - m1s + 1
   rc = nf90_inq_varid(ncid, trim(var_name), varid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_put1Dvar.F90", ">, line: ", 128
      stop
   end if
  !print *, 'var_name=', trim(var_name)
  !print *, 'ncid,varid=', ncid,varid
  !print *, 'v1d=', v1d
   rc = nf90_put_var(ncid,varid,v1d,start=start,count=length)
  !rc = nf90_put_var(ncid,varid,v1d)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_put1Dvar.F90", ">, line: ", 142
      stop
   end if
end subroutine nc_put1Ddbl0
