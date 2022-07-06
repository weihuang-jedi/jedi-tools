#!/bin/bash
#SBATCH --ntasks-per-node=1
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 06:00:00
#SBATCH -A gsienkf
#SBATCH --partition=orion
##SBATCH --partition=bigmem
#SBATCH --job-name=interp
#SBATCH --output=log.traject.o%j
##SBATCH --mem=0

 set -x

 module load esmf

 ulimit -s unlimited
 ulimit -c unlimited

 generate_weights=0

 executable=/work2/noaa/gsienkf/weihuang/tools/traject/vertical-interp2/verticalinterp.exe

 year=2021
 month=07
 day=31
 hour=00

 end_day=31

 while [ $day -le $end_day ]
 do
   for hour in 00 12
   do
     if [ $day -lt 10 ]
     then
       dm=0$day
     else
       dm=$day
     fi

     sed -e "s?YEAR?${year}?g" \
         -e "s?MM?${month}?g" \
         -e "s?DD?${dm}?g" \
         -e "s?HH?${hour}?g" \
         input.nml.template > input.nml

     ${executable}
   done

   day=$(( $day + 1 ))
 done

