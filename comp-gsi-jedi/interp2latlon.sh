#!/bin/bash

 set -x

#module load esmf
 module load ncl

 gsidir=/work2/noaa/gsienkf/weihuang/C96_psonly_delp/2020011006
 for inf in sfg_2020011006_fhr06_ensmean sanl_2020011006_fhr06_ensmean
 do
   rm -f input.nc
   ln -sf ${gsidir}/${inf} input.nc
   ncl regrid_gaussian2latlon.ncl
   if [ -f output.nc ]
   then
     mv output.nc latlon_${inf}.nc
   fi
 done

#exit 0

 inputdir=/work2/noaa/gsienkf/weihuang/jedi/case_study/surf/run_80.40t1n_24p/analysis/increment
 inputfile=xainc.20200110_030000z.nc4
 rm -f input.nc
 ln -sf ${inputdir}/${inputfile} input.nc
 ncl regrid_jediINCR2latlon.ncl
 if [ -f output.nc ]
 then
   mv output.nc latlon_${inputfile}
 fi

 rm -f input.nc
