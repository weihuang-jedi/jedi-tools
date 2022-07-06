#!/bin/bash

#SBATCH --ntasks-per-node=6
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 05:15:00
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

 generate_weights=0

 executable=/work2/noaa/gsienkf/weihuang/tools/weiinterp/fv3interp2latlon.exe

 if [ "generate_weights" -eq "1" ]
 then
   cp input.nml.weights input.nml
   ${executable}
   generate_weights=0
 fi

 year=2015
 month=12
 day=6
 hour=3
#hour=9

 second=$((hour*3600))
 monthstr=`printf "%02d\n" $month`
 daystr=`printf "%02d\n" $day`
 hourstr=`printf "%02d\n" $hour`
 secondtr=`printf "%02d\n" $second`
 yymmdd=${year}${monthstr}${daystr}
 prefix=${yymmdd}.${hourstr}0000.

 topdatadir=/work2/noaa/gsienkf/weihuang/WCLEKF_PRODFORECAST/20151205000000/production
 atmlatlondir=${topdatadir}/latlongrid/ATM
 ocnlatlondir=${topdatadir}/latlongrid/OCN
 icelatlondir=${topdatadir}/latlongrid/ICE
 weightfilename=/work2/noaa/gsienkf/weihuang/tools/weiinterp/weights.nc
 numberoftypes=5
 datatypes="'fv_core.res.tile', 'sfc_data.tile', 'fv_tracer.res.tile', 'fv_srf_wnd.res.tile', 'phy_data.tile'"

 mkdir -p ${atmlatlondir}
 mkdir -p ${ocnlatlondir}
 mkdir -p ${icelatlondir}

 number_members=80

 n=1
 while [ $n -le $number_members ]
 do
   if [ $n -lt 10 ]
   then
     member_str=mem00${n}
     ensfile=ens1_00000${n}.nc
   elif [ $n -lt 100 ]
   then
     member_str=mem0${n}
     ensfile=ens1_0000${n}.nc
   else
     member_str=mem${n}
     ensfile=ens1_000${n}.nc
   fi

   datadir=${topdatadir}/${member_str}/RESTART/
   outfv3filename=${atmlatlondir}/${ensfile}

   sed -e "s?DIRNAME?${datadir}?g" \
       -e "s?OUTPUTFILE?${outfv3filename}?g" \
       -e "s?WEIGHTFILE?${weightfilename}?g" \
       -e "s?PREFIX?${prefix}?g" \
       -e "s?NUM_TYPES?${numberoftypes}?g" \
       -e "s?DATATYPES?${datatypes}?g" \
       input.nml.template > input.nml

   ${executable}

   python ocean2latlon.py --nemsrc=${datadir} --year=${year} --month=${monthstr} --day=${daystr} --hour=${hourstr}

  #mv MOM.res.${year}-${monthstr}-${daystr}-${hourstr}-00-00_360x180.nc ${ocnlatlondir}/${ensfile}
   mv MOM.res.*.nc ${ocnlatlondir}/${ensfile}

   python ice2latlon.py --icesrc=${datadir} --year=${year} --month=${monthstr} --day=${daystr} --hour=${hourstr}

  #mv iced.${year}-${monthstr}-${daystr}-${secondstr}_360x180.nc ${icelatlondir}/${ensfile}
   mv iced.*.nc ${icelatlondir}/${ensfile}

   n=$(( $n + 1 ))
 done

