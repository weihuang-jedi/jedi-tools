#!/bin/bash

 set -x

 casedir=/work2/noaa/gsienkf/weihuang/jedi/case_study
 run_dir=run_80.40t1n_36p

#caselist=(sondes sondes sondes sondes)
#caselist=(sfcship sfcship sfcship sfcship)
#var_list=(tsen   tv     uv     q     )
#namelist=(air_temperature virtual_temperature eastward_wind,northward_wind specific_humidity)

#caselist=(aircraft aircraft aircraft)
#var_list=(tsen     uv       q     )
#namelist=(air_temperature eastward_wind,northward_wind specific_humidity)

#caselist=(satwind)
 caselist=(scatwind)
#caselist=(vadwind)
#caselist=(windprof)
 var_list=(uv)
 namelist=(eastward_wind,northward_wind)

#---------------------------------------------------------------------------
 for i in ${!var_list[@]}
 do
   echo "element $i is ${var_list[$i]}"
  #if [ "${var_list[$i]}" -eq "vadwind" ]
  #then
     obsfile=${casedir}/${caselist[$i]}/${run_dir}/obsout/${caselist[$i]}_obs_2020011006_0000.nc4
  #else
  #  obsfile=${casedir}/${caselist[$i]}/${run_dir}/obsout/${caselist[$i]}_${var_list[$i]}_obs_2020011006_0000.nc4
  #fi
   varname=${namelist[$i]}
   plotdir=${caselist[$i]}

   sed -e "s?OBSFILE?${obsfile}?g" \
       -e "s?VARNAME?${varname}?g" \
       -e "s?PLOTDIR?${plotdir}?g" \
       obscoef.yaml.template > obscoef.yaml

   eva obscoef.yaml
 done

