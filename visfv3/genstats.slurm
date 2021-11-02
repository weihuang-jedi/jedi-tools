#!/bin/bash
#SBATCH --ntasks-per-node=5
#SBATCH -N 1
#SBATCH -n 5
#SBATCH -t 06:00:00
#SBATCH -A gsienkf
##SBATCH --partition=orion
#SBATCH --partition=bigmem
#SBATCH --job-name=genstats
#SBATCH --output=log.stats.o%j
##SBATCH --mem=0

 source ~/intelenv

 ulimit -s unlimited
 ulimit -c unlimited

#--------------------------------------------------------------------------------------------
 cd /work2/noaa/gsienkf/weihuang/tools/visfv3

 python jedi-gsi-obs.py --varname=surface_pressure

 srun -n 1 --exclusive python jedi-gsi-obs.py --varname=eastward_wind &
 srun -n 1 --exclusive python jedi-gsi-obs.py --varname=northward_wind &
 srun -n 1 --exclusive python jedi-gsi-obs.py --varname=air_temperature &
 srun -n 1 --exclusive python jedi-gsi-obs.py --varname=surface_pressure &
 srun -n 1 --exclusive python jedi-gsi-obs.py --varname=specific_humidity &
 wait

 sacct --format=JobID,CPUTime,Elapsed,AveVMSize,MaxRSS,NodeList%30 --units=M -j $SLURM_JOBID

