#!/bin/bash
#SBATCH --ntasks-per-node=1
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 06:00:00
#SBATCH -A gsienkf
#SBATCH --partition=orion
##SBATCH --partition=bigmem
#SBATCH --job-name=stats
#SBATCH --output=log.stats.o%j
##SBATCH --mem=0

 set -x

 ulimit -s unlimited
 ulimit -c unlimited

#for varname in specific_humidity surface_pressure air_temperature virtual_temperature northward_wind
#do
#  time python sondes_combine_jed-gsi-omb.py --varname=${varname} &
#done

#wait

#exit 0

 function back_ground_process () {
   start=$(date +%Y%m%d%H%M%S)
   varname=${1}

   echo "Processing ${1} started..."
   time python sondes_combine_jed-gsi-omb.py --varname=${varname}
   echo "Processing ${1} Ended."

   end=$(date +%Y%m%d%H%M%S)
   elapsed=$(($end-$start))
   ftime=$(for((i=1;i<=$((${#end}-${#elapsed}));i++));
        do echo -n "-";
        done;
        echo ${elapsed})
   echo -e "Start  : ${start}"
   echo -e "Stop   : ${end}"
   echo -e "Elapsed: ${ftime}"
 }

# array in shell script
 varlist=("specific_humidity" "surface_pressure" "air_temperature" "virtual_temperature" "northward_wind")

# @ means all elements in array
 for varname in ${varlist[@]}
 do
  # run back_ground_process function in background
  # pass element of array as argument
  # make log file
   back_ground_process $varname > ./log_${varname}.txt &
 done

 wait

