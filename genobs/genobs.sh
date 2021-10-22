#!/bin/bash

 source ~/intelenv

 export LD_LIBRARY_PATH=${blddir}/lib:$LD_LIBRARY_PATH
 executable=${blddir}/bin/ioda-upgrade.x

 set -x

 ln -sf /work/noaa/gsienkf/weihuang/jedi/surface/ioda_v2_data/obs/ncdiag.oper.ob.PT6H.sfc.2021-01-08T21:00:00Z.nc4 sample_obs.nc4
 createobs.exe

 rm sample_obs.nc4

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

