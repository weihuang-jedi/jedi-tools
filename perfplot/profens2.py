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
  def __init__(self, debug=0, enslist=None,
               workdir=None, linear=0, ncore=0, show=0):

    """ Initialize class attributes """
    self.debug = debug
    self.workdir = workdir
    self.enslist = enslist
    self.linear = linear
    self.ncore = ncore
    self.show = show

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    if(enslist is None):
      print('enslist not defined. Exit.')
      sys.exit(-1)

    if(self.ncore < 1):
      print('ncore is less than 1. Exit.')
      sys.exit(-1)

    self.function_list = ['computeWeights', 'applyWeights', 'ObsSpace', 'write', 'State', 'print']
    self.fullfunction_list = ['oops::GETKFSolver::computeWeights', 'oops::GETKFSolver::applyWeights',
                              'oops::ObsSpace::ObsSpace', 'oops::State::write',
                              'oops::State::State', 'oops::State::print']
   #self.color_list = ['red', 'orange', 'magenta', 'blue', 'cyan', 'yellow']
    self.color_list = ['red', 'orange', 'magenta', 'blue', 'lightblue', 'yellow', 'darkgreen', 'darkblue']

  def process(self):
    nc = 0
    self.filelist = []
    for n in self.enslist:
      flnm = '%s/n%dm%d/log.run.np%d_nens%d' %(self.workdir, self.ncore, n, self.ncore, n)

      if(not os.path.exists(flnm)):
        print('Filename ' + flnm + ' does not exit. Stop')
        sys.exit(-1)

      self.filelist.append(flnm)
      nc += 1
      if(self.debug):
        print('Case ' + str(nc) + ' name: ' + flnm)

    self.stats_list = []
    nc = 0
    for flnm in self.filelist:
      nc += 1
      if(self.debug):
        print('Processing case ' + str(nc) + ': ' + flnm)
      res = self.stats(flnm)
      self.stats_list.append(res)

     #if(self.debug):
     #  return

     #self.print_gen_name(nc)
     #self.print_gen_time(nc)

     #self.print_par_name(nc)
     #self.print_par_time(nc)

      self.print_gen(nc)
      self.print_par(nc)

  def print_gen_name(self, nc):
    print('\nTiming Statistics: Name')
    nl = len(self.stats_list[0][1])

    hinfo = '+----+'
    for i in range(nc):
      hinfo = '%s%s+' %(hinfo, 22*'-')
    print(hinfo)

    pinfo = '+Mems+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.enslist[i], 9*' ')
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
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.enslist[i], 9*' ')
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
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.enslist[i], 9*' ')
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
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.enslist[i], 9*' ')
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
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.enslist[i], 9*' ')
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
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.enslist[i], 9*' ')
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
      print('Total number of lines: ', num_lines)

      nl = 0
      while(nl < num_lines):
        if(lines[nl].find('Parallel Timing Statistics') > 0):
          if(self.debug):
            print('Start Parallel Timing Statistics')
          nl, par_stats, index = self.parallel_time_stats(lines, nl)
          prof[2] = par_stats
          prof[3] = index
          nl += num_lines
        elif(lines[nl].find('Timing Statistics') > 0):
          if(self.debug):
            print('Start Timing Statistics')
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

     #pinfo = '\t%50s%10.2f%8d' %(stats[idx]['name'], stats[idx]['time'], stats[idx]['call'])
     #print(pinfo)
      idx += 1

    index = self.get_index(stats, 'time', 1)
    if(self.debug):
      for idx in index:
        pinfo = '\t%50s%10.2f%8d' %(stats[idx]['name'], stats[idx]['time'], stats[idx]['call'])
        print(pinfo)
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
     #print('\tName: ' + name + ' avg ' + str(stats[name]['avg']))
      idx += 1

    index = self.get_index(stats, 'avg', 2)
    if(self.debug):
      for idx in index:
        pinfo = '\t%50s%10.2f' %(stats[idx]['name'], stats[idx]['avg'])
        print(pinfo)
    return ns, stats, index

  def get_index(self, stats, varname, nleft):
    s = []
    keys = stats.keys()
    for n in range(len(keys) - nleft):
      t = stats[n][varname]
      s.append(t)
    index = sorted(range(len(s)), key=lambda k: s[k])
    return index[::-1]

  def plot_percent(self):
    title = '%d Cores, Top 6 functions Percentage' %(self.ncore)

    x = np.array(self.enslist)
    y = []

    nc = len(self.enslist)
    nl = len(self.stats_list[0][2])

    for i in range(nc):
      nl = len(self.stats_list[i][2])
      t = 0.001*self.stats_list[i][2][nl-2]['avg']
      y.append(t)

   #total = plt.plot(x, y, marker='x', markerfacecolor='Green', markersize=12, color='cyan', linewidth=3, label='Top 6 Sum')

    line = []
    tp = {}

    nf = len(self.function_list)

    pmax = 0.0
    for n in range(nf):
      tp[n] = []
      pl = None
      line.append(pl)
      for i in range(nc):
        pc = 100.0*self.function_timing[n][i]/y[i]
        if(pc > pmax):
          pmax = pc
        tp[n].append(pc)

    print('nc = ', nc)
    print('x = ', x)

    ng = 0
    gl = []
    xt = {}
    yt = {}
    t0 = 0.0
    while(t0 < pmax):
      xg = []
      yg = []
      for e in x:
        xg.append(float(e))
        yg.append(t0)
      t0 += 5.0

      pl = None
      gl.append(pl)
      xt[ng] = xg
      yt[ng] = yg
  
      ng += 1

   #multiple line plot
    for num in range(nf):
      print('x = ', x)
      print('tp[num] = ', tp[num])
      line[num] = plt.plot(x, tp[num], marker='', color=self.color_list[num],
                           linewidth=2, alpha=0.9, label=self.function_list[num])
   #plt.plot(x, tp, marker='', color=self.color_list[nf],
   #         linewidth=2, alpha=0.75, label='Top 6 Funcs')

    for num in range(ng):
     #print('xt[' + str(num) + ']=', xt[num])
     #print('yt[' + str(num) + ']=', yt[num])
      gl[num] = plt.plot(xt[num], yt[num], marker='', color='grey', linestyle='dotted', linewidth=1, alpha=0.8)

   #Add title and axis names
   #plt.title(title)
    plt.xlabel('Members')
    plt.ylabel('Percen(%)')

    plt.xscale("log", base=2)
   #plt.yscale("log", base=2)
   #plt.yscale("log", base=10)

    plt.legend()
    plt.title(title)

    imgname = 'percent_%dc_plot.png' %(self.ncore)
 
    if(self.show):
      plt.show()
    else:
      plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def find_gen_name_idx(self, cn, idx):
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

  def find_name2idx(self, name):
   #print('find idx for  name = ' + name)
    nl = len(self.stats_list[0][2])

    idx = -1
    for n in range(nl):
      long_name = self.stats_list[0][2][n]['name']
     #nlst = long_name.split('::')
     #print('n = ' + str(n) + ', name = ' + name + ', long_name = ' + nlst[-1])
     #print('n = ' + str(n) + ', name = ' + name + ', long_name = ' + long_name)
     #if(nlst[-1] == name):
      if(long_name == name):
        idx = n
        break
   #print('find idx = ' + str(idx) + ' for  name = ' + name)
    return idx

  def plot_functions(self):
    title = '%d Cores, Top 6 functions timing' %(self.ncore)

    nc = len(self.enslist)
    x = np.array(self.enslist)
    ts = {}
    namelist = []
    line = []

    ymin = 1.0e+36
    ymax = 0.0

    for n in range(len(self.function_list)):
      idx = self.find_name2idx(self.fullfunction_list[n])
     #print('n = ' + str(n) + ', name = ' + self.function_list[n] + ', idx = ' + str(idx))
      pl = None
      line.append(pl)
      ts[n] = []
      for i in range(nc):
        ni = self.find_gen_name_idx(i, idx)
        t = 0.001*self.stats_list[i][2][ni]['avg']
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

    self.function_timing = ts

    print('ymin = ', ymin)
    print('ymax = ', ymax)

    print('nc = ', nc)
    print('x = ', x)

    ng = 0
    gl = []
    xt = {}
    yt = {}
    for t0 in [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0]:
      xg = []
      yg = []
      for e in x:
        t = t0*float(e)/x[0]
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
    for num in range(len(self.function_list)):
      line[num] = plt.plot(x, ts[num], marker='', color=self.color_list[num],
                           linewidth=2, alpha=0.9, label=self.function_list[num])

    for num in range(ng):
      print('xt[' + str(num) + ']=', xt[num])
      print('yt[' + str(num) + ']=', yt[num])
      gl[num] = plt.plot(xt[num], yt[num], marker='', color='grey', linestyle='dotted', linewidth=1, alpha=0.8)

   #Add title and axis names
   #plt.title(title)
    plt.xlabel('Members')
    plt.ylabel('Time(s)')

    if(not self.linear):
     #if(ymax < 128.0):
     #  plt.ylim(1.0, 128.0)
      plt.ylim(1.0, 128.0)
   #plt.xlim(0,10)

    if(self.linear):
      pass
    else:
      plt.xscale("log", base=2)
      plt.yscale("log", base=2)
     #plt.yscale("log", base=10)

    plt.legend()
    plt.title(title)
 
    if(self.linear):
      imgname = 'lin_%dc_plot.png' %(self.ncore)
    else:
      imgname = 'log_%dc_plot.png' %(self.ncore)

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

  def set_ncore(self, ncore=24):
    self.ncore = ncore

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
  workdir = '/work/noaa/gsienkf/weihuang/jedi/prof'
  enslist = [10, 20, 40]
  linear = 1
 #ncore = 24
  ncore = 240
  show = 1

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'workdir=',
    'enslist=', 'ncore='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--workdir'):
      workdir = a
    elif o in ('--enslist'):
      enslist = a
    elif o in ('--linear'):
      linear = int(a)
    elif o in ('--ncore'):
      ncore = int(a)
    elif o in ('--show'):
      show = int(a)
    else:
      assert False, 'unhandled option'

  pr = Profiler(debug=debug, enslist=enslist, workdir=workdir, linear=linear, ncore=ncore, show=show)

  for show in [1, 0]: 
    pr.set_show(show=show)
    for ncore in [24, 240]:
      pr.set_ncore(ncore=ncore)
      for linear in [0, 1]:
        pr.set_linear(linear=linear)
        pr.process()
        pr.plot_functions()
      pr.plot_percent()

