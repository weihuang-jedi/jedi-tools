#!/bin/bash

 source ~/intelenv

 export LD_LIBRARY_PATH=${blddir}/lib:$LD_LIBRARY_PATH
 executable=${blddir}/bin/ioda-upgrade.x

 set -x

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

