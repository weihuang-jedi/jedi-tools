#!/bin/bash

 set -x

 topdir=/work2/noaa/gsienkf/weihuang/jedi/case_study/satwind

 taskspernode=40
 NUMMEM=80
 MYLAYOUT=1,20

#cpu_list=(   6    12    18    24    30    36     72     78)
#nodelist=(   1     1     1     1     1     1      2      2)
#lay_list=("1,1" "1,2" "1,3" "1,4" "1,5" "1,6" "1,12" "1,13")

#cpu_list=(  24)
#nodelist=(   1)
#lay_list=("2,2")

 cpu_list=(  36)
 nodelist=(   1)
 lay_list=("2,3")

#------------------------------------------------------------------------------
 cd ${topdir}
 ln -sf ../Data .
 ln -sf ../ioda_v2_data .

 for i in ${!cpu_list[@]}
 do
   echo "element $i is ${myArray[$i]}"
   totalcpus=${cpu_list[$i]}
   nodes=${nodelist[$i]}
   MYLAYOUT=${lay_list[$i]}

   workdir=${topdir}/run_${NUMMEM}.${taskspernode}t${nodes}n_${totalcpus}p
   mkdir -p ${workdir}
   cd ${workdir}

   sed -e "s?TASKSPERNODE?${taskspernode}?g" \
       -e "s?TOTALNODES?${nodes}?g" \
       -e "s?TOTALCPUS?${totalcpus}?g" \
       -e "s?WORKDIR?${workdir}?g" \
       -e "s?NUMMEM?${NUMMEM}?g" \
       -e "s?MYLAYOUT?${MYLAYOUT}?g" \
       ${topdir}/template.slurm > run.slurm

   sed -e "s?LAYOUT?${MYLAYOUT}?" \
       -e "s?NUMBEROFMEMBERS?${NUMMEM}?" \
       ${topdir}/getkf.yaml.template > getkf.yaml

   if [ $i -lt 1 ]
   then
    #DEPEND=$(sbatch --parsable run.slurm)
    #echo "job_id: ${DEPEND}"
     sbatch run.slurm
   else
    #DEPEND=$(sbatch --dependency=afterany:${DEPEND} --parsable run.slurm)
     sbatch run.slurm
   fi

   cd ${topdir}
 done

