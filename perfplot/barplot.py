import matplotlib.pyplot as plt; plt.rcdefaults()
import numpy as np
import matplotlib.pyplot as plt

objects = ('12', '24', '48', '120')
x_pos = np.arange(len(objects))
perf = [152436, 107831, 74783, 57188]

plt.bar(x_pos, perf, align='center', alpha=0.5)
plt.xticks(x_pos, objects)
plt.xlabel('Number of Cores')
plt.ylabel('Time (sec)')
plt.title('LETKF Speed-Up')

plt.show()

