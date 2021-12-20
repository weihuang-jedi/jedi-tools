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

 executable=/work2/noaa/gsienkf/weihuang/tools/traject/src2/trajectory.exe

 year=2021
 month=04
 day=01
 hour=00

#for HEIGHT in 500 1000
#for HEIGHT in 2000 3000 4000 5000 6000 7000 8000 9000 10000
#for HEIGHT in 500 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000
#for HEIGHT in 11000 12000 13000 14000 15000
 for HEIGHT in 18000 22000 25000 30000 35000 40000 45000 50000
 do
   sed -e "s?HEIGHT?${HEIGHT}?g" \
       input.nml.template > input.nml

   if [ ! -f 'trajectory_${HEIGHT}m.nc' ]
   then
     ${executable}
   fi

   n=$(( $n + 1 ))
 done

