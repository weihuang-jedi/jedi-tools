#!/bin/bash

#Email from Cory
#Cory Martin - NOAA Affiliate <cory.r.martin@noaa.gov>
#11:10 AM (31 minutes ago)
#to Sergey, Daniel, Jeffrey, me

#Hi Sergey,
#
#To convert the GSI netCDF diag files to IODA observation files use this script in the ioda-converters:
#https://github.com/JCSDA-internal/ioda-converters/blob/develop/src/gsi-ncdiag/proc_gsi_ncdiag.py
#
#Once ioda-converters are built on your machine, to use it:
#python proc_gsi_ncdiag.py -n NTASKS -o /path/to/output/obs/ /path/to/gsi/diags
#
#This script will find all files in /path/to/gsi/diags (diag_conv_t..., etc.) and process them appropriately and write out files to /path/to/output/obs/.
#There is an additional script that can combine files together (for example, sondes have uv, t, tv, q, ps, can concatenate them all into sondes.nc4), that is combine_files.py
#
#These converters (as of today) still write out IODAv1 format, so if you are using an up-to-date JEDI build,
#you will need to run the ioda-upgrade.x executable on each file in the ioda repository.
#
#Let me know if you have any questions or need any help with this.
#
#-Cory

 set -x

#ioda-bundle build dir:
 export ioda_bld_dir=/work/noaa/gsienkf/weihuang/jedi/src/my.fv3-bundle/ioda-bundle/build

#output dir.
 output_dir=/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/

#diag files from GSI runs.
#diag_conv_q_ges.2021010900_ensmean.nc4  diag_conv_t_ges.2021010900_ensmean.nc4  diag_conv_uv_ges.2021010900_ensmean.nc4

#input file fir.
 input_dir=/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/jeff-gsi-run/2021010900
 
#Convert to ioda_v1 data
 python ${ioda_bld_dir}/bin/proc_gsi_ncdiag.py -n 1 -o ${output_dir} ${input_dir}

#file name of the combined file.
 flnm=sondes_obs_2021010900.nc4

#Combine the files to a single ioda-v1 obs. file
 python ${ioda_bld_dir}/bin/combine_files.py \
	-i sondes_q_obs_2021010900.nc4  sondes_tsen_obs_2021010900.nc4  sondes_tv_obs_2021010900.nc4  sondes_uv_obs_2021010900.nc4 \
	-o $flnm

#Convert from ioda-v1 to ioda-v2.
 /work/noaa/gsienkf/weihuang/jedi/src/my.compile/bin/ioda-upgrade.x $flnm ioda_v2_${flnm}

