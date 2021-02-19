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

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def cmdout(command):
    result = run(command, stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
    ostr = result.stdout
    return ostr.strip()

""" Profiler """
class Profiler:
  """ Constructor """
  def __init__(self, debug=0, threadlist=[], corelist=[], enslist=[],
               workdir=None, linear=0, show=0):

    """ Initialize class attributes """
    self.debug = debug
    self.workdir = workdir
    self.threadlist = threadlist
    self.corelist = corelist
    self.enslist = enslist
    self.linear = linear
    self.show = show

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    self.color_list = ['red', 'orange', 'magenta', 'blue', 'lightblue', 'cyan', 'darkgreen', 'darkblue']
    self.function_list = ['computeWeights', 'applyWeights', 'ObsSpace', 'write', 'State', 'print']
    self.fullfunction_list = ['oops::GETKFSolver::computeWeights', 'oops::GETKFSolver::applyWeights',
                              'oops::ObsSpace::ObsSpace', 'oops::State::write',
                              'oops::State::State', 'oops::State::print']

  def process(self):
    self.filelist = {}
    self.stats_list = {}
    for core in self.corelist:
      self.filelist[core] = {}
      self.stats_list[core] = {}
      for member in self.enslist:
        self.filelist[core][member] = {}
        self.stats_list[core][member] = {}
        self.stats_list[core][member][0] = []
        self.stats_list[core][member][1] = []
        self.stats_list[core][member][2] = {}
        for n in self.threadlist:
          ncore = core / n
          flnm = '%s/omp%d/n%dm%do%d/log.run.np%d_nens%d' %(self.workdir, n, ncore, member, n, ncore, member)

          if(os.path.exists(flnm)):
            print('Processing file: ', flnm)
            avgtime, ttltime = self.stats(flnm)
            if((ttltime > 0.0) and (len(avgtime) == len(self.function_list))):
              self.stats_list[core][member][0].append(n)
              self.stats_list[core][member][1].append(ttltime)
              self.stats_list[core][member][2][n] = avgtime
          else:
            pinfo = 'Log file %s/omp%d/n%dm%do%d/log.run.np%d_nens%d does not exist.' %(self.workdir, n, ncore, member, n, ncore, member)
            print(pinfo)
        nc = len(self.stats_list[core][member][0])
        pinfo = 'Process %d core, %d member has cases: %d' %(core, member, nc)
        print(pinfo)

  def stats(self, flnm):
    ttltime = -1.0
    avgtime = []

    with open(flnm) as fp:
      lines = fp.readlines()
     #line = fp.readline()
      num_lines = len(lines)
     #print('Total number of lines: ', num_lines)

      nl = 0
      while(nl < num_lines):
        if(lines[nl].find('Parallel Timing Statistics') > 0):
         #if(self.debug):
         #  print('Start Parallel Timing Statistics')
          nl, avgtime, ttltime = self.parallel_time_stats(lines, nl)
          nl += num_lines
        nl += 1

    return avgtime, ttltime

  def parallel_time_stats(self, lines, nl):
    avgtime = []
    ttltime = -1.0
    going = 1
    ns = nl + 3
    while(going):
      line = lines[ns].strip()
      ns += 1
      if(line.find('Parallel Timing Statistics') > 0):
        going = 0
        break

     #print('Line ' + str(ns) + ': ' + line)

      item = line.split(' : ')
     #print(item)
      nlist = item[0].strip().split(' ')
      name = nlist[1]

      tstr = item[1].strip()
      while(tstr.find('  ') > 0):
        tstr = tstr.replace('  ', ' ')
      nlist = tstr.split(' ')

      for funcname in self.fullfunction_list:
        if(name == funcname):
          avgtime.append(float(nlist[2]))
         #print('      ' + name + ':' + nlist[2])

      if(name == 'util::Timers::Total'):
        ttltime = float(nlist[2])
       #print('      Total time:', ttltime)

    return ns, avgtime, ttltime

  def plot_sample(self):
    rows, cols = 2, 3
    fig, ax = plt.subplots(rows, cols,
                           sharex='col', 
                           sharey='row')

    for row in range(rows):
      for col in range(cols):
        ax[row, col].text(0.5, 0.5, 
                          str((row, col)),
                          color="green",
                          fontsize=18, 
                          ha='center')

    plt.tight_layout()

    plt.show()

    plt.cla()
    plt.clf()

  def plot(self):
   #self.plot_sample()

    self.function_timing = {}
    for core in self.corelist:
      self.function_timing[core] = {}
      for member in self.enslist:
        nc = len(self.stats_list[core][member][0])
        pinfo = 'Plot %d core, %d member has cases: %d' %(core, member, nc)
        print(pinfo)

        if(nc > 1):
          self.plot_it(core, member)
          self.plot_total(core, member)
          self.plot_percent(core, member)

  def plot_it(self, core, member):
    title = '%d Cores, %d members' %(core, member)

    threads = self.stats_list[core][member][0]
    print('core: ', core)
    print('member: ', member)
    print('Threads: ', threads)
    print('self.stats_list[core][member][2]: ', self.stats_list[core][member][2])

    x = np.array(threads)
    ts = {}
    line = []

    ymin = 1.0e+36
    ymax = 0.0

    nf = len(self.function_list)
    for n in range(nf):
      pl = None
      line.append(pl)
      ts[n] = []
      for i in threads:
        t = 0.001*self.stats_list[core][member][2][i][n]
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

   #print('x = ', x)
   #print('ymin = ', ymin)
   #print('ymax = ', ymax)

    if(self.linear):
      tmin = 10.0*int(ymin/10.0) - 10.0
      tmax = 10.0 + 10.0*int(ymax/10.0)
    else:
      tmin = 8192.0
      while(tmin > ymin):
        tmin /= 2.0
      tmax = 1.0
      while(tmax < ymax):
        tmax *= 2.0

    plt.xlim([x[0], x[-1]])
    plt.ylim([tmin, tmax])

   #multiple line plot
    for num in range(nf):
      line[num] = plt.plot(x, ts[num], marker='', color=self.color_list[num],
                           linewidth=2, alpha=0.9, label=self.function_list[num])

   #Add title and axis names
    plt.title(title)
    plt.xlabel('Threads')
    plt.ylabel('Time(s)')

    plt.xscale("log", base=2)
    if(self.linear):
      imgname = 'lin_%dc_%dm.png' %(core, member)
    else:
      imgname = 'log_%dc_%dm.png' %(core, member)
      plt.yscale("log", base=2)
     #plt.yscale("log", base=10)

    plt.legend()

   #Show the major grid lines with dark grey lines
    plt.grid(b=True, which='major', color='#666666', linestyle='dotted')

   #Show the minor grid lines with very faint and almost transparent grey lines
    plt.minorticks_on()
    plt.grid(b=True, which='minor', color='#999999', linestyle='dotted', alpha=0.2)

    plt.tight_layout()

    if(self.show):
      plt.show()
    else:
      plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def plot_percent(self, core, member):
    title = '%d Cores, %d members' %(core, member)

    threads = self.stats_list[core][member][0]

   #print('core = ', core)
   #print('member = ', member)
   #print('threads = ', threads)

    x = np.array(threads)
    tp = {}
    line = []

    ymin = 0.0
    ymax = 0.0

    nf = len(self.function_list)
    for n in range(nf):
      pl = None
      line.append(pl)
      tp[n] = []
      ni = 0
      for i in threads:
        p = 100.0*self.stats_list[core][member][2][i][n]/self.stats_list[core][member][1][ni]
        tp[n].append(p)
        if(p > ymax):
          ymax = p
        ni += 1

   #print('ymax = ', ymax)
   #print('x = ', x)

    ymax = 10.0 + 10.0*int(ymax/10.0)
    plt.xlim([x[0], x[-1]])
    plt.ylim([0.0, ymax])

   #multiple line plot
    for num in range(nf):
      line[num] = plt.plot(x, tp[num], marker='', color=self.color_list[num],
                           linewidth=2, alpha=0.9, label=self.function_list[num])
   #Add title and axis names
    plt.title(title)
    plt.xlabel('Threads')
    plt.ylabel('Percent(%)')

    plt.xscale("log", base=2)
    if(self.linear):
      imgname = 'percent_lin_%dc_%dm.png' %(core, member)
    else:
     #plt.yscale("log", base=2)
     #plt.yscale("log", base=10)
      imgname = 'percent_log_%dc_%dm.png' %(core, member)

    plt.legend()

   #Show the major grid lines with dark grey lines
    plt.grid(b=True, which='major', color='#666666', linestyle='dotted')

   #Show the minor grid lines with very faint and almost transparent grey lines
    plt.minorticks_on()
    plt.grid(b=True, which='minor', color='#999999', linestyle='dotted', alpha=0.2)

    plt.tight_layout()

    if(self.show):
      plt.show()
    else:
      plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def plot_total(self, core, member):
    title = '%d Cores, %d members Total time' %(core, member)

    threads = self.stats_list[core][member][0]
   #print('Threads: ', threads)

    nt = len(threads)
    x = np.array(threads)
    ts = []

    ymin = 1.0e+36
    ymax = 0.0

    thread0 = threads[0]

    for i in range(nt):
      t = 0.001*self.stats_list[core][member][1][i]
      ts.append(t)
      if(t > ymax):
        ymax = t
      if(t < ymin):
        ymin = t

    if(self.linear):
      tmin = 10.0*int(ymin/10.0) - 10.0
      tmax = 10.0 + 10.0*int(ymax/10.0)
    else:
      tmin = 8192.0
      while(tmin > ymin):
        tmin /= 2.0
      tmax = 1.0
      while(tmax < ymax):
        tmax *= 2.0

    plt.xlim([x[0], x[-1]])
    plt.ylim([tmin, tmax])

    plt.plot(x, ts, marker='x', color='red', linewidth=2, alpha=0.9)

   #Add title and axis names
    plt.title(title)
    plt.xlabel('Threads')
    plt.ylabel('Time(s)')

    plt.xscale("log", base=2)
    if(self.linear):
      imgname = 'ttl_lin_%dc_%dm.png' %(core, member)
    else:
      plt.yscale("log", base=2)
     #plt.yscale("log", base=10)
      imgname = 'ttl_log_%dc_%dm.png' %(core, member)

   #plt.legend()
   #plt.grid()
   #Show the major grid lines with dark grey lines
    plt.grid(b=True, which='major', color='#666666', linestyle='dotted')

   #Show the minor grid lines with very faint and almost transparent grey lines
    plt.minorticks_on()
    plt.grid(b=True, which='minor', color='#999999', linestyle='dotted', alpha=0.2)

    plt.tight_layout()

    if(self.show):
      plt.show()
    else:
      plt.savefig(imgname)

    plt.cla()
    plt.clf()

    return ts

  def set_linear(self, linear=1):
    self.linear = linear

  def set_show(self, show=1):
    self.show = show

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/base'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case1'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case2'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case3'
  workdir = '/work/noaa/gsienkf/weihuang/jedi/intelcase'
 #enslist = [10, 20, 40, 80]
  enslist = [10, 20, 40]
  threadlist = [1, 2, 4]
  linear = 1
  corelist = [24, 240]
  show = 1

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'workdir=',
    'corelist=', 'enslist=', 'threadlist=', 'ncore='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--workdir'):
      workdir = a
    elif o in ('--corelist'):
      corelist = a
    elif o in ('--enslist'):
      enslist = a
    elif o in ('--threadlist'):
      threadlist = a
    elif o in ('--linear'):
      linear = int(a)
    elif o in ('--show'):
      show = int(a)
    else:
      assert False, 'unhandled option'

  pr = Profiler(debug=debug, threadlist=threadlist, corelist=corelist,
                enslist=enslist, workdir=workdir, show=show)
 #for show in [1, 0]:
  for show in [0]:
    pr.set_show(show=show)
    pr.process()
    for linear in [0, 1]:
      pr.set_linear(linear=linear)
      pr.plot()

