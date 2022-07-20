!----------------------------------------------------------------------------------------

subroutine output_obs(obs)

   use netcdf
   use namelist_module
   use obs_module

   implicit none

   type(obsgrid), intent(in) :: obs

   integer :: ncid, dimidvars, dimidlocs, dimidstring, dimiddatetime
   integer :: i, k, n, rc, nvar, nvars, nlocs, nstring, ndatetime
   integer, dimension(50) :: iv
   integer, dimension(6) :: dimids, start, length
   integer :: xtype, ndims, nGlobalAtts, unlimdimid, natts

   real, dimension(50) :: fv

   character(len=1), parameter :: delimiter = '@'
   character(len=50), dimension(numobs) :: cv
   character(len=20), dimension(numobs) :: ltstr
   character(len=256) :: varname
   character(len=4096) :: cmdstr
   character(len=128) :: obsname, obstype
   integer, parameter  :: nmax = 100
   integer :: nreal
   integer, dimension(nmax) :: varids
   character(len=256), dimension(nmax) :: varlist

   logical :: keepit, file_exists

   CHARACTER(LEN=8)  :: datestr
   CHARACTER(LEN=10) :: timestr
   CHARACTER(LEN=5)  :: timezone
   integer(kind=8)   :: longdatetime

   CALL DATE_AND_TIME(DATE=datestr, TIME=timestr, ZONE=timezone)

   nreal = 0
   rc = nf90_noerr

   start(1) = 1
   length(1) = numobs

   INQUIRE(FILE=trim(output_flnm), EXIST=file_exists)

   if(file_exists) then
     print *, 'File ', trim(output_flnm), ' already exist. it is remved first.'
     cmdstr = 'rm '//trim(output_flnm)
     call system(trim(cmdstr))
   end if

   !Create the file. 
  !rc = nf90_create(trim(output_flnm), NF90_CLOBBER, ncid)
   rc = nf90_create(trim(output_flnm), NF90_NETCDF4, ncid)
   call check_rc(rc)

   nvar = 1
  !nvars = 6 - numskipvars
  !nvars = numkeptvars
   nlocs = numobs
   nstring = 50
   ndatetime = 20

   rc = nf90_def_dim(ncid, 'nvars', nvar, dimidvars)
   call check_rc(rc)

   rc = nf90_def_dim(ncid, 'nlocs', nlocs, dimidlocs)
  !rc = nf90_def_dim(ncid, 'nlocs', NF90_UNLIMITED, dimidlocs)
   call check_rc(rc)

   rc = nf90_def_dim(ncid, 'nstring', nstring, dimidstring)
   call check_rc(rc)

   rc = nf90_def_dim(ncid, 'ndatetime', ndatetime, dimiddatetime)
   call check_rc(rc)

  !print *, 'output global attr'

   call output_global_attr(ncid, output_flnm, 'Manually Created Observations', 'Observation')

  !longdatetime = 2021010900
   read(date_time,*,iostat=rc)  longdatetime
   print *, 'longdatetime = ', longdatetime
   call nc_putGlobalIntAttr(ncid, 'nvars', nvar)
   call nc_putGlobalIntAttr(ncid, 'nlocs', nlocs)
  !call nc_putGlobalLongAttr(ncid, 'date_time', longdatetime)
   rc = nf90_put_att(ncid, NF90_GLOBAL, 'date_time', 2021010900)
   call check_rc(rc)
   cmdstr = 'Created '//trim(datestr)//' '//trim(timestr)//' '//trim(timezone)
   call nc_putGlobalCharAttr(ncid, 'history', trim(cmdstr))

  !print *, 'output var attr'

   call output_var_attr(ncid, dimidvars, dimidlocs, dimidstring, dimiddatetime, &
                        obs, nmax, nreal, varids, varlist)

  !print *, 'varids = ', varids(1:nreal)
   rc= nf90_inquire(ncid, ndims, nvars, nGlobalAtts, unlimdimid)
   call check_rc(rc)

   rc= nf90_inq_varids(ncid, nvars, varids(1:nreal))
   call check_rc(rc)
  !print *, 'varids = ', varids(1:nreal)

   print *, 'Number of obs vars in orignal file = ', obs%nVars
   print *, 'Number of obs vars in created file = ', nvars

   do n = 1, nstring
     iv(n) = n
     fv(n) = real(n)
     write(cv(n), fmt='(i5)') n
   end do

   !write nvars
   call nc_put1Dvar0(ncid, 'nvars', fv(1:nvar), 1, 1)

   !write nlocs
   call nc_put1Dvar0(ncid, 'nlocs', fv(1:nlocs), 1, nlocs)

   !write nstring
   call nc_put1Dvar0(ncid, 'nstring', fv(1:nstring), 1, nstring)

   !write ndatetime
   call nc_put1Dvar0(ncid, 'ndatetime', fv(1:ndatetime), 1, ndatetime)

   n = 4
   do i = 1, obs%nVars
    !rc= nf90_inquire_variable(obs%fileid, obs%varids(i), &
    !         name=obs%vars(i)%varname)
    !call check_rc(rc)

     call split_string(obs%vars(i)%varname, obsname, obstype, delimiter)
    !print *, 'Var ', i, ': ', trim(varname)
    !print *, 'obsname = ', trim(obsname), ', obstype = ', trim(obstype)

     call checkvar(obsname, keepit)
    !print *, 'Keep Var ', i, ': <', trim(obs%vars(i)%varname), '> = ', keepit

    !if(.not. keepit) then
    ! !print *, 'Skip var ', i, ': ', trim(obs%vars(i)%varname)
    !  cycle
    !end if

     n = n + 1
     xtype = obs%vars(i)%xtype

    !print *, ' '
     write(unit=6, fmt='(a, i3, 3a)') 'Orig Var ', i, ': <', trim(obs%vars(i)%varname), '>'
     write(unit=6, fmt='(a, i3, 3a)') ' New Var ', n, ': <', trim(varlist(n)), '>'

    !print *, 'xtype = ', obs%vars(i)%xtype, ', dimids = ', obs%vars(i)%dimids(1:obs%vars(i)%nDims)

     rc= nf90_inquire_variable(ncid, varids(n), varname)
     call check_rc(rc)

    !print *, 'File: ', __FILE__, ', line: ', __LINE__
    !print *, 'ncid: ', ncid, ', varids(', n, ') = ', varids(n), ', name: <', trim(varname), '>'

     if(obs%vars(i)%xtype == NF90_INT) then
       rc = nf90_get_var(obs%fileid, obs%varids(i), iv(1:length(1)), start(1:1), length(1:1))
       call check_rc(rc)
      !print *, 'iv = ', iv

       if('record_number' == trim(obsname)) then
        !print *, 'File: ', __FILE__, ', line: ', __LINE__
         do k = 1, numobs
           iv(k) = k - 1
         end do
      !else if('air_temperature' == trim(obsname)) then
       else if('surface_pressure' == trim(obsname)) then
         if(('PreQC' == trim(obstype)) .or. ('PreUseFlag' == trim(obstype))) then
           do k = 1, numobs
             iv(k) = 0
           end do
         else if('GsiUseFlag' == trim(obstype)) then
           do k = 1, numobs
             iv(k) = 1
           end do
         else if('ObsType' == trim(obstype)) then
           do k = 1, numobs
             iv(k) = 181
           end do
         end if
       else
         if('PreQC' == trim(obstype)) then
           if(.not. keepit) then
             do k = 1, numobs
               iv(k) = 100
             end do
           end if
         end if
       end if
      !print *, 'iv = ', iv
       rc = nf90_put_var(ncid, varids(n), iv(1:length(1)), start(1:1), length(1:1))
       call check_rc(rc)
     else if(obs%vars(i)%xtype == NF90_REAL) then
       rc = nf90_get_var(obs%fileid, obs%varids(i), fv(1:length(1)), start(1:1), length(1:1))
       call check_rc(rc)
      !print *, 'fv = ', fv

       if('MetaData' == trim(obstype)) then
         if('latitude' == trim(obsname)) then
           do k = 1, numobs
             fv(k) = lat(k)
           end do
         else if('longitude' == trim(obsname)) then
           do k = 1, numobs
             fv(k) = lon(k)
           end do
         else if('air_pressure' == trim(obsname)) then
           do k = 1, numobs
             fv(k) = prs(k)
           end do
         else if(('height' == trim(obsname)) .or. &
                 ('time' == trim(obsname)) .or. &
                 ('station_elevation' == trim(obsname))) then
           do k = 1, numobs
             fv(k) = 0.0
           end do
         end if
       end if
      !if('air_temperature' == trim(obsname)) then
       if('surface_pressure' == trim(obsname)) then
         if('ObsError' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = obserr(k)
           end do
         else if('ObsValue' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = tmp(k) + omb(k)
           end do
         else if('GsiHofX' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = tmp(k)
           end do
         else if('GsiHofXBc' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = tmp(k)
           end do
         else if('GsiFinalObsError' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = obserr(k)
           end do
         else if('GsiAdjustObsError' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = obserr(k)
           end do
         else if('GsiQCWeight' == trim(obstype)) then
           do k = 1, numobs
             fv(k) = 4.0
           end do
         end if
       end if
      !print *, 'fv = ', fv
       rc = nf90_put_var(ncid, varids(n), fv(1:length(1)), start(1:1), length(1:1))
       call check_rc(rc)
     else if(obs%vars(i)%xtype == NF90_CHAR) then
       if(('station_id@MetaData' == trim(obs%vars(i)%varname)) .or. &
          ('LaunchTime@MetaData' == trim(obs%vars(i)%varname))) then
         if('station_id@MetaData' == trim(obs%vars(i)%varname)) then
           start(1) = 1
           length(1) = nstring
           start(2) = 1
           length(2) = numobs

          !print *, 'File: ', __FILE__, ', line: ', __LINE__
           do k = 1, numobs
             write(cv(k), fmt='(i5)') k*11111
            !print *, 'cv(', k, ') = ', trim(cv(k))
           end do
           rc = nf90_put_var(ncid, varids(n), cv, start(1:2), length(1:2))
           call check_rc(rc)
         else if('LaunchTime@MetaData' == trim(obs%vars(i)%varname)) then
           start(1) = 1
           length(1) = ndatetime
           start(2) = 1
           length(2) = numobs

           do k = 1, numobs
             ltstr(k) = trim(LaunchTime(k))
            !print *, 'ltstr(', k, ') = ', trim(ltstr(k))
           end do
           rc = nf90_put_var(ncid, varids(n), ltstr, start(1:2), length(1:2))
           call check_rc(rc)
         endif
       else if('variable_names@VarMetaData' == trim(obs%vars(i)%varname)) then
         start(1) = 1
         length(1) = nstring
         start(2) = 1
         length(2) = 1
        !cv(1) = 'air_temperature'
         cv(1) = 'surface_pressure'
        !print *, 'cv(1) = ', trim(cv(1))
         rc = nf90_put_var(ncid, varids(n), cv(1:1), start(1:2), length(1:2))
         call check_rc(rc)
       end if
     else
       print *, 'Unknown xtype = ', obs%vars(i)%xtype
     end if

     start(1) = 1
     length(1) = numobs
   end do

  !print *, 'Number of obs vars in orignal file = ', obs%nVars
  !print *, 'Number of obs vars in created file = ', nvars

   rc =  nf90_close(ncid)
   call check_rc(rc)
   print *, 'Finished Write obs to file: ', trim(output_flnm)

end subroutine output_obs

!--------------------------------------------------------------------------------------
subroutine output_var_attr(ncid, dimidvars, dimidlocs, dimidstring, dimiddatetime, &
                           obs, nmax, nreal, varids, varlist)

   use netcdf
   use namelist_module
   use obs_module

   implicit none

   integer, intent(in) :: ncid
   integer, intent(in) :: dimidvars, dimidlocs, dimidstring, dimiddatetime
   type(obsgrid), intent(in) :: obs
   integer, intent(in)  :: nmax
   integer, intent(out) :: nreal
   integer, dimension(nmax), intent(out) :: varids
   character(len=256), dimension(nmax), intent(out) :: varlist

   character(len=1), parameter :: delimiter = '@'
   character(len=128) :: obsname, obstype
   integer, dimension(2) :: dimids
   integer, dimension(6) :: orig_dimids
   integer :: xtype, varid
   integer :: rc, nd, i, k
   logical :: keepit

   nreal = 0

!--Axis nvars
   dimids(1) = dimidvars
   nd = 1
   call nc_putAxisAttr(ncid, nd, dimidvars, "nvars", varid)
   nreal = 1
   varids(nreal) = varid
   varlist(nreal) = "nvars"

!--Axis nlocs
   dimids(1) = dimidlocs
   nd = 1
   call nc_putAxisAttr(ncid, nd, dimidlocs, "nlocs", varid)
   nreal = 2
   varids(nreal) = varid
   varlist(nreal) = "nlocs"

!--Axis nstring
   dimids(1) = dimidstring
   nd = 1
   call nc_putAxisAttr(ncid, nd, dimidstring, "nstring", varid)
   nreal = 3
   varids(nreal) = varid
   varlist(nreal) = "nstring"

!--Axis ndatetime
   dimids(1) = dimiddatetime
   nd = 1
   call nc_putAxisAttr(ncid, nd, dimiddatetime, "ndatetime", varid)
   nreal = 4
   varids(nreal) = varid
   varlist(nreal) = "ndatetime"

  !print *, 'Number of obs vars in sample file = ', obs%nVars

   do i = 1, obs%nVars

     call split_string(obs%vars(i)%varname, obsname, obstype, delimiter)
    !print *, 'obsname = ', trim(obsname), ', obstype = ', trim(obstype)

    !call checkvar(obsname, keepit)
    !print *, 'Keep Var ', i, ': <', trim(obs%vars(i)%varname), '> = ', keepit

    !if(.not. keepit) then
    ! !print *, 'Skip var ', i, ': ', trim(obs%vars(i)%varname)
    !  cycle
    !end if

    !print *, 'Var ', i, ': ', trim(obs%vars(i)%varname)
    !print *, 'Var ', i, ': ndims = ', obs%vars(i)%nDims

     rc = nf90_inquire_variable(obs%fileid, obs%varids(i), &
              dimids=orig_dimids(1:obs%vars(i)%nDims), xtype=xtype)
     call check_rc(rc)

    !print *, 'xtype = ', xtype, ', orig_dimids = ', orig_dimids(1:obs%vars(i)%nDims)

     nd = obs%vars(i)%nDims
     do k = 1, nd
       if(orig_dimids(k) == 1) then
          dimids(k) = dimidvars
       else if(orig_dimids(k) == 2) then
          dimids(k) = dimidlocs
       else if(orig_dimids(k) == 3) then
          dimids(k) = dimidstring
       else if(orig_dimids(k) == 4) then
          dimids(k) = dimiddatetime
       end if
     end do

     if('station_id@MetaData' == trim(obs%vars(i)%varname)) then
       dimids(1) = dimidstring
       dimids(2) = dimidlocs
     end if

     if('LaunchTime@MetaData' == trim(obs%vars(i)%varname)) then
       dimids(1) = dimiddatetime
       dimids(2) = dimidlocs
     end if

     if('variable_names@VarMetaData' == trim(obs%vars(i)%varname)) then
      !cycle
       dimids(1) = dimidstring
       dimids(2) = dimidvars
     end if

     call nc_putAttr(ncid, nd, xtype, dimids, obs%vars(i)%varname, varid)
     nreal = nreal + 1
     varids(nreal) = varid
     varlist(nreal) = trim(obs%vars(i)%varname)

     if(obs%vars(i)%nAtts > 0) then
      !print *, 'Var ', trim(obs%vars(i)%varname), ' has ', obs%vars(i)%nAtts, ', attributes'
       call copy_att(obs%fileid, obs%varids(i), obs%vars(i)%nAtts, ncid, varid)
     end if
   end do

!--End define mode.
   rc = nf90_enddef(ncid)
   call check_rc(rc)

   print *, 'Finished define obs vars.'
end subroutine output_var_attr

!---------------------------------------------------------------------------
subroutine copy_att(inncid, invarid, natts, outncid, outvarid)
  use netcdf
  use obs_module, only : check_rc
  implicit none
  integer, intent(in) :: inncid, invarid, natts, outncid, outvarid

  integer :: rc

  integer :: attnum, na, attlen, xtype
  character(len=80) :: attname, cv

  do attnum = 1, natts
     rc = nf90_inq_attname(inncid, invarid, attnum, attname)
     call check_rc(rc)
     rc = nf90_copy_att(inncid, invarid, trim(attname), outncid, outvarid)
     call check_rc(rc)
  end do

end subroutine copy_att

!---------------------------------------------------------------------------
subroutine output_global_attr(ncid, filename, title, gridtype)

   implicit none

   integer, intent(in) :: ncid
   character(len = *), intent(in) :: filename, title, gridtype

 ! ----put global attributes----
   call nc_putGlobalCharAttr(ncid, 'filename', trim(filename))
   call nc_putGlobalCharAttr(ncid, 'title', trim(title))
   call nc_putGlobalCharAttr(ncid, 'gridtype', trim(gridtype))

  !call nc_putGlobalIntAttr(ncid, 'WRF_for_first_guess', iwrf)
  !call nc_putGlobalRealAttr(ncid, 'top_height',bdytop)

end subroutine output_global_attr

!---------------------------------------------------------------------------
! split a string into 2 either side of a delimiter token
SUBROUTINE split_string(instring, string1, string2, delim)
  implicit none

  CHARACTER(len=*) :: instring, delim
  CHARACTER(len=*), INTENT(OUT):: string1, string2
  INTEGER :: index

  instring = TRIM(instring)

  index = SCAN(instring,delim)

  string1 = instring(1:index-1)
  string2 = instring(index+1:)

END SUBROUTINE split_string

!---------------------------------------------------------------------------
subroutine checkvar(varname, keepit)

   use namelist_module

   implicit none

   character(len=*), intent(in)  :: varname
   logical,          intent(out) :: keepit
   integer :: i

   keepit = .true.

   do i = 1, numskipvars
    !print *, 'varname = <', trim(varname), '>, skipvars(', i, ') = <', trim(skipvars(i)), '>'
     if(trim(varname) == trim(skipvars(i))) then
      !print *, 'skip varname = <', trim(varname), '>, skipvars(', i, ') = <', trim(skipvars(i)), '>'
       keepit = .false.
       exit
     end if
   end do

end subroutine checkvar

