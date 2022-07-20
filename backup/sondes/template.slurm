#!/bin/bash
#SBATCH --ntasks-per-node=TASKSPERNODE
#SBATCH -N TOTALNODES
#SBATCH -n TOTALCPUS
#SBATCH -t 02:25:00
#SBATCH -A gsienkf
##SBATCH --partition=orion
#SBATCH --partition=bigmem
#SBATCH --job-name=getkf
#SBATCH --output=log.getkf
##SBATCH --mem=0

 source ~/intelenv

 ulimit -S unlimited
 ulimit -c unlimited

#export blddir=/work/noaa/gsienkf/weihuang/jedi/sergey-code/build
#export LD_LIBRARY_PATH=${blddir}/lib:$LD_LIBRARY_PATH
 executable=$blddir/bin/fv3jedi_letkf.x

#--------------------------------------------------------------------------------------------
 export OOPS_DEBUG=-11
 export OOPS_TRACK=-11
#export OOPS_TRACE=1

#--------------------------------------------------------------------------------------------
 cd WORKDIR

 ln -sf ../Data .
 ln -sf ../ioda_v2_data .

#--------------------------------------------------------------------------------------------
 if [ -f log.getkf ]
 then
   ns=1
   while [ -f log.getkf.${ns} ]
   do
     ns=$((ns+1))
   done
   mv log.getkf log.getkf.${ns}
 fi
#--------------------------------------------------------------------------------------------
 for dir in obsout analysis stdoutNerr
 do
   if [ -d ${dir} ]
   then
     ns=1
     while [ -d ${dir}.${ns} ]
     do
       ns=$((ns+1))
     done
     mv ${dir} ${dir}.${ns}
   fi
 done

 rm -f core.*

 mkdir -p analysis/mean analysis/increment hofx obsout

 srun -n TOTALCPUS ${executable} getkf.yaml

 sacct --format=JobID,CPUTime,Elapsed,AveVMSize,MaxRSS,NodeList%30 --units=M -j $SLURM_JOBID

