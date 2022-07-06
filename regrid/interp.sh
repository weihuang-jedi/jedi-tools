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

 if [ "generate_weights" -eq "1" ]
 then
   cp input.nml.weights input.nml
 else
  #DIRNAME=/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/Data/bkg/
   DIRNAME=/work2/noaa/gsienkf/weihuang/WCLEKF_PRODFORECAST/20151205000000/production/mem001/RESTART/
   OUTPUTFILE=grid_fv3.nc
   WEIGHTFILE=/work2/noaa/gsienkf/weihuang/tools/weiinterp/weights.nc
   NUM_TYPES=5
   PREFIX='20151205.030000.'
   DATATYPES="'fv_core.res.tile', 'sfc_data.tile', 'fv_tracer.res.tile', 'fv_srf_wnd.res.tile', 'phy_data.tile'"

   sed -e "s?DIRNAME?${DIRNAME}?g" \
       -e "s?OUTPUTFILE?${OUTPUTFILE}?g" \
       -e "s?WEIGHTFILE?${WEIGHTFILE}?g" \
       -e "s?PREFIX?${PREFIX}?g" \
       -e "s?NUM_TYPES?${NUM_TYPES}?g" \
       -e "s?DATATYPES?${DATATYPES}?g" \
       input.nml.template > input.nml
 fi

 executable=/work2/noaa/gsienkf/weihuang/tools/weiinterp/fv3interp2latlon.exe

#${executable}

 nemsrc=/work2/noaa/gsienkf/weihuang/WCLEKF_PRODFORECAST/20151205000000/production/mem001/RESTART/
 year=2015
 month=12
 day=06
 hour=03

 python ocean2latlon.py --nemsrc=${nemsrc} --year=${year} --month=${month} --day=${day} --hour=${hour}

#icesrc=/work2/noaa/gsienkf/weihuang/WCLEKF_PRODFORECAST/20151205000000/production/mem001/RESTART/

#python ice2latlon.py --icesrc=${icesrc} --year=${year} --month=${month} --day=${day} --hour=${hour}

