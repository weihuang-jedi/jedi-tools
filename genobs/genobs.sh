#!/bin/bash

 source ~/intelenv

 export LD_LIBRARY_PATH=${blddir}/lib:$LD_LIBRARY_PATH
 executable=${blddir}/bin/ioda-upgrade.x

 set -x

 rm -f sample_obs.nc4 created_sample_obs.nc4

 ln -sf /work/noaa/gsienkf/weihuang/jedi/case_study/Data/obs/ncdiag.oper.ob.PT6H.sondes.2021-01-08T21:00:00Z.nc4 sample_obs.nc4

 createobs.exe

 if [ "$#" -lt 1 ]
 then
   fl=created_sample_obs.nc4
 else
   fl=$1
 fi

 if [ -f $fl ]
 then
   rm -f ioda_v2_${fl}
  #ncrename -h -O -v "LaunchTime@MetaData","date_time@MetaData" $fl
  #ncrename -h -O -v "LaunchTime@MetaData","datetime@MetaData" $fl
   ${executable} $fl ioda_v2_${fl}
 fi

