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
        nc = 0
        for n in self.threadlist:
          ncore = core / n
          flnm = '%s/omp%d/n%dm%do%d/log.run.np%d_nens%d' %(self.workdir, n, ncore, member, n, ncore, member)

          if(os.path.exists(flnm)):
            self.filelist[core][member][n] = flnm
            outflnm = '%s/omp%d/n%dm%do%d/output/mem000/20191203.000000.letkf.fv_core.res.tile1.nc' %(self.workdir, n, ncore, member,n)
            if(os.path.exists(outflnm)):
              nc += 1
              self.stats_list[core][member][n] = self.stats(flnm)
              self.stats_list[core][member][0].append(n)
          else:
            pinfo = 'Log file %s/omp%d/n%dm%do%d/log.run.np%d_nens%d does not exist.' %(self.workdir, n, ncore, member, n, ncore, member)
            print(pinfo)
        nc = len(self.stats_list[core][member].keys())
        pinfo = 'Process %d core, %d member has cases: %d' %(core, member, nc)
        print(pinfo)

  def print_gen_name(self, nc):
    print('\nTiming Statistics: Name')
    nl = len(self.stats_list[0][1])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.threadlist[i], 9*' ')
    print(pinfo)

    print(hinfo)

    n = 0
    for n in range(nl-10):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      for i in range(nc):
       #print('self.stats_list[i][1] = ', self.stats_list[i][1])
        idx = self.stats_list[i][1][n]
        name = self.stats_list[i][0][idx]['name']
       #pinfo = '%s %20s |' %(pinfo, self.stats_list[i][0][idx]['name'])
        nlst = name.split('::')
        pinfo = '%s %20s |' %(pinfo, nlst[-1])
      print(pinfo)
    print(hinfo)

  def print_gen_time(self, nc):
    print('\nTiming Statistics: Time')
    nl = len(self.stats_list[0][1])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.threadlist[i], 9*' ')
    print(pinfo)

    print(hinfo)

    n = 0
    for n in range(nl-10):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      for i in range(nc):
       #print('self.stats_list[i][1] = ', self.stats_list[i][1])
        idx = self.stats_list[i][1][n]
        tim = self.stats_list[i][0][idx]['time']
        pinfo = '%s %s %10.2f %s |' %(pinfo, 4*' ', tim, 4*' ')
      print(pinfo)
    print(hinfo)

  def print_par_name(self, nc):
    print('\nParallel Timing Statistics: Name')
    nl = len(self.stats_list[0][3])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.threadlist[i], 9*' ')
    print(pinfo)

    print(hinfo)

    n = 0
    for n in range(nl-10):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      for i in range(nc):
       #print('self.stats_list[i][1] = ', self.stats_list[i][1])
        idx = self.stats_list[i][3][n]
        name = self.stats_list[i][2][idx]['name']
       #pinfo = '%s %20s |' %(pinfo, self.stats_list[i][2][idx]['name'])
        nlst = name.split('::')
        pinfo = '%s %20s |' %(pinfo, nlst[-1])
      print(pinfo)
    print(hinfo)

  def print_par_time(self, nc):
    print('\nParallel Timing Statistics: Time')
    nl = len(self.stats_list[0][3])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.threadlist[i], 9*' ')
    print(pinfo)

    print(hinfo)

    n = 0
    for n in range(nl-10):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      for i in range(nc):
       #print('self.stats_list[i][3] = ', self.stats_list[i][3])
        idx = self.stats_list[i][3][n]
        tim = self.stats_list[i][2][idx]['avg']
        pinfo = '%s %s %10.2f %s |' %(pinfo, 4*' ', tim, 4*' ')
      print(pinfo)
    print(hinfo)

  def print_gen(self, nc):
    print('\nTiming Statistics: Name')
    nl = len(self.stats_list[0][1])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.threadlist[i], 9*' ')
    print(pinfo)

    print(hinfo)

    n = 0
    for n in range(nl-10):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      tinfo = '|    |'
      for i in range(nc):
       #print('self.stats_list[i][1] = ', self.stats_list[i][1])
        idx = self.stats_list[i][1][n]
        name = self.stats_list[i][0][idx]['name']
       #pinfo = '%s %20s |' %(pinfo, self.stats_list[i][0][idx]['name'])
        nlst = name.split('::')
        pinfo = '%s %20s |' %(pinfo, nlst[-1])

        tim = self.stats_list[i][0][idx]['time']
        tinfo = '%s %s %10.2f %s |' %(tinfo, 4*' ', tim, 4*' ')
      print(pinfo)
      print(tinfo)
      print(hinfo)

  def print_par(self, nc):
    print('\nParallel Timing Statistics: Name')
    nl = len(self.stats_list[0][3])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.threadlist[i], 9*' ')
    print(pinfo)

    print(hinfo)

    n = 0
    for n in range(nl-10):
      ni = n + 1

      pinfo = '|%3d |' %(ni)
      tinfo = '|    |'
      for i in range(nc):
       #print('self.stats_list[i][1] = ', self.stats_list[i][1])
        idx = self.stats_list[i][3][n]
        name = self.stats_list[i][2][idx]['name']
       #pinfo = '%s %20s |' %(pinfo, self.stats_list[i][2][idx]['name'])
        nlst = name.split('::')
        pinfo = '%s %20s |' %(pinfo, nlst[-1])

        tim = self.stats_list[i][2][idx]['avg']
        tinfo = '%s %s %10.2f %s |' %(tinfo, 4*' ', tim, 4*' ')
      print(pinfo)
      print(tinfo)
      print(hinfo)

  def stats(self, flnm):
    if(os.path.exists(flnm)):
      pass
    else:
      print('Filename ' + flnm + ' does not exit. Stop')
      sys.exit(-1)

    prof = {}

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
          nl, par_stats, index = self.parallel_time_stats(lines, nl)
          prof[2] = par_stats
          prof[3] = index
          nl += num_lines
        elif(lines[nl].find('Timing Statistics') > 0):
         #if(self.debug):
         #  print('Start Timing Statistics')
          nl, gen_stats, index = self.time_stats(lines, nl)
          prof[0] = gen_stats
          prof[1] = index
        nl += 1

    return prof

  def time_stats(self, lines, nl):
    stats = {}
    going = 1
    idx = 0
    ns = nl + 2
    while(going):
      line = lines[ns].strip()

      ns += 1
      
      if(line.find('Timing Statistics') > 0):
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
      ft = float(nlist[0])
     #if(ft < 1.0):
     #  continue

      tinfo = {}
      tinfo['name'] = name
      tinfo['time'] = ft
      tinfo['call'] = int(nlist[2])

      stats[idx] = tinfo

      if(name == 'util::Timers::Total'):
        pinfo = '\t%50s%10.2f%8d' %(stats[idx]['name'], stats[idx]['time'], stats[idx]['call'])
        print(pinfo)
      idx += 1

    index = self.get_index(stats, 'time', 1)
   #if(self.debug):
   #  for idx in index:
   #    pinfo = '\t%50s%10.2f%8d' %(stats[idx]['name'], stats[idx]['time'], stats[idx]['call'])
   #    print(pinfo)
    return ns, stats, index

  def parallel_time_stats(self, lines, nl):
    stats = {}
    going = 1
    ns = nl + 3
    idx = 0
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
      ft = float(nlist[0])
     #if(ft < 1.0):
     #  continue

      tinfo = {}
      tinfo['name'] = name
      tinfo['min'] = ft
      tinfo['max'] = float(nlist[1])
      tinfo['avg'] = float(nlist[2])

     #total = 100. * avg / total
      tinfo['total'] = float(nlist[3])
   
     #imbalance = 100. * (max - min) / avg
      tinfo['imbalance'] = float(nlist[4])

      stats[idx] = tinfo

     #pinfo = '\t%50s%10.2f' %(stats[idx]['name'], stats[idx]['avg'])
     #print(pinfo)
      if(name == 'util::Timers::Total'):
        pinfo = '\t%50s%10.2f' %(stats[idx]['name'], stats[idx]['avg'])
        print(pinfo)
      idx += 1

     #if('Total' == name):
     #  print('\tName: ' + name + ' avg ' + str(stats[name]['avg']))

    index = self.get_index(stats, 'avg', 2)
   #if(self.debug):
   #  for idx in index:
   #    pinfo = '\t%50s%10.2f' %(stats[idx]['name'], stats[idx]['avg'])
   #    print(pinfo)
    return ns, stats, index

  def get_index(self, stats, varname, nleft):
    s = []
    keys = stats.keys()
    for n in range(len(keys) - nleft):
      t = stats[n][varname]
      s.append(t)
    index = sorted(range(len(s)), key=lambda k: s[k])
    return index[::-1]

  def find_gen_name_idx(self, core, member, thread, cn, idx):
    name = self.stats_list[core][member][thread][0][idx]['name']
    if(cn):
      nl = len(self.stats_list[core][member][cn][0])
      indx = -1
      for n in range(nl):
        if(name == self.stats_list[core][member][cn][0][n]['name']):
         #print('name = ' + name + ', new name = ' + self.stats_list[core][member][cn][0][n]['name'])
          indx = n
          break
    else:
      indx = idx
    return indx

  def plot(self, ns, nl):
    for core in self.corelist:
      for member in self.enslist:
        nc = len(self.stats_list[core][member][0])
        pinfo = 'Plot %d core, %d member has cases: %d' %(core, member, nc)
        print(pinfo)

        if(nc > 1):
          self.plot_it(core, member, ns, nl)
          self.plot_total(core, member)

  def plot_it(self, core, member, ns, nl):
    title = '%d Cores, %d members, Function %d-%d' %(core, member, ns, ns+nl)

    threads = self.stats_list[core][member][0]
    print('Threads: ', threads)

    nc = len(threads)
    x = np.array(threads)
    ts = {}
    namelist = []
    line = []

    ymin = 1.0e+36
    ymax = 0.0

    thread0 = threads[0]
    print('thread0 = ', thread0)

    for n in range(nl):
      nt = ns + n 
      idx = self.stats_list[core][member][thread0][1][nt]
      name = self.stats_list[core][member][thread0][0][idx]['name']
      nlst = name.split('::')
      namelist.append(nlst[-1])
      pl = None
      line.append(pl)
      ts[n] = []
      i = 0
      for i in threads:
        ni = self.find_gen_name_idx(core, member, thread0, i, idx)
        t = 0.001*self.stats_list[core][member][i][0][ni]['time']
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

    colorlist = ['red', 'orange', 'cyan', 'blue', 'black', 'magenta', 'yellow', 'darkgreen', 'darkblue', 'darkgrey']

    print('ymin = ', ymin)
    print('ymax = ', ymax)

    print('nc = ', nc)
    print('x = ', x)

    if(self.linear):
      if(ymax > 750):
        baselevs = self.get_baselev(ymin, ymax, 100.0)
      elif(ymax > 200):
        baselevs = self.get_baselev(ymin, ymax, 50.0)
      elif(ymax > 60):
        baselevs = self.get_baselev(ymin, ymax, 20.0)
      else:
        baselevs = self.get_baselev(ymin, ymax, 10.0)
    else:
      baselevs = [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0]

    ng = 0
    gl = []
    xt = {}
    yt = {}
    for t0 in baselevs:
      xg = []
      yg = []
      for e in x:
       #t = t0*float(e)/x[0]
        t = t0
        if((ymin < t) and (t < ymax)):
          xg.append(float(e))
          yg.append(t)

      if(len(xg) > 1):
        pl = None
        gl.append(pl)
        xt[ng] = xg
        yt[ng] = yg
  
        print('xt[' + str(ng) + ']=', xt[ng])
        print('yt[' + str(ng) + ']=', yt[ng])
        ng += 1

   #multiple line plot
    for num in range(nl):
      line[num] = plt.plot(x, ts[num], marker='', color=colorlist[num], linewidth=2, alpha=0.9, label=namelist[num])

    for num in range(ng):
      print('xt[' + str(num) + ']=', xt[num])
      print('yt[' + str(num) + ']=', yt[num])
     #gl[num] = plt.plot(xt[num], yt[num], marker='x', color='grey', linestyle='dotted', linewidth=4, alpha=0.8)
      gl[num] = plt.plot(xt[num], yt[num], marker='', color='grey', linestyle='dotted', linewidth=1, alpha=0.8)

   #Add title and axis names
   #plt.title(title)
    plt.xlabel('Threads')
    plt.ylabel('Time(ms)')

    if(self.linear):
      pass
    else:
      plt.xscale("log", base=2)
      plt.yscale("log", base=2)
     #plt.yscale("log", base=10)

    plt.legend()
 
    plt.title(title)

    if(self.linear):
      imgname = 'lin_%dc_%dm.png' %(core, member)
    else:
      imgname = 'log_%dc_%dm.png' %(core, member)
    if(self.show):
      plt.show()
    else:
      plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def get_baselev(self, ymin, ymax, step):
    baseval = []
    val = 0.0
    while(val < ymax):
      if(val > ymin):
        baseval.append(val)
      val += step
    return baseval

  def plot_total(self, core, member):
    title = '%d Cores, %d members Total time' %(core, member)

    threads = self.stats_list[core][member][0]
    print('Threads: ', threads)

    nc = len(threads)
    x = np.array(threads)
    ts = []

    ymin = 1.0e+36
    ymax = 0.0

    thread0 = threads[0]

    for i in threads:
      nl = len(self.stats_list[core][member][i][2])
      t = 0.001*self.stats_list[core][member][i][2][nl-2]['avg']
      ts.append(t)
      if(t > ymax):
        ymax = t
      if(t < ymin):
        ymin = t

    if(self.linear):
      if(ymax > 750.0):
        baselevs = self.get_baselev(ymin, ymax, 100.0)
      elif(ymax > 200.0):
        baselevs = self.get_baselev(ymin, ymax, 50.0)
      elif(ymax > 60.0):
        baselevs = self.get_baselev(ymin, ymax, 20.0)
      else:
        baselevs = self.get_baselev(ymin, ymax, 10.0)
    else:
      baselevs = [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0]

    ng = 0
    gl = []
    xt = {}
    yt = {}
    for t0 in baselevs:
      xg = []
      yg = []
      for e in x:
       #t = t0*float(e)/x[0]
        t = t0
        if((ymin < t) and (t < ymax)):
          xg.append(float(e))
          yg.append(t)

      if(len(xg) > 1):
        pl = None
        gl.append(pl)
        xt[ng] = xg
        yt[ng] = yg
  
        print('xt[' + str(ng) + ']=', xt[ng])
        print('yt[' + str(ng) + ']=', yt[ng])
        ng += 1

    plt.plot(x, ts, marker='x', color='red', linewidth=2, alpha=0.9)

    for num in range(ng):
      print('xt[' + str(num) + ']=', xt[num])
      print('yt[' + str(num) + ']=', yt[num])
      gl[num] = plt.plot(xt[num], yt[num], marker='', color='grey', linestyle='dotted', linewidth=1, alpha=0.8)

   #Add title and axis names
   #plt.title(title)
    plt.xlabel('Threads')
    plt.ylabel('Time(ms)')

    plt.xscale("log", base=2)
    plt.yscale("log", base=2)
   #plt.yscale("log", base=10)

   #plt.legend()
 
    plt.title(title)

    imgname = 'ttl_%dc_%dm.png' %(core, member)

    if(self.show):
      plt.show()
    else:
      plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def find_par_name_idx(self, cn, idx):
    name = self.stats_list[0][2][idx]['name']
    if(cn):
      nl = len(self.stats_list[cn][2])
      indx = -1
      for n in range(nl):
        if(name == self.stats_list[cn][2][n]['name']):
         #print('name = ' + name + ', new name = ' + self.stats_list[cn][0][n]['name'])
          indx = n
          break
    else:
      indx = idx
    return indx

  def set_linear(self, linear=1):
    self.linear = linear

  def set_show(self, show=1):
    self.show = show

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
  workdir = '/work/noaa/gsienkf/weihuang/jedi/base'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case1'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case2'
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/case3'
  enslist = [10, 20, 40, 80]
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
    for linear in [1, 0]:
      pr.set_linear(linear=linear)
     #pr.plot(0, 9)
      pr.plot(0, 6)
     #pr.plot(0, 3)

