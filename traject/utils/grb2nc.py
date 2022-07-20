import os, sys
import glob
import getopt
import pygrib

import xarray as xr
import numpy as np

import subprocess

#-------------------------------------------------------------------------------------------
class Grb2NC():
  def __init__(self, debug=0):
    self.debug = debug

    if(self.debug):
      print('debug = ', debug)

  def process_file(self, infilename=None):
    if(not os.path.isfile(infilename)):
      print('input file %s does not exist. Stop' %infilename)
      sys.exit(-1)
      
    print('Processing file: ', infilename)

    path, flnm = os.path.split(infilename)
    outfilename = '%s' %(flnm.replace('.grb2', '.nc4'))

   #cmdstr = 'wgrib2 %s %s' %(infilename, outfilename)
   #cmdstr = 'ncl_convert2nc %s -nc4c -cl 2 %s' %(infilename, outfilename)
    cmdstr = 'ncl_convert2nc %s -nc4 -cl 2 -o output' %(infilename)

    print(cmdstr)

    os.system(cmdstr)

   #result = subprocess.run(['wgrib2', infilename, '-netcdf', outfilename], stdout=subprocess.PIPE)
   #result.stdout

#------------------------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  datadir = '/work2/noaa/gsienkf/weihuang/gfs/data/'

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'datadir='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--datadir'):
      datadir = a
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('datadir = ', datadir)

 #open input file to get input grid
 #files=glob.glob('ocn_????_??_??.nc')
  files=glob.glob(datadir + 'gfs_4_????????_??00_000.grb2')
  files.sort()

 #print('files = ', files)

  g2n = Grb2NC(debug=debug)

  for infile in files:
    g2n.process_file(infilename=infile)

