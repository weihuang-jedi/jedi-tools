#########################################################################
#$Id: bld.py 28 2021-01-21 15:10:31Z whuang $
#$Revision: 28 $
#$HeadURL: file:///Users/whuang/.wei_svn_repository/trunk/jedi-build-tools/bld.py $
#$Date: 2021-01-21 08:10:31 -0700 (Thu, 21 Jan 2021) $
#$Author: whuang $
#########################################################################

import getopt
import os, sys
import subprocess
import time
import datetime

#from subprocess import PIPE, run

#def cmdout(command):
#    result = run(command, stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
#    ostr = result.stdout
#    return ostr.strip()

""" Build Stack """
class BuildStack:
  """ Constructor """
  def __init__(self, debug=0, buildHome='/work/noaa/gsienkf/weihuang/JEDI_LIB',
               compilerName='gnu', compilerVersion='9.2.0',
               mpiName='openmpi', mpiVersion = '4.1.0',
               software_file='software.txt',
               workdir=None,
               checkonly=0,
               overwrite=0):

    """ Initialize class attributes """
    self.debug = debug
    self.buildHome = buildHome
    self.compilerName = compilerName
    self.compilerVersion = compilerVersion
    self.mpiName = mpiName
    self.mpiVersion = mpiVersion
    self.software_file=software_file

    self.checkonly = 0
    self.overwrite = overwrite

    self.compiler = self.compilerName + self.compilerVersion + '_' \
      + self.mpiName + self.mpiVersion

    self.jediHome = os.environ['JEDI_OPT']
    self.prefix = self.jediHome + '/' + self.compiler

    if(workdir is None):
      self.cwd = os.getcwd()
      self.workdir = self.cwd + '/pkg'
    else:
      self.workdir = workdir

    os.system('mkdir -p ' + self.workdir)

    self.package = self.get_package()

    self.print_head()
    self.print_package()
    self.print_tail()

  def get_package(self):
    package = {}

    self.software_list = {}

    if(os.path.exists(self.software_file)):
      with open(self.software_file) as fp:
       #self.lines = fp.readlines()
        line = fp.readline()
        cnt = -1
        while line:
          line = line.strip()
         #print('Line {}: {}'.format(cnt, line))
          if(cnt > 0):
            item = line.split('|')
           #print('item = ', item)
            name = item[1].strip()
            version = item[2].strip()
            package[name] = version
           #print('Package {} name {}, version {}'.format(cnt, name, version))

            info = {}
            info['version'] = item[2].strip()
            info['method'] = item[3].strip()
            info['url'] = item[4].strip()
            self.software_list[name] = info

          line = fp.readline()
          cnt += 1
    else:
      pinfo = 'file <%s> does not exist. Exit' %(self.software_file)
      print(pinfo)
      sys.exit(-1)

    return package

  def print_head(self):
    self.moduleDir = self.buildHome + '/modulefiles'
    os.system('mkdir -p ' + self.moduleDir)

    self.moduleName = self.moduleDir + '/' + self.compiler + '.lua'

    self.NMF = open(self.moduleName, 'w')

    self.NMF.write('help([[\n')
    self.NMF.write(']])\n')
    self.NMF.write('\n')

    self.NMF.write('local pkgName    = myModuleName()\n')
   #self.NMF.write('local pkgVersion = myModuleVersion()\n')
    self.NMF.write('local pkgNameVer = myModuleFullName()\n')
    self.NMF.write('\n')

    self.NMF.write('local compiler = "' + self.compiler + '"\n')
    self.NMF.write('local opt = os.getenv("JEDI_OPT") or os.getenv("OPT") or "/opt/modules"\n')
    self.NMF.write('local base = pathJoin(opt, compiler)\n')
    self.NMF.write('\n')

    self.NMF.write('prepend_path("PATH", pathJoin(base,"bin"))\n')
    self.NMF.write('prepend_path("CPATH", pathJoin(base,"include"))\n')
    self.NMF.write('prepend_path("MANPATH", pathJoin(base,"share","man"))\n')
    self.NMF.write('prepend_path("LIBRARY_PATH", pathJoin(base,"lib"))\n')
    self.NMF.write('prepend_path("LD_LIBRARY_PATH", pathJoin(base,"lib"))\n')
    self.NMF.write('prepend_path("DYLD_LIBRARY_PATH", pathJoin(base,"lib"))\n')
    self.NMF.write('prepend_path("LIBRARY_PATH", pathJoin(base,"lib64"))\n')
    self.NMF.write('prepend_path("LD_LIBRARY_PATH", pathJoin(base,"lib64"))\n')
    self.NMF.write('prepend_path("DYLD_LIBRARY_PATH", pathJoin(base,"lib64"))\n')
    self.NMF.write('\n')

    self.cc = 'gcc'
    self.cxx = 'g++'
    self.fc = 'gfortran'

    self.mpi_cc = 'mpicc'
    self.mpi_cxx = 'mpic++'
    self.mpi_fc = 'mpif90'

    if(self.compilerName == 'gnu'):
      self.cc = 'gcc'
      self.cxx = 'g++'
      self.fc = 'gfortran'

      self.mpi_cc = 'mpicc'
      self.mpi_cxx = 'mpic++'
      self.mpi_fc = 'mpif90'
    elif(self.compilerName == 'intel'):
      self.cc = 'icc'
      self.cxx = 'icpc'
      self.fc = 'ifort'

      self.mpi_cc = 'mpiicc'
      self.mpi_cxx = 'mpiicpc'
      self.mpi_fc = 'mpiifort'
   
    self.NMF.write('local cc = "' + self.cc + '"\n')
    self.NMF.write('local cxx = "' + self.cxx + '"\n')
    self.NMF.write('local fc = "' + self.fc + '"\n')
    self.NMF.write('\n')
   
    self.NMF.write('local mpi_cc = "' + self.mpi_cc + '"\n')
    self.NMF.write('local mpi_cxx = "' + self.mpi_cxx + '"\n')
    self.NMF.write('local mpi_fc = "' + self.mpi_fc + '"\n')
    self.NMF.write('\n')

    self.NMF.write('-- Default serial compiler names may be overridden by compiler module itself\n')
    self.NMF.write('setenv("FC",  fc)\n')
    self.NMF.write('setenv("CC",  cc)\n')
    self.NMF.write('setenv("CXX", cxx)\n')
    self.NMF.write('\n')

    self.NMF.write('setenv("SERIAL_FC",  fc)\n')
    self.NMF.write('setenv("SERIAL_CC",  cc)\n')
    self.NMF.write('setenv("SERIAL_CXX", cxx)\n')
    self.NMF.write('\n')

    self.NMF.write('setenv("MPI_FC",  mpi_fc)\n')
    self.NMF.write('setenv("MPI_CC",  mpi_cc)\n')
    self.NMF.write('setenv("MPI_CXX", mpi_cxx)\n')
    self.NMF.write('\n')

    self.NMF.write('-- Enable FindMPI.cmake to automatically find and configure OpenMPI\n')
    self.NMF.write('setenv("MPI_ROOT", base)\n')
    self.NMF.write('setenv("MPI_HOME", base)\n')
    self.NMF.write('setenv("MPI_Fortran_COMPILER", pathJoin(base,"bin", mpi_fc))\n')
    self.NMF.write('setenv("MPI_C_COMPILER", pathJoin(base,"bin", mpi_cc))\n')
    self.NMF.write('setenv("MPI_CXX_COMPILER", pathJoin(base,"bin", mpi_cxx))\n')
    self.NMF.write('\n')

  def print_tail(self):
    self.NMF.write('whatis("Name: " .. pkgName)\n')
    self.NMF.write('whatis("Version: " .. "' + self.compiler + '")\n')
    self.NMF.write('whatis("Category: library")\n')
    self.NMF.write('whatis("Description: compiler and MPI library")\n')

    self.NMF.close()

  def print_package(self):
    cnt = 0
    for name in self.package.keys():
      cnt += 1
      version = self.package[name]
     #print('Package {} name {}, version {}'.format(cnt, name, version))
      self.NMF.write('\n')
      if(name == 'openmpi'):
        print('Make module setup for ' + name)
      elif(name == 'zlib'):
        self.NMF.write('setenv("ZLIB_ROOT", base)\n')
        self.NMF.write('setenv("ZLIB_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("ZLIB_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("ZLIB_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libz.a'
      elif(name == 'szip'):
        self.NMF.write('setenv("SZIP_ROOT", base)\n')
        self.NMF.write('setenv("SZIP_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("SZIP_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("SZIP_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libsz.a'
      elif(name == 'hdf5'):
        self.NMF.write('setenv("HDF5_ROOT", base)\n')
        self.NMF.write('setenv("HDF5_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("HDF5_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("HDF5_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libhdf5.a'
      elif(name == 'pnetcdf'):
        self.NMF.write('setenv("PNETCDF", base)\n')
        self.NMF.write('setenv("PNETCDF_ROOT", base)\n')
        self.NMF.write('setenv("PNETCDF_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("PNETCDF_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("PNETCDF_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libpnetcdf.a'
      elif(name == 'netcdf-c'):
        self.NMF.write('setenv("NETCDF", base)\n')
        self.NMF.write('setenv("NETCDF_ROOT", base)\n')
        self.NMF.write('setenv("NETCDF_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("NETCDF_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("NETCDF_VERSION", ' + '"' + version + '")\n')
        self.NMF.write('\n')

        self.NMF.write('setenv("NetCDF", base)\n')
        self.NMF.write('setenv("NetCDF_ROOT", base)\n')
        self.NMF.write('setenv("NetCDF_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("NetCDF_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("NetCDF_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libnetcdf.a'
      elif(name == 'netcdf-fortran'):
        self.software_list[name]['lib'] = self.prefix + '/lib/libnetcdff.a'
      elif(name == 'netcdf-cxx4'):
        self.software_list[name]['lib'] = self.prefix + '/lib/libnetcdf_c++4.a'
      elif(name == 'nccmp'):
        self.NMF.write('setenv("NCCMP_ROOT", base)\n')
        self.NMF.write('setenv("NCCMP_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/bin/nccmp'
      elif(name == 'PIO'):
        self.NMF.write('setenv("PIO", base)\n')
        self.NMF.write('setenv("PIO_ROOT", base)\n')
        self.NMF.write('setenv("PIO_INCLUDES", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("PIO_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("PIO_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libpiof.a'
      elif(name == 'udunits'):
        self.NMF.write('setenv("UDUNITS2_ROOT", base)\n')
        self.NMF.write('setenv("UDUNITS2_PATH", base)\n')
        self.NMF.write('setenv("UDUNITS2_INCLUDE_DIRS", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("UDUNITS2_LIBRARIES", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("UDUNITS2_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libudunits2.a'
      elif(name == 'boost'):
        self.NMF.write('setenv( "BOOST_ROOT", base)\n')
        self.NMF.write('setenv( "Boost_INCLUDE_DIR", pathJoin(base,"include"))\n')
        self.NMF.write('setenv( "BOOST_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libboost_wave.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libboost_wave.so'
      elif(name == 'eigen'):
        self.NMF.write('setenv("EIGEN_ROOT", base)\n')
        self.NMF.write('setenv("EIGEN3_PATH", base)\n')
        self.NMF.write('setenv("EIGEN_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/include/eigen3/Eigen/SuperLUSupport'
      elif(name == 'sqlite'):
        self.NMF.write('setenv("SQLITE3_ROOT", base)\n')
        self.NMF.write('setenv("SQLITE3_PATH", base)\n')
        self.NMF.write('setenv("SQLITE3_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libsqlite3.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libsqlite3.so.0.8.6'
      elif(name == 'proj'):
        self.NMF.write('setenv("proj_ROOT", base)\n')
        self.NMF.write('setenv("proj_PATH", base)\n')
        self.NMF.write('setenv("proj_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libproj.dylib'
          self.software_list[name]['lib'] = self.prefix + '/lib/libproj.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libproj.so.19.2.1'
      elif(name == 'ecbuild'):
        self.NMF.write('setenv("ECBUILD_PATH",base)\n')
        self.NMF.write('setenv("ECBUIID_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/bin/ecbuild'
      elif(name == 'eckit'):
        self.NMF.write('setenv("eckit_ROOT", base)\n')
        self.NMF.write('setenv("eckit_DIR", pathJoin(base,"lib","cmake","eckit"))\n')
        self.NMF.write('setenv("ECKIT_PATH", base)\n')
        self.NMF.write('setenv("ECKIT_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libeckit.dylib'
          self.software_list[name]['lib'] = self.prefix + '/lib64/libeckit.so'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libeckit.so'
      elif(name == 'fckit'):
        self.NMF.write('setenv("fckit_ROOT", base)\n')
        self.NMF.write('setenv("fckit_DIR", pathJoin(base,"lib","cmake","fckit"))\n')
        self.NMF.write('setenv("FCKIT_PATH", base)\n')
        self.NMF.write('setenv("FCKIT_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libfckit.dylib'
          self.software_list[name]['lib'] = self.prefix + '/lib64/libfckit.so'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libfckit.so'
      elif(name == 'atlas'):
        self.NMF.write('setenv("atlas_ROOT", base)\n')
        self.NMF.write('setenv("atlas_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libatlas.0.20.dylib'
          self.software_list[name]['lib'] = self.prefix + '/lib64/libatlas.so.0.20'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libatlas.so'
      elif(name == 'fms'):
        self.NMF.write('setenv("fms_ROOT", base)\n')
        self.NMF.write('setenv("fms_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libfms.dylib'
          self.software_list[name]['lib'] = self.prefix + '/lib64/libfms.so'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libfms.so'
      elif(name == 'gsl_lite'):
        self.NMF.write('setenv("gsl_lite_ROOT", base)\n')
        self.NMF.write('setenv("gsl_lite_DIR", pathJoin(base,"lib","cmake","gsl-lite"))\n')
        self.NMF.write('setenv("gsl_lite_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/include/gsl-lite/gsl-lite.hpp'
      elif(name == 'CGAL'):
        self.NMF.write('setenv("CGAL_ROOT", base)\n')
        self.NMF.write('setenv("CGAL_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/include/CGAL/atomic.h'
      elif(name == 'ESMF'):
        self.NMF.write('setenv("ESMF_ROOT", base)\n')
        self.NMF.write('setenv("ESMF_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libesmf.a'
      elif(name == 'pybind11'):
        self.NMF.write('setenv("pybind11_ROOT", base)\n')
        self.NMF.write('setenv("pybind11_DIR", base,"share","cmake","pybind11")\n')
        self.NMF.write('setenv("pybind11_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/include/pybind11/eigen.h'
      elif(name == 'nco'):
        self.NMF.write('setenv("nco_ROOT", base)\n')
        self.NMF.write('setenv("nco_DIR", base)\n')
        self.NMF.write('setenv("nco_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libnco.a'
      elif(name == 'lapack'):
        self.NMF.write('setenv("LAPACK_ROOT", base)\n')
        self.NMF.write('setenv("LAPACK_LIBRARIES", base)\n')
        self.NMF.write('setenv("LAPACK_LIBRARIES_DIR", base)\n')
        self.NMF.write('setenv("LAPACK_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/liblapack.a'
          self.software_list[name]['lib'] = self.prefix + '/lib64/liblapack.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/liblapack.a'
      elif(name == 'plasma'):
        self.NMF.write('setenv("LAPACK_ROOT", base)\n')
        self.NMF.write('setenv("LAPACK_LIBRARIES", base)\n')
        self.NMF.write('setenv("LAPACK_LIBRARIES_DIR", base)\n')
        self.NMF.write('setenv("LAPACK_INCLUDE_DIR", pathJoin(base,"include"))\n')
        self.NMF.write('setenv("LAPACK_VERSION", ' + '"' + version + '")\n')
        self.NMF.write('setenv("BLAS_DIR", base)\n')
        self.NMF.write('setenv("BLAS_LIBDIR", pathJoin(base,"lib"))\n')
        self.NMF.write('setenv("BLAS_INCDIR", pathJoin(base,"include"))\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libplasma.a'
          self.software_list[name]['lib'] = self.prefix + '/lib64/libplasma.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libplasma.a'
      elif(name == 'gptl'):
        self.NMF.write('setenv("gptl_ROOT", base)\n')
        self.NMF.write('setenv("gptl_DIR", base)\n')
        self.NMF.write('setenv("gptl_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libgptl.a'
      elif(name == 'fftw'):
        self.NMF.write('setenv("fftw_ROOT", base)\n')
        self.NMF.write('setenv("fftw_DIR", base)\n')
        self.NMF.write('setenv("fftw_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libfftw3_mpi.a'
      elif(name == 'bufr'):
        self.NMF.write('setenv("bufr_ROOT", base)\n')
        self.NMF.write('setenv("bufrlib_ROOT", base)\n')
        self.NMF.write('setenv("bufr_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libbufr_d_DA.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libbufr_d.a'
      elif(name == 'odc'):
        self.NMF.write('setenv("odc_ROOT", base)\n')
        self.NMF.write('setenv("odc_DIR", base)\n')
        self.NMF.write('setenv("odc_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libodc.a'
      elif(name == 'libpng'):
        self.NMF.write('setenv("libpng_ROOT", base)\n')
        self.NMF.write('setenv("libpng_DIR", base)\n')
        self.NMF.write('setenv("libpng_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libpng.a'
          self.software_list[name]['lib'] = self.prefix + '/lib64/libpng.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib64/libpng.a'
      elif(name == 'libjpeg'):
        self.NMF.write('setenv("libjpeg_ROOT", base)\n')
        self.NMF.write('setenv("libjpeg_DIR", base)\n')
        self.NMF.write('setenv("libjpeg_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/libjpeg.dylib'
          self.software_list[name]['lib'] = self.prefix + '/lib/libjpeg.so'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libjpeg.so'
      elif(name == 'jasper'):
        self.NMF.write('setenv("jasper_ROOT", base)\n')
        self.NMF.write('setenv("jasper_DIR", base)\n')
        self.NMF.write('setenv("jasper_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libjasper.a'
      elif(name == 'baselibs'):
        self.NMF.write('setenv("baselibs_ROOT", base)\n')
        self.NMF.write('setenv("baselibs_DIR", base)\n')
        self.NMF.write('setenv("baselibs_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libbaselibs.a'
      elif(name == 'nceplibs'):
        self.NMF.write('setenv("nceplibs_ROOT", base)\n')
        self.NMF.write('setenv("nceplibs_DIR", base)\n')
        self.NMF.write('setenv("nceplibs_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libw3emc_d.a'
      elif(name == 'geos'):
        self.NMF.write('setenv("geos_ROOT", base)\n')
        self.NMF.write('setenv("geos_DIR", base)\n')
        self.NMF.write('setenv("geos_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libgeos.3.9.0.dylib'
      elif(name == 'pdtoolkit'):
        self.NMF.write('setenv("PDTOOLKIT_ROOT", base)\n')
        self.NMF.write('setenv("PDTOOLKIT_DIR", base)\n')
        self.NMF.write('setenv("PDTOOLKIT_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/apple/lib/libpdb.a'
          self.software_list[name]['lib'] = self.prefix + '/lib/libpdb.a'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/lib/libpdb.a'
      elif(name == 'tau2'):
        self.NMF.write('setenv("tau2_ROOT", base)\n')
        self.NMF.write('setenv("tau2_DIR", base)\n')
        self.NMF.write('setenv("tau2_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libTAU_tf.a'
      elif(name == 'tkdiff'):
       #self.NMF.write('setenv("tkdiff_ROOT", base)\n')
       #self.NMF.write('setenv("tkdiff_DIR", base)\n')
       #self.NMF.write('setenv("tkdiff_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/bin/tkdiff'
      elif(name == 'xerces'):
        self.NMF.write('setenv("xerces_ROOT", base)\n')
        self.NMF.write('setenv("xerces_DIR", base)\n')
        self.NMF.write('setenv("xerces_VERSION", ' + '"' + version + '")\n')
        self.software_list[name]['lib'] = self.prefix + '/lib/libxerces-c.a'
      elif(name == 'json'):
        self.NMF.write('setenv("json_ROOT", base)\n')
        self.NMF.write('setenv("json_DIR", base)\n')
        self.NMF.write('setenv("json_VERSION", ' + '"' + version + '")\n')
        if('gnu' == self.compilerName):
         #self.software_list[name]['lib'] = self.prefix + '/lib/pkgconfig/nlohmann_json.pc'
          self.software_list[name]['lib'] = self.prefix + '/include/nlohmann/json.hpp'
        elif('intel' == self.compilerName):
          self.software_list[name]['lib'] = self.prefix + '/include/nlohmann/json.hpp'
      elif(name == 'json-schema-validator'):
        self.software_list[name]['lib'] = self.prefix + '/lib/libnlohmann_json_schema_validator.a'
     #else:
     #  self.NMF.write('setenv("' + name + '_ROOT", base)\n')
     #  self.NMF.write('setenv("' + name + '_VERSION", ' + '"' + version + '")\n')

    self.NMF.write('\n')

  def build_package(self):
    self.history = {}
   #self.build_mpi()

    cnt = 0
    for name in self.package.keys():
      cnt += 1
      version = self.package[name]
      print('Building package {} name {}, version {}'.format(cnt, name, version))
      if(name == 'zlib'):
        self.build_zlib(name)
      elif(name == 'szip'):
        self.build_szip(name)
      elif(name == 'hdf5'):
        self.build_hdf5(name)
      elif(name == 'pnetcdf'):
        self.build_pnetcdf(name)
      elif(name == 'netcdf-c'):
        self.build_netcdf_c(name)
      elif(name == 'netcdf-fortran'):
        self.build_netcdf_fortran(name)
      elif(name == 'netcdf-cxx4'):
        self.build_netcdf_cxx4(name)
      elif(name == 'nccmp'):
        self.build_nccmp(name)
      elif(name == 'PIO'):
        self.build_pio(name)
      elif(name == 'udunits'):
        self.build_udunits(name)
      elif(name == 'boost'):
        self.build_boost(name)
      elif(name == 'eigen'):
        self.build_eigen(name)
      elif(name == 'sqlite'):
        self.build_sqlite(name)
      elif(name == 'proj'):
        self.build_proj(name)
      elif(name == 'ecbuild'):
        self.build_ecbuild(name)
      elif(name == 'eckit'):
        self.build_eckit(name)
      elif(name == 'fckit'):
        self.build_fckit(name)
      elif(name == 'bufr'):
        self.build_bufr(name)
     #elif(name == 'atlas'):
     #  self.build_atlas(name)
      elif(name == 'fms'):
        self.build_fms(name)
      elif(name == 'gsl_lite'):
        self.build_gsl_lite(name)
      elif(name == 'CGAL'):
        self.build_cgal(name)
     #elif(name == 'ESMF'):
     #  self.build_esmf(name)
      elif(name == 'pybind11'):
        self.build_pybind11(name)
     #elif(name == 'nco'):
     #  self.build_nco(name)
      elif(name == 'lapack'):
        self.build_lapack(name)
      elif(name == 'plasma'):
        self.build_plasma(name)
      elif(name == 'gptl'):
        self.build_gptl(name)
      elif(name == 'fftw'):
        self.build_fftw(name)
     #elif(name == 'odc'):
     #  self.build_odc(name)
      elif(name == 'libpng'):
        self.build_libpng(name)
      elif(name == 'libjpeg'):
        self.build_libjpeg(name)
      elif(name == 'jasper'):
        self.build_jasper(name)
     #elif(name == 'baselibs'):
     #  self.build_baselibs(name)
      elif(name == 'nceplibs'):
        self.build_nceplibs(name)
     #elif(name == 'geos'):
     #  self.build_geos(name)
      elif(name == 'pdtoolkit'):
        self.build_pdtoolkit(name)
     #elif(name == 'tau2'):
     #  self.build_tau2(name)
     #elif(name == 'tkdiff'):
     #  self.build_tkdiff(name)
      elif(name == 'xerces'):
        self.build_xerces(name)
      elif(name == 'json'):
        self.build_json(name)
      elif(name == 'json-schema-validator'):
        self.build_json_schema_validator(name)

  def gen_script_head(self, OF):
    OF.write('#!/bin/bash\n')
    OF.write('set -ex\n')
    OF.write('\n')
    OF.write('mkdir -p ' + self.workdir + '\n')
    OF.write('cd ' + self.workdir + '\n')
    OF.write('\n')

    OF.write('export CC=' + self.cc + '\n')
    OF.write('export CXX=' + self.cxx + '\n')
    OF.write('export FC=' + self.fc + '\n')
    OF.write('\n')

    OF.write('export CFLAGS=' + '" -fPIC"\n')
    OF.write('export CXXFLAGS=' + '" -fPIC"\n')
    OF.write('export FFLAGS=' + '" -fPIC"\n')
    OF.write('export FCFLAGS=' + '" -fPIC"\n')
   #OF.write('export FCFLAGS=' + '" -fPIC -fallow-argument-mismatch -fallow-invalid-boz"\n')
    OF.write('\n')

  def gen_mpi_head(self, OF):
    OF.write('#!/bin/bash\n')
    OF.write('set -ex\n')
    OF.write('\n')
    OF.write('mkdir -p ' + self.workdir + '\n')
    OF.write('cd ' + self.workdir + '\n')
    OF.write('\n')

    OF.write('export CC=' + self.mpi_cc + '\n')
    OF.write('export CXX=' + self.mpi_cxx + '\n')
    OF.write('export FC=' + self.mpi_fc + '\n')
    OF.write('\n')

    OF.write('export CFLAGS=' + '" -fPIC -w"\n')
    OF.write('export CXXFLAGS=' + '" -fPIC -w"\n')
    OF.write('export FFLAGS=' + '" -fPIC -w"\n')
    OF.write('export FCFLAGS=' + '" -fPIC -w"\n')
    OF.write('\n')

  def gen_script_tail(self, OF):
    OF.write('make clean\n')
    OF.write('make -j 8\n')
   #OF.write('make check\n')
    OF.write('make install\n')

    OF.close()

  def wget_tarfile(self, url, tarfile, OF):
    OF.write('if [ ! -f ' + tarfile + ' ]\n')
    OF.write('then\n')
    OF.write('  wget ' + url + ' -O ' + tarfile + '\n')

    item = tarfile.split('.')
    if('gz' == item[-1]):
      OF.write('  tar -zxf ' + tarfile + '\n')
    elif('xz' == item[-1]):
      OF.write('  tar -xf ' + tarfile + '\n')
    elif('bz2' == item[-1]):
      OF.write('  tar -xf ' + tarfile + '\n')
    OF.write('\n')

    OF.write('fi\n')

  def git_clone(self, gitURL, version, src_dir, OF):
    OF.write('if [ ! -d ' + src_dir + ' ]\n')
    OF.write('then\n')
    if(len(version)):
      OF.write('  git clone -b ' + version + ' ' + gitURL + ' ' + src_dir + '\n')
    else:
      OF.write('  git clone ' + gitURL + ' ' + src_dir + '\n')
    OF.write('fi\n')
    OF.write('\n')

  def get_source(self, OF, name, version=''):
    if('wget' == self.software_list[name]['method']):
      software = name + '-' + self.package[name]
      url = self.software_list[name]['url']
      item = url.split('.')
      tarfile = software + '.tar.' + item[-1]
      print(name + ' wget url: ' + url)
      self.wget_tarfile(url, tarfile, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      gitURL = self.software_list[name]['url']
      print(name + ' clone url: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)

  def create_build_dir(self, name, OF):
    build_dir = self.workdir + '/' + name + '-' + self.package[name] + '/build'
   #OF.write('rm -rf ' +  build_dir + '\n')
    OF.write('mkdir -p ' +  build_dir + '\n')
    OF.write('cd ' +  build_dir + '\n')
    OF.write('\n')

  def create_build_dirname(self, dirname, OF):
    build_dir = self.workdir + '/' + dirname + '/build'
    OF.write('rm -rf ' +  build_dir + '\n')
    OF.write('mkdir -p ' +  build_dir + '\n')
    OF.write('cd ' +  build_dir + '\n')
    OF.write('\n')

  def build_general(self, name, version=''):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    self.get_source(OF, name, version=version)

    conf_opts = ' '
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_mpi(self):
   #liba = self.prefix + '/lib/libhdf5.a'

   #if(os.path.exists(liba)):
   #  self.history[name] = self.get_cm_time(liba)
   #  return

    flnm = self.workdir + '/build_mpi.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    major = self.mpiVersion[0:3]

    tarfile = 'openmpi-' + self.mpiVersion + '.tar.gz'
    code_dir = self.workdir + '/openmpi-' + self.mpiVersion

    OF.write('if [ ! -d ' + code_dir + ' ]\n')
    OF.write('then\n')
    OF.write('if [ ! -f ' + tarfile + ' ]\n')
    OF.write('then\n')
    url = 'https://download.open-mpi.org/release/open-mpi/v' + major + '/' + tarfile

    OF.write('wget ' + url + '\n')
    OF.write('fi\n')
    OF.write('tar -zxvf ' + tarfile + '\n')
    OF.write('\n')
    OF.write('fi\n')
    
    build_dir = self.workdir + '/openmpi-' + self.mpiVersion + '/build'
    OF.write('mkdir -p ' +  build_dir + '\n')
    OF.write('cd ' +  build_dir + '\n')
    OF.write('\n')

    conf_opts = ' --enable-mpi-fortran --enable-mpi-cxx'
    conf_opts = conf_opts + ' --with-hwloc=internal --with-libevent=internal'
    conf_opts = conf_opts + ' --with-wrapper-ldflags=-Wl,-use_dylibs'
   #conf_opts = conf_opts + ' --with-wrapper-ldflags=-Wl,-commons,use_dylibs'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    os.system('chmod +x ' + flnm)

   #p = subprocess.Popen(flnm, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
   #for line in p.stdout.readlines():
   #    print line,
   #retval = p.wait()

  def build_zlib(self, name):
    self.build_general(name, version='')

  def build_szip(self, name):
    self.build_general(name, version='')

  def build_hdf5(self, name):
    liba = self.prefix + '/lib/libhdf5.a'

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_mpi_head(OF)

    self.get_source(OF, name, version='')

    OF.write('cd ..\n')
    OF.write('autoreconf -i -f\n')
    OF.write('cd build\n')

    conf_opts = ' --with-pic --enable-fortran'
    conf_opts = conf_opts + ' --enable-static --enable-shared'
    conf_opts = conf_opts + ' --with-szlib=' + self.prefix
    conf_opts = conf_opts + ' --with-zlib=' + self.prefix
    conf_opts = conf_opts + ' --enable-parallel'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_pnetcdf(self, name):
    liba = self.prefix + '/lib/libpnetcdf.a'

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_mpi_head(OF)

    src_dir = name + '-' + self.package[name]

   #src_dir = src_dir.replace('.', '_')
   #gitURL = 'https://bitbucket.hdfgroup.org/scm/hdffv/hdf5.git'
   #print(name + ' gitURL: ' + gitURL)
   #self.git_clone(gitURL, src_dir, OF)

    tarfile = name + '-' + self.package[name] + '.tar.gz'
    url = 'https://parallel-netcdf.github.io/Release/' + tarfile

    print(name + ' url: ' + url)

    self.wget_tarfile(url, tarfile, OF)
    self.create_build_dir(name, OF)

   #OF.write('autoreconf -i -f\n')

    conf_opts = ' --enable-static --enable-shared --disable-cxx'
   #conf_opts = conf_opts + ' --with-szlib=' + self.prefix
   #conf_opts = conf_opts + ' --with-zlib=' + self.prefix
   #conf_opts = conf_opts + ' --enable-parallel'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def get_cm_time(self, filename):
   #print("Last modified: %s" % time.ctime(os.path.getmtime("test.txt")))
   #print("Created: %s" % time.ctime(os.path.getctime("test.txt")))
    mt = time.ctime(os.path.getmtime(filename))
    ct = time.ctime(os.path.getctime(filename))

    t = datetime.datetime.strptime(mt, '%a %b %d %H:%M:%S %Y')
    mstamp = t.timestamp()

    t = datetime.datetime.strptime(ct, '%a %b %d %H:%M:%S %Y')
    cstamp = t.timestamp()

    if(self.debug):
      print('File: ' + filename)
      print('\tCreated: ' + ct)
      print('\tStamp: ', cstamp)
      print('')

    hist = {}
    hist['mstamp'] = mstamp
    hist['cstamp'] = cstamp
    hist['mtime'] = mt
    hist['ctime'] = ct

    return hist

  def gen_netcdf(self, OF):
    OF.write('#!/bin/bash\n')
    OF.write('set -ex\n')
    OF.write('\n')
    OF.write('mkdir -p ' + self.workdir + '\n')
    OF.write('cd ' + self.workdir + '\n')
    OF.write('\n')

    OF.write('export CC=' + self.mpi_cc + '\n')
    OF.write('export CXX=' + self.mpi_cxx + '\n')
    OF.write('export FC=' + self.mpi_fc + '\n')
    OF.write('\n')

    OF.write('export CFLAGS=' + '" -fPIC -I' + self.prefix + '/include"\n')
    OF.write('export CXXFLAGS=' + '" -fPIC -std=c++11 -I' + self.prefix + '/include"\n')
    OF.write('export FFLAGS=' + '" -fPIC -I' + self.prefix + '/include"\n')
    OF.write('export FCFLAGS=' + '" -fPIC -I' + self.prefix + '/include"\n')

  def gen_netcdf_c_prerequites(self, OF):
    self.gen_netcdf(OF)

    OF.write('export LDFLAGS=' + '" -L' + self.prefix + '/lib -lz -lsz -lhdf5 -lhdf5_hl -lpnetcdf"\n')
    OF.write('\n')

    for name in ['zlib', 'szip', 'hdf5', 'pnetcdf']:
      liba = self.software_list[name]['lib']
      if(os.path.exists(liba)):
        pass
      else:
        print('Library ' + liba + ' does not exist. Stop')
        sys.exit(-1)

  def build_netcdf_c(self, name):
    liba = self.software_list[name]['lib']

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_netcdf_c_prerequites(OF)

    self.get_source(OF, name)

   #OF.write('autoreconf -i -f\n')

    conf_opts = ' --enable-netcdf-4'
    conf_opts = conf_opts + ' --enable-pnetcdf'
    conf_opts = conf_opts + ' --enable-parallel-tests'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def gen_netcdf_fortran_prerequites(self, OF):
    self.gen_netcdf(OF)

    OF.write('export LDFLAGS=' + '" -L' + self.prefix + '/lib -lz -lsz -lhdf5 -lhdf5_hl -lpnetcdf -lnetcdf"\n')
    OF.write('\n')

    for name in ['zlib', 'szip', 'hdf5', 'pnetcdf', 'netcdf-c']:
      liba = self.software_list[name]['lib']
      if(os.path.exists(liba)):
        pass
      else:
        print('Library ' + liba + ' does not exist. Stop')
        sys.exit(-1)

  def build_netcdf_fortran(self, name):
    liba = self.software_list[name]['lib']

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_netcdf_fortran_prerequites(OF)

    self.get_source(OF, name)

   #OF.write('autoreconf -i -f\n')

    conf_opts = ' --enable-netcdf-4'
    conf_opts = conf_opts + ' --enable-pnetcdf'
    conf_opts = conf_opts + ' --enable-parallel-tests'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_netcdf_cxx4(self, name):
    liba = self.software_list[name]['lib']

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #Prerequisites is the same as netcdf-fortran
    self.gen_netcdf_fortran_prerequites(OF)

    self.get_source(OF, name)

    conf_opts = ' '
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_nccmp(self, name):
    liba = self.software_list[name]['lib']

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #Prerequisites is the same as netcdf-fortran
    self.gen_netcdf_fortran_prerequites(OF)

    version = self.package[name]
    tarfile = name + '-' + version + '.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
    self.wget_tarfile(url, tarfile, OF)
    self.create_build_dir(name, OF)

   #OF.write('autoreconf -i -f\n')

    conf_opts = ' '
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def gen_pio_prerequites(self, OF):
    self.gen_netcdf(OF)

    OF.write('export CFLAGS=" -fPIC -fcommon -I' + self.prefix + '/include"\n')
    OF.write('export LDFLAGS=' + '" -L' + self.prefix + '/lib -lz -lsz -lhdf5 -lhdf5_hl -lpnetcdf -lnetcdf -lnetcdff"\n')
    OF.write('\n')

    for name in ['zlib', 'szip', 'hdf5', 'pnetcdf', 'netcdf-c', 'netcdf-fortran']:
      liba = self.software_list[name]['lib']
      if(os.path.exists(liba)):
        pass
      else:
        print('Library ' + liba + ' does not exist. Stop')
        sys.exit(-1)

  def build_pio(self, name):
    liba = self.software_list[name]['lib']

    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_pio_prerequites(OF)

    self.get_source(OF, name, version='')
   #version = self.package[name]
   #src_dir = name + '-' + version
   #gitURL = self.software_list[name]['url']
   #print(name + ' gitURL: ' + gitURL)
   #self.git_clone(gitURL, '', src_dir, OF)

    pio_dir = self.workdir + '/' + name + '-' + self.package[name]
    OF.write('cd ' + pio_dir + '\n')
    OF.write('autoreconf -i -f\n')

   #self.create_build_dir(name, OF)

    conf_opts = ' --enable-fortran'
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_udunits(self, name):
    self.build_general(name)

  def build_boost(self, name):
    liba = self.software_list[name]['lib']
    print('boost lib:' + liba)
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    software = name + '_' + self.package[name]
    software = software.replace('.', '_')
    tarfile = software + '.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
    self.wget_tarfile(url, tarfile, OF)

   #self.create_build_dir(name, OF)
   #BoostRoot = self.workdir + '/' + software
   #BoostBuild = BoostRoot + '/BoostBuild'
   #build_boost = BoostRoot + '/build_boost'
   #OF.write('[[ -d ' + BoostBuild + ' ]] && rm -rf ' + BoostBuild + '\n')
   #OF.write('[[ -d ' + build_boost + ' ]] && rm -rf ' + build_boost + '\n')

   #OF.write('mkdir -p ' + BoostRoot + '/tools/build\n')
   #OF.write('cd ' + BoostRoot + '/tools/build\n')

   #toolset = self.cc
   #debug='--debug-configuration'

   #OF.write('cp ' + BoostRoot + '/tools/build/example/user-config.jam ./user-config.jam\n')
   #OF.write('cat >> ./user-config.jam << EOF\n')

   #OF.write('# ------------------\n')
   #OF.write('# MPI configuration.\n')
   #OF.write('# ------------------\n')
   #OF.write('using mpi : $MPICC ;\n')
   #OF.write('EOF\n')
   #OF.write('\n')

   #OF.write('rm -f $HOME/user-config.jam\n')
   #OF.write('[[ -z $mpi ]] && rm -f ./user-config.jam || mv -f ./user-config.jam $HOME\n')
   #OF.write('\n')

   #OF.write('./bootstrap.sh --with-toolset=' + toolset + '\n')
   #OF.write('./b2 install ' + debug + ' --prefix=' + BoostBuild + '\n')
   #OF.write('\n')

   #OF.write('export PATH="' + BoostBuild + '/bin:$PATH"\n')
   #OF.write('\n')

   #OF.write('cd ' + BoostRoot + '\n')
   #OF.write('b2 ' + debug + ' --build-dir=' + build_boost + ' address-model=64 toolset=' + toolset + ' stage\n')
   #OF.write('cp -R boost ' + self.prefix + '/include\n')
   #OF.write('mv stage/lib/* ' + self.prefix + '/lib\n')
   #OF.write('\n')

   #OF.write('rm -f $HOME/user-config.jam\n')

   #OF.write('autoreconf -i -f\n')

   #conf_opts = ' --with-pic --enable-fortran'
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
   #OF.write('\n')

   #self.gen_script_tail(OF)

    build_dir = self.workdir + '/' + name + '-' + self.package[name]
    OF.write('cd ' +  build_dir + '\n')
    OF.write('\n')

    OF.write('./bootstrap.sh --prefix=' + self.prefix + '\n')
   #OF.write('./b2 headers\n')
    OF.write('./b2 install\n')

    self.run_script(flnm)
    self.check_libs(liba, name)

  def get_dir_name(self, url):
    item = url.split('/')
    tarfile = item[-1].strip()
    item = tarfile.split('.')
    dirname = item[0]
    return tarfile, dirname

  def build_eigen(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    self.get_source(OF, name, version='')
   #software = name + '-' + self.package[name]
   #tarfile = software + '.tar.gz'
   #url = self.software_list[name]['url']
   #print(name + ' url: ' + url)
   #self.wget_tarfile(url, tarfile, OF)

    self.create_build_dir(name, OF)

    conf_opts = ' '
    OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_sqlite(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

   #software = name + '-' + self.package[name]
   #tarfile = software + '.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
    tarfile, dirname = self.get_dir_name(url)
    self.wget_tarfile(url, tarfile, OF)

    self.create_build_dirname(dirname, OF)

    conf_opts = ' '
   #OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_proj(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    OF.write('export SQLITE3_CFLAGS=' + '" -I' + self.prefix + '/include"\n')
    OF.write('export SQLITE3_LIBS=' + '" -L' + self.prefix + '/lib -lsqlite3"\n')

    software = name + '-' + self.package[name]
    tarfile = software + '.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
   #tarfile, dirname = self.get_dir_name(url)
    self.wget_tarfile(url, tarfile, OF)

   #self.create_build_dir(name, OF)
   #self.create_build_dirname(dirname, OF)
    build_dir = self.workdir + '/' + software
    OF.write('cd ' +  build_dir + '\n')
    OF.write('\n')

   #conf_opts = ' --enable-static --enable-lto --with-gnu-ld --disable-tiff'
    conf_opts = ' '
   #OF.write('LIB_DIR=$SQLITE_ROOT cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

   #OF.write('cd build\n')
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
   #OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_ecbuild(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    src_dir = name + '-' + self.package[name]
    version = ''
    gitURL = self.software_list[name]['url']
    print(name + ' gitURL: ' + gitURL)
    self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    OF.write('cd ..\n')
    OF.write('\n')

    OF.write('git fetch --tags\n')
    OF.write('git checkout ' + self.package[name] + '\n')

    OF.write('cd build\n')
    OF.write('\n')

    conf_opts = ' '
    OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def check_ec_prerequites(self):
    for name in ['ecbuild']:
      liba = self.software_list[name]['lib']
      if(os.path.exists(liba)):
        pass
      else:
        print('Library ' + liba + ' does not exist. Stop')
        sys.exit(-1)

  def build_eckit(self, name):
    self.build_kit(name)

  def build_fckit(self, name):
    self.build_kit(name)

  def build_kit(self, name):
    self.check_ec_prerequites()

    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    src_dir = name + '-' + self.package[name]
    version = ''
    gitURL = self.software_list[name]['url']
    print(name + ' gitURL: ' + gitURL)
    self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    OF.write('cd ..\n')
    OF.write('\n')

    OF.write('git fetch --tags\n')
    OF.write('git checkout ' + self.package[name] + '\n')

    OF.write('cd build\n')
    OF.write('\n')

    conf_opts = ' --build=Release'
    OF.write('ecbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_bufr(self, name):
    liba = self.software_list[name]['lib']
   #print('bufr liba = ', liba)
   #sys.exit(-1)
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    src_dir = name + '-' + self.package[name]
    version = ''
    gitURL = self.software_list[name]['url']
    print(name + ' gitURL: ' + gitURL)
    self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    OF.write('cd ..\n')
    OF.write('\n')

    OF.write('git fetch \n')
    OF.write('git checkout --detach ' + self.package[name] + '\n')

    OF.write('cd build\n')
    OF.write('\n')

    conf_opts = ' '
    OF.write('cmake -DENABLE_PYTHON=ON -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_atlas(self, name):
    self.check_ec_prerequites()

    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    src_dir = name + '-' + self.package[name]
    version = ''
    gitURL = self.software_list[name]['url']
    print(name + ' gitURL: ' + gitURL)
    self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    OF.write('cd ..\n')
    OF.write('\n')

    OF.write('git fetch --tags\n')
    OF.write('git checkout ' + self.package[name] + '\n')

    OF.write('cd build\n')
    OF.write('\n')

    OF.write('export LDFLAGS=' + '" -L' + self.prefix + '/lib64 -leckit -leckit_mpi"\n')

    conf_opts = ' --build=Release'
    OF.write('ecbuild --prefix=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_fms(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    src_dir = name + '-' + self.package[name]
    version = self.package[name]
    gitURL = self.software_list[name]['url']
    print(name + ' gitURL: ' + gitURL)
    self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    OF.write('cd ..\n')
    OF.write('\n')

   #OF.write('git fetch --tags\n')
   #OF.write('git checkout ' + self.package[name] + '\n')

    OF.write('cd build\n')
    OF.write('\n')

    conf_opts = ' -D32BIT=ON -D64BIT=ON -DGFS_PHYS=ON -DLARGEFILE=ON'
    OF.write('ecbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_gsl_lite(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    src_dir = name + '-' + self.package[name]
    version = ''
    gitURL = self.software_list[name]['url']
    print(name + ' gitURL: ' + gitURL)
    self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    OF.write('cd ..\n')
    OF.write('\n')

    OF.write('git fetch \n')
    OF.write('git checkout ' + self.package[name] + '\n')

    OF.write('cd build\n')
    OF.write('\n')

    conf_opts = ' -DGSL_LITE_OPT_BUILD_TESTS=OFF -DGSL_LITE_OPT_INSTALL_COMPAT_HEADER=ON -DCMAKE_VERBOSE_MAKEFILE=1'
    OF.write('cmake -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_cgal(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    software = name + '-' + self.package[name]
    tarfile = software + '-library.tar.xz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
   #tarfile, dirname = self.get_dir_name(url)
    self.wget_tarfile(url, tarfile, OF)

   #src_dir = name + '-' + self.package[name]
   #version = ''
   #gitURL = self.software_list[name]['url']
   #print(name + ' gitURL: ' + gitURL)
   #self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)
   
    conf_opts = ' '
    OF.write('cmake -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    OF.write('make clean\n')
    OF.write('make install\n')
    OF.write('\n')

   #self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_esmf(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    software = name + '_' + self.package[name]
    tarfile = software + '.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
   #tarfile, dirname = self.get_dir_name(url)
    self.wget_tarfile(url, tarfile, OF)

   #src_dir = name + '-' + self.package[name]
   #version = ''
   #gitURL = self.software_list[name]['url']
   #print(name + ' gitURL: ' + gitURL)
   #self.git_clone(gitURL, version, src_dir, OF)

   #self.create_build_dir(name, OF)
    build_dir = self.workdir + '/esmf-' + name + '_' + self.package[name]
    OF.write('cd ' +  build_dir + '\n')
    OF.write('\n')

    OF.write('export ESMF_CXXCOMPILER=' + self.mpi_cxx + '\n')
    OF.write('export ESMF_CXXLINKER=' + self.mpi_cxx + '\n')
    OF.write('export ESMF_F90COMPILER=' + self.mpi_fc + '\n')
    OF.write('export ESMF_F90LINKER=' + self.mpi_fc + '\n')
    OF.write('export ESMF_NETCDF=nc-config\n')
    OF.write('export ESMF_NFCONFIG=nf-config\n')
    OF.write('export ESMF_PNETCDF=pnetcdf-config\n')
    OF.write('export ESMF_BOPT=O\n')
    OF.write('export ESMF_OPTLEVEL=2\n')
    OF.write('export ESMF_INSTALL_PREFIX=' + self.prefix + '\n')
    OF.write('export ESMF_INSTALL_BINDIR=bin\n')
    OF.write('export ESMF_INSTALL_LIBDIR=lib\n')
    OF.write('export ESMF_INSTALL_MODDIR=mod\n')
    OF.write('export ESMF_ABI=64\n')
    OF.write('export ESMF_DIR=' + build_dir + '\n')
   
   #conf_opts = ' '
   #OF.write('cmake -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
   #OF.write('\n')

    OF.write('make clean\n')
    OF.write('make info\n')
    OF.write('make -j 4\n')
    OF.write('make install\n')
    OF.write('\n')

   #self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_pybind11(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)
   
    conf_opts = ' '
    OF.write('cmake -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
   #OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    OF.write('make clean\n')
    OF.write('make install\n')
    OF.write('\n')

   #self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_nco(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)
   
    conf_opts = ' --enable-doc=no'
   #OF.write('cmake -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + ' ..\n')
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_lapack(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

    OF.write('cd ..\n')
    OF.write('\n')
   
    conf_opts = ' -DCMAKE_BUILD_TYPE=Release  -DCMAKE_Fortran_COMPILER=' + self.fc
    OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    OF.write('cd build\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_plasma(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    software = name + '-' + self.package[name]
    tarfile = software + '-library.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
   #tarfile, dirname = self.get_dir_name(url)
    self.wget_tarfile(url, tarfile, OF)

    self.create_build_dir(name, OF)

    OF.write('cd ..\n')
    OF.write('\n')
   
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_gptl(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      uname = name.upper()
     #self.create_build_dir(uname, OF)
      build_dir = self.workdir + '/' + uname + '-' + self.package[name] + '/build'
      OF.write('rm -rf ' +  build_dir + '\n')
      OF.write('mkdir -p ' +  build_dir + '\n')
      OF.write('cd ' +  build_dir + '\n')
      OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

    OF.write('cd ..\n')
    OF.write('\n')

    OF.write('autoreconf -i -f\n')

    OF.write('cd build\n')
    OF.write('\n')
   
    conf_opts = ' --enable-pmpi'
   #OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_fftw(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = name + '-' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
     #uname = name.upper()
      self.create_build_dir(name, OF)
     #build_dir = self.workdir + '/' + uname + '-' + self.package[name] + '/build'
     #OF.write('rm -rf ' +  build_dir + '\n')
     #OF.write('mkdir -p ' +  build_dir + '\n')
     #OF.write('cd ' +  build_dir + '\n')
      OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

   #OF.write('cd ..\n')
   #OF.write('\n')

   #OF.write('autoreconf -i -f\n')

   #OF.write('cd build\n')
   #OF.write('\n')
   
    conf_opts = ' --enable-openmp --enable-threads --enable-mpi'
   #OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_odc(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
     #self.create_build_dir(name, OF)
     #uname = name.upper()
      build_dir = self.workdir + '/' + 'react-tabtab-' + self.package[name] + '/build'
      OF.write('rm -rf ' +  build_dir + '\n')
      OF.write('mkdir -p ' +  build_dir + '\n')
      OF.write('cd ' +  build_dir + '\n')
      OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

   #OF.write('cd ..\n')
   #OF.write('\n')

   #OF.write('autoreconf -i -f\n')

   #OF.write('cd build\n')
   #OF.write('\n')
   
    conf_opts = ' --build=Release ..'
    OF.write('ecbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_libpng(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
     #uname = name.upper()
     #build_dir = self.workdir + '/' + 'react-tabtab-' + self.package[name] + '/build'
     #OF.write('rm -rf ' +  build_dir + '\n')
     #OF.write('mkdir -p ' +  build_dir + '\n')
     #OF.write('cd ' +  build_dir + '\n')
     #OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

   #OF.write('cd ..\n')
   #OF.write('\n')

   #OF.write('autoreconf -i -f\n')

   #OF.write('cd build\n')
   #OF.write('\n')

    OF.write('export LDFLAGS=' + '" -L' + self.prefix + '/lib -lz"\n')
   
    conf_opts = ' -DCMAKE_BUILD_TYPE=RELEASE -DZLIB_ROOT=' + self.prefix 
    OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_libjpeg(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
     #uname = name.upper()
     #build_dir = self.workdir + '/' + 'react-tabtab-' + self.package[name] + '/build'
     #OF.write('rm -rf ' +  build_dir + '\n')
     #OF.write('mkdir -p ' +  build_dir + '\n')
     #OF.write('cd ' +  build_dir + '\n')
     #OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

     #OF.write('cd ..\n')
     #OF.write('\n')

     #OF.write('git fetch \n')
     #OF.write('git checkout ' + self.package[name] + '\n')

     #OF.write('cd build\n')
     #OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

   #OF.write('cd ..\n')
   #OF.write('\n')

   #OF.write('autoreconf -i -f\n')

   #OF.write('cd build\n')
   #OF.write('\n')
   
    conf_opts = ' -DBUILD_TESTS=ON -DBUILD_EXECUTABLES=ON -DCMAKE_BUILD_TYPE=RELEASE'
    OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_jasper(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'version-' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
     #uname = name.upper()
      build_dir = self.workdir + '/' + 'jasper-version-' + self.package[name] + '/build'
      OF.write('rm -rf ' +  build_dir + '\n')
      OF.write('mkdir -p ' +  build_dir + '\n')
      OF.write('cd ' +  build_dir + '\n')
      OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

    OF.write('cd ..\n')
   #OF.write('rm -rf ' +  build_dir + '\n')
    OF.write('\n')

   #OF.write('autoreconf -i -f\n')
    OF.write('autoreconf -i\n')

    OF.write('cd build\n')
    OF.write('\n')
   
   #conf_opts = ' -DCMAKE_BUILD_TYPE=RELEASE -DJAS_ENABLE_DOC=FALSE -DJAS_ENABLE_LIBJPEG=TRUE'
   #OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    conf_opts = ' --enable-static --enable-libjpeg'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def run_script(self, flnm):
    print('Run Script: '  + flnm)

    os.system('chmod +x ' + flnm)
    os.system(flnm)

   #p = subprocess.Popen(flnm, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
   #for line in p.stdout.readlines():
   #    print line,
   #retval = p.wait()

  def check_libs(self, liba, name):
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      return 0
    else:
      print('Failed to buile ' + name)
      sys.exit(-1)
    return -1

  def build_baselibs(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = 'version-' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
     #uname = name.upper()
      build_dir = self.workdir + '/' + 'jasper-version-' + self.package[name] + '/build'
      OF.write('rm -rf ' +  build_dir + '\n')
      OF.write('mkdir -p ' +  build_dir + '\n')
      OF.write('cd ' +  build_dir + '\n')
      OF.write('\n')
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = self.package[name]
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)

      OF.write('cd ' + src_dir + '\n')
     #OF.write('git fetch \n')
     #OF.write('git checkout ' + self.package[name] + '\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

   #OF.write('autoreconf -i -f\n')
   
   #conf_opts = ' -DCMAKE_BUILD_TYPE=RELEASE -DJAS_ENABLE_DOC=FALSE -DJAS_ENABLE_LIBJPEG=TRUE'
   #OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #conf_opts = ' --enable-static --enable-libjpeg'
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
   #OF.write('\n')

    OF.write('make clean\n')
    OF.write('make install F90=' + self.mpi_fc + ' ESMF_COMM=' + self.mpiName + ' CONFIG=' + self.mpiVersion + ' prefix=' + self.prefix + '\n')
    OF.write('\n')

   #self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_nceplibs(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    OF.write('cd /work/noaa/gsienkf/weihuang/src/jedi_tools/NCEPlibs\n')
    OF.write('rm -f *.a\n')
    OF.write('rm -f macro.make\n')

    if('gnu' == self.compilerName):
      if('darwin' == sys.platform):
        OF.write('ln -sf macros.make.macosx.gnu macros.make\n')
      else:
        OF.write('ln -sf macros.make.cheyenne.gnu macros.make\n')
    elif('intel' == self.compilerName):
     #OF.write('ln -sf macros.make.aws.intel macros.make\n')
      OF.write('ln -sf macros.make.hera macros.make\n')
    else:
      print('Do not know how to compile ' + name + ' using compiler ' + self.compilerName)
      sys.exit(-1)
      
    OF.write('export MACOSX=1\n')
    OF.write('make\n')

    OF.write('cp *.a ' + self.prefix + '/lib/.\n')
    OF.write('cp include/* ' + self.prefix + '/include/.\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_geos(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = name + '-' + self.package[name]
      tarfile = software + '.tar.bz2'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = self.package[name]
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)

      OF.write('cd ' + src_dir + '\n')
     #OF.write('git fetch \n')
     #OF.write('git checkout ' + self.package[name] + '\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

   #OF.write('autoreconf -i -f\n')

    OF.write('cd ..\n')
    OF.write('\n')
   
    conf_opts = ' '
    OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #conf_opts = ' --enable-static --enable-libjpeg'
   #OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
   #OF.write('\n')

    OF.write('cd build\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_pdtoolkit(self, name):
   #self.build_general_wget(name)
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    tarfile = name + '-' + self.package[name] + '.tar.gz'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
    self.wget_tarfile(url, tarfile, OF)
    self.create_build_dir(name, OF)

    OF.write('cd ..\n')
    OF.write('mkdir -p apple/bin\n')

    conf_opts = ' '
    OF.write('./configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

   #self.gen_script_tail(OF)

    OF.write('make\n')
    OF.write('make install\n')
    OF.write('\n')
    OF.write('cp -r ./include/* ' + self.prefix + '/include/.\n')
    for item in ['cparse', 'f95parse', 'pdbcomment', 'pdbmerge', 'tau_instrumentor',
      'cxxparse', 'gfparse', 'pdbconv', 'pdbstmt', 'xmlgen',
      'f90parse', 'gfparse48', 'pdbhtml', 'pdbtree']:
      OF.write('cp -r ./apple/bin/' + item + ' ' + self.prefix + '/bin/.\n')
   #OF.write('cp -r ./ductape ' + self.prefix + '/apple/.\n')
    OF.write('cp -r ./ductape/lib/libpdb.a ' + self.prefix + '/apple/lib/.\n')

    OF.close()

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_tau2(self, name):
   #self.build_general_wget(name)
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = name + '-' + self.package[name]
      tarfile = software + '.tar.bz2'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)

    OF.write('cd ..\n')

    conf_opts = ' -c++=' + self.mpi_cxx + ' -cc=' + self.mpi_cc + ' -fortran=' + self.mpi_fc + ' -mpi -ompt -bfd=download '
    conf_opts = conf_opts + ' -dwarf=download -unwind=download -iowrapper -pdt=' + self.prefix
    OF.write('./configure -prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_tkdiff(self, name):
   #self.build_general_wget(name)
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)

    software = name + '-' + self.package[name]
    tarfile = software + '.zip'
    url = self.software_list[name]['url']
    print(name + ' url: ' + url)
    OF.write('if [ ! -f ' + tarfile + ' ]\n')
    OF.write('then\n')
    OF.write('  wget ' + url + ' -O ' + tarfile + '\n')
    OF.write('  unzip ' + tarfile + '\n')
    OF.write('fi\n')
    OF.write('\n')

    OF.write('cp ' + software + '/tkdiff ' + self.prefix + '/bin/.\n')

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_xerces(self, name):
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

    self.gen_script_head(OF)
   #self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
      software = name + '-' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)
      self.create_build_dir(name, OF)

      OF.write('cd ..\n')
      OF.write('\n')

      OF.write('git fetch \n')
      OF.write('git checkout ' + self.package[name] + '\n')

      OF.write('cd build\n')
      OF.write('\n')
    else:
      print('Do not know how to get source code for ' + name)
      sys.exit(-2)

    OF.write('cd ..\n')
   #OF.write('rm -rf ' +  build_dir + '\n')
    OF.write('\n')

   #OF.write('autoreconf -i -f\n')
   #OF.write('autoreconf -i\n')

    OF.write('cd build\n')
    OF.write('\n')
   
   #conf_opts = ' -DCMAKE_BUILD_TYPE=RELEASE -DJAS_ENABLE_DOC=FALSE -DJAS_ENABLE_LIBJPEG=TRUE'
   #OF.write('cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
    conf_opts = ' --with-curl --without-icu'
    OF.write('../configure --prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_json(self, name):
   #self.build_general_wget(name)
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
     #software = name + '-' + self.package[name]
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)

    conf_opts = ' -DJSON_BuildTests=T'
    OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('./configure -prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

  def build_json_schema_validator(self, name):
   #self.build_general_wget(name)
    liba = self.software_list[name]['lib']
    if(os.path.exists(liba)):
      self.history[name] = self.get_cm_time(liba)
      if(not self.overwrite):
        return

    flnm = self.workdir + '/build_' + name + '.sh'
    OF = open(flnm, 'w')

   #self.gen_script_head(OF)
    self.gen_mpi_head(OF)

    if('wget' == self.software_list[name]['method']):
     #software = name + '-' + self.package[name]
      software = 'v' + self.package[name]
      tarfile = software + '.tar.gz'
      url = self.software_list[name]['url']
      print(name + ' url: ' + url)
     #tarfile, dirname = self.get_dir_name(url)
      self.wget_tarfile(url, tarfile, OF)
      self.create_build_dir(name, OF)
    elif('clone' == self.software_list[name]['method']):
      src_dir = name + '-' + self.package[name]
      version = ''
      gitURL = self.software_list[name]['url']
      print(name + ' gitURL: ' + gitURL)
      self.git_clone(gitURL, version, src_dir, OF)

    self.create_build_dir(name, OF)

    conf_opts = ' -DJSON_BuildTests=T'
    OF.write('cmake .. -DCMAKE_INSTALL_PREFIX=' + self.prefix + conf_opts + '\n')
   #OF.write('./configure -prefix=' + self.prefix + conf_opts + '\n')
    OF.write('\n')

    self.gen_script_tail(OF)

    self.run_script(flnm)
    self.check_libs(liba, name)

#--------------------------------------------------------------------------------
if __name__== '__main__':
 #buildHome = os.environ['JEDI_OPT']
 #username = os.environ['LOGNAME']
  buildHome = os.environ['JEDI_OPT']
 #compilerName = 'intel'
 #compilerVersion = '2020.2'
 #mpiName = 'impi'
 #mpiVersion = '2020.2'
  compilerName = 'gnu'
  compilerVersion = '8.3.0'
 #compilerVersion = '10.2.0'
  mpiName = 'openmpi'
  mpiVersion = '4.0.4'
  software_file = 'software.txt'
  debug = 1
  currdir = os.getcwd()
  workdir = currdir + '/pkg'
  overwrite = 0
  checkonly = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'buildHome=',
    'compilerName=', 'compilerVersion=',
    'mpiName=', 'mpiVersion=',
    'software_file=', 'workdir='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--overwrite'):
      overwrite = int(a)
    elif o in ('--checkonly'):
      checkonly = int(a)
    elif o in ('--buildHome'):
      buildHome = a
    elif o in ('--compilerName'):
      compilerName = a
    elif o in ('--compilerVersion'):
      compilerVersion = a
    elif o in ('--mpiName'):
      mpiName = a
    elif o in ('--mpiVersion'):
      mpiVersion = a
    elif o in ('--software_file'):
      software_file = a
    elif o in ('--workdir'):
      workdir = a
    else:
      assert False, 'unhandled option'

  print(os.environ['JEDI_OPT'])

  bs = BuildStack(debug=debug, buildHome=buildHome,
                  compilerName=compilerName, compilerVersion=compilerVersion,
                  mpiName=mpiName, mpiVersion=mpiVersion,
                  software_file=software_file, workdir=workdir,
                  checkonly=checkonly, overwrite=overwrite)
  bs.build_package()

