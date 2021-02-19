#########################################################################
#$Id: bld.py 28 2021-01-21 15:10:31Z whuang $
#$Revision: 28 $
#$HeadURL: file:///Users/whuang/.wei_svn_repository/trunk/jedi-build-tools/bld.py $
#$Date: 2021-01-21 08:10:31 -0700 (Thu, 21 Jan 2021) $
#$Author: whuang $
#########################################################################

import os, sys
import time
import datetime

""" Profiler """
class Profiler:
  """ Constructor """
  def __init__(self, debug=0):

    """ Initialize class attributes """
    self.debug = debug

  def process(self):
    username = os.environ['LOGNAME']
    cmd= 'squeue -u %s > joblist' %(username)
    os.system(cmd)

    with open('joblist') as fp:
      lines = fp.readlines()
      num_lines = len(lines)
      print('Total number of lines: ', num_lines)

      nl = 1
      while(nl < num_lines):
        item = lines[nl].strip().split(' ')
        jobid = item[0]
        pinfo = 'Job %d: %s' %(nl, jobid)
        print(pinfo)
        cmd = 'scancel %s' %(jobid)
        os.system(cmd)
        nl += 1

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1

  pr = Profiler(debug=debug)
  pr.process()

