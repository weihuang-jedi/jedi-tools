#=========================================================================
import os
import sys
import types
import getopt
import netCDF4
import numpy as np
import matplotlib.pyplot as plt

def gen_pressure(filename):
  ncfile = netCDF4.Dataset(filename)
  ak = ncfile.variables['ak'][0, :]
  bk = ncfile.variables['bk'][0, :]
  ncfile.close()

 #print('ak = ', ak)
 #print('bk = ', bk)

  print('len(ak) = ', len(ak))
  print('len(bk) = ', len(bk))

  nlevs = len(ak)

 #constants
  rd = 2.8705e+2
  cp = 1.0046e+3
  kap = rd/cp
  kapr = cp/rd
  kap1 = kap + 1.0

 #set mean surface pressure (has to be a global constant)
  psgmean = 1.e5

  fullpres = np.empty((nlevs), 'd')  # interface pressure
  halfpres = np.empty((nlevs-1), 'd')  # mid-layer pressure

  for k in range(nlevs):
    fullpres[k] = ak[k] + bk[k]*psgmean
  for k in range(nlevs-1):
   #phillips vertical interpolation from guess_grids.F90 in GSI (used for global model)
    halfpres[k] = ((fullpres[k]**kap1-fullpres[k+1]**kap1)
                  /(kap1*(fullpres[k]-fullpres[k+1])))**kapr
   #simple average of interface pressures (used by fv3_regional in GSI)
   #halfpres[k] = 0.5*(fullpres[k]+fullpres[k+1])
   #linear in logp interpolation from interface pressures
   #halfpres[k] = np.exp(0.5*(np.log(fullpres[k])+np.log(fullpres[k+1])))

  logp = -np.log(halfpres) # (ranges from -2 to -11)

 #print('fullpres = ', fullpres)
 #print('halfpres = ', halfpres)
  print('len(logp) = ', len(logp))
  print('logp = ', logp)

  return fullpres, halfpres, logp

#=========================================================================
gsi_sqrt = []
jedi_sqrt = []
gsi_jedi_sqrt = []
normerr = []

with open('profile_data.txt', 'r') as filehandle:
  lines = filehandle.readlines()

diminfo = lines[0].split(', ')
nz = int(diminfo[0])

for i in range(nz):
  item = lines[i+1].split(', ')
  gsi_sqrt.append(float(item[0]))
  jedi_sqrt.append(float(item[1]))
  gsi_jedi_sqrt.append(float(item[2]))
  rms = 100.0*float(item[2])/float(item[0])
  normerr.append(rms)

print('len(gsi_sqrt) = ', len(gsi_sqrt))
print('nz = ', nz)

#print('gsi_sqrt = ', gsi_sqrt)
#print('jedi_sqrt = ', jedi_sqrt)
#print('gsi_jedi_sqrt = ', gsi_jedi_sqrt)
#print('normerr = ', normerr)

y = np.arange(0.0, float(nz), 1.0)

plt.figure(num = 3, figsize=(8, 5))  
plt.plot(gsi_sqrt, y, color='blue', linewidth=1.5, linestyle='--')
plt.plot(jedi_sqrt, y, color='black',  linewidth=1.5,  linestyle='dotted')
plt.plot(gsi_jedi_sqrt, y, color='red',  linewidth=2.0)

plt.xlim((0, 0.80))  
plt.ylim((0, nz-1))  

ax = plt.gca()
ax.xaxis.set_ticks_position('bottom')
ax.yaxis.set_ticks_position('left')

plt.title('delp PS Only Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
plt.ylabel('Level', fontsize=14)
plt.grid(True)

plt.legend(['Sqrt(GSI^2)', 'Sqrt(JEDI^2)', 'Sqrt((GSI-JEDI)^2)'])

#plt.show()
plt.savefig('rmserr.png')

#--------------------------------------------------------------------------------------------------
plt.clf()

plt.plot(normerr, y, color='blue', linewidth=2.0) 

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

#--------------------------------------------------------------------------------------------------
fullpres, halfpres, logp = gen_pressure('akbk64.nc4')

markpres = [1000.0, 700.0, 500.0, 300.0, 200.0, 100.0,
            50.0, 30.0, 20.0, 10.0, 5.0, 3.0, 2.0, 1.0]
marklogp = np.empty((len(markpres)), 'f')
for n in range(len(markpres)):
  marklogp[n] = -np.log(100.0*markpres[n])

plt.clf()

plt.xlim((0, 0.80))
plt.ylim((0.2, 1000.0))

ax = plt.gca()
ax.xaxis.set_ticks_position('bottom')
ax.yaxis.set_ticks_position('left')

print('len(gsi_sqrt) = ', len(gsi_sqrt))
print('len(fullpres) = ', len(fullpres))
print('len(halfpres) = ', len(halfpres))

plt.plot(gsi_sqrt[::-1], halfpres[::-1], color='blue', linewidth=1.5, linestyle='--')
plt.plot(jedi_sqrt[::-1], halfpres[::-1], color='black', linewidth=1.5, linestyle='dotted')
plt.plot(gsi_jedi_sqrt[::-1], halfpres[::-1], color='red', linewidth=2.0)

plt.title('PS Only Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
plt.ylabel('Pressure (hPa)', fontsize=14)
#plt.grid(True)

ax.set_yticks(markpres[::-1])
ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
ax.set_ylabel('Unit: hPa')

yticklabels = []
for p in markpres:
  lbl = '%d' %(int(p+0.1))
  yticklabels.append(lbl)
ax.set_yticklabels(yticklabels)

plt.legend(['Sqrt(GSI^2)', 'Sqrt(JEDI^2)', 'Sqrt((GSI-JEDI)^2)'])

#plt.show()
plt.savefig('rmserr_p.png')

#--------------------------------------------------------------------------------------------------
plt.clf()

plt.plot(normerr[::-1], halfpres[::-1], color='blue', linewidth=2.0)

plt.xlim((0, 400.0))
plt.ylim((0.2, 1000.0))

ax = plt.gca()
ax.xaxis.set_ticks_position('bottom')
ax.yaxis.set_ticks_position('left')

plt.title('Rate of Sqrt(Mean((GSI-JEDI)^2)/Mean(GSI^2))', fontsize=14)
plt.xlabel('%', fontsize=14)
plt.ylabel('Pressure (hPa)', fontsize=14)
plt.grid(True)

#plt.show()
plt.savefig('rate_p.png')

#--------------------------------------------------------------------------------------------------
plt.clf()

#len(logp) =  64
#logp =  [ -3.70519741  -4.59897694  -5.18564904  -5.59502281  -5.91991073
# ......
# -11.49061789 -11.49802967 -11.50454108 -11.51025664]

plt.xlim((0, 0.80))
plt.ylim((-12.0, -3.50))

ax = plt.gca()
ax.xaxis.set_ticks_position('bottom')
ax.yaxis.set_ticks_position('left')

plt.plot(gsi_sqrt[::-1], logp[::-1], color='blue',
         linewidth=1.5, linestyle='--')

plt.plot(jedi_sqrt[::-1], logp[::-1], color='black',
         linewidth=1.5, linestyle='dotted')

plt.plot(gsi_jedi_sqrt[::-1], logp[::-1],
         color='red', linewidth=2.0)

plt.legend(['Sqrt(GSI^2)', 'Sqrt(JEDI^2)', 'Sqrt((GSI-JEDI)^2)'])

ax.set_yticks(marklogp)
ax.grid(b=True, which='major', color='green', linestyle='-', alpha=0.5)
ax.set_ylabel('Unit: hPa')

yticklabels = []
for p in markpres:
  lbl = '%d' %(int(p+0.1))
  yticklabels.append(lbl)
ax.set_yticklabels(yticklabels)

plt.title('PS Only Sqrt(Mean(GSI^2)), Sqrt(Mean((JEDI)^2)) and Sqrt(Mean((GSI-JEDI)^2))', fontsize=10)
plt.ylabel('Pressure (hPa)', fontsize=14)
plt.grid(True)

#plt.show()
plt.savefig('rmserr_logp.png')

