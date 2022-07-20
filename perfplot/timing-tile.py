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

from genplot import GeneratePlot as genplot

def cmdout(command):
    result = run(command, stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
    ostr = result.stdout
    return ostr.strip()

""" TimingTile """
class TimingTile:
  """ Constructor """
  def __init__(self, debug=0, workdir=None):
    """ Initialize class attributes """
    self.debug = debug
    self.workdir = workdir

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    nc = 0
    self.filelist = []
    for root, dirs, files in os.walk(workdir):
      for filename in files:
        if(filename.find('stderr') >= 0):
          continue
       #print('File No %d: %s' %(nc, filename))
        self.filelist.append(filename)
        nc += 1

    self.filelist.sort()
   #print('filelist: ', self.filelist)

  def process(self):
    self.lon = []
    self.lat = []
    self.loc = []
    self.stats = []

    nc = 0
    for flnm in self.filelist:
      nc += 1
      if(self.debug):
        print('Processing case ' + str(nc) + ': ' + flnm)
      lon, lat, stats = self.get_stats(flnm)
      loc = {}
      loc['lon'] = lon
      loc['lat'] = lat
      self.loc.append(loc)
      self.stats.append(stats)
      self.lon.extend(lon)
      self.lat.extend(lat)

   #self.lon = np.array(self.lon)
   #self.lat = np.array(self.lat)

  def get_latlon(self):
    return self.lat, self.lon

  def get_val(self, name):
   #val = np.zeros(len(self.lon), dtype=float)
   #val = np.linspace(1, len(self.lon), len(self.lon))
    val = []
    idx = self.get_idx(name)
    i = 0
    for n in range(len(idx)):
      if(idx[n] >= 0):
        t = 0.001*self.stats[n][idx[n]]['time']
      else:
        t = 0.0

     #print('Tile %d time %f, name: %s' %(n, t, name))

      ni = len(self.loc[n]['lon'])
      for k in range(ni):
        val.append(t)
        i += 1

    print('len(self.lon) = ', len(self.lon))
    print('len(val) = ', len(val))

    return val
      
  def get_stats(self, flnm):
    fullpath = '%s/%s' %(self.workdir, flnm)
    if(os.path.exists(fullpath)):
      pass
    else:
      print('Filename ' + fullpath + ' does not exit. Stop')
      sys.exit(-1)

    lon = []
    lat = []
    time = []

    with open(fullpath) as fh:
      lines = fh.readlines()
      num_lines = len(lines)
     #print('Total number of lines: ', num_lines)

      nl = 0
      while(nl < num_lines):
       #if(lines[nl].find('Longitude:') > 0):
       #  item = lines[nl].split(':')
       #  lonitem = item[1].split(',')
       #  lonval = float(lonitem[0].strip())
       #  latval = float(item[2].strip())
       #  print('lon: %f, lat: %f' %(lonval, latval))
       #  lon.append(lonval)
       #  lat.append(latval)
        if(lines[nl].find('Longitude:') > 0):
          item = lines[nl].split(':')
          lonval = float(item[1].strip())
         #print('lon: %f' %(lonval))
          lon.append(lonval)
        elif(lines[nl].find('Latitude:') > 0):
          item = lines[nl].split(':')
          latval = float(item[1].strip())
         #print('lat: %f' %(latval))
          lat.append(latval)
        elif(lines[nl].find('Timing Statistics') > 0):
         #if(self.debug):
         #  print('Start Timing Statistics')
          nl, stats = self.time_stats(lines, nl)
          nl += num_lines
        nl += 1

    return lon, lat, stats

  def time_stats(self, lines, nl):
    stats = {}
    going = 1
    idx = 0
   #print('lines[nl]:', lines[nl])

    if(lines[nl].find('OOPS_STATS ') >= 0):
      ns = nl + 6
     #print('1. lines[nl]:', lines[nl])
    else:
      ns = nl + 3
     #print('2. lines[nl]:', lines[nl])

    while(going):
      line = lines[ns].strip()
     #print('Line ' + str(ns) + ': ' + line)
      ns += 1
      if(line.find('Timing Statistics') > 0):
        going = 0
        break

      item = line.split(': ')
     #print(item)
      name = item[0].strip()

      tstr = item[1].strip()
      while(tstr.find('  ') > 0):
        tstr = tstr.replace('  ', ' ')
      nlist = tstr.split(' ')
      ft = float(nlist[0])
      tinfo = {}
      tinfo['name'] = name
      tinfo['time'] = float(nlist[0])
      tinfo['call'] = int(nlist[1])

      stats[idx] = tinfo

     #pinfo = '\t%50s%10.2f%8d' %(stats[idx]['name'], stats[idx]['time'], stats[idx]['call'])
     #print(pinfo)

      idx += 1

    return ns, stats

  def get_idx(self, name):
    self.idx = []
    for n in range(len(self.stats)):
      stats = self.stats[n]
      idx = -1
      for k in stats.keys():
       #if(n == 0):
       #  print('No %d name: %s' %(k, stats[k]['name']))
        if(stats[k]['name'] == name):
          idx = k
          break
      self.idx.append(idx)

    return self.idx

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
  output = 0
  workdir = '/work2/noaa/gsienkf/weihuang/jedi/case_study/satwind/run_80.40t1n_36p/stdoutNerr.2'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output=', 'workdir='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
    elif o in ('--workdir'):
      workdir = a
    else:
      assert False, 'unhandled option'

  tt = TimingTile(debug=debug, workdir=workdir)
  tt.process()
  lat, lon = tt.get_latlon()

  gp = genplot(debug=debug, output=output, lat=lat, lon=lon)

 #val = tt.get_val('util::Timers::Total')

  namelist = ['fv3jedi::IOFms::read state',
              'fv3jedi::IOFms::write increment',
              'fv3jedi::VarChaModel2GeoVaLs::changeVar',
              'oops::GETKFSolver::applyWeights',
              'oops::GETKFSolver::computeHofX',
              'oops::GETKFSolver::computeWeights',
              'oops::GETKFSolver::measurementUpdate',
              'oops::Geometry::Geometry',
              'oops::GetValues::GetValues',
              'oops::GetValues::fillGeoVaLs',
              'oops::Increment::getLocal',
              'oops::LocalEnsembleSolver::computeHofX',
              'oops::ObsError::ObsErrors',
              'oops::ObsError::update',
              'oops::ObsOperator::Radiosonde::ObsOperator',
              'oops::ObsSpace::save',
              'oops::ObsVector::packEigen',
              'oops::ObsVector::packEigenSize',
              'oops::Parameters::validate',
              'oops::State::State',
              'oops::State::toFieldSet',
              'oops::UnstructuredInterpolator::UnstructuredInterpolator',
              'oops::UnstructuredInterpolator::apply',
              'oops::VariableChange::changeVar',
              'util::Timers::Total',
              'util::Timers::measured']
  for name in namelist:
    print('processing: ', name)
    val = tt.get_val(name)
    namestr = name.replace('::', '_')
    namestr = namestr.replace(' ', '_')
    gp.set_imagename(namestr)
    gp.set_title(name)
    gp.plot(val)

