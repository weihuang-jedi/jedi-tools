#!/bin/bash

 set -x

 module list

 export PYTHONPATH=$PYTHONPATH:/work2/noaa/gsienkf/weihuang/ioda/ioda-bundle-bld/lib/python3.9/pyioda

#ioda-bundle build dir:
 export ioda_bld_dir=/work2/noaa/gsienkf/weihuang/ioda/ioda-bundle-bld

#work dir:
 work_dir=/work2/noaa/gsienkf/weihuang/tools/convert_GSI2IODAv2

#output dir.
 output_dir=${work_dir}/output
 mkdir -p ${output_dir}

#input file fir.
 input_dir=${work_dir}/obs
 
#usage: proc_gsi_ncdiag.py [-h] [-o OBS_DIR] [-g GEOVALS_DIR] [-d OBSDIAG_DIR] [-b ADD_OBSBIAS] [-q ADD_QCVARS] [-r ADD_TESTREFS] input_dir

#Convert to ioda_v1 data
 python ${ioda_bld_dir}/bin/proc_gsi_ncdiag.py -o ${output_dir} ${input_dir}

 exit 0

#file name of the combined file.
 input1=sondes_q_obs_2020011006.nc4
 input2=sondes_tsen_obs_2020011006.nc4
 input3=sondes_tv_obs_2020011006.nc4
 input4=sondes_uv_obs_2020011006.nc4
 flnm=sondes_obs_2020011006.nc4

#Combine the files to a single ioda-v1 obs. file
#python ${ioda_bld_dir}/bin/combine_files.py \
 python ${ioda_bld_dir}/bin/combine_obsspace.py \
 -i ${output_dir}/$input1 \
    ${output_dir}/$input2 \
    ${output_dir}/$input3 \
    ${output_dir}/$input4 \
 -o $flnm

#Convert from ioda-v1 to ioda-v2.
 /work/noaa/gsienkf/weihuang/jedi/src/my.compile/bin/ioda-upgrade.x $flnm ioda_v2_${flnm}

