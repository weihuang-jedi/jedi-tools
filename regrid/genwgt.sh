#!/bin/bash

#SBATCH --ntasks-per-node=6
#SBATCH -N 1
#SBATCH -n 6
#SBATCH -t 01:15:00
#SBATCH -A gsienkf
##SBATCH --partition=orion
#SBATCH --partition=bigmem
#SBATCH --job-name=esmf
#SBATCH --output=log.esmf.o%j
##SBATCH --mem=0

 set -x

 module load esmf

 ulimit -s unlimited
 ulimit -c unlimited

#gridlocation = "/gpfs/hps/ptmp/George.Gayno/fv3_grid.uniform/C96/grid/" ;
#newgridlocation="C96/"

#INFILE=/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/C96_mosaic.nc
#OUTFILE=/work/noaa/gsienkf/weihuang/tools/UFS-RNR-tools/JEDI.FV3-increments/grid/C96/mosaic.nc

#ncap2 -O -s gridlocation=\"$newgridlocation\" $INFILE $OUTFILE

#python chgvar.py

 mosaic=C96_mosaic.nc

#srun -n 6 ESMF_RegridWeightGen -s $mosaic -d ll1.0deg_grid.nc -w fv3C96wgt.nc -m bilinear
#ESMF_RegridWeightGen -s $mosaic -d ll1.0deg_grid.nc -w fv3C96wgt.nc -m bilinear
 ESMF_RegridWeightGen -s C48_mosaic.nc -d ll2.5deg_grid.nc -w fv3C48wgt.nc -m bilinear

