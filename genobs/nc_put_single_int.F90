!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! svn propset svn:keywords "URL Rev Author Date Id"
! $URL: file:///data/zhuming/.vdras_source_code/SVN_REPOSITORY/VDRAS/trunk/vdras/io/netcdf4/nc_put_single_int.F90 $
! $Rev: 288 $
! $Author: zhuming $
! $Date: 2013-01-03 13:42:37 -0700 (Thu, 03 Jan 2013) $
! $Id: nc_put_single_int.F90 288 2013-01-03 20:42:37Z zhuming $
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine nc_put_single_int(ncid, var_name, iv, nrec)

   use netcdf

   implicit none
 
   integer,          intent(in) :: ncid, nrec, iv
   character(len=*), intent(in) :: var_name

!--Variable id
   integer :: varid

!--Return status
   integer :: status

!  integer, dimension(2) :: start, count, nv
   integer, dimension(1) :: start, count, nv

   nv(1) = iv

!  start(1) = 1
   start(1) = nrec
!  start(2) = nrec
   count(1) = 1
!  count(2) = 1

   status = nf90_inq_varid(ncid, trim(var_name), varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

   status = nf90_put_var(ncid, varid, nv, start=start, count=count)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

end subroutine nc_put_single_int

