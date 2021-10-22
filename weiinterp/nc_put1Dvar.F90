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

!--Return status
   integer :: status

   integer :: start(2), count(2)

   start(1) = m1s
   start(2) = nrec

   count(1) = m1e - m1s + 1
   count(2) = 1

   status = nf90_inq_varid(ncid, trim(var_name), varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

   status = nf90_put_var(ncid,varid,v1d,start=start,count=count)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
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

!--Return status
   integer :: status

   integer :: start(1), count(1)

   start(1) = m1s

   count(1) = m1e - m1s + 1

   status = nf90_inq_varid(ncid, trim(var_name), varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

  !print *, 'var_name=', trim(var_name)
  !print *, 'ncid,varid=', ncid,varid
  !print *, 'v1d=', v1d

   status = nf90_put_var(ncid,varid,v1d,start=start,count=count)
  !status = nf90_put_var(ncid,varid,v1d)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
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

!--Return status
   integer :: status

   integer :: start(1), count(1)

   start(1) = m1s

   count(1) = m1e - m1s + 1

   status = nf90_inq_varid(ncid, trim(var_name), varid)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to get varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

  !print *, 'var_name=', trim(var_name)
  !print *, 'ncid,varid=', ncid,varid
  !print *, 'v1d=', v1d

   status = nf90_put_var(ncid,varid,v1d,start=start,count=count)
  !status = nf90_put_var(ncid,varid,v1d)
   if(status /= nf90_noerr) then
      write(unit=0, fmt='(3a)') "Problem to write variable: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(status))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   end if

end subroutine nc_put1Ddbl0

