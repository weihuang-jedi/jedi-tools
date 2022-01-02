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

 cd /work2/noaa/gsienkf/weihuang/tools/traject/src2

 generate_weights=0

 executable=/work2/noaa/gsienkf/weihuang/tools/traject/src2/trajectory.exe

 intvhour=12
 dt=600

 syear=2021
 smonth=10
 sday=4
 shour=00

 eyear=2021
 emonth=10
 eday=7
 ehour=00

 datadir=../vertical-interp2

 for HEIGHT in 1000 3000 5000 7000 9000 11000 12000 13000 15000
 do
   sed -e "s?HEIGHT?${HEIGHT}?g" \
       -e "s?DATADIR?${datadir}?g" \
       -e "s?DT?${dt}?g" \
       -e "s?SYEAR?${syear}?g" \
       -e "s?SMONTH?${smonth}?g" \
       -e "s?SDAY?${sday}?g" \
       -e "s?SHOUR?${shour}?g" \
       -e "s?EYEAR?${eyear}?g" \
       -e "s?EMONTH?${emonth}?g" \
       -e "s?EDAY?${eday}?g" \
       -e "s?EHOUR?${ehour}?g" \
       -e "s?INTVHOUR?${intvhour}?g" \
       input.nml.template > input.nml

   if [ ! -f 'trajectory_${HEIGHT}m.nc' ]
   then
     ${executable} &
     sleep 5
   fi

   n=$(( $n + 1 ))
 done

 wait

 exit 0

