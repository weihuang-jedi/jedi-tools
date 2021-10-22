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
from os.path import isfile, join, islink, exists
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
    self.dict = {}

    filelist = []
    dir_list = []
    for item in listdir(self.workdir):
      name = join(self.workdir, item)
      if(isfile(name)):
        filelist.append(name)
      else:
        dir_list.append(name)

   #if(self.debug):
   #  print('filelist: ', filelist)
   #  print('dir_list: ', dir_list)

    for d in dir_list:
      if(d.find('.git') > 0):
        continue
      self.process_dir(d)

    for d in dir_list:
      if(d.find('.git') > 0):
        continue
     #self.write_dir(d)
      if(d.find('oops') > 0):
        self.write_dir(d)

  def process_dir(self, d):
    filelist = []
    dir_list = []
    for item in listdir(d):
      name = join(d, item)
      if(islink(name)):
        continue

      if(isfile(name)):
        filelist.append(name)
      else:
        dir_list.append(name)

   #if(self.debug):
   #  print('filelist: ', filelist)
   #  print('dir_list: ', dir_list)

    for d in dir_list:
      if(d.find('.git') > 0):
        continue
      self.process_dir(d)

    for f in filelist:
      self.preprocess_file(f)

  def write_dir(self, d):
    filelist = []
    dir_list = []
    for item in listdir(d):
      name = join(d, item)
      if(islink(name)):
        continue

      if(isfile(name)):
        filelist.append(name)
      else:
        dir_list.append(name)

    for d in dir_list:
      if(d.find('.git') > 0):
        continue
      self.write_dir(d)

    for f in filelist:
      self.write_file(f)

  def iscode(self, flnm):
    item = flnm.split('.')
    if(len(item) > 1):
      if(item[-1] in ['h', 'c', 'cc', 'cxx', 'f', 'F', 'f90', 'F90']):
        return 1
    return 0

  def get_include_name(self, incstr):
    item = incstr.split(' ')
    incname = item[-1][1:-2]
    return incname

  def preprocess_file(self, flnm):
    if(islink(flnm)):
      return

   #if(os.path.exists(flnm)):
   #  if(self.debug):
   #    print('Process file: ', flnm)
   #else:
   #  print('Filename ' + flnm + ' does not exit. Stop')
   #  sys.exit(-1)

    htmlfile = flnm.replace(self.workdir, self.htmldir)
    htmlfile = '%s.html' %(htmlfile)
    htmldir, filename = os.path.split(htmlfile)
    os.system('mkdir -p ' + htmldir)

    srccode = self.iscode(flnm)

    if(srccode):
      sp = len(self.workdir)
      hp = len(self.htmldir)
      sname = flnm[sp+1:]
      self.dict[sname] = {}
      self.dict[sname]['html'] = htmlfile
     #self.dict[sname]['html'] = htmlfile[hp:]
      self.dict[sname]['include'] = []

      with open(flnm, 'r', encoding="ascii", errors="surrogateescape") as fp:
        print('Process file: ', sname)
       #print('Process file: ', htmlfile[hp+1:])
        lines = fp.readlines()
       #num_lines = len(lines)
       #print('Total number of lines: ', num_lines)
        for line in lines:
          if(line.find('#include') >= 0):
            if(line.find('>') < 0):
              incname = self.get_include_name(line)
              print(incname)
              self.dict[sname]['include'].append(incname)
   #else:
   #  self.print_file(flnm)

  def get_inclink(self, line):
    incname = self.get_include_name(line)
    link = line.rstrip()
    for key in self.dict.keys():
      if(key.find(incname) > 0):
        html = '<a href="file://' + self.dict[key]['html'] + '">'  + incname + '</a>'
        link = link.replace('"', '&quot;')
        link = link.replace(incname, html)
        break
    return link

  def write_file(self, flnm):
    if(islink(flnm)):
      return

    htmlfile = flnm.replace(self.workdir, self.htmldir)
    htmlfile = '%s.html' %(htmlfile)
    htmldir, filename = os.path.split(htmlfile)
    os.system('mkdir -p ' + htmldir)

    srccode = self.iscode(flnm)

    if(srccode):
      sp = len(self.workdir)
      sname = flnm[sp+1:]
      HTML = open(htmlfile, 'w', encoding="ascii", errors="surrogateescape")
      HTML.write('<h2>' + sname + '</h2>\n')
      HTML.write('<html>\n')
      HTML.write('<body>\n')
      HTML.write('<ol>\n')

      with open(flnm, 'r', encoding="ascii", errors="surrogateescape") as fp:
        print('Process file: ', sname)
        lines = fp.readlines()
       #num_lines = len(lines)
       #print('Total number of lines: ', num_lines)
        for line in lines:
          if(line.find('#include') >= 0):
            if(line.find('>') < 0):
              html = self.get_inclink(line)
              print(html)
            else:
              html = line.rstrip().replace('<', '&lt;')
              html = html.replace('>', '&gt;')
            HTML.write('  <li>' + html + '</li>\n')
          else:
            HTML.write('  <li><code>' + line.rstrip() + '</code></li>\n')

      HTML.write('</ol>\n')
      HTML.write('</body>\n')
      HTML.write('</html>\n')
      HTML.close()

  def isdatafile(self, flnm):
    item = flnm.split('.')
    if(len(item) > 1):
      if(item[-1] in ['nc', 'nc4', 'hdf', 'h5', 'pdf', 'png', 'gif', 'jpeg']):
        return 1
    return 0

  def print_file(self, flnm):
    if(os.path.exists(flnm)):
      if(self.isdatafile(flnm)):
        return
      else:
        print('Print file: ', flnm)
    else:
      print('Filename ' + flnm + ' does not exit. Stop')
      sys.exit(-1)

    htmlfile = flnm.replace(self.workdir, self.htmldir)
    htmlfile = '%s.html' %(htmlfile)
    htmldir, filename = os.path.split(htmlfile)
    os.system('mkdir -p ' + htmldir)

    sp = len(self.workdir)
    HTML = open(htmlfile, 'w')
    HTML.write('<h2>' + flnm[sp+1:] + '</h2>\n')
    HTML.write('<html>\n')
    HTML.write('<body>\n')
    HTML.write('<ol>\n')

    with open(flnm) as fp:
      lines = fp.readlines()
     #num_lines = len(lines)
     #print('Total number of lines: ', num_lines)
      for line in lines:
        HTML.write('  <li>' + line.rstrip() + '</li>\n')

    HTML.write('</ol>\n')
    HTML.write('</body>\n')
    HTML.write('</html>\n')
    HTML.close()
    
"""
<h1>Largest Heading</h1>
<h2> . . . </h2>
<h3> . . . </h3>
<h4> . . . </h4>
<h5> . . . </h5>
<h6>Smallest Heading</h6>

<p>This is a paragraph.</p>
<br> (line break)
<hr> (horizontal rule)
<!-- This is a comment -->

<b>Bold text</b>
<code>Computer code</code>
<em>Emphasized text</em>
<i>Italic text</i>
<kbd>Keyboard input</kbd> 
<pre>Preformatted text</pre>
<small>Smaller text</small>
<strong>Important text</strong>
"""

#--------------------------------------------------------------------------------
if __name__== '__main__':
  debug = 1
 #workdir = '/work/noaa/gsienkf/weihuang/jedi/src/fv3-bundle-omp-log-control'
  workdir = '/Users/whuang/jedi/navigating/fv3-bundle'
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

