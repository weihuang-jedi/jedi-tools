#########################################################################
#$Id: bld.py 28 2021-01-21 15:10:31Z whuang $
#$Revision: 28 $
#$HeadURL: file:///Users/whuang/.wei_svn_repository/trunk/jedi-build-tools/bld.py $
#$Date: 2021-01-21 08:10:31 -0700 (Thu, 21 Jan 2021) $
#$Author: whuang $
#########################################################################

import getopt
import os, sys
from os import listdir
from os.path import isfile, join
import time
import datetime

""" Generate HTML links for JEDI """
class GenHTML4JEDI:
  """ Constructor """
  def __init__(self, debug=0, workdir=None, htmldir=None):
    """ Initialize class attributes """
    self.debug = debug
    self.workdir = workdir
    self.htmldir = htmldir

    if(workdir is None):
      print('workdir not defined. Exit.')
      sys.exit(-1)

    if(htmldir is None):
     #os.chdir(os.path.dirname(__file__))
      self.htmldir = os.getcwd()
      print('self.htmldir: ', self.htmldir)

  def process(self):
   #onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]

    filelist = []
    dir_list = []
    for item in listdir(self.workdir):
      if(isfile(join(self.workdir, item))):
        filelist.append(item)
      else:
        dir_list.append(item)

    if(self.debug):
      print('filelist: ', filelist)
      print('dir_list: ', dir_list)

    parentdir = self.workdir
    for newdir in dir_list:
      self.process_dir(parentdir, newdir)

  def process_dir(self, parentdir, newdir):
    currentdir = join(parentdir, newdir)
    parentdir = currentdir
    filelist = []
    dir_list = []
    for item in listdir(currentdir):
      if(isfile(join(currentdir, item))):
        filelist.append(item)
      else:
        dir_list.append(item)

    if(self.debug):
      print('filelist: ', filelist)
      print('dir_list: ', dir_list)

    parentdir = currentdir
    for newdir in dir_list:
      self.process_dir(parentdir, newdir)

  def stats(self, flnm):
    if(os.path.exists(flnm)):
      pass
    else:
      print('Filename ' + flnm + ' does not exit. Stop')
      sys.exit(-1)

    with open(flnm) as fp:
      lines = fp.readlines()
      num_lines = len(lines)
      print('Total number of lines: ', num_lines)

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
  workdir = '/work/noaa/gsienkf/weihuang/jedi/src/fv3-bundle-omp-log-control'
  htmldir = None

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'workdir=', 'htmldir='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--workdir'):
      workdir = a
    elif o in ('--htmldir'):
      htmldir = a
    else:
      assert False, 'unhandled option'

  gh = GenHTML4JEDI(debug=debug, workdir=workdir, htmldir=htmldir)
  gh.process()

