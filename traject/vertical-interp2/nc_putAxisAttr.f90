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
! $URL: file:///neem/users/huangwei/.vdras_source_code/SVN_REPOSITORY/trunk/vdras/io/netcdf4/nc_putAttr.F90 $
! $Rev: 144 $
! $Author: huangwei $
! $Date: 2010-11-15 10:33:52 -0700 (Mon, 15 Nov 2010) $
! $Id: nc_putAttr.F90 144 2010-11-15 17:33:52Z huangwei $
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine nc_putAxisAttr(ncid, nd, dimid, xtype, var_name, &
                      desc, units, coordinates)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nd, xtype
   integer, dimension(6), intent(in) :: dimid
   character(len=*), intent(in) :: var_name, desc, units, coordinates
! real, intent(in) :: missing_real
! real, intent(in), optional :: missing_real
! integer, intent(in), optional :: missing_int
!--Variable id
   integer :: varid, md
!--Return status
   integer :: status
   md = nd
   if(md > 6) then
       write(unit=0, fmt='(a, i6)') "We can only handle data up to 5d. but here nd = ", nd
   endif
!--Always set the extra dimension unlimited.
! dimid(nd+1) = nf90_unlimited
   status = nf90_def_var(ncid, trim(var_name), xtype, dimid(1:md), varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(a, i6)') "ncid: ", ncid
      write(unit=0, fmt='(a, 6i6)') "dimid: ", dimid(1:md)
      write(unit=0, fmt='(3a)') "Problem to def varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAxisAttr.F90", ">, line: ", 47
      stop
   endif
! status = nf90_put_att(ncid, varid, "description", trim(desc))
   status = nf90_put_att(ncid, varid, "long_name", trim(desc))
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute description: <", trim(desc), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAxisAttr.F90", ">, line: ", 57
      stop
   endif
! status = nf90_put_att(ncid, varid, "long_name", trim(var_name))
! if(status /= nf90_noerr) then
! write(unit=0, fmt='(3a)') "Problem to write attribute long_name: <", trim(var_name), ">.", &
! "Error status: ", trim(nf90_strerror(status))
! write(unit=0, fmt='(3a, i4)') &
! "Stop in file: <", "nc_putAxisAttr.F90", ">, line: ", 66
! stop
! endif
   status = nf90_put_att(ncid, varid, "units", trim(units))
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute units: <", trim(units), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAxisAttr.F90", ">, line: ", 75
      stop
   endif
   status = nf90_put_att(ncid, varid, "_CoordinateAxisType", trim(coordinates))
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute coordinates: <", trim(coordinates), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_putAxisAttr.F90", ">, line: ", 84
      stop
   endif
! if(present(missing_real)) then
! status = nf90_put_att(ncid, varid, "_FillValue", missing_real)
! if(status /= nf90_noerr) then
! write(unit=0, fmt='(a, f12.2)') "Problem to write attribute missing_real: ", missing_real
! write(unit=0, fmt='(3a)') "Error status: ", trim(nf90_strerror(status))
! write(unit=0, fmt='(3a, i4)') &
! "Stop in file: <", "nc_putAxisAttr.F90", ">, line: ", 94
! stop
! endif
! endif
end subroutine nc_putAxisAttr
