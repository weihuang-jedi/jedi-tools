#!/bin/bash

#SBATCH --ntasks-per-node=6
#SBATCH -N 1
#SBATCH -n 6
#SBATCH -t 01:15:00
#SBATCH -A gsienkf
##SBATCH --partition=orion
#SBATCH --partition=bigmem
#SBATCH --job-name=interp
#SBATCH --output=log.interp.o%j
##SBATCH --mem=0

 set -x

 module load esmf

 ulimit -s unlimited
 ulimit -c unlimited

 generate_weights=0

 executable=/work2/noaa/gsienkf/weihuang/tools/weiinterp/fv3interp2latlon.exe

 ensdir=/work/noaa/gsienkf/weihuang/jedi/EnsembleDaVal/Data/ens
 latlondir=/work/noaa/gsienkf/weihuang/jedi/case_study/bump/latlondata

 number_members=80

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

   datadir=${ensdir}/${member_str}/
   grid_fv3=${latlondir}/${ensfile}

   if [ "generate_weights" -eq "1" ]
   then
     cp input.nml.weights input.nml
   else
     DIRNAME=${datadir}
     OUTPUTFILE=${grid_fv3}
     WEIGHTFILE=/work2/noaa/gsienkf/weihuang/tools/weiinterp/weights.nc
     NUM_TYPES=5
     DATATYPES="'fv_core.res.tile', 'sfc_data.tile', 'fv_tracer.res.tile', 'fv_srf_wnd.res.tile', 'phy_data.tile',"

     sed -e "s?DIRNAME?${DIRNAME}?g" \
         -e "s?OUTPUTFILE?${OUTPUTFILE}?g" \
         -e "s?WEIGHTFILE?${WEIGHTFILE}?g" \
         -e "s?NUM_TYPES?${NUM_TYPES}?g" \
         -e "s?DATATYPES?${DATATYPES}?g" \
         input.nml.template > input.nml
   fi

   ${executable}

   n=$(( $n + 1 ))
 done

#nemsrc=/work/noaa/gsienkf/weihuang/jedi/vis_tools/sergey.samples/RESTART/

#python ocean2latlon.py --nemsrc=${nemsrc}

#icesrc=/work/noaa/gsienkf/weihuang/jedi/vis_tools/sergey.samples/RESTART/

#python ice2latlon.py --icesrc=${icesrc}

