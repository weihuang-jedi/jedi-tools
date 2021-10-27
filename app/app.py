import os
import sys
import types
import getopt

from PyQt5.QtCore import QSize, Qt
from PyQt5.QtWidgets import QApplication, QMainWindow, QPushButton, QLabel
from PyQt5.QtWidgets import QWidget, QVBoxLayout

#------------------------------------------------------------------------------
class DisplayWindow(QWidget):
  """
  This "window" is a QWidget. If it has no parent, it
  will appear as a free-floating window as we want.
  """
  def __init__(self):
    super().__init__()
    layout = QVBoxLayout()
    self.label = QLabel("Display Window")
    layout.addWidget(self.label)
    self.setLayout(layout)

#------------------------------------------------------------------------------
#Subclass QMainWindow to customize your application's main window
class MainWindow(QMainWindow):
  def __init__(self):
    super().__init__()
    self.setWindowTitle("My App")

    self.button_is_checked = True
    self.button = QPushButton("Press Me!")
    self.button.setCheckable(True)
    self.button.clicked.connect(self.the_button_was_clicked)
    self.button.clicked.connect(self.the_button_was_toggled)
    self.button.released.connect(self.the_button_was_released)
    self.button.setChecked(self.button_is_checked)

   #Set the central widget of the Window.
    self.setCentralWidget(self.button)

    self.show_display_window()

  def the_button_was_clicked(self):
    print("Clicked!")

  def the_button_was_toggled(self, checked):
   #print("Checked?", checked)
    self.button_is_checked = checked 
    print(self.button_is_checked)

  def the_button_was_released(self):
    self.button_is_checked = self.button.isChecked()
    print(self.button_is_checked)

  def show_display_window(self):
    self.display = DisplayWindow()
    self.display.show()

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

