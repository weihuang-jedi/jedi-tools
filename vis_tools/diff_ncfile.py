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
  def __init__(self, debug=0, threadlist=[], fileheader='output/mem000/20191203.000000.letkf.',
               basedir=None, workdir=None, enslist=[], corelist=[], show=0):

    """ Initialize class attributes """
    self.debug = debug
    self.basedir = basedir
    self.workdir = workdir
    self.fileheader = fileheader
    self.threadlist = threadlist
    self.corelist = corelist
    self.enslist = enslist
    self.show = show

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    self.corevars = ['u', 'v', 'T', 'DELP']
    self.tracervars = ['sphum', 'ice_wat', 'liq_wat', 'o3mr']

  def process(self):
    for member in self.enslist:
      corebase = '%s/omp1/n24m%do1/%sfv_core.res.tile' %(self.basedir, member, self.fileheader)
      tracerbase = '%s/omp1/n24m%do1/%sfv_tracer.res.tile' %(self.basedir, member, self.fileheader)

      print('\n')
      print('Base  :', corebase)
      print('Tracerbase:', tracerbase)

      for core in self.corelist:
        for n in self.threadlist:
          ncore = core / n
          coreflnm = '%s/omp%d/n%dm%do%d/%sfv_core.res.tile' %(self.workdir, n, ncore, member, n, self.fileheader)
          tracerflnm = '%s/omp%d/n%dm%do%d/%sfv_tracer.res.tile' %(self.workdir, n, ncore, member, n, self.fileheader)

          core_avail, corediff = self.cal_diff(corebase, coreflnm, self.corevars)
          tracer_avail, tracerdiff = self.cal_diff(tracerbase, tracerflnm, self.tracervars)

          if(core_avail):
             pinfo = 'Core stats for %d members, %d core, omp threads %d' %(member, ncore, n)
             print(pinfo)
             self.print_diff(self.corevars, corediff)
          if(tracer_avail):
             pinfo = 'Tracer stats for %d members, %d core, omp threads %d' %(member, ncore, n)
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
  basedir = '/work/noaa/gsienkf/weihuang/jedi/base'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case1'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case2'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case3'
  workdir = '/work/noaa/gsienkf/weihuang/jedi/case4'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/intelcase'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/intelbase'
  fileheader = 'output/mem000/20191203.000000.letkf.'
  enslist = [10, 20, 40, 80]
  threadlist = [1, 2, 4]
  corelist = [24, 240]
  show = 1

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'workdir=', 'threadlist='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--basedir'):
      basedir = a
    elif o in ('--workdir'):
      workdir = a
    elif o in ('--fileheader'):
      fileheader = a
    elif o in ('--threadlist'):
      threadlist = a
   #elif o in ('--corelist'):
   #  corelist = a
   #elif o in ('--enslist'):
   #  enslist = a
    elif o in ('--show'):
      show = int(a)
    else:
      assert False, 'unhandled option'

  cf = CompareNCfile(debug=debug, threadlist=threadlist, fileheader=fileheader,
       basedir=basedir, workdir=workdir, enslist=enslist, corelist=corelist, show=show)

  cf.process()

