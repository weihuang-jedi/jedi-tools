#!/bin/bash

 set -x

 export PROJ_LIB=/work2/noaa/gsienkf/weihuang/anaconda3/share/proj
 export PYTHONPATH=/work/noaa/gsienkf/weihuang/jedi/vis_tools/xESMF/build/lib:/work2/noaa/gsienkf/weihuang/anaconda3/lib
 export LD_LIBRARY_PATH=/work2/noaa/gsienkf/weihuang/anaconda3/lib:${LD_LIBRARY_PATH}
 export PATH=/work/noaa/gsienkf/weihuang/anaconda3/bin:${PATH}

 python writeIODA2Obs.py

 exit 0

