#!/bin/bash
#SBATCH --ntasks-per-node=40
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -t 01:15:00
#SBATCH -A gsienkf
##SBATCH --partition=orion
#SBATCH --partition=bigmem
#SBATCH --job-name=interp
#SBATCH --output=log.interp.o%j
##SBATCH --mem=0

 set -x

#module load esmf

#ulimit -s unlimited
#ulimit -c unlimited

 generate_weights=0

 executable=/work2/noaa/gsienkf/weihuang/tools/weiinterp/fv3interp2latlon.exe

 yymmdd=20200110
 analhour=06
 fcsthout=03
 PREFIX=${yymmdd}.${fcsthout}0000.

 datadir=/work2/noaa/gsienkf/weihuang/jedi/case_study/surf/run_80.40t1n_36p/analysis.1/increment/
 grid_fv3=latlondata/latlon_increment.nc
 weights=/work2/noaa/gsienkf/weihuang/tools/weiinterp/weights.nc

 if [ "generate_weights" -eq "1" ]
 then
   cp input.nml.weights input.nml
 else
   NUM_TYPES=2
  #DATATYPES="'fv_core.res.tile', 'sfc_data.tile', 'fv_tracer.res.tile', 'fv_srf_wnd.res.tile', 'phy_data.tile',"
   DATATYPES="'fv_core.res.tile', 'fv_tracer.res.tile'"

   sed -e "s?DIRNAME?${datadir}?g" \
       -e "s?OUTPUTFILE?${grid_fv3}?g" \
       -e "s?WEIGHTFILE?${weights}?g" \
       -e "s?PREFIX?${PREFIX}?g" \
       -e "s?NUM_TYPES?${NUM_TYPES}?g" \
       -e "s?DATATYPES?${DATATYPES}?g" \
       input.nml.template > input.nml
 fi

 ${executable}

