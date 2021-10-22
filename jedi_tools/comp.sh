#!/bin/bash
#SBATCH -N 1
#SBATCH --ntasks-per-node=40
#SBATCH -n 40
#SBATCH -t 01:00:00
#SBATCH -A gsienkf
#SBATCH --partition=orion
#SBATCH --exclusive
#SBATCH -J jedi_letkf

 set -x

#source /etc/bashrc
 module purge
 export JEDI_OPT=/work/noaa/da/grubin/opt/modules
 module use $JEDI_OPT/modulefiles/core
 module load jedi/intel-impi
 module load mkl/2020.2
 module list
 ulimit -s unlimited

 ifort -o sg.exe sgemm.f90 \
	-i8 -I${MKLROOT}/include \
	-Wl,--start-group \
	${MKLROOT}/lib/intel64/libmkl_intel_ilp64.a \
	${MKLROOT}/lib/intel64/libmkl_intel_thread.a \
	${MKLROOT}/lib/intel64/libmkl_core.a \
	${MKLROOT}/lib/intel64/libmkl_blacs_intelmpi_ilp64.a \
	-Wl,--end-group -liomp5 -lpthread -lm -ldl

 export KMP_AFFINITY=compact
 export MKL_DYNAMIC=FALSE 
 export I_MPI_PIN_DOMAIN="core"

 for thread in 1 2 4 8
 do
   export OMP_NUM_THREADS=${thread}
   export MKL_NUM_THREADS=$OMP_NUM_THREADS

   time sg.exe >& o${thread}.log
 done

