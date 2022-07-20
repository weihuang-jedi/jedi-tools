!--------------------------------------------------------------------------------------------

subroutine nc_putAttr(ncid, nd, xtype, dimid, var_name, varid)

   use netcdf

   implicit none
 
   integer, intent(in) :: ncid, nd, xtype
   integer, dimension(6), intent(in) :: dimid
   character(len=*), intent(in) :: var_name
   integer, intent(out) :: varid

!--Return status
   integer :: rc

   if(nd > 6) then
       write(unit=0, fmt='(a, i6)') "We can only handle data up to 5d. but here nd = ", nd
   endif

!--Always set the extra dimension unlimited.
!  dimid(nd+1) = nf90_unlimited

   rc = nf90_def_var(ncid, trim(var_name), xtype, dimid(1:nd), varid)
   if(rc /= nf90_noerr) then 
      write(unit=0, fmt='(a, i6)') "ncid: ", ncid
      write(unit=0, fmt='(a, 6i6)') "dimid: ", dimid(1:nd)
      write(unit=0, fmt='(3a)') "Problem to def varid for: <", trim(var_name), ">.", &
                                "Error status: ", trim(nf90_strerror(rc))
      write(unit=0, fmt='(3a, i4)') &
           "Stop in file: <", __FILE__, ">, line: ", __LINE__
      stop
   endif

end subroutine nc_putAttr

