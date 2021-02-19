#!/bin/bash

#set -x

 cores_per_node=40
 memberlist="10 20 40 80"
 corelist="24 240"
 threadlist="1 2 4"

 curr_dir=`pwd`
 data_dir=/work/noaa/gsienkf/weihuang/data/basedata/ensemble
 out_file=output/mem000/20191203.000000.letkf.fv_core.res.tile1.nc

#case_dir=/work/noaa/gsienkf/weihuang/jedi/case1
#case_dir=/work/noaa/gsienkf/weihuang/jedi/case2
#case_dir=/work/noaa/gsienkf/weihuang/jedi/case3
 case_dir=/work/noaa/gsienkf/weihuang/jedi/intelbase

 for ompthread in ${threadlist}
 do
   omp_base=omp${ompthread}
   for cores in ${corelist}
   do
     mpitasks=$(( $cores / $ompthread ))
     for num_member in ${memberlist}
     do
       case_name=${omp_base}/n${mpitasks}m${num_member}o${ompthread}
       workdir=${case_dir}/${case_name}

       if [ ! -f ${workdir}/${out_file} ]
       then 
         echo "${workdir} not available"
        #cd ${workdir}
        #sbatch run.sh
      #else
      #  echo "${case_name} ready"
       fi
     done
   done
 done

 exit 0

