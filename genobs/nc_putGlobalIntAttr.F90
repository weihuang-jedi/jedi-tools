!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine nc_putGlobalIntAttr(ncid,desc,var)

   use netcdf

   implicit none
 
   integer, intent(in) :: ncid, var
   character(len = *), intent(in) :: desc
   integer :: status

   status = nf90_put_att(ncid, NF90_GLOBAL, trim(desc), var)

   if(status /= nf90_noerr) then 
       write(unit=0, fmt='(3a)') "Problem to put att: <", trim(desc), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))

       write(unit=0, fmt='(3a,i6)') "file: ", __FILE__, ", line: ", __LINE__
       write(unit=0, fmt='(a, i6)') "ncid=", ncid
       write(unit=0, fmt='(2a)') "desc=", desc
       write(unit=0, fmt='(a, i12)') "var=", var
       stop
   end if

end subroutine nc_putGlobalIntAttr

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine nc_putGlobalLongAttr(ncid,desc,var)

   use netcdf

   implicit none

   integer, intent(in) :: ncid
   integer(kind=8), intent(in) :: var
   character(len = *), intent(in) :: desc
   integer :: status

   status = nf90_put_att(ncid, NF90_GLOBAL, trim(desc), var)

   if(status /= nf90_noerr) then
       write(unit=0, fmt='(3a)') "Problem to put att: <", trim(desc), ">.", &
                                 "Error status: ", trim(nf90_strerror(status))

       write(unit=0, fmt='(3a,i6)') "file: ", __FILE__, ", line: ", __LINE__
       write(unit=0, fmt='(a, i6)') "ncid=", ncid
       write(unit=0, fmt='(2a)') "desc=", desc
       write(unit=0, fmt='(a, i12)') "var=", var
       stop
   end if

end subroutine nc_putGlobalLongAttr

