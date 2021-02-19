#!/bin/bash

 set -x

 export JEDI_OPT=/work/noaa/gsienkf/weihuang/JEDI_OPT
 module use /work/noaa/gsienkf/weihuang/JEDI_OPT/modulefiles

 module purge

 module load gcc/8.3.0 openmpi/4.0.4
 module load gnu8.3.0_openmpi4.0.4
 module load mkl/2020.2
 module load cmake/3.18.1 python/3.7.5

 export FC=gfortran
 export CC=gcc
 export CXX=g++

 export SERIAL_FC=FC
 export SERIAL_CC=CC
 export SERIAL_CXX=CXX

 export MPI_FC=mpif90
 export MPI_CC=mpicc
 export MPI_CXX=mpic++

 python bld.py

