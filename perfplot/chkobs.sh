#!/bin/bash

#set -x

 cores_per_node=40
 memberlist="10 20 40 80"
 corelist="24 240"
 threadlist="1 2 4"

 curr_dir=`pwd`
 data_dir=/work/noaa/gsienkf/weihuang/data/basedata/ensemble
#obs_file=hofx_scatwind_obs_2019120300.nc4
 obs_file=hofx_scatwind_obs_2019120300_0000.nc4

#case_dir=/work/noaa/gsienkf/weihuang/jedi/case1
#case_dir=/work/noaa/gsienkf/weihuang/jedi/case2
 case_dir=/work/noaa/gsienkf/weihuang/jedi/case3

 for ompthread in ${threadlist}
 do
   omp_base=omp${ompthread}
   for cores in ${corelist}
   do
     mpitasks=$(( $cores / $ompthread ))
     for num_member in ${memberlist}
     do
       obsdata=${omp_base}/n${mpitasks}m${num_member}o${ompthread}
       workdir=${case_dir}/${obsdata}

       if [ ! -f ${workdir}/observations/${obs_file} ]
       then 
         echo "${workdir} obs not available"
       else
        #ls -l ${workdir}/observations/${obs_file}
         echo "${obsdata} obs ready"
       fi
     done
   done
 done

 exit 0

