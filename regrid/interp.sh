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

 DIRNAME=/work/noaa/gsienkf/weihuang/jedi/case_study/sondes/Data/bkg/
 PREFIX=fv_core.res.tile
 OUTPUTFILE=latlon_grid.nc
 WEIGHTFILE=/work2/noaa/gsienkf/weihuang/tools/weiinterp/weight/weights.nc

 sed -e "s?DIRNAME?${DIRNAME}?g" \
     -e "s?PREFIX?${PREFIX}?g" \
     -e "s?OUTPUTFILE?${OUTPUTFILE}?g" \
     -e "s?WEIGHTFILE?${WEIGHTFILE}?g" \
     input.nml.template > input.nml

 executable=/work2/noaa/gsienkf/weihuang/tools/weiinterp/fv3interp2latlon.exe
#ln -sf /work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96 .

#${executable}

 nemsrc=/work/noaa/gsienkf/weihuang/jedi/vis_tools/sergey.samples/RESTART/

 python ocean2latlon.py --nemsrc=${nemsrc}

 icesrc=/work/noaa/gsienkf/weihuang/jedi/vis_tools/sergey.samples/RESTART/

 python ice2latlon.py --icesrc=${icesrc}

