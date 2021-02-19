#!/bin/bash

 set -x

 curr_dir=`pwd`
 data_dir=/work/noaa/gsienkf/weihuang/data/basedata/ensemble
 prof_base=/work/noaa/gsienkf/weihuang/jedi/prof
 queuename=orion
#queuename=bigmem

 tasks_per_node=40
 ompthread=1

 methodlist="obs"
#methodlist="run"
#memberlist="10 20 40"
 memberlist="80"
#corelist="24 240"
 corelist="48 96 120 180"

 for method in ${methodlist}
 do
 for num_member in ${memberlist}
 do
   for mpitasks in ${corelist}
   do
     cd ${curr_dir}

     jobname=n${mpitasks}m${num_member}
     workdir=${prof_base}/${jobname}

     mkdir -p ${workdir}/output/mem000
     mkdir -p ${workdir}/observations

     if [ "${method}" = "obs" ]
     then
       rm -r ${workdir}/output/mem000/*
       rm -r ${workdir}/observations/*
       cp ${prof_base}/observations/hofx*.nc4 ${workdir}/observations/.
     fi

     case ${mpitasks} in
       240)
         numnode=6
         layout="[5,8]"
         ;;
       180)
         numnode=5
         layout="[5,6]"
         ;;
       120)
         numnode=3
         layout="[5,4]"
         ;;
       96)
         numnode=3
         layout="[4,4]"
         ;;
       48)
         numnode=2
         layout="[2,4]"
         ;;
       24)
         numnode=1
         layout="[2,2]"
         ;;
       *)
         numnode=1
         layout="[1,1]"
         ;;
     esac

     #--------------------------------------------------------------------------
     runscript=${workdir}/${method}.sh
     rm -f ${runscript}

     sed -e "s/NUMNODE/${numnode}/" \
         -e "s/TASKS_PER_NODE/${tasks_per_node}/" \
         -e "s/MPITASKS/${mpitasks}/" \
         -e "s/QUEUENAME/${queuename}/" \
         -e "s/JOBNAME/${jobname}/" \
         -e "s?WORKDIR?${workdir}?" \
         -e "s/NUMBER_MEMBER/${num_member}/" \
         -e "s/METHOD/${method}/" \
         -e "s/OMPTHREADSNUMBER/${ompthreads}/" \
         ./template.script > ${runscript}

     #--------------------------------------------------------------------------
     #yaml_filename=${workdir}/letkf_gfs_np${mpitasks}_nens${num_member}.yaml
      yaml_filename=${workdir}/${method}.getkf_gfs_np${mpitasks}_nens${num_member}.yaml
      rm -f ${yaml_filename}

      sed -e "s/LAYOUT/${layout}/" ./${method}.letkf_gfs.template > ${yaml_filename}

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
       #sed -e "s/XXX/${member_str}/" ./member.template >> ${yaml_filename}
        sed -e "s?DATAPATH?${datapath}?" ./member.template >> ${yaml_filename}

        mkdir -p ${workdir}/output/mem${member_str}
       #cp 20191203.000000.coupler.res ${workdir}/output/mem${member_str}/.

        n=$(( $n + 1 ))
      done

      cd ${workdir}
      sbatch ${runscript}
   done
 done
 done

 exit 0

RES=$(sbatch simulation) && sbatch --dependency=afterok:${RES##* } postprocessing
The RES variable will hold the result of the sbatch command, something like Submitted batch job 102045. The construct ${RES##* } isolates the last word (see more info here), in the current case the job id. The && part ensures you do not try to submit the second job in the case the first submission fails.

