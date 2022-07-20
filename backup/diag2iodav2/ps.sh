#!/bin/bash

 set -x

#ioda-bundle build dir:
 export ioda_dir=/work2/noaa/gsienkf/weihuang/jedi/ioda-bundle

#output dir.
 output_dir=/work2/noaa/gsienkf/weihuang/jedi/case_study/diag2iodav2/out

#input file fir.
 input_dir=/work2/noaa/gsienkf/weihuang/jedi/case_study/diag2iodav2/obs
 
 export PYTHONPATH=/work2/noaa/gsienkf/weihuang/jedi/ioda-bundle/build/lib/python3.9/pyioda:$PYTHONPATH
#Convert to ioda_v1 data
 python ${ioda_dir}/build/bin/proc_gsi_ncdiag.py -o ${output_dir} ${input_dir}

 exit 0

#file name of the combined file.
 flnm=ps_obs_2020011006.nc4

#Combine the files to a single ioda-v1 obs. file
 python ${ioda_dir}/iodaconv/src/gsi-ncdiag/combine_files.py \
 	-i out/sfc_ps_obs_2020011006.nc4 \
 	 out/sfcship_ps_obs_2020011006.nc4 \
 	 out/sondes_ps_obs_2020011006.nc4 \
 	-o $flnm

#ncrename -h -O -v datetime@MetaData,LaunchTime@MetaData ${flnm}

#Convert from ioda-v1 to ioda-v2.
 /work/noaa/gsienkf/weihuang/jedi/src/my.compile/bin/ioda-upgrade.x $flnm ioda_v2_${flnm}

