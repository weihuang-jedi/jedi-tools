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
  def __init__(self, debug=0, caselist=None,
               workdir=None, elaped=None, linear=0):

    """ Initialize class attributes """
    self.debug = debug
    self.workdir = workdir
    self.caselist = caselist
    self.elaped = elaped
    self.linear = linear

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    if(caselist is None):
      print('caselist not defined. Exit.')
      sys.exit(-1)

    nc = 0
    self.filelist = []
    for n in self.caselist:
      flnm = '%s%s%d%s' %(self.workdir, '/log_np', n, '_nens10_all')

      if(os.path.exists(flnm)):
        pass
      else:
        print('Filename ' + flnm + ' does not exit. Stop')
        sys.exit(-1)

      self.filelist.append(flnm)
      nc += 1
     #if(self.debug):
     #  print('Case ' + str(nc) + ' name: ' + flnm)

  def process(self):
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

    pinfo = '+-NP-+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.caselist[i], 9*' ')
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

    pinfo = '+-NP-+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.caselist[i], 9*' ')
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

    pinfo = '+-NP-+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.caselist[i], 9*' ')
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

    pinfo = '+-NP-+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.caselist[i], 9*' ')
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

    pinfo = '+-NP-+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.caselist[i], 9*' ')
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

    pinfo = '+-NP-+'
    for i in range(nc):
      pinfo = '%s%s%4d%s+' %(pinfo, 9*' ', self.caselist[i], 9*' ')
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

  def plot_total(self):
    title = 'Elapes, Measured, and Total time'
    x = np.array(self.caselist)

    y1 = []
    y2 = []

    nc = len(self.caselist)

    nl = len(self.stats_list[0][2])
    name1 = self.stats_list[0][2][nl-1]['name']
    name2 = self.stats_list[0][2][nl-2]['name']
   #print('self.stats_list[0][2][nl-1]=', self.stats_list[0][2][nl-1])
   #print('self.stats_list[0][2][nl-2]=', self.stats_list[0][2][nl-2])

    for i in range(nc):
      nl = len(self.stats_list[i][2])
      t1 = 0.001*self.stats_list[i][2][nl-1]['avg']
      t2 = 0.001*self.stats_list[i][2][nl-2]['avg']
      y1.append(t1)
      y2.append(t2)

    nlst1 = name1.split('::')
    nlst2 = name2.split('::')
    label1 = nlst1[-1]
    label2 = nlst2[-1]
    title = label1 + '-' + label2

   #multiple line plot
    lin1 = plt.plot(x, y1, marker='+', markerfacecolor='blue', markersize=12, color='skyblue', linewidth=4, label=label1)
    lin2 = plt.plot(x, y2, marker='x', markerfacecolor='magenta', markersize=12, color='red', linewidth=4, label=label2)
    if(self.elaped):
      lin3 = plt.plot(x, self.elaped, marker='o', markerfacecolor='darkgreen', markersize=12, color='cyan', linewidth=6, label='Real')

   #Add title and axis names
    plt.title(title)
    plt.xlabel('Procs')
    plt.ylabel('Time(sec)')

    if(self.linear):
      pass
    else:
      plt.xscale("log", base=2)
      plt.yscale("log", base=2)
     #plt.yscale("log", base=10)

    plt.legend()
   #plt.legend(handles=[lin1, lin2])

    if(self.linear):
      imgname = 'lin_totalNmeasured.png'
    else:
      imgname = 'log_totalNmeasured.png'
   #plt.show()
    plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def find_gen_name_idx(self, cn, idx):
    name = self.stats_list[0][0][idx]['name']
    if(cn):
      nl = len(self.stats_list[cn][0])
      indx = -1
      for n in range(nl):
        if(name == self.stats_list[cn][0][n]['name']):
         #print('name = ' + name + ', new name = ' + self.stats_list[cn][0][n]['name'])
          indx = n
          break
    else:
      indx = idx
    return indx

  def plot_multiple(self, ns, nl):
    title = 'Function %d-%d' %(ns, ns+nl)

    nc = len(self.caselist)
    x = np.array(self.caselist)
    ts = {}
    namelist = []
    line = []

    ymin = 1.0e+36
    ymax = 0.0

    for n in range(nl):
      nt = ns + n 
      idx = self.stats_list[0][1][nt]
      name = self.stats_list[0][0][idx]['name']
      nlst = name.split('::')
      namelist.append(nlst[-1])
      pl = None
      line.append(pl)
      ts[n] = []
      for i in range(nc):
        ni = self.find_gen_name_idx(i, idx)
        t = 0.001*self.stats_list[i][0][ni]['time']
       #print('n = ' + str(n) + ', i = ' + str(i) + ', ni = ' + str(ni) + ', t = ' + str(t))
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

    colorlist = ['red', 'orange', 'cyan', 'blue', 'black', 'magenta', 'yellow', 'darkgreen', 'darkblue', 'darkgrey']

   #t0 = ymax
   #print('t0=', t0)
   #print('x=', x)
   #yt = x
   #for i in range(nc):
   #  t = t0*x[0]/x[i]
   #  yt[i] = t
 
   #multiple line plot
    for num in range(nl):
      line[n] = plt.plot(x, ts[num], marker='', color=colorlist[num], linewidth=2, alpha=0.9, label=namelist[num])
   #line[nl] = plt.plot(x, yt, marker='x', color='green', linewidth=3, alpha=0.95, label=namelist[num])

   #Add title and axis names
   #plt.title(title)
    plt.xlabel('Procs')
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
      imgname = 'lin_plot_%d-%d.png' %(ns, ns+nl)
    else:
      imgname = 'log_plot_%d-%d.png' %(ns, ns+nl)
   #plt.show()
    plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def plot_orig_multiple(self, ns, nl):
    title = 'Function %d-%d' %(ns, ns+nl)

    nc = len(self.caselist)
    x = np.array(self.caselist)
    ts = {}
    namelist = []
    line = []

    ymin = 1.0e+36
    ymax = 0.0

    for n in range(nl):
      nt = ns + n
      idx = self.stats_list[0][1][nt]
      name = self.stats_list[0][0][idx]['name']
      nlst = name.split('::')
      namelist.append(nlst[-1])
      pl = None
      line.append(pl)
      ts[n] = []
      for i in range(nc):
        ni = self.find_gen_name_idx(i, idx)
        t = 0.001*self.stats_list[i][0][ni]['time']
       #print('n = ' + str(n) + ', i = ' + str(i) + ', ni = ' + str(ni) + ', t = ' + str(t))
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

   #Initialize the figure
    plt.style.use('seaborn-darkgrid')
 
   #create a color palette
   #palette = plt.get_cmap('Set1')
    palette = plt.get_cmap('rainbow_r')
 
   #multiple line plot
    for num in range(nl):
      pnum = num + 1
     #Find the right spot on the plot
     #plt.subplot(3, 3, pnum)
 
     #plot every groups, but discreet
     #for v in df.drop('x', axis=1):
     #  plt.plot(df['x'], df[v], marker='', color='grey', linewidth=0.6, alpha=0.3)
 
     #Plot the lineplot
     #plt.plot(df['x'], df[column], marker='o', color=palette(pnum), linewidth=2.4, alpha=0.9, label=column)
 
     #print('ts[' + str(num) + '] = ', ts[num])

      line[n] = plt.plot(x, ts[num], marker='', color=palette(16*pnum), linewidth=2, alpha=0.9, label=namelist[num])
     #line[n] = plt.plot(x, ts[num], marker='', color=palette(pnum), linewidth=2, label=namelist[num])

   #Add title and axis names
   #plt.title(title)
    plt.xlabel('Procs')
    plt.ylabel('Time(ms)')

    if(self.linear):
      pass
    else:
      plt.xscale("log", base=2)
      plt.yscale("log", base=10)

    plt.legend()
 
    plt.title(title)

    if(self.linear):
      imgname = 'lin_plot_%d-%d.png' %(ns, ns+nl)
    else:
      imgname = 'log_plot_%d-%d.png' %(ns, ns+nl)
   #plt.show()
    plt.savefig(imgname)

    plt.cla()
    plt.clf()

  def plot_panel(self, ns):
    nv = len(self.stats_list[0][1])
    if(nv < ns+9):
      return

    title = 'Function %d-%d' %(ns, ns+9)

    nc = len(self.caselist)
    x = np.array(self.caselist)
    ts = {}
    namelist = []

    ymin = 1.0e+36
    ymax = 0.0

    for n in range(10):
      nt = ns + n
      idx = self.stats_list[0][1][nt]
      name = self.stats_list[0][0][idx]['name']
      nlst = name.split('::')
      namelist.append(nlst[-1])
      ts[n] = []
      for i in range(nc):
        ni = self.find_gen_name_idx(i, idx)
        t = 0.001*self.stats_list[i][0][ni]['time']
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

   #if(ymin > 1000.0):
   #  ymin = float(100*(int(ymin)/100))
   #  ymax = float(100*(1 + int(ymax)/100))
   #elif(ymin > 100.0):
   #  ymin = float(10*(int(ymin)/10))
   #  ymax = float(10*(1 + int(ymax)/10))
   #elif(ymin > 10.0):
   #  ymin = float(int(ymin))
   #  ymax = float(1 + int(ymax))

   #Make a data frame
    df = pd.DataFrame({'x': x,
                       namelist[0]: ts[0],
                       namelist[1]: ts[1],
                       namelist[2]: ts[2],
                       namelist[3]: ts[3],
                       namelist[4]: ts[4],
                       namelist[5]: ts[5],
                       namelist[6]: ts[6],
                       namelist[7]: ts[7],
                       namelist[8]: ts[8],
                       namelist[9]: ts[9]})
 
   #Initialize the figure
    plt.style.use('seaborn-darkgrid')
 
   #print(plt.colormaps())
   # ['Accent', 'Accent_r', 'Blues', 'Blues_r', 'BrBG', 'BrBG_r', 'BuGn', 'BuGn_r', 'BuPu', 'BuPu_r', 'CMRmap', 'CMRmap_r', 'Dark2', 'Dark2_r', 'GnBu', 'GnBu_r', 'Greens', 'Greens_r', 'Greys', 'Greys_r', 'OrRd', 'OrRd_r', 'Oranges', 'Oranges_r', 'PRGn', 'PRGn_r', 'Paired', 'Paired_r', 'Pastel1', 'Pastel1_r', 'Pastel2', 'Pastel2_r', 'PiYG', 'PiYG_r', 'PuBu', 'PuBuGn', 'PuBuGn_r', 'PuBu_r', 'PuOr', 'PuOr_r', 'PuRd', 'PuRd_r', 'Purples', 'Purples_r', 'RdBu', 'RdBu_r', 'RdGy', 'RdGy_r', 'RdPu', 'RdPu_r', 'RdYlBu', 'RdYlBu_r', 'RdYlGn', 'RdYlGn_r', 'Reds', 'Reds_r', 'Set1', 'Set1_r', 'Set2', 'Set2_r', 'Set3', 'Set3_r', 'Spectral', 'Spectral_r', 'Wistia', 'Wistia_r', 'YlGn', 'YlGnBu', 'YlGnBu_r', 'YlGn_r', 'YlOrBr', 'YlOrBr_r', 'YlOrRd', 'YlOrRd_r', 'afmhot', 'afmhot_r', 'autumn', 'autumn_r', 'binary', 'binary_r', 'bone', 'bone_r', 'brg', 'brg_r', 'bwr', 'bwr_r', 'cividis', 'cividis_r', 'cool', 'cool_r', 'coolwarm', 'coolwarm_r', 'copper', 'copper_r', 'cubehelix', 'cubehelix_r', 'flag', 'flag_r', 'gist_earth', 'gist_earth_r', 'gist_gray', 'gist_gray_r', 'gist_heat', 'gist_heat_r', 'gist_ncar', 'gist_ncar_r', 'gist_rainbow', 'gist_rainbow_r', 'gist_stern', 'gist_stern_r', 'gist_yarg', 'gist_yarg_r', 'gnuplot', 'gnuplot2', 'gnuplot2_r', 'gnuplot_r', 'gray', 'gray_r', 'hot', 'hot_r', 'hsv', 'hsv_r', 'inferno', 'inferno_r', 'jet', 'jet_r', 'magma', 'magma_r', 'nipy_spectral', 'nipy_spectral_r', 'ocean', 'ocean_r', 'pink', 'pink_r', 'plasma', 'plasma_r', 'prism', 'prism_r', 'rainbow', 'rainbow_r', 'seismic', 'seismic_r', 'spring', 'spring_r', 'summer', 'summer_r', 'tab10', 'tab10_r', 'tab20', 'tab20_r', 'tab20b', 'tab20b_r', 'tab20c', 'tab20c_r', 'terrain', 'terrain_r', 'turbo', 'turbo_r', 'twilight', 'twilight_r', 'twilight_shifted', 'twilight_shifted_r', 'viridis', 'viridis_r', 'winter', 'winter_r']

   #create a color palette
   #palette = plt.get_cmap('Set1')
   #palette = plt.get_cmap('Sequential')
    palette = plt.get_cmap('rainbow_r')

    colorlist = ['grey', 'red', 'orange', 'cyan', 'blue', 'black', 'magenta', 'yellow', 'darkgreen', 'darkblue', 'darkgrey']
 
   #multiple line plot
    num=0
    for column in df.drop('x', axis=1):
      num+=1
 
     #Find the right spot on the plot
      plt.subplot(3,3, num)
 
     #plot every groups, but discreet
      for v in df.drop('x', axis=1):
        plt.plot(df['x'], df[v], marker='', color='grey', linewidth=0.5, alpha=0.3)
 
     #Plot the lineplot
      plt.plot(df['x'], df[column], marker='o', color=palette(16*num), linewidth=2, alpha=0.9, label=column)
     #plt.plot(df['x'], df[column], marker='o', color=colorlist[num], linewidth=3, alpha=0.9, label=column)
 
     #Same limits for everybody!
      plt.xlim(x[0], x[-1])
     #plt.ylim(0.0, 40000)
      plt.ylim(ymin, ymax)
 
     #Not ticks everywhere
     #if num in range(7) :
     #  plt.tick_params(labelbottom='off')
      if num not in [3, 6, 9]:
        plt.tick_params(labelbottom='off')
      if num not in [1,4,7] :
        plt.tick_params(labelleft='off')
 
      plt.xticks(x)

     #Add title
     #plt.title(column, loc='Center', fontsize=12, fontweight=0, color=palette(num) )
      plt.legend()
 
     #general title
      plt.suptitle(title, fontsize=13, fontweight=0, color='black', style='italic', y=1.02)
 
     #Axis title
     #plt.text(0.5, 0.02, 'Proc', ha='center', va='center')
     #plt.text(0.06, 0.5, 'TIme(ms)', ha='center', va='center', rotation='vertical')

      plt.xlabel('Procs')
      plt.ylabel('Time(ms)')

      if(self.linear):
        pass
      else:
        plt.xscale("log", base=2)
        plt.yscale("log", base=10)

    if(self.linear):
      imgname = 'lin_panel_%d-%d.png' %(ns, ns+9)
    else:
      imgname = 'log_panel_%d-%d.png' %(ns, ns+9)
   #plt.show()
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

  def plot_par_panel(self, ns):
    nv = len(self.stats_list[0][3])
    if(nv < ns+9):
      return

    title = 'Parallel Function %d-%d' %(ns, ns+9)

    nc = len(self.caselist)
    x = np.array(self.caselist)
    ts = {}
    namelist = []

    for i in range(nc):
      nv = len(self.stats_list[i][3])
     #print('Case ' + str(i) + ' has ' + str(nv) + ' vars')


    ymin = 1.0e+36
    ymax = 0.0

    for n in range(10):
      nt = ns + n
      idx = self.stats_list[0][3][nt]
      name = self.stats_list[0][2][idx]['name']
      nlst = name.split('::')
      namelist.append(nlst[-1])
      ts[n] = []
      for i in range(nc):
        ni = self.find_par_name_idx(i, idx)
        t = 0.001*self.stats_list[i][2][ni]['avg']
        ts[n].append(t)
        if(t > ymax):
          ymax = t
        if(t < ymin):
          ymin = t

   #Make a data frame
    df = pd.DataFrame({'x': x,
                       namelist[0]: ts[0],
                       namelist[1]: ts[1],
                       namelist[2]: ts[2],
                       namelist[3]: ts[3],
                       namelist[4]: ts[4],
                       namelist[5]: ts[5],
                       namelist[6]: ts[6],
                       namelist[7]: ts[7],
                       namelist[8]: ts[8],
                       namelist[9]: ts[9]})
 
   #Initialize the figure
    plt.style.use('seaborn-darkgrid')
 
   #create a color palette
   #palette = plt.get_cmap('Set1')
   #palette = plt.get_cmap('Sequential')
    palette = plt.get_cmap('rainbow_r')

    colorlist = ['grey', 'red', 'orange', 'cyan', 'blue', 'black', 'magenta', 'yellow', 'darkgreen', 'darkblue', 'darkgrey']
 
   #multiple line plot
    num=0
    for column in df.drop('x', axis=1):
      num+=1
 
     #Find the right spot on the plot
      plt.subplot(3,3, num)
 
     #plot every groups, but discreet
      for v in df.drop('x', axis=1):
        plt.plot(df['x'], df[v], marker='', color='grey', linewidth=0.5, alpha=0.3)
 
     #Plot the lineplot
      plt.plot(df['x'], df[column], marker='o', color=palette(16*num), linewidth=2, alpha=0.9, label=column)
     #plt.plot(df['x'], df[column], marker='o', color=colorlist[num], linewidth=3, alpha=0.9, label=column)
 
     #Same limits for everybody!
      plt.xlim(x[0], x[-1])
     #plt.ylim(0.0, 40000)
      plt.ylim(ymin, ymax)
 
     #Not ticks everywhere
     #if num in range(7) :
     #  plt.tick_params(labelbottom='off')
      if num not in [3, 6, 9]:
        plt.tick_params(labelbottom='off')
      if num not in [1,4,7] :
        plt.tick_params(labelleft='off')
 
      plt.xticks(x)

     #Add title
     #plt.title(column, loc='Center', fontsize=12, fontweight=0, color=palette(num) )
      plt.legend()
 
     #general title
      plt.suptitle(title, fontsize=13, fontweight=0, color='black', style='italic', y=1.02)
 
     #Axis title
     #plt.text(0.5, 0.02, 'Proc', ha='center', va='center')
     #plt.text(0.06, 0.5, 'TIme(ms)', ha='center', va='center', rotation='vertical')

      if num in [7, 8, 9]:
        plt.xlabel('Procs')
      if num in [1,4,7] :
        plt.ylabel('Time(sec)')

      if(self.linear):
        pass
      else:
        plt.xscale("log", base=2)
        plt.yscale("log", base=10)

    if(self.linear):
      imgname = 'lin_par_panel_%d-%d.png' %(ns, ns+9)
    else:
      imgname = 'log_par_panel_%d-%d.png' %(ns, ns+9)
   #plt.show()
    plt.savefig(imgname)

    plt.cla()
    plt.clf()

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
 #workdir = '/scratch2/BMC/gsienkf/Wei.Huang/jedi/run/profiling'
  workdir = '.'
  caselist = [6, 12, 18, 24, 30, 36]
 #elaped = [87.586, 39.165, 33.037, 28.109, 29.311, 25.728]
  elaped = None
  linear = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'workdir=',
    'caselist='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--workdir'):
      workdir = a
    elif o in ('--caselist'):
      caselist = a
    elif o in ('--linear'):
      linear = int(a)
    else:
      assert False, 'unhandled option'

  pr = Profiler(debug=debug, caselist=caselist, workdir=workdir, elaped=elaped, linear=linear)
  pr.process()
  pr.plot_total()
  pr.plot_multiple(0, 9)
  pr.plot_panel(0)
  pr.plot_panel(9)
 #pr.plot_panel(18)
  pr.plot_par_panel(0)
  pr.plot_par_panel(3)

