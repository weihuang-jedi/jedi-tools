#!/bin/bash

#set -x

 queuename=orion
#queuename=bigmem

 cores_per_node=40
 methodlist="obs run"
 memberlist="10 20 40 80"
#corelist="24 240"
 corelist="240"
#threadlist="1 2 4"
 threadlist="8"

 curr_dir=`pwd`
 data_dir=/work/noaa/gsienkf/weihuang/data/basedata/ensemble
 obs_name=hofx_scatwind_obs_2019120300
 obs_file=/work/noaa/gsienkf/weihuang/data/basecase1/observations/${obs_name}.nc4

#base_dir=/work/noaa/gsienkf/weihuang/jedi/base
#case_dir=/work/noaa/gsienkf/weihuang/jedi/case1
#case_dir=/work/noaa/gsienkf/weihuang/jedi/case2
#case_dir=/work/noaa/gsienkf/weihuang/jedi/case3
#base_dir=/work/noaa/gsienkf/weihuang/jedi/intelbase
#case_dir=/work/noaa/gsienkf/weihuang/jedi/intelcase1
#case_dir=/work/noaa/gsienkf/weihuang/jedi/intelcase0
 case_dir=/work/noaa/gsienkf/weihuang/jedi/intelcase
#exec_dir=/work/noaa/gsienkf/weihuang/jedi/src/intel-plasma
 exec_dir=/work/noaa/gsienkf/weihuang/jedi/src/intel

 for ompthread in ${threadlist}
 do
   tasks_per_node=$(( $cores_per_node / $ompthread ))
   omp_base=${case_dir}/omp${ompthread}

   if [ ! -d  ${omp_base} ]
   then
      mkdir -p ${omp_base}
   fi

   cd ${omp_base}
   if [ ! -d observations ]
   then
      if [ -d ${base_dir}/omp${ompthread}/observations ]
      then
        ln -sf ${base_dir}/omp${ompthread}/observations .
      else
        mkdir -p ${obs_dir}
        cp ${obs_file} observations/.
      fi
   fi

   for cores in ${corelist}
   do
     mpitasks=$(( $cores / $ompthread ))
     case ${mpitasks} in
       240)
         numnode=6
         layout="[5,8]"
         queuename=orion
         ;;
       120)
         numnode=6
         layout="[5,4]"
         queuename=orion
         ;;
       60)
         numnode=6
         layout="[5,2]"
         queuename=orion
         ;;
       30)
         numnode=6
         layout="[5,1]"
         queuename=orion
         ;;
       24)
         numnode=1
         layout="[2,2]"
         queuename=bigmem
         ;;
       12)
         numnode=1
         layout="[1,2]"
         queuename=bigmem
         ;;
       6)
         numnode=1
         layout="[1,1]"
         queuename=bigmem
         ;;
       *)
         numnode=1
         layout="[1,1]"
         ;;
     esac

    #--------------------------------------------------------------------------
     for num_member in ${memberlist}
     do
       jobname=n${mpitasks}m${num_member}o${ompthread}
       workdir=${omp_base}/${jobname}

       mkdir -p ${workdir}/stdoutNerr
       mkdir -p ${workdir}/output/mem000
      #mkdir -p ${workdir}/observations

       cd ${workdir}

      #rm -rf output/mem000/*
      #rm -rf observations/*
       ln -sf ${base_dir}/omp${ompthread}/${jobname}/observations .

      #--------------------------------------------------------------------------
       for method in ${methodlist}
       do
         yaml_filename=${method}.getkf_gfs_np${mpitasks}_nens${num_member}.yaml
         rm -f ${yaml_filename}

         runscript=${method}.sh
         rm -f ${runscript}

         sed -e "s/NUMNODE/${numnode}/" \
             -e "s/TASKS_PER_NODE/${tasks_per_node}/" \
             -e "s/MPITASKS/${mpitasks}/" \
             -e "s/QUEUENAME/${queuename}/" \
             -e "s/JOBNAME/${jobname}/" \
             -e "s?FV3BLDDIR?${exec_dir}?" \
             -e "s?WORKDIR?${workdir}?" \
             -e "s/NUMBER_MEMBER/${num_member}/" \
             -e "s/METHOD/${method}/" \
             -e "s/OMPTHREADSNUMBER/${ompthread}/" \
             ${curr_dir}/template.script.intelomp > ${runscript}

         sed -e "s/LAYOUT/${layout}/" ${curr_dir}/${method}.letkf_gfs.template > ${yaml_filename}

        #--------------------------------------------------------------------------
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

           datapath=${data_dir}/mem${member_str}/INPUT
           sed -e "s?DATAPATH?${datapath}?" ${curr_dir}/member.template >> ${yaml_filename}
 
           mkdir -p ${workdir}/output/mem${member_str}
  
           n=$(( $n + 1 ))
         done
       done

       if [ ! -f observations/${obs_name}_0000.nc4 ]
       then
         RES=$(sbatch obs.sh) && sbatch --dependency=afterok:${RES##* } run.sh
         echo "${jobname} JobID: ${RES##* }"
       else
         sbatch run.sh
       fi

       cd ${curr_dir}
     done
   done
 done

 exit 0

#RES=$(sbatch simulation) && sbatch --dependency=afterok:${RES##* } postprocessing
#The RES variable will hold the result of the sbatch command,
#something like Submitted batch job 102045.
#The construct ${RES##* } isolates the last word (see more info here),
#in the current case the job id. The && part ensures you do not try
#to submit the second job in the case the first submission fails.

