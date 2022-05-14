#!/bin/bash

#SBATCH --ntasks-per-node=6
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 03:15:00
#SBATCH -A gsienkf
##SBATCH --partition=orion
#SBATCH --partition=bigmem
#SBATCH --job-name=interp
#SBATCH --output=log.interp.o%j
##SBATCH --mem=0

 set -x

 ulimit -s unlimited
 ulimit -c unlimited

#executable=/work2/noaa/gsienkf/weihuang/tools/concatefiles/concatefiles.exe
 executable=/work/noaa/gsienkf/weihuang/tools/concatefiles/concatefiles.exe

#sourcedir=/work/noaa/gsienkf/weihuang/jedi/case_study/bump/latlondata
#targetdir=/work/noaa/gsienkf/weihuang/jedi/case_study/bump/tmplatlondata

 sourcedir=/work2/noaa/gsienkf/weihuang/WCLEKF_PRODFORECAST/20151205000000/production/latlongrid
 targetdir=/work2/noaa/gsienkf/weihuang/WCLEKF_PRODFORECAST/20151205000000/production/latlongrid/AtmOcnIce

 mkdir -p ${targetdir}

 number_members=80
#number_members=1

 n=1
 while [ $n -le $number_members ]
 do
   if [ $n -lt 10 ]
   then
     member_str=mem00${n}
     ensfile=ens1_00000${n}.nc
   elif [ $n -lt 100 ]
   then
     member_str=mem0${n}
     ensfile=ens1_0000${n}.nc
   else
     member_str=mem${n}
     ensfile=ens1_000${n}.nc
   fi

   atmfile=${sourcedir}/ATM/${ensfile}
   ocnfile=${sourcedir}/OCN/${ensfile}
   icefile=${sourcedir}/ICE/${ensfile}
   combinedfile=${targetdir}/${ensfile}

   sed -e "s?ATMFILE?${atmfile}?" \
       -e "s?OCNFILE?${ocnfile}?" \
       -e "s?ICEFILE?${icefile}?" \
       -e "s?COMBINEDFILE?${combinedfile}?" \
       input.nml.template > input.nml

   ${executable}

   n=$(( $n + 1 ))
 done

