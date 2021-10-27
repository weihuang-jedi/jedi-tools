import os
import sys
import types
import getopt

from PyQt5.QtCore import QSize, Qt
from PyQt5.QtWidgets import QApplication, QMainWindow, QPushButton

#Subclass QMainWindow to customize your application's main window
class MainWindow(QMainWindow):
  def __init__(self):
    super().__init__()
    self.setWindowTitle("My App")

    button = QPushButton("Press Me!")
    button.setCheckable(True)
    button.clicked.connect(self.the_button_was_clicked)
    button.clicked.connect(self.the_button_was_toggled)

   #Set the central widget of the Window.
    self.setCentralWidget(button)

  def the_button_was_clicked(self):
    print("Clicked!")

  def the_button_was_toggled(self, checked):
    print("Checked?", checked)

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)

  app = QApplication(sys.argv)
  window = MainWindow()
  window.show()
  app.exec()

