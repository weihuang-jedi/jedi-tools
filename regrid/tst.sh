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

#srun -n 6 ESMF_RegridWeightGen -s C48_mosaic.nc -d ll1.0deg_grid.nc -w fv3C48wgt.nc -m bilinear
 ESMF_RegridWeightGen -s C48_mosaic.nc -d ll1.0deg_grid.nc -w fv3C48wgt.nc -m bilinear

