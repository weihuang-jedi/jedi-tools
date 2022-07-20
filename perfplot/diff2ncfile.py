#########################################################################
#$Id: $
#$Revision: $
#$HeadURL: $
#$Date: $
#$Author: $
#########################################################################

from __future__ import print_function
from netCDF4 import Dataset
import numpy as np
import sys
import getopt
import os, sys
import time
import datetime

class CompareNCfile:
  """ Constructor """
  def __init__(self, debug=0, dir1=None, dir2=None):
    """ Initialize class attributes """
    self.debug = debug
    self.dir1 = dir1
    self.dir2 = dir2

    if(dir1 is None):
      print('dir1 not defined. Exit.')
      sys.exit(-1)

    if(dir2 is None):
      print('dir2 not defined. Exit.')
      sys.exit(-1)

    self.corevars = ['u', 'v', 'T', 'DELP']
    self.tracervars = ['sphum', 'ice_wat', 'liq_wat', 'o3mr']
    self.fileheader = 'mem000/20191203.000000.letkf.'
   #self.fileheader = 'mem000/20191203.000000.increment.'

  def process(self):
    corebase = '%s/%sfv_core.res.tile' %(self.dir1, self.fileheader)
    tracerbase = '%s/%sfv_tracer.res.tile' %(self.dir1, self.fileheader)

    print('\n')
    print('Base  :', corebase)
    print('Tracerbase:', tracerbase)

    coreflnm = '%s/%sfv_core.res.tile' %(self.dir2, self.fileheader)
    tracerflnm = '%s/%sfv_tracer.res.tile' %(self.dir2, self.fileheader)

    core_avail, corediff = self.cal_diff(corebase, coreflnm, self.corevars)
    tracer_avail, tracerdiff = self.cal_diff(tracerbase, tracerflnm, self.tracervars)

    if(core_avail):
       pinfo = 'Core stats between %s and %s' %(self.dir1, self.dir2)
       print(pinfo)
       self.print_diff(self.corevars, corediff)
    if(tracer_avail):
       pinfo = 'Tracer stats between %s and %s' %(self.dir1, self.dir2)
       print(pinfo)
       self.print_diff(self.tracervars, tracerdiff)

  def cal_diff(self, f1, f2, varlist):
    diffavail = 0
    difflist = {}
    for i in range(6):
      fn1 = '%s%d.nc' %(f1, i+1)
      fn2 = '%s%d.nc' %(f2, i+1)

      if(not os.path.exists(fn1)):
        print('fn1 ' + fn1 + ' does not exit')
        return diffavail, difflist
      if(not os.path.exists(fn2)):
        print('fn2 ' + fn2 + ' does not exit')
        return diffavail, difflist

      diffavail = 1
      difflist[i+1] = {}
      nc1 = Dataset(fn1)
      nc2 = Dataset(fn2)
      for varname in varlist:
        data1 = nc1[varname][:]
        data2 = nc2[varname][:]
        diff = data2 - data1
       #print('%s max abs diff=%s'%(varname, (np.abs(diff)).max()))
        difflist[i+1][varname] = (np.abs(diff)).max()
    return diffavail, difflist

  def print_diff(self, varlist, diff):
    nv = len(varlist)

    if(not debug):
      vmax = 0.0

      for n in range(6):
        ni = n + 1
        for var in varlist:
          val = diff[ni][var]
          if(val > vmax):
            vmax = val
      if(vmax < 1.0e-10):
        print('Max diff: ', vmax)
        return

    hinfo = '+----+'
    for i in range(nv):
      hinfo = '%s%s+' %(hinfo, 20*'-')
    print(hinfo)

    pinfo = '+Tile+'
    for i in range(nv):
      pinfo = '%s%s%12s%s+' %(pinfo, 4*' ', varlist[i], 4*' ')
    print(pinfo)

    print(hinfo)

    for n in range(6):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      for var in varlist:
        val = diff[ni][var]
        vstr = f'{val:.6E}'
        pinfo = '%s%s%s%s|' %(pinfo, 4*' ', vstr, 4*' ')
      print(pinfo)
    print(hinfo)

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 0

 #dir1 = '/work/noaa/gsienkf/weihuang/jedi/run/bugfix/output'
 #dir2 = '/work/noaa/gsienkf/weihuang/jedi/run/bugfix240/output'

 #dir1 = '/work/noaa/gsienkf/weihuang/jedi/run/bugfix/output.inef'
  dir1 = '/work/noaa/gsienkf/weihuang/jedi/run/bugfix/output.whl'
  dir2 = '/work/noaa/gsienkf/weihuang/jedi/run/bugfix/output'
 #dir2 = '/work/noaa/gsienkf/weihuang/jedi/run/bugfix/output.halo'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'dir1=', 'dir2='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--dir1'):
      dir1 = a
    elif o in ('--dir2'):
      dir2 = a
    else:
      assert False, 'unhandled option'

  cf = CompareNCfile(debug=debug, dir1=dir1, dir2=dir2)
  cf.process()

