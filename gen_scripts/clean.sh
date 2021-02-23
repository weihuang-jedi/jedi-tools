#!/bin/bash

#set -x

 memberlist="10 20 40 80"
 corelist="24 240"
 threadlist="1 2 4"

#caselist="base case1 case2 case3 intelbase intelcase"
 caselist="case4"

 for case in ${caselist}
 do
 case_dir=/work/noaa/gsienkf/weihuang/jedi/${case}

 for ompthread in ${threadlist}
 do
   omp_base=${case_dir}/omp${ompthread}

   for cores in ${corelist}
   do
     mpitasks=$(( $cores / $ompthread ))
     for num_member in ${memberlist}
     do
       jobname=n${mpitasks}m${num_member}o${ompthread}
       workdir=${omp_base}/${jobname}

       rm -rf ${workdir}/stdoutNerr

       n=1
       while [ $n -le ${num_member} ]
       do
         if [ $n -lt 10 ]
         then
           member_str=00${n}
         elif [ $n -lt 100 ]
         then
           member_str=0${n}
         else
           member_str=${n}
         fi

         rm -rf ${workdir}/output/mem${member_str}

         n=$(( $n + 1 ))
       done
     done
   done
 done
 done

 exit 0

