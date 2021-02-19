#!/bin/bash

 set -x

 base=/work/noaa/gsienkf/weihuang/jedi/base/omp1/n24m20o1/output/mem000
 case1=/work/noaa/gsienkf/weihuang/jedi/intelbase/omp4/n6m10o4/output/mem000

 outfile=20191203.000000.letkf.fv_core.res.tile1.nc
 file1=${base}/${outfile}
 file2=${base}/${outfile}

 cdo -timavg -sub $file1 $file2 $outfile

