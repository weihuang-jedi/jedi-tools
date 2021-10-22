!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! svn propset svn:keywords "URL Rev Author Date Id"
! $URL: file:///neem/users/huangwei/.vdras_source_code/SVN_REPOSITORY/trunk/vdras/io/netcdf4/nc_putAttr.F90 $
! $Rev: 144 $
! $Author: huangwei $
! $Date: 2010-11-15 10:33:52 -0700 (Mon, 15 Nov 2010) $
! $Id: nc_putAttr.F90 144 2010-11-15 17:33:52Z huangwei $
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine nc_putAxisAttr(ncid, nd, dimid, var_name, varid)

   use netcdf

   implicit none
 
   integer, intent(in) :: ncid, nd
   integer, dimension(6), intent(in) :: dimid
   character(len=*), intent(in) :: var_name
   integer, intent(out) :: varid

!  real,    intent(in) :: missing_real
!  real,    intent(in), optional :: missing_real
!  integer, intent(in), optional :: missing_int

!--Variable id
   integer :: md

!--Return status
   integer :: status

   md = nd

   if(md > 6) then
       write(unit=0, fmt='(a, i6)') "We can only handle data up to 5d. but here nd = ", nd
   endif

   status = nf90_def_var(ncid, trim(var_name), NF90_REAL, dimid(1:md), varid)
   if(status /= nf90_noerr) then 
      write(unit=0, fmt='(a, i6)') "ncid: ", ncid
      write(unit=0, fmt='(a, 6i6)') "dimid: ", dimid(1:md)
      write(unit=0, fmt='(3a)') "Problem to def varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   endif

end subroutine nc_putAxisAttr

