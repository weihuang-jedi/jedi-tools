#!/bin/bash

 set -x

 workbase=/work/noaa/gsienkf/weihuang/jedi

#caselist="base case1 case2 case3 case4 intelbase intelcase"
 caselist="case0 case2 case4 intelcase0 intelcase intelcase1"

 rm -f *.tar

 for case in ${caselist}
 do
   rm -f *.png

   workdir=${workbase}/${case}

   python plotomp3.py --workdir=${workdir}

   tar cvf ${case}_png.tar *.png
 done

 tar cvf png.tar *_png.tar

