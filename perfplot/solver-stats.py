#########################################################################
#$Id: bld.py 28 2021-01-21 15:10:31Z whuang $
#$Revision: 28 $
#$HeadURL: $
#$Date: 2021-01-21 08:10:31 -0700 (Thu, 21 Jan 2021) $
#$Author: whuang $
#########################################################################

import getopt
import os, sys
import subprocess
import time
import datetime

import numpy as np

def cmdout(command):
    result = run(command, stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
    ostr = result.stdout
    return ostr.strip()

""" Profiler """
class Profiler:
  """ Constructor """
  def __init__(self, debug=0, rundir=None):

    """ Initialize class attributes """
    self.debug = debug
    self.rundir = rundir

  def setup(self, mtpn=1, nodelist=[]):
    self.mtpn = mtpn
    self.titles = []
    self.filelist = []
    self.nodelist = []
    self.corelist = []

    for n in range(len(nodelist)):
      procs = mtpn*nodelist[n]
      title = 'solver.%dt%dn_%dp' %(self.mtpn, nodelist[n], procs)
      flnm = '%s/soca_%s/stdoutNerr/stdout.00000000' %(self.rundir, title)

      if(os.path.exists(flnm)):
        self.corelist.append(procs)
        self.titles.append(title)
        self.nodelist.append(nodelist[n])
        self.filelist.append(flnm)

   #print("self.nodelist:", self.nodelist)
   #print("self.corelist:", self.corelist)

  def process(self):
    self.stats_list = []
    nc = 0
    for flnm in self.filelist:
      nc += 1
      if(self.debug):
        print('Processing case ' + str(nc) + ': ' + flnm)
      res = self.get_stats(flnm)
      if(len(res.keys())):
        self.stats_list.append(res)

  def print_stats(self):
    print('\nRun Dir: %s' %(self.rundir))
    print('Timing Statistics for Procs: %d' %(self.mtpn))
    nl = len(self.stats_list)

   #hinfo = 'Nodes, RunTime(sec), Runtime(min), TotalMem, MinMem, MaxMem, MPItasksPerNode, TotalCPUs'
   #print(hinfo)
   #for n in range(nl):
     #stats = self.stats_list[n]

#-----------'12345-123456789012-123456789012-1234567890-12345678-12345678-123456789012345-123456789'
    hinfo = 'Nodes RunTime(sec) Runtime(min)   TotalMem   MinMem   MaxMem MPItasksPerNode TotalCPUs'
    print(hinfo)

    for n in range(nl):
      stats = self.stats_list[n]
      pinfo = '%5d %12.2f' %(self.nodelist[n], stats['RunTime'])
      pinfo = '%s %12.2f' %(pinfo, stats['RunTime']/60.0)
      pinfo = '%s %10.2f' %(pinfo, stats['TotalMemory'])
      pinfo = '%s %8.2f' %(pinfo, stats['MinMemory'])
      pinfo = '%s %8.2f' %(pinfo, stats['MaxMemory'])
      pinfo = '%s %15d' %(pinfo, self.mtpn)
      pinfo = '%s %10d' %(pinfo, self.corelist[n])
      print(pinfo)

  def get_stats(self, flnm):
    stats = {}
    with open(flnm) as fp:
      lines = fp.readlines()
      num_lines = len(lines)
     #print('Total number of lines: ', num_lines)

      for line in lines:
        if(line.find('OOPS_STATS Run end') < 0):
          continue

       #print('Line: ' + line)

        item = line.split('- Runtime: ')
       #print(item)
       #print('item[1]: ', item[1])

        tstr = item[1].strip()
        while(tstr.find('  ') > 0):
          tstr = tstr.replace('  ', ' ')
        tlist = tstr.split(', ')

        for n in range(len(tlist)):
          term = tlist[n].split(' ')
         #print('term=', term)
          if(0 == n):
            stats['RunTime'] = float(term[0])
          elif(1 == n):
            stats['TotalMemory'] = float(term[-2])
          elif(2 == n):
            stats['MinMemory'] = float(term[-2])
          elif(3 == n):
            stats['MaxMemory'] = float(term[-2])
             
        break

        if(self.debug):
          pinfo = 'RunTime: %8.2f' %(stats['RunTime'])
          pinfo = '%s, TotalMemory: %7.2f' %(pinfo, stats['TotalMemory'])
          pinfo = '%s, MinMemory: %7.2f' %(pinfo, stats['MinMemory'])
          pinfo = '%s, MaxMemory: %7.2f' %(pinfo, stats['MaxMemory'])
          print(pinfo)

    return stats

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 0
 #rundir = '/work2/noaa/gsienkf/weihuang/ufs/soca/new-soca-solver'
 #rundir = '/work2/noaa/gsienkf/weihuang/ufs/soca/new-soca-solver/ineff'
 #rundir = '/work2/noaa/gsienkf/weihuang/ufs/soca/new-soca-solver/halo'
  rundir = '/work2/noaa/gsienkf/weihuang/ufs/soca/new-soca-solver'

  mtpn = 1
  nodelist = [30, 40, 50, 60, 70, 80, 90, 100, 120, 140, 160]

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'mtpn=', 'rundir='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--mtpn'):
      mtpn = int(a)
    elif o in ('--rundir'):
      rundir = a
    else:
      assert False, 'unhandled option'

  pr = Profiler(debug=debug, rundir=rundir)

  for mtpn in [1, 2, 4, 6, 8, 10, 12]:
    pr.setup(mtpn=mtpn, nodelist=nodelist)
    pr.process()
    pr.print_stats()

