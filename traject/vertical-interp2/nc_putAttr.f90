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
!--------------------------------------------------------------------------------------------
subroutine nc_putAttr(ncid, nd, dimids, xtype, var_name, &
                      long_name, units, coordinates, missing_real)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nd, xtype
   integer, dimension(6), intent(in) :: dimids
   character(len=*), intent(in) :: var_name, long_name, units, coordinates
   real, intent(in) :: missing_real
!--Variable id
   integer :: varid, md
!--Return rc
   integer :: rc
   md = nd
   if(md > 6) then
       write(unit=0, fmt='(a, i6)') "We can only handle data up to 5d. but here nd = ", nd
   endif
   rc = nf90_def_var(ncid, trim(var_name), xtype, dimids(1:md), varid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a, i6)') "ncid: ", ncid
      write(unit=0, fmt='(a, 6i6)') "dimids: ", dimids(1:md)
      write(unit=0, fmt='(3a)') "Problem to def varid for: <", trim(var_name), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 34
      stop
   endif
   rc = nf90_put_att(ncid, varid, "long_name", trim(long_name))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute long_name: <", trim(long_name), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 43
      stop
   endif
   rc = nf90_put_att(ncid, varid, "units", trim(units))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute units: <", trim(units), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 52
      stop
   endif
   rc = nf90_put_att(ncid, varid, "_CoordinateAxes", trim(coordinates))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute coordinates: <", trim(coordinates), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_putAttr.F90", ">, line: ", 61
      stop
   endif
   rc = nf90_put_att(ncid, varid, "_FillValue", missing_real)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a, f12.2)') "Problem to write attribute missing_real: ", missing_real
      write(unit=0, fmt='(3a)') "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 70
      stop
   endif
end subroutine nc_putAttr
!--------------------------------------------------------------------------------------------
subroutine nc_putAttrInt(ncid, nd, dimids, xtype, var_name, &
                         long_name, units, coordinates, missing_int)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nd, xtype
   integer, dimension(6), intent(in) :: dimids
   character(len=*), intent(in) :: var_name, long_name, units, coordinates
   integer, intent(in) :: missing_int
!--Variable id
   integer :: varid, md
!--Return rc
   integer :: rc
   md = nd
   if(md > 6) then
       write(unit=0, fmt='(a, i6)') "We can only handle data up to 5d. but here nd = ", nd
   endif
!--Always set the extra dimension unlimited.
! dimids(nd+1) = nf90_unlimited
   rc = nf90_def_var(ncid, trim(var_name), xtype, dimids(1:md), varid)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a, i6)') "ncid: ", ncid
      write(unit=0, fmt='(a, 6i6)') "dimids: ", dimids(1:md)
      write(unit=0, fmt='(3a)') "Problem to def varid for: <", trim(var_name), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 112
      stop
   endif
   rc = nf90_put_att(ncid, varid, "long_name", trim(long_name))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute long_name: <", trim(long_name), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 121
      stop
   endif
   rc = nf90_put_att(ncid, varid, "units", trim(units))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute units: <", trim(units), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 130
      stop
   endif
   rc = nf90_put_att(ncid, varid, "_CoordinateAxes", trim(coordinates))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute coordinates: <", trim(coordinates), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_putAttr.F90", ">, line: ", 139
      stop
   endif
   rc = nf90_put_att(ncid, varid, "_FillValue", missing_int)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a, f12.2)') "Problem to write attribute missing_int: ", missing_int
      write(unit=0, fmt='(3a)') "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 148
      stop
   endif
end subroutine nc_putAttrInt
!--------------------------------------------------------------------------------------------
subroutine nc_putAttrWithChunking(ncid, nd, dimids, chunksizes, xtype, var_name, &
                                  long_name, units, coordinates, missing_real)
   use netcdf
   implicit none
   integer, intent(in) :: ncid, nd, xtype
   integer, dimension(6), intent(in) :: dimids, chunksizes
   character(len=*), intent(in) :: var_name, long_name, units, coordinates
   real, intent(in) :: missing_real
!--Variable id
   integer :: varid, md
   integer, parameter :: deflate_level = 2
!--Return rc
   integer :: rc
   md = nd
   if(md > 6) then
       write(unit=0, fmt='(a, i6)') "We can only handle data up to 5d. but here nd = ", nd
   endif
  !rc = nf90_def_var(ncid, trim(var_name), xtype, dimids(1:md), varid)
  ! fletcher32 = .true., endianness = nf90_endian_big,
   rc = nf90_def_var(ncid, trim(var_name), xtype, dimids(1:md), varid, &
                     chunksizes = chunksizes(1:md), shuffle = .true., &
                     fletcher32 = .true., deflate_level = deflate_level)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a, i6)') "ncid: ", ncid
      write(unit=0, fmt='(a, 6i6)') "dimids: ", dimids(1:md)
      write(unit=0, fmt='(3a)') "Problem to def varid for: <", trim(var_name), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 192
      stop
   endif
   rc = nf90_put_att(ncid, varid, "long_name", trim(long_name))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute long_name: <", trim(long_name), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 201
      stop
   endif
   rc = nf90_put_att(ncid, varid, "units", trim(units))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute units: <", trim(units), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 210
      stop
   endif
   rc = nf90_put_att(ncid, varid, "_CoordinateAxes", trim(coordinates))
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write attribute coordinates: <", trim(coordinates), ">.", &
                                "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
          "Stop in file: <", "nc_putAttr.F90", ">, line: ", 219
      stop
   endif
   rc = nf90_put_att(ncid, varid, "_FillValue", missing_real)
   if(rc /= nf90_noerr) then
      write(unit=0, fmt='(a, f12.2)') "Problem to write attribute missing_real: ", missing_real
      write(unit=0, fmt='(3a)') "Error rc: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", "nc_putAttr.F90", ">, line: ", 228
      stop
   endif
end subroutine nc_putAttrWithChunking
