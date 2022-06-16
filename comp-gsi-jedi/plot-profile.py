#=========================================================================
import os
import sys
import types
import getopt

import numpy as np
import matplotlib.pyplot as plt

#=========================================================================
with open('profile_data.txt', 'r') as filehandle:
  lines = filehandle.readlines()

  diminfo = lines[0].split(', ')
  nz = int(diminfo[0])
  ny = int(diminfo[1])
  nx = int(diminfo[2])

  gsi_sqrt = []
  jedi_sqrt = []
  gsi_jedi_sqrt = []
  normerr = []

  for i in range(nz):
    item = lines[i+1].split(', ')
    gsi_sqrt.append(float(item[0]))
    jedi_sqrt.append(float(item[1]))
    gsi_jedi_sqrt.append(float(item[2]))
    rms = 100.0*float(item[2])/float(item[0])
    normerr.append(rms)

  print('len(gsi_sqrt) = ', len(gsi_sqrt))

  print('nz = ', nz)
  print('ny = ', ny)
  print('nx = ', nx)

  print('gsi_sqrt = ', gsi_sqrt)
  print('jedi_sqrt = ', jedi_sqrt)
  print('gsi_jedi_sqrt = ', gsi_jedi_sqrt)
  print('normerr = ', normerr)

  y = np.arange(0.0, float(nz), 1.0)

  plt.figure(num = 3, figsize=(8, 5))  
  plt.plot(gsi_sqrt, y,
           color='blue',
           linewidth=1.5,
           linestyle='--')

  plt.plot(jedi_sqrt, y, 
           color='black',  
           linewidth=1.5,  
           linestyle='dotted')

  plt.plot(gsi_jedi_sqrt, y, 
           color='red',  
           linewidth=2.0)

 #plt.xlim((0, 0.10))  
 #plt.xlim((0, 0.20))  
 #plt.xlim((0, 0.30))  
 #plt.xlim((0, 0.40))  
 #plt.xlim((0, 0.50))  
 #plt.xlim((0, 0.60))  
  plt.xlim((0, 0.80))  
  plt.ylim((0, nz-1))  

  ax = plt.gca()
  ax.xaxis.set_ticks_position('bottom')
  ax.yaxis.set_ticks_position('left')

 #plt.title('uvOnly Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
 #plt.title('PS Only Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
 #plt.title('New uv Only Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
  plt.title('use delp PS Only Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
  plt.ylabel('Level', fontsize=14)
  plt.grid(True)

  plt.legend(['Sqrt(GSI^2)', 'Sqrt(JEDI^2)', 'Sqrt((GSI-JEDI)^2)'])

 #plt.show()
  plt.savefig('rmserr.png')

  plt.clf()

  plt.plot(normerr, y,
           color='blue',
           linewidth=2.0)

 #plt.xlim((0, 120.0))
 #plt.xlim((0, 200.0))
  plt.xlim((0, 400.0))
  plt.ylim((0, nz-1))  

  ax = plt.gca()
  ax.xaxis.set_ticks_position('bottom')
  ax.yaxis.set_ticks_position('left')

  plt.title('Rate of Sqrt(Mean((GSI-JEDI)^2)/Mean(GSI^2))', fontsize=14)
  plt.xlabel('%', fontsize=14)
  plt.ylabel('Level', fontsize=14)
  plt.grid(True)

 #plt.show()
  plt.savefig('rate.png')

