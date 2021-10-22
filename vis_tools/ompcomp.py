#########################################################################
#$Id: bld.py 28 2021-01-21 15:10:31Z whuang $
#$Revision: 28 $
#$HeadURL: file:///Users/whuang/.wei_svn_repository/trunk/jedi-build-tools/bld.py $
#$Date: 2021-01-21 08:10:31 -0700 (Thu, 21 Jan 2021) $
#$Author: whuang $
#########################################################################

import getopt
import os, sys
import time
import datetime

import matplotlib.pyplot as plt
import numpy as np

""" Profiler """
class Profiler:
  """ Constructor """
  def __init__(self, debug=0, threadlist=[], corelist=[], enslist=[],
               workdir=None, linear=0, show=0, caselist=[]):

    """ Initialize class attributes """
    self.debug = debug
    self.workdir = workdir
    self.threadlist = threadlist
    self.corelist = corelist
    self.enslist = enslist
    self.linear = linear
    self.show = show
    self.caselist = caselist

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    self.colorlist = ['red', 'orange', 'magenta', 'blue', 'cyan', 'darkgreen']
    self.namelist = ['GNU-0', 'GNU-1', 'GNU-PLASMA', 'Intel-0', 'Intel-1', 'Intel-PLASMA']

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
        nt = len(self.stats_list[core][member][0])
        pinfo = 'Process %d core, %d member has cases: %d' %(core, member, nt)
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

  def plot(self):
    self.rows, self.cols = len(self.enslist), len(self.corelist)

   #fig, axes = plt.subplots(self.rows, self.cols, sharex='col', sharey='row')
   #fig, axes = plt.subplots(self.rows, self.cols, sharex='col', sharey='row', figsize=(10,10))
    fig, axes = plt.subplots(self.rows, self.cols, figsize=(10,10))

   #add a big axis, hide frame
   #fig.add_subplot(111, frameon=False)
   #hide tick and tick label of the big axis
   #plt.tick_params(labelcolor='none', top=False, bottom=False, left=False, right=False)
   #plt.xlabel('Threads')
   #plt.ylabel('Time (sencond)')

    if(self.linear):
      imgname = 'lin_total.png'
    else:
      imgname = 'log_total.png'

    for nc in range(len(self.corelist)):
      core = self.corelist[nc]
      for nm in range(len(self.enslist)):
        member = self.enslist[nm]
        nt = len(self.stats_list[core][member][0])

        if(nt > 1):
          self.plot_total(axes[nm, nc], core, member)

    fig.tight_layout()

    if(self.show):
      plt.show()
    else:
      fig.savefig(imgname)

    plt.cla()
    plt.clf()

  def plot_total(self, ax, core, member):
    title = '%d Cores, %d members Total time' %(core, member)

    threads = self.stats_list[core][member][0]

    nt = len(threads)
    x = np.array(threads)
    ts = []

    ymin = 1.0e+36
    ymax = 0.0

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

    ax.set_xlim([x[0], x[-1]])
    ax.set_ylim([tmin, tmax])

    ax.plot(x, ts, marker='x', color='red', linewidth=2, alpha=0.9)

   #Add title and axis names
    ax.set_title(title)
    ax.set_xlabel('Threads')
    ax.set_ylabel('Time(s)')

    ax.set_xscale("log", base=2)
    if(self.linear):
      pass
    else:
      ax.set_yscale("log", base=2)
     #ax.set_yscale("log", base=10)

   #Show the major grid lines with dark grey lines
    ax.grid(b=True, which='major', color='#666666', linestyle='dotted')

   #Show the minor grid lines with very faint and almost transparent grey lines
    ax.minorticks_on()
    ax.grid(b=True, which='minor', color='#999999', linestyle='dotted', alpha=0.2)

  def set_linear(self, linear=1):
    self.linear = linear

  def set_show(self, show=1):
    self.show = show

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
  workdir = '/work/noaa/gsienkf/weihuang/jedi'
  enslist = [10, 20, 40, 80]
 #enslist = [10, 20, 40]
  threadlist = [1, 2, 4]
  linear = 1
  corelist = [24, 240]
  show = 1
  caselist = ['base', 'case2', 'case4', 'intelbase', 'intelcase', 'intelcase1']

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
                enslist=enslist, workdir=workdir, show=show, caselist=caselist)
  pr.process()

 #for show in [1, 0]:
  for show in [0]:
    pr.set_show(show=show)
    for linear in [0, 1]:
      pr.set_linear(linear=linear)
      pr.plot()

